#!/bin/bash

#pASDI
#v2.0
#GCH - 5/26/21

#Major Revision History:
#7/19/2021 - pASDI v2.0 now generates a "logName"-ircdata.txt file from .fchk file (need a .log and a .chk file as input, now)
	 #This enables pASDI to extract geometries for structures with >50 atoms (this output is suppressed in .log for >50 atoms)
	 #comment line of the generated .xyz files will have "charge= x mult= y" line
	 #This line used (awk) to make g16 inputs with fragment-specific charge/mult 

### COLORS FOR FUN FORMATTING ###
RED='\033[0;31m'
GREEN='\033[0;32m'
PURP='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

### PRINT JOB HEADER ###
echo ""
echo "-----------------------------------------------------------------"
echo "                              pASDI                              "
echo "              Activation Strain/Distortion Interaction           "
echo "-----------------------------------------------------------------"

#temporarily using an awk script to etract geoms - will roll in to be self-contained, later
### POINT TO SCRIPTS DIRECTORY ###
shopt -s expand_aliases
#You will need to point this as where your scripts are
source /home1/05793/rdg758/scripts/alii.env


#Function to parse user-specified range for a fragment (ex: a ligand)
function cleanRange {
	#Split on commas/spaces first; this chunks down into mini-ranges
	#likely fails for sequential delimiters
        #ex: "1-3,5 9-10"
        IFS=', ' read -a ranges <<< "$*"
        for range in "${ranges[@]}"; do
		IFS=- read start end <<< "$range"
                [ -z "$start" ] && continue
                [ -z "$end" ] && end=$start
                for (( i=start ; i <= end ; i++ )); do
			echo "$i"
		done
	done
}

function list2range {
	echo $frag2range, | sed "s/,/\n/g" | while read num; do
	if [[ -z $first ]]; then
		first=$num; last=$num; continue;
	fi
	if [[ num -ne $((last + 1)) ]]; then
		if [[ first -eq last ]]; then echo $first; else echo $first-$last; fi
		first=$num; last=$num
	else
		: $((last++))
	fi
done | paste -sd ","
}

function whichDFA {
#what basis set to use
	echo ''
	echo -e "${GREEN}Select a DFA to use:${NC}"
	dfaQ=$(echo -e "${CYAN}List or manual?   ${NC}")
	initOptions=("Pick from a list" "Enter manually")
	PS3=$dfaQ
	COLUMNS=0
	select initCase in "${initOptions[@]}"; do
		case $REPLY in
			1) #Pick from a list
				#This is a simple list of my most commonly used and doesn't include "gen" option, yet
				#eventually include options for SP basis sets like TZVPPD - but will need a "database" file that has the
				#BS for each atom and can parse geoms for atoms to determine - much more complicated case
				echo ''
				echo -e "${GREEN}Select a DFA from the list: ${NC}"
				selectDFA=$(echo -e "${CYAN}Which DFA:  ${NC}")
				#can add/remove common options, here
				dfaOptions=("M06-2X(D3)" "wB97X-D" "PW6B95(D3BJ)" "PBEO(D3BJ)" "B3LYP(D3BJ)" "CAM-B3LYP(D3BJ)" "MN15")
				PS3=$selectDFA
				select dfa in "${dfaOptions[@]}"; do
					case $REPLY in
						1) #M06-2X(D3)
							export DFA='m062x'
							export DISPERSION='empiricaldispersion=gd3'
							echo -e "${GREEN}Using DFA: ${CYAN}M06-2X(D3)${NC}\n"
							export xc='-m062xd3'
							break;;
							
						2) #wB97X-D
							export DFA='wb97xd'
							export DISPERSION=''
							echo -e "${GREEN}Using DFA: ${CYAN}wB97X-D${NC}\n"
							export xc='-wb97xd'
							break;;
							
						3) #PW6B95-D3BJ
							export DFA='pw6b95d3'
							export DISPERSION='empiricaldispersion=gd3bj'
							echo -e "${GREEN}Using DFA: ${CYAN}PW6B95(D3BJ){NC}\n"
							export xc='-pw6b95d3bj'
							break;;
						4) #PBE0-D3
							export DFA='pbe1pbe'
							export DISPERSION='empiricaldispersion=gd3bj'
							echo -e "${GREEN}Using DFA: ${CYAN}PBE0(D3BJ)${NC}\n"
							export xc='-pbe0d3bj'
							break;;
	
						5) #B3LYP-D3BJ
							export DFA='b3lyp'
							export DISPERSION='empiricaldispersion=gd3bj'
							echo -e "${GREEN}Using DFA: ${CYAN}B3LYP(D3BJ){NC}\n"
							export xc='-b3lypd3bj'
							break;;
							
						6) #CAM-B3LYP-D3BJ
							export DFA='cam-b3lyp'
							export DISPERSION='empiricaldispersion=gd3bj'
							echo -e "${GREEN}Using DFA: ${CYAN}CAM-B3LYP(D3BJ){NC}\n"
							export xc='-camb3lypd3bj'
							break;;
						
						7) #MN15
							export DFA='mn15'
                                                        export DISPERSION=''
                                                        echo -e "${GREEN}Using DFA: ${CYAN}MN15${NC}\n"
                                                        export xc='-mn15'
                                                        break;;
							
						*) #Error Catch
							echo -e "${RED}Error: ${NC} select one of the above DFAs...\n"
							continue;;
					esac
				done
				break;;
				
			2) # User Enters DFA Manually
				echo""
				echo -e "${RED}Make sure your keyword format is correct...${NC}"
				userDFA=$(echo -e "${GREEN}Type your DFA keyword: ${NC}")
				read -ep "$userDFA" typedDFA
				echo -e "${GREEN}Using DFA: ${CYAN}$typedDFA${NC}\n"
				export DFA=${typedDFA}
				export xc='-${typedDFA}'
				
				#check if user wants to specify a dispersion method in addition to their entered DFA
				while true; do
				userDisp=$(echo -e "${GREEN}Specify empirical dispersion? (y/n) ${NC}")
				read -ep "$userDisp" yn
					case $yn in
						[Yy]* ) #yes case
							selectDisp=$(echo -e "${GREEN}Select D3 or D3(BJ) Dispersion.${NC}")
							dispOptions=("D3" "D3(BJ)")
							PS3=$selectDisp
							COLUMNS=0
							select dispmodel in "${dispOptions[@]}"; do
								case $REPLY in
									1) #D3
										export DISPERSION='empiricaldispersion=gd3'
										echo -e "${GREEN}Using dispersion: ${CYAN}D3${NC}"
										break;;
										
									2) #D3(BJ)
										export DISPERSION='empiricaldispersion=gd3bj'
										echo -e "${GREEN}Using dispersion: ${CYAN}D3(BJ)${NC}"
										break;;
										
									*) #Error Catch
										echo -e "${RED}Error: ${NC} select D3 or D3(BJ) dispersion...\n"
										continue;;
								esac
							done 
							break;;	
							
						[Nn]* ) #no case
							export DISPERSION=''
							break;;
							
						* )	#error case
							echo -e "${RED}Enter y/n...\n${NC}"
							continue;;
					esac
				done
				break;;
			
			*) #Error Catch
				echo -e "${RED}Error: ${NC} select option 1 or 2...\n"
				continue;;
		esac
	done
}

