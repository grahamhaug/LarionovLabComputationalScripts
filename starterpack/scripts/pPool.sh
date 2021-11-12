#!/bin/bash

#pPool
#v1.3
#GCH - 1/26/21
#Last Modified - 11/11/21

### DESCRIPTION AND USE ###
#Sends an exampleJob.com to the user-specified jobPool directory for autonomous submission by qManager (makes the job available to run automatically)
#Creates a SBATCH submission script to accompany exampleJob.com
#qManager determines the nextJob to run next (based on priority etc) from the jobPool directory and submits the SBATCH file corresponding to exampleJob.com
#Use with 'pPool exampleJob' - no need for extension
#You need to have the accompanying 'g16_SBATCH_template.txt' file stored in your $Home/scripts/ folder

### TO DO ###
#if user wants to submit many similar jobs, ex: exampleJob{1..16}.com, don't make them input specs for each job; do it once and copy to other jobs
#this will have to be an added option, somehow, while still saving time

### SET jobPool DIRECTORY LOCATION ###
jobPool=/work/05793/rdg758/frontera/jobPool

### SPECIFY LOCATION OF sbatchTemplate.sh FILE ###
sbatchTemplate=/home/scripts/g16_SBATCH_template.txt

### POINT TO SCRIPTS DIRECTORY ###
shopt -s expand_aliases
#You will need to point this as where your scripts are
source /home1/05793/rdg758/scripts/alii.env

### COLORS FOR FUN FORMATTING ###
RED='\033[0;31m'
GREEN='\033[0;32m'
PURP='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

### PRINT JOB HEADER ###
echo ""
echo "-----------------------------------------------------------------"
echo "                              pPool                              "
echo "-----------------------------------------------------------------"

### JOB NAMES AND CURRENT DIRECTORY ###
#Capture the name of the job to be sent
fullInput=$(basename "$1")
jobName="${fullInput%.*}"

#capture the current directory to send job output
returnDir=$(pwd)
export RETURNDIR=${returnDir}

#sends exampleJob.com and exampleJob SBATCH to jobPool directory 
function sendPool {
	cp ${jobName}.com $jobPool
	cp ${jobName} $jobPool
}

#parses a user-specified range
function cleanRange {
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

#for a group of jobs that share a common prefix  
function getComs {
        while true; do
                userFile=$(echo -e "${GREEN}What job prefix/keyword to search for?: ${NC}")
                read -ep "$userFile" typedFile
                echo -e "${CYAN}Searching for G16 input.coms containing '${PURP}${typedFile}${CYAN}'...${NC}"

                #search current directory for input files containing the specified string
                searchResults=$(ls *${typedFile}*.com 2> /dev/null | tr ' ' '\n')

                #check if user entered some nonsense (is $searchResults empty?)
                if [ -z "$searchResults" ]; then
                        echo -e "${RED}No files match your string.${NC}"
                        exit 1
                fi

                searchResultsCount=$(echo "$searchResults" | wc -l)
                echo -e "\n${CYAN}Search returns ${PURP}${searchResultsCount}${CYAN} results:${NC}"
                echo "$searchResults"



                echo -e "\n${GREEN}Is this range of jobs correct?${NC}"
                fileSelectQ=$(echo -e "${CYAN}Select an option:    ${NC}")
                fileSelectOptions=("Correct; let's submit!" "Define a different search keyword" "Exit")
                PS3=$fileSelectQ
                COLUMNS=0
                select fsCase in "${fileSelectOptions[@]}"; do
                        case $REPLY in
                                1) #correct
                                        comsToSubmit=${searchResults}
                                        #echo "going to submit: ${comsToSubmit}"
                                        break 2;;

                                2) #define a different search term
                                        break;;

                                3) #exit
                                        echo -e "${RED}Exiting...\n${NC}"
                                        exit 1;;
                                *) #error
                                        echo -e "${RED}Select one of the above options...\n${NC}"
                                        continue;;
                        esac
                done
        done
}


