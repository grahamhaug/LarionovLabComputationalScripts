#!/bin/bash

#pASDI
#v1.0
#GCH - 5/26/21

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

#Do we need to make individual .xyz files from an irc.log or are they already present?
echo -e "\n${GREEN}What's the status of your .xyz files?${NC}"
xyzExistQ=$(echo -e "${CYAN}Select an option:   ${NC}")
xyzExistOptions=("Extract .xyz files from an IRC.log" "Current folder already contains needed .xyz's") 
PS3=$xyzExistQ
COLUMNS=0
select xyzCase in "${xyzExistOptions[@]}"; do 
	case $REPLY in
		1)	#extract from irc.log
			#ask user for the log file name 
			userIRCfile=$(echo -e "${GREEN}What is the name of your irc.log file? ${NC}")
			read -ep "$userIRCfile" typedIRC
			echo -e "${CYAN}Using IRC file: ${PURP}$typedIRC${NC}\n"
			export DFA=${typedDFA}
			
			#Check that their file exists in current directory; otherwise exit
			if [[ -f "./${typedIRC}" ]]; then
				echo -e "${CYAN}IRC output file located in current directory: \n${PURP}${typedIRC}${NC}"
			#otherwise, exit
			else
				echo -e "${RED}No file was found matching ${PURP}$typedIRC.${NC}"
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
			logName=$(echo "$typedIRC" | sed 's/.log//g')
			#echo "logname is $logName"	
	
			### CAPTURE CHARGE/MULTIPLICITY FROM THE LOG FILE ###
			#extract charge and mult from .log file
			chargeLine=$(grep 'Charge =' ${logName}.log | sed 's/^ *//g'| sed 's/* $//g')
			chargeTrim=$(echo $chargeLine | sed -ne 's/^[^0-9-]*\([0-9-][0-9]*\) [a-zA-Z]* = \([0-9]*\).*$/\1 \2 /p')
			#store values into vars for printing 
			molCharge=$(echo $chargeTrim | awk '{print $1}')
			molMult=$(echo $chargeTrim | awk '{print $2}')

			#array with periodic table IDs - for replacing #'erd atom indices 
			periodicTable=("" "H" "He" "Li" "Be" "B" "C" "N" "O" "F" "Ne" "Na" "Mg" "Al" "Si" "P" "S" "Cl" "Ar" "K" "Ca" "Sc" "Ti" "V" "Cr" "Mn" "Fe"
              		  "Co" "Ni" "Cu" "Zn" "Ga" "Ge" "As" "Se" "Br" "Kr" "Rb" "Sr" "Y" "Zr" "Nb" "Mo" "Tc" "Ru" "Rh" "Pd" "Ag" "Cd" "In" "Sn" "Sb"
 			  "Te" "I" "Xe" "Cs" "Ba" "La" "Ce" "Pr" "Nd" "Pm" "Sm" "Eu" "Gd" "Tb" "Dy" "Ho" "Er" "Tm" "Yb" "Lu" "Hf" "Ta" "W" "Re" "Os" 
			  "Ir" "Pt" "Au" "Hg" "Tl" "Pb" "Bi" "Po" "At" "Rn" "Fr" "Ra" "Ac" "Th" "Pa" "U" "Np" "Pu" "Am" "Cm" "Bk" "Cf" "Es" "Fm" 
			  "Md" "No" "Lr" "Rf" "Db" "Sg" "Bh" "Hs" "Mt" "Ds" "Rg" "Uub" "Uut" "Uuq" "Uup" "Uuh" "Uus" "Uuo")

			### LOCATE THE INDIVIDUAL GEOMETRIES IN THE LOG FILE ### 
			#locates all the line numbers for the start of the geom blocks
			sGeoms=$(awk '/CURRENT STRUCTURE/ {print FNR}' ${logName}.log | tr '\n\r' ' ')
			IFS=' ' read -r -a sGeomArray <<< "$sGeoms"

			#locates all the line numbers for the end of the geom blocks
			eGeoms=$(awk '/CHANGE IN THE REACTION COORDINATE/ {print FNR}' ${logName}.log | tr '\n\r' ' ')
			IFS=' ' read -r -a eGeomArray <<< "$eGeoms"

			#check that the number of these is equal (should always be equal)
			sCount="${#sGeomArray[@]}"
			#echo "sCount = ${sCount}"
			eCount="${#eGeomArray[@]}"
			
			#capture the raw geoms from the output.log per the identified indices, above
			#store them into an array "geomArray" 
			declare -a geomArray
			j=1
			for (( i=1; i<$sCount; i++ ));	do
				startVar=${sGeomArray[i]}
				endVar=${eGeomArray[j]}
				currentGeom=$(sed -n "${startVar}, ${endVar}p" ${logName}.log)
				columnRemoved=$(echo "$currentGeom" | awk '/^ --/{flag=1; next} /^ --/{flag=0} flag {printf "%5s %15s %15s %15s \n", $2,$3,$4,$5}')	
				choppedGeom=$(echo "$columnRemoved" | awk '$1 ~ /[0-9]/ {print}') 
				geomArray+=("$choppedGeom")	
				(( j+=1 ))	
			done

			#how many geoms were captured
			geomsCount="${#geomArray[@]}"
			echo -e "${CYAN}Extracting full geometries from ${PURP}${logName}.log....${NC}"
	
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
	
				ithXYZ=$(echo "${geomArray[i]}" | awk '{printf "\t %10s %15s %15s \n", $2,$3,$4}')	
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
	
				#add the #atoms and a blank line to the top of each .xyz file 
				echo -e "$numAtoms\n" >> ./${logName}-xyz${itercount}.xyz 

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
			sampleGeom=$(awk '$1 ~ /[A-Z]/ {printf "%-2s  %15s % 15s %15s\n", $1, $2, $3, $4}' ${logName}-xyz1.xyz)
			numberAtoms=$(echo "$sampleGeom" | wc -l)
			#echo "contains atoms: $numberAtoms"
			sampleNumGeom=$(echo "$sampleGeom" | cat -n)

			#put all the "complete" geometries into an array "to be divided" 
			declare -a tbdArray 
			for (( xyzNum=1; xyzNum<$itercount; xyzNum++ )) do
				fullGeom=$(awk '$1 ~ /[A-Z]/ {printf "%-2s  %15s % 15s %15s\n", $1, $2, $3, $4}' ./${logName}-xyz${xyzNum}.xyz)
				tbdArray+=("$fullGeom")
			done

			#count how many frag geoms will need to be made
			fragGeomsCount="${#tbdArray[@]}" 
			#echo "fragGeomsCount = $fragGeomsCount"
				
			#check that all out geoms were extracted from the current xyz's.
			#echo -e "the first array is: \n$tbdArray[0]}"
			#echo -e "the fifth array is: \n$tbdArray[4]}"
	
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
							capturedRow=($(echo "$sampleNumGeom" | awk -v k=$capLN 'NR==k {printf "%-2s %10s %10s %10s \n", $2, $3, $4, $5}'))
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
							capturedRow=($(echo "$sampleNumGeom" | awk -v k=$ln 'NR==k {printf "%-2s %10s %10s %10s \n", $2, $3, $4, $5}'))
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
						echo -e "${PURP}Fragment2 ${CYAN}includes remaining atoms:${NC} $condensedFrag2"
						#for i in "${fragArray2[@]}"; do
				        		#print the data corresponding to captured atom#
						#	echo $i
						#done	
						
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
										echo -e "$lenfrag1Array\n" >> ./${logName}-frag1-xyz${frag1Iter}.xyz
										
										#trim current iteration's xyz into its frag1 output
										for capLN in "${sortedFrag1[@]}"; do
                                                                                	IFS=$'\n'
											frag1Capture=($(echo "$fullIterGeom" | awk -v k=$capLN 'NR==k {printf "%-2s %10s %10s %10s \n", $1, $2, $3, $4}'))
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
                                                                                echo -e "$lenfrag2Array\n" >> ./${logName}-frag2-xyz${frag2Iter}.xyz

                                                                                #trim current iteration's xyz into its frag2 output
                                                                                for ln in "${numberlist[@]}"; do
                                                                                        IFS=$'\n'
                                                                                        frag2Capture=($(echo "$fullIterGeom" | awk -v k=$ln 'NR==k {printf "%-2s %10s %10s %10s \n", $1, $2, $3, $4}'))
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