function whichBasis {
	#what basis set to use
	echo -e "${GREEN}Which Basis Set to use:${NC}"
	basisQ=$(echo -e "${CYAN}Select Basis Set option.   ${NC}")
	initOptions=("Pick from a list" "Enter manually")
	PS3=$basisQ
	COLUMNS=0
	select initCase in "${initOptions[@]}"; do
		case $REPLY in
			1) #Pick from a list
				#This is a simple list of my most commonly used and doesn't include "gen" option, yet
				#eventually include options for SP basis sets like TZVPPD - but will need a "database" file that has the
				#BS for each atom and can parse geoms for atoms to determine - much more complicated case
				echo ""
				echo -e "${GREEN}Which Basis set:${NC}"
				selectBasis=$(echo -e "${CYAN}Select a Basis Set option:  ${NC}")
				#can add/remove common options, here
				basisOptions=("def2-SVP" "def2-TZVP" "6-31+G*" "6-311+G**")
				PS3=$selectBasis
				select basisSet in "${basisOptions[@]}"; do
					case $REPLY in
						1) #def2-SVP
							export BASIS='def2svp'
							echo -e "${GREEN}Using Basis: ${CYAN}def2-SVP${NC}\n"
							export bset='-def2svp'
							break;;
							
						2) #def2-TZVP
							export BASIS='def2tzvp'
							echo -e "${GREEN}Using Basis: ${CYAN}def2-TZVP${NC}\n"
							export bset='-def2tzvp'
							break;;
							
						3) #6-31+G*
							export BASIS='6-31+g*'
							echo -e "${GREEN}Using Basis: ${CYAN}6-31+G*${NC}\n"
							export bset='-dzpop'
							break;;
							
						4) #6-311+G**
							export BASIS='6-311+g**'
							echo -e "${GREEN}Using Basis: ${CYAN}6-311+G**${NC}\n"
							export bset='-tzpop'
							break;;
							
						*) #Error Catch
							echo -e "${RED}Error: ${NC} select one of the above basis sets...\n"
							continue;;
					esac
				done
				break;;
				
			2) # Enter Manually
				echo""
				echo -e "${RED}Make sure your format is correct...${NC}"
				userBasis=$(echo -e "${GREEN}Type your basis set: ${NC}")
				read -ep "$userBasis" typedBasis
				echo -e "${GREEN}Using Basis: ${CYAN}$typedBasis${NC}\n"
				export BASIS=${typedBasis}
				export bset='-${typedBasis}'
				break;; 
				
			*) #Error Catch
				echo -e "${RED}Error: ${NC} select option 1 or 2...\n"
				continue;;
		esac
	done
}