#captures user-specified job parameters for template substitution
function makeSBATCH {
		echo ""
		
		# which queue to run on
		queueQ=$(echo -e "${GREEN}Which queue to use?$   ${NC}")
		queueOptions=("Small" "Normal")
		PS3=$queueQ
		COLUMNS=0
		select qCase in "${queueOptions[@]}"; do 
			case $REPLY in
				1) #small
					export WHICHQ=small
					#don't need for frontera
					#export NUMCORE=1
					#export NUMTASK=64
					echo -e "${GREEN}Using queue: ${CYAN}Small${NC}\n"
					#debug
					#echo "Cores: $NUMCORE Tasks: $NUMTASK"
					break;;

				2) #SKX-Normal
					export WHICHQ=normal
					#export NUMCORE=1
					#export NUMTASK=48
					echo -e "${GREEN}Using queue: ${CYAN}Normal${NC}\n"
					#debug
					echo "Cores: $NUMCORE Tasks: $NUMTASK"
					break;;

				*) #Error Catch
					echo -e "${RED}Error: ${NC} select Normal or SKX...\n"
					continue;;
			esac
		done
		#debug
		#echo "using queue: $WHICHQ"

		### USER SELECTS TIME ###
		#hours to run
		echo -e "${GREEN}How long to run the job? ${NC}"
		hoursQuestion=$(echo -e "Hours? ")
		while [ -z "$hours" ]; do
			read -ep "$hoursQuestion" ans	
				if [[ ! $ans =~ ^[0-9]+$ ]] ; then
					echo -e "${RED}Error:${NC} Must enter an integer." >&2
				else 
					export hours=$ans
				fi
			done		

		minsQuestion=$(echo -e "Minutes? ")
		while [ -z "$mins" ]; do
			read -ep "$minsQuestion" minutes	
				if [[ ! $minutes =~ ^[0-9]+$ ]] ; then
					echo -e "${RED}Error:${NC} Must enter an integer." >&2
				else 
					export mins=$minutes
				fi
		done		
		echo -e "${GREEN}Requesting: ${CYAN}$hours ${GREEN}hours ${CYAN}$mins ${GREEN}minutes.${NC}\n"
		export HOURS=${hours}
		export MINS=${mins}		
		#debug
		#echo "time requested: $HOURS:$MINS"

		#store the current allocations' fairshares
		#fsChe=$(fairshare | awk 'FNR == 8 {print $7}')
		#fsMech=$(fairshare | awk 'FNR == 10 {print $7}')
		#fsComp=$(fairshare | awk 'FNR == 4 {print $7}')
		#fsExcited=$(fairshare | awk 'FNR == 6 {print $7}')
		#fsSOCI=$(fairshare | awk 'FNR == 12 {print $7}')

		#Only one frontera allocation at the moment
		# User indicates which allocation to use
		#alloQ=$(echo -e "${GREEN}Which allocation to use?$  ${NC}")
		#can add or remove active allocations here
		#alloOptions=("($fsKinetics) Kinetics-of-selectiv" "($fsMech) Mechanistic-Studies" "($fsComp) Computational-Analys" "($fsExcited) Excited-state-reactiv" 
		#"($fsSOCI) SOCI-Xmers")
		#PS3=$alloQ
		#COLUMNS=0
		#select allocation in "${alloOptions[@]}"; do 
		#	case $REPLY in
		#		1) #Kinetics-of-selectiv
		#			export ALLOCATION='Kinetics-of-selectiv'
		#			echo -e "${GREEN}Using allocation: ${CYAN}Kinetics-of-selectiv${NC}\n"
		#			break;;
		
		#		2) #Mechanistic-Studies
		#			export ALLOCATION='Mechanistic-Studies'
		#			echo -e "${GREEN}Using allocation: ${CYAN}Mechanistic-Studies${NC}\n"
		#			break;;

		#		3) #Computational-Analys
		#			export ALLOCATION='Computational-Analys'
		#			echo -e "${GREEN}Using allocation: ${CYAN}Computational-Analys${NC}\n"
		#			break;;

		#		4) #Excited-state-reacti
		#			export ALLOCATION='Excited-state-reacti'
		#			echo -e "${GREEN}Using allocation: ${CYAN}Excited-state-reacti${NC}\n"
		#			break;;

		#		5) #SOCI-Xmers
		#			export ALLOCATION='SOCI-Xmers'
		#			echo -e "${GREEN}Using allocation: ${CYAN}SOCI-Xmers${NC}\n"
		#			break;;

		#		*) #Error Catch
		#			echo -e "${RED}Error: ${NC} select available allocation...\n"
		#			continue;;
		#	esac
		#done
		#debug
		#echo "using allocation $ALLOCATION"
}