function whichSolvation {
	#choose gas phase or solvation calculation
	while true; do
		ynSolvation=$(echo -e "${GREEN}Use Solvation model? ${CYAN}(y/n) ${NC}")
		read -ep "$ynSolvation" yn
			case $yn in 
				[Yy]* ) #yes case => need to select solvation model
					echo ""
					echo -e "${GREEN}Which solvation model?${NC}"
					selectISM=$(echo -e "${CYAN}Select SMD/PCM:   ${NC}")
					ismOptions=("SMD" "PCM")
					PS3=$selectISM
					COLUMNS=0
					select ism in "${ismOptions[@]}"; do
						case $REPLY in
							1) #SMD Model
								#specify the solvent
								echo ""
								echo -e "${GREEN}Model which solvent with SMD:${NC}"
								solventID=$(echo -e "${CYAN}Select a solvent:   ${NC}")
								#can add more solvents here as needed
								solvOptions=("Water" "MeCN" "DCM" "DMF" "THF" "DMAc" "TFE")
								PS3=$solventID
								COLUMNS=0
								select solvID in "${solvOptions[@]}"; do
									case $REPLY in
										1) #water
											export SOLVATION='scrf=(solvent=water,smd)'
											echo -e "${GREEN}Using solvation: ${CYAN}SMD(water)${NC}"
											export solv='-smd'
											break;;
										
										2) #acetonitrile
											export SOLVATION='scrf=(solvent=acetonitrile,smd)'
											echo -e "${GREEN}Using solvation: ${CYAN}SMD(MeCN)${NC}"
											export solv='-smd'
											break;;
												
										3) #dichloromethane
											export SOLVATION='scrf=(solvent=dichloromethane,smd)'
											echo -e "${GREEN}Using solvation: ${CYAN}SMD(DCM)${NC}"
											export solv='-smd'
											break;;
										4) #n,n-dimethylformamide
											export SOLVATION='scrf=(solvent=n,n-dimethylformamide,smd)'
											echo -e "${GREEN}Using solvation: ${CYAN}SMD(DMF)${NC}"
											export solv='-smd'
											break;;

										5) #tetrahydrofuran
											export SOLVATION='scrf=(solvent=tetrahydrofuran,smd)'
											echo -e "${GREEN}Using solvation: ${CYAN}SMD(THF)${NC}"
                                                                                        export solv='-smd'
                                                                                        break;;

										6) #n,n-dimetyhlacetamide
                                                                                        export SOLVATION='scrf=(solvent=n,n-dimethylacetamide,smd)'
                                                                                        echo -e "${GREEN}Using solvation: ${CYAN}SMD(DMAc)${NC}"
                                                                                        export solv='-smd'
                                                                                        break;;
											
										7) #2,2,2-trifluoroethanol
											export SOLVATION='scrf=(solvent=2,2,2-trifluoroethanol,smd)'
                                                                                        echo -e "${GREEN}Using solvation: ${CYAN}SMD(TFE)${NC}"
                                                                                        export solv='-smd'
                                                                                        break;;
										
											
										*) #error case
											echo -e "${RED}Choose from one of the listed solvents...\n${NC}"
											continue;;
									esac
								done
								break;;
										
							2) #PCM Model
								#specify the solvent
								echo ""
								echo -e "${GREEN}Model which solvent with PCM:${NC}"
								solventID=$(echo -e "${CYAN}Select a solvent:   ${NC}")
								#can add more solvents here as needed
								solvOptions=("Water" "MeCN" "DCM")
								PS3=$solventID
								COLUMNS=0
								select solvID in "${solvOptions[@]}"; do
									case $REPLY in
										1) #water
											export SOLVATION='scrf=(solvent=water,pcm)'
											echo -e "${GREEN}Using solvation: ${CYAN}PCM(water)${NC}"
											export solv='-pcm'
											break;;
											
										2) #acetonitrile
											export SOLVATION='scrf=(solvent=acetonitrile,pcm)'
											echo -e "${GREEN}Using solvation: ${CYAN}PCM(MeCN)${NC}"
											export solv='-pcm'
											break;;
												
										3) #dichloromethane
											export SOLVATION='scrf=(solvent=dichloromethane,pcm)'
											echo -e "${GREEN}Using solvation: ${CYAN}PCM(DCM)${NC}"
											export solv='-pcm'
											break;;
											
										*) #error case
											echo -e "${RED}Choose from one of the listed solvents...\n${NC}"
											continue;;
									esac
								done
								break;;
									
							*) #Error Catch
								echo -e "${RED}Error: ${NC} select SMD or PCM...\n"
								continue;;
						esac
					done 
					break;;	
					
				[Nn]* ) #no case => Gas Phase calc
					export SOLVATION=''
					export solv=''
					break;;
						
				* )	#error case
					echo -e "${RED}Enter y/n...\n${NC}"
					continue;;
			esac
	done
}	

function captureGeomXYZ {
#	inputName=$(basename "$1")
#	geom=$(awk '$1 ~ /[A-Z]/ {printf "%-2s  %15s %15s %15s\n", $1, $2, $3, $4}' $inputName)
#	printf "$geom"
inputName=$(basename "$1")
#get the charge/mult line
chamult=$(sed -n '2 p' $inputName)
#get the geom lines
geomBlock=$(awk '$1 ~ /[A-Z]/ {printf "%-2s  %15s % 15s %15s\n", $1, $2, $3, $4}' $inputName)
#stick them together
geom=$(printf -- "${chamult}\n${geomBlock}\n")
printf -- "$geom\n"
}

function whichQ {
	#which queue to run on - determines %nproc and %mem parameters in input.com's
	echo ""
	queueQ=$(echo -e "${GREEN}Which queue to use?   ${NC}")
	queueOptions=("Normal" "SKX-Normal")
	PS3=$queueQ
	COLUMNS=0
	select qCase in "${queueOptions[@]}"; do 
		case $REPLY in
			1) #Normal
				export NUMTASK=64
				export MEM=70
				echo -e "${GREEN}Using queue: ${CYAN}Normal${NC}\n"
				break;;

			2) #SKX-Normal
				export NUMTASK=48
				export MEM=128
				echo -e "${GREEN}Using queue: ${CYAN}SKX${NC}\n"
				break;;

			*) #Error Catch
				echo -e "${RED}Error: ${NC} select Normal or SKX...\n"
				continue;;
		esac
	done
}