# pPool a single job or a range of jobs?
echo ""
echo -e "${GREEN}What type of job(s) to submit?${NC}"
numQ=$(echo -e "${CYAN}Select an option:   ${NC}")
jobOptions=("Single job" "Locate input.coms by keyword" "Range (ex: job-conf{1..10}.com)")
PS3=$numQ
COLUMNS=0
select numCase in "${jobOptions[@]}"; do
        case $REPLY in
                1) #single job
                        echo -e "${GREEN}Submitting a single job.${NC}"
                        makeSBATCH
                        envsubst '${WHICHQ} ${HOURS} ${MINS} ${RETURNDIR}' </home1/05793/rdg758/scripts/pPool/g16_SBATCH_template.txt> ./$jobName
                        sendPool
                        echo ""
                        echo -e "${CYAN}$jobName ${GREEN}sent to jobPool.${NC}"
                        echo ""
                        sbatch $jobName
                        break;;

                2) #select jobs by keyword
                        #echo -e "${GREEN}Searching for input.coms by keyword.${NC}"
                        #get the list of jobs by keyword
                        getComs

                        for subJob in $comsToSubmit; do
                                cp ${subJob} $jobPool
                        done

                        #remove the '.com's from these to make SBATCH names
                        trimmedJobNames=$(echo "$comsToSubmit" | sed 's/.com//')
                        #echo $trimmedJobName

                        #get the common parameters via makeSBATCH
                        makeSBATCH

                        #make the SBATCH's for the located files
                        for subJob in $trimmedJobNames; do
                                envsubst '${WHICHQ} ${HOURS} ${MINS} ${RETURNDIR}' </home1/05793/rdg758/scripts/pPool/g16_SBATCH_template.txt> ./$subJob
                                cp ${subJob} $jobPool
                        done

                        cd $jobPool

                        for subJob in $trimmedJobNames; do
                                sbatch $subJob
                        done
                        break;;

                3) #range of jobs
                        echo -e "${GREEN}Submitting a range of jobs.${NC}"
                        #get an array of jobs to make
                        userRange=$(echo -e "${GREEN}Enter the job range ${NC}: ")
                        read -ep "$userRange" jobRange
                        cleanedRange=($(cleanRange $jobRange))
                        #make sure the user-defined range is in ascending order
                        IFS=$'\n' sortedRange=($(sort -n <<< "${cleanedRange[*]}"))
                        unset IFS

                        #get the base name of the job (minus any ending #s)
                        #ex: job-conf1.com .. job-conf10.com <= need to pull "job-conf"
                        noNum=$(echo "$jobName" | sed 's/[0-9]*$//' | tr -d '[:space:]')
                        #for debug
                        echo $noNum


                        #ask for settings for the first job
                        echo -e "\n${GREEN}Enter common job parameters.${NC}"
                        makeSBATCH
                        #now we have captured env variables that will be applied to all of the jobs in the user's range

                        #for debug
                        #echo "debug"
                        #for i in "${sortedRange[@]}"; do
                        #       echo $i
                        #done

                        #declare an array for jobs to submit
                        declare -a jobstoSubmit

                        #make an sbatch file for each entry in the range
                        for num in "${sortedRange[@]}"; do
                                jobName=${noNum}${num}
                                envsubst '${WHICHQ} ${HOURS} ${MINS} ${RETURNDIR}' </home1/05793/rdg758/scripts/pPool/g16_SBATCH_template.txt> ./$jobName
				sendPool
                                jobstoSubmit+=("$jobName")

                                #temporarily autosubmit

                                echo -e "${CYAN}$jobName ${GREEN}sent to jobPool.${NC}"
                        done
                        cd $jobPool
#                       jobstoSubmit=$(grep $jobName)
#                       echo $jobstoSubmit
                        for f in "${jobstoSubmit[@]}"; do
                                #echo $f
                                sbatch $f
                        done
                        break;;

                *) #Error Catch
                        echo -e "${RED}Error: ${NC} select single job or range...\n"
                        continue;;
        esac
done
	