#Do we need to make individual .xyz files from an irc.log or are they already present?
echo -e "\n${CYAN}What's the status of your .xyz files?${NC}"
xyzExistQ=$(echo -e "${CYAN}Select an option:   ${NC}")
xyzExistOptions=("Extract .xyz files from an IRC.log" "Current folder already contains needed .xyz's") 
PS3=$xyzExistQ
COLUMNS=0
select xyzCase in "${xyzExistOptions[@]}"; do 
	case $REPLY in
		1)	#extract from irc.log
			#ask user for the log file name 
			userIRCfile=$(echo -e "\n${CYAN}What is the name of your irc.log file? (no extension)   ${NC}")
			read -ep "$userIRCfile" typedIRC
			#echo -e "${CYAN}Using IRC file: ${PURP}$typedIRC${NC}\n"
			
			#Check that their file exists in current directory; otherwise exit
			if [[ -f "./${typedIRC}.log" ]] && [[ -f "./${typedIRC}.chk" ]]; then
				echo -e "${PURP}${typedIRC}.log ${GREEN}FOUND${NC}"
				echo -e "${PURP}${typedIRC}.chk ${GREEN}FOUND${NC}"
			#otherwise, exit
			elif [[ -f "./${typedIRC}.log" ]] && [[ ! -f "./${typedIRC}.chk" ]]; then
				echo -e "${PURP}${typedIRC}.log${NC} ${GREEN}FOUND"
				echo -e "${PURP}${typedIRC}.chk ${RED}NOT FOUND${NC}"	
				echo -e "\n${CYAN}Both .log and .chk must exist in current directory.${NC}"
				echo -e "${RED}EXITING...\n${NC}"
				exit 1
			#otherwise, exit
			else
				echo -e "${RED}No file was found matching ${PURP}${typedIRC}.${NC}"
				echo -e "${RED}EXITING...\n${NC}"
				exit 1
			fi

			#ask user to confirm selection
			while true; do
				userConfirm=$(echo -e "${CYAN}Confirmed? ${NC}(y/n)  ")
				read -ep "$userConfirm" yn
				case $yn in
					[Yy]* )
						 break ;;
					[Nn]* )
					echo -e "${RED}EXITING...\n${NC}"
					exit;;
					* ) 
						echo -e "${RED}Enter y/n...\n${NC}"
						continue;;
				esac 
			done
			
			#assign user's irc name to working logName
			logName=$(echo "$typedIRC")
			#echo "logname is $logName"
	
			### CAPTURE CHARGE/MULTIPLICITY FOR THE COMPLEX FROM THE LOG FILE ###
			#extract charge and mult from .log file
			chargeLine=$(grep 'Charge =' ${logName}.log | sed 's/^ *//g'| sed 's/* $//g')
			chargeTrim=$(echo $chargeLine | sed -ne 's/^[^0-9-]*\([0-9-][0-9]*\) [a-zA-Z]* = \([0-9]*\).*$/\1 \2 /p')
			#store values into vars for printing 
			molCharge=$(echo $chargeTrim | awk '{print $1}')
			export CHARGE=${molCharge}
			molMult=$(echo $chargeTrim | awk '{print $2}')
			export MULT=${molMult}

			#array with periodic table IDs - for replacing #'erd atom indices 
			periodicTable=("" "H" "He" "Li" "Be" "B" "C" "N" "O" "F" "Ne" "Na" "Mg" "Al" "Si" "P" "S" "Cl" "Ar" "K" "Ca" "Sc" "Ti" "V" "Cr" "Mn" "Fe"
              		  "Co" "Ni" "Cu" "Zn" "Ga" "Ge" "As" "Se" "Br" "Kr" "Rb" "Sr" "Y" "Zr" "Nb" "Mo" "Tc" "Ru" "Rh" "Pd" "Ag" "Cd" "In" "Sn" "Sb"
 			  "Te" "I" "Xe" "Cs" "Ba" "La" "Ce" "Pr" "Nd" "Pm" "Sm" "Eu" "Gd" "Tb" "Dy" "Ho" "Er" "Tm" "Yb" "Lu" "Hf" "Ta" "W" "Re" "Os" 
			  "Ir" "Pt" "Au" "Hg" "Tl" "Pb" "Bi" "Po" "At" "Rn" "Fr" "Ra" "Ac" "Th" "Pa" "U" "Np" "Pu" "Am" "Cm" "Bk" "Cf" "Es" "Fm" 
			  "Md" "No" "Lr" "Rf" "Db" "Sg" "Bh" "Hs" "Mt" "Ds" "Rg" "Uub" "Uut" "Uuq" "Uup" "Uuh" "Uus" "Uuo")

			### LOCATE THE INDIVIDUAL GEOMETRIES IN THE LOG FILE ### 
			#will now get all the xyz files from the fchk file, instead, since this method works for systems of >50 atoms
			
			#need a formchk file for the current job
			echo -e "\n${CYAN}Creating formatted .fchk: ${PURP}${logName}.fchk${NC}"
			module load gaussian			
			formchk ${logName}.chk
				
			#generate a temp.txt file with the extracted coordinates using extract_irc.awk script
			echo -e "\n${CYAN}Extracting IRC xyz's from: ${PURP}${logName}.fchk${NC}"
			echo -e "${CYAN}Summary of IRC data written to: ${PURP}${logName}-ircdata.txt${NC}"
			extract_irc ${logName}.fchk > ${logName}-ircdata.txt 
			
			
			#the "POINT" starting line #s
			sGeoms=$(awk '/Point/ {print FNR}' ${logName}-ircdata.txt | tr '\n\r' ' ')
			IFS=' ' read -r -a sGeomArray <<< "$sGeoms"
			sCount="${#sGeomArray[@]}"
			#debug
			#echo "sCount = ${sCount}"
			
			#the "----" ending line #s; omit the first instance
			eGeoms=$(awk '/----------/ {print FNR}' ${logName}-ircdata.txt | tail -n +2 | tr '\n\r' ' ')
		        IFS=' ' read -r -a eGeomArray <<< "$eGeoms"
			eCount="${#eGeomArray[@]}"
			#debug
			#echo "eCount = ${eCount}"


			#capture the raw geoms from the output.log per the identified indices, above
			#store them into an array "geomArray" 
			declare -a geomArray
			j=1
			for (( i=1; i<$sCount; i++ ));	do
				startVar=${sGeomArray[i]}
				endVar=${eGeomArray[j]}
				capGeom=$(sed -n "${startVar}, ${endVar}p" ${logName}-ircdata.txt)
				currentGeom=$(echo "$capGeom" | awk '$1 ~ /[0-9]/ {print}')				
				geomArray+=("$currentGeom")	
				(( j+=1 ))	
			done

			#how many geoms were captured
			geomsCount="${#geomArray[@]}"
			#debug
			#echo "#geoms extracted: $geomsCount "
			echo -e "\n${CYAN}Extracting ${PURP}${geomsCount} ${CYAN}geometries from ${PURP}${logName}-ircdata.txt....${NC}"
	
			### CONVERT THE EXTRACTED GEOMS TO INDIVIDUAL $logName-xyz#.xyz FILES ###
			#set a 1-indexed counter to append output filenames 
			itercount=1
			for (( i=0; i<$geomsCount; i++ )) do
				#capture the first column from the raw output (atom indices) 
				declare -a atomNumbers
				capturedColumn=$(echo "${geomArray[i]}" | awk '{print $1}')
				#stick these into an array
				for f in $capturedColumn; do
					atomNumbers+=("$f")
				done	
	
				#how many atoms are in a geom?
				numAtoms="${#atomNumbers[@]}"
	
				declare -a atomNames
				for atom in "${atomNumbers[@]}"; do
		                	currentAtom=$(echo "${periodicTable[$atom]}")
               				atomNames+=($currentAtom)
				done
	
				ithXYZ=$(echo "${geomArray[i]}" | awk '{printf "\t %15s %15s %15s \n", $2,$3,$4}')	
				#store its currentXYZ lines into an array
				SAVEIFS=$IFS
				IFS=$'\n'
				ithXYZArray=($ithXYZ)
	
				lineCount="${#atomNames[@]}"
	
				declare -a atomSubsArray
				for (( j=0; j<$lineCount; j++ )) do
        	        		currentLine=$(echo -e "${atomNames[j]}${ithXYZArray[j]}")
					atomSubsArray+=($currentLine)
				done

				#check if xyz's already exist for the targeted output; append '.bak' to the old ones
				if [ -f "${logName}-xyz${itercount}.xyz" ]; then
					mv ./${logName}-xyz${itercount}.xyz ./${logName}-xyz${itercount}.xyz.bak
				fi
	
				#add the #atoms to the top of each .xyz file 
				echo -e "$numAtoms" >> ./${logName}-xyz${itercount}.xyz

				#In the comment line, store charge/mult of the complex for g16 input creation
				echo -e "${molCharge} ${molMult}" >> ./${logName}-xyz${itercount}.xyz  

				#output the array into a numbered file.xyz
				for entry in "${atomSubsArray[@]}"; do
		                	echo "$entry" >> ./${logName}-xyz${itercount}.xyz
				done
	
				#provide a list of the .xyz's that were generated 
				echo -e "${GREEN}Created: ${CYAN}${logName}-xyz${itercount}.xyz${NC}"
	
				#unset the current iteration's temp arrays	
				atomNumbers=()	
				atomNames=()
				ithXYZArray=()
				atomSubsArray=()

				#iterate itercount
				(( itercount+=1 ))
			done
			
			### NOW WORKING WITH FRAGMENTS ###
			sampleGeom=$(awk '$1 ~ /[A-Z]/ {printf "%-2s  %15s %15s %15s\n", $1, $2, $3, $4}' ${logName}-xyz1.xyz)
			numberAtoms=$(echo "$sampleGeom" | wc -l)
			#echo "contains atoms: $numberAtoms"
			sampleNumGeom=$(echo "$sampleGeom" | cat -n)

			#put all the "complete" geometries into an array "to be divided" 
			declare -a tbdArray 
			for (( xyzNum=1; xyzNum<$itercount; xyzNum++ )) do
				fullGeom=$(awk '$1 ~ /[A-Z]/ {printf "%-2s  %15s %15s %15s\n", $1, $2, $3, $4}' ./${logName}-xyz${xyzNum}.xyz)
				tbdArray+=("$fullGeom")
			done

			#count how many frag geoms will need to be made
			fragGeomsCount="${#tbdArray[@]}" 
			#echo "fragGeomsCount = $fragGeomsCount"
				
			while true; do 
				userConfirm=$(echo -e "\n${CYAN}Define fragments for the pASDI analysis? ${NC}(y/n)  ")
				read -ep "$userConfirm" yn
				case $yn in
					[Yy]* )	
						userFrag1=$(echo -e "\n${GREEN}Specify ${PURP}Fragment1 ${GREEN}by atom indices (ex: 1-3,5,9-11). \n${CYAN}Enter range: ${NC}")
						read -ep "$userFrag1" frag1
						#echo "frag1 is: $frag1"
						fragment1=($(cleanRange $frag1))
	
						#make sure the user-defined fragment is in ascending order
						IFS=$'\n' sortedFrag1=($(sort -n <<< "${fragment1[*]}"))
						unset IFS
						
						declare -a fragArray1
						for capLN in "${sortedFrag1[@]}"; do
							IFS=$'\n'
							capturedRow=($(echo "$sampleNumGeom" | awk -v k=$capLN 'NR==k {printf "%-2s %15s %15s %15s \n", $2, $3, $4, $5}'))
						#	echo "$capturedRow"
							fragArray1+=($capturedRow)
						done
					
						#count how many atoms in fragment1	
						lenfrag1Array="${#fragArray1[@]}"
						
						#echo the fragment 1 definition
						echo -e "\n${PURP}Fragment1 ${CYAN}includes atoms: ${NC}${frag1}"
						#for i in "${fragArray1[@]}"; do
				        		#print the data corresponding to captured atom#
						#	echo $i
						#done

						#make an variable that contains #numberAtoms elements
						declare -a numberlist
						for (( i=1; i<=$numberAtoms; i++ )) do
							numberlist+=($i)
						done
						
						#get fragment1 charge/mult from user entry
						userFrag1Charge=$(echo -e "${GREEN}Enter ${PURP}Fragment1 ${GREEN}charge: ${NC}")
						read -ep "$userFrag1Charge" frag1C
						frag1Charge=$frag1C
						userFrag1Mult=$(echo -e "${GREEN}Enter ${PURP}Fragment1 ${GREEN}multiplicity: ${NC}")
                                                read -ep "$userFrag1Mult" frag1M
						frag1Mult=$frag1M
						
						#trim the frag1 values from a new array describing frag2 (remaining lines)
						declare -a deleteFrag1
						for ln in "${sortedFrag1[@]}"; do
							deleteFrag1+=($ln)
						done
						for del in ${deleteFrag1[@]}; do 
							for i in "${!numberlist[@]}"; do
								if [[ ${numberlist[i]} = $del ]]; then
								unset 'numberlist[i]'
							fi
							done
						done

						#fragment2 will be everything not defined in fragment 1
						declare -a fragArray2
						#for each line number contained in the user's fragment1 defintion
						#print all the lines of the geometry that are NOT those lines (omit those line numbers) 
						for ln in "${numberlist[@]}"; do						
							IFS=$'\n'
							capturedRow=($(echo "$sampleNumGeom" | awk -v k=$ln 'NR==k {printf "%-2s %15s %15s %15s \n", $2, $3, $4, $5}'))
							fragArray2+=($capturedRow)
						done
						
						#count the number of atoms in frag2
						lenfrag2Array="${#fragArray2[@]}"
					
						#transfer numberlist numbers into a variable to convert into range
						frag2rangeraw=""
						for ln in "${numberlist[@]}"; do
							frag2rangeraw="$frag2rangeraw$ln,"
						done
						#trim the last comma
						frag2range=$(echo $frag2rangeraw | sed 's/.$//')
						#condense into range
						condensedFrag2=$(list2range)
							
						#echo the fragment2 definition
						echo -e "\n${PURP}Fragment2 ${CYAN}includes remaining atoms:${NC} $condensedFrag2"
						#for i in "${fragArray2[@]}"; do
				        		#print the data corresponding to captured atom#
						#	echo $i
						#done	
					        
						#get fragment2 charge/mult from user entry
                                                userFrag2Charge=$(echo -e "${GREEN}Enter ${PURP}Fragment2 ${GREEN}charge: ${NC}")
                                                read -ep "$userFrag2Charge" frag2C
						frag2Charge=$frag2C
						userFrag2Mult=$(echo -e "${GREEN}Enter ${PURP}Fragment2 ${GREEN}multiplicity: ${NC}")
                                                read -ep "$userFrag2Mult" frag2Mult
						frag2Mult=$frag2Mult
						
						#check that fragment definition(s) are correct:
						while true; do
							fragConfirm=$(echo -e "${CYAN}Confirm fragment defintions? ${NC} (y/n)   ")
							read -ep "$fragConfirm" yn
							case $yn in
								[Yy]* ) #confirm case
									### FRAGMENT 1 ###
									echo -e "\n${CYAN}Generating .xyz files for ${PURP}Fragment1${CYAN}...${NC}"
									frag1Iter=1
									for (( i=0; i<$fragGeomsCount; i++ )); do
										#get the current iteration's xyz from the xyz array 
										fullIterGeom=$(echo "${tbdArray[i]}")
										
										#backup frag1 xyz files if they exist
										if [ -f "${logName}-frag1-xyz${frag1Iter}.xyz" ]; then
											mv ./${logName}-frag1-xyz${frag1Iter}.xyz ./${logName}-frag1-xyz${frag1Iter}.xyz.bak
										fi
										
										#append frag1's atom count to the top of the xyz files
										echo -e "$lenfrag1Array" >> ./${logName}-frag1-xyz${frag1Iter}.xyz
										
						                                #In the comment line, store fragment1 charge/mult data for g16 input creation
						                                echo -e "${frag1Charge} ${frag1Mult}" >> ./${logName}-frag1-xyz${frag1Iter}.xyz
	
										#trim current iteration's xyz into its frag1 output
										for capLN in "${sortedFrag1[@]}"; do
                                                                                	IFS=$'\n'
											frag1Capture=($(echo "$fullIterGeom" | awk -v k=$capLN 'NR==k {printf "%-2s %15s %15s %15s \n", $1, $2, $3, $4}'))
											echo "$frag1Capture" >> ./${logName}-frag1-xyz${frag1Iter}.xyz
										done
										
										#provide a list of the .xyz's that were generated
										echo -e "${GREEN}Created: ${CYAN}${logName}-frag1-xyz${frag1Iter}.xyz${NC}"
										
										#iterate fragIter
										(( frag1Iter+=1 ))
									done
									
									### FRAGMENT 2 ###
                                                                        echo -e "\n${CYAN}Generating .xyz files for ${PURP}Fragment2${CYAN}...${NC}"
                                                                        frag2Iter=1
                                                                        for (( i=0; i<$fragGeomsCount; i++ )); do
                                                                                #get the current iteration's xyz from the xyz array
                                                                                fullIterGeom=$(echo "${tbdArray[i]}")

                                                                                #backup frag2 xyz files if they exist
                                                                                if [ -f "${logName}-frag2-xyz${frag2Iter}.xyz" ]; then
                                                                                        mv ./${logName}-frag2-xyz${frag2Iter}.xyz ./${logName}-frag2-xyz${frag2Iter}.xyz.bak
                                                                                fi

                                                                                #append frag2's atom count to the top of the xyz files
                                                                                echo -e "$lenfrag2Array" >> ./${logName}-frag2-xyz${frag2Iter}.xyz

                                                                                #In the comment line, store fragment1 charge/mult data for g16 input creation
                                                                                echo -e "${frag2Charge} ${frag2Mult}" >> ./${logName}-frag2-xyz${frag2Iter}.xyz

                                                                                #trim current iteration's xyz into its frag2 output
                                                                                for ln in "${numberlist[@]}"; do
                                                                                        IFS=$'\n'
                                                                                        frag2Capture=($(echo "$fullIterGeom" | awk -v k=$ln 'NR==k {printf "%-2s %15s %15s %15s \n", $1, $2, $3, $4}'))
                                                                                        echo "$frag2Capture" >> ./${logName}-frag2-xyz${frag2Iter}.xyz
                                                                                done

                                                                                #provide a list of the .xyz's that were generated
                                                                                echo -e "${GREEN}Created: ${CYAN}${logName}-frag2-xyz${frag2Iter}.xyz${NC}"

                                                                                #iterate fragIter
                                                                                (( frag2Iter+=1 ))
                                                                        done
										
									break;;
																
								[Nn]* )
									#placeholder - offer option to redefine frags
									echo -e "${RED}EXITING...\n${NC}"
									exit;;

								* ) #error case
									echo -e "${RED}Enter y/n...\n${NC}"
									continue;;
							esac
						done	
							
						break ;;

					[Nn]* )
						echo -e "${RED}EXITING...\n${NC}"
						exit;;

					* ) 
						echo -e "${RED}Enter y/n...\n${NC}"
						continue;;
				esac
			done
			break;;	
		 
		2)	#already present
			echo "option is pending - check back later"
			break;;
			
		*)
			echo -e "${RED}Error: ${NC} select one of the above scenarios...\n"
			continue;;
	esac
done

#determine next course of action 
echo -e "\n${GREEN}Create G16 input files for your newly minted ${PURP}${logName}.xyz${GREEN}'s?${NC}"
whatNextQ=$(echo -e "${CYAN}Select an option:   ${NC}")
whatNextOptions=("Create G16 input.coms with pASDI" "Nothing; exit with grace")
PS3=$whatNextQ
COLUMNS=0
select nextCase in "${whatNextOptions[@]}"; do
        case $REPLY in
                1)      #create G16 inputs from files
			#gather info pertaining to current job in local directory
			echo -e "\n${GREEN}Locating xyz files corresponding with ${PURP}${logName}${GREEN}...${NC}" 
			jobsToMake=$(ls ${logName}*.xyz | tr ' ' '\n')
			jobCount=$(echo "$jobsToMake" | wc -l)
			echo -e "${PURP}${jobCount}${CYAN} xyz files were found for ${PURP}${logName}${CYAN} in current directory. ${NC}"
			
			#entering common parameters for the jobs - computational method selection
			echo -e "\n${GREEN}Enter common job parameters:${NC}"
			
			#all of these jobs will be of jobtype "single point + freq"
			export JOBTYPE='freq'
			
			#determine other job parameters via functions
			whichDFA
			whichBasis
			whichSolvation
			whichQ
			
			#make a job input for each file - append "pasdi" to the jobname
			for subjob in $jobsToMake; do
				#assign jobname
				currentJob=$(basename -s .xyz $subjob)
				pasdiJob="${currentJob}-pasdi"
				export JOBNAME=${pasdiJob}
			
				#determine location of current directory - output to here
				submitLoc=$(pwd)
				checkLoc=$(echo "$submitLoc/")
				export CHECKLOC=${checkLoc}
				
				#extract the geom from the .xyz file 
				currentGeom=$(captureGeomXYZ $subjob)
				export GEOM=${currentGeom}

				envsubst '${NUMTASK} ${MEM} ${DFA} ${DISPERSION} ${BASIS} ${SOLVATION} ${JOBTYPE} ${JOBNAME} ${CHECKLOC} ${GEOM}' </home1/05793/rdg758/scripts/G16_Input_Template.txt> ./$pasdiJob.com	
			done
			echo -e "Your input files have been created"
			break;;
		
		2) #exit with grace
			echo -e "${RED}A graceful "goodbye"...\n${NC}"
			exit;;
		
		*) #error case
			echo -e "${RED}Select from one of the above...\n${NC}"
			continue;;
	esac
done

