#!/bin/bash
#################################################################################
# Imports variables from a config file
source ./config

# Variables
SAVENUM=($NUMBEROFTRIES)

# Functions
function TESTURL {
STATUSCODE=(`curl -s -o /dev/null -w "%{http_code}" $URL`)
}

function ECHORETRIES {
echo "NUMBEROFTRIES = $NUMBEROFTRIES" # Debugging
}

function PAUSE {
sleep $DELAY
}

function NORESPONSE {
echo "Error: URL Not Responding"
}

function LOG_DATE {
log_running_date=`date '+%Y-%m-%d %H:%M:%S'`
}

function LIST_MODE {
echo -e "\e[92mList mode detected... Running now...\e[0m"
LIST_RUN=1
if [ -f ./$LIST_NAME ]
then
    LIST_CS=$(cat ./$LIST_NAME)
else
	echo "I can't seem to fidnt he file..."
	read -p "Would you like me to make one? [y/n] - " MKLIST
	if [ $MKLIST == "y" ] || [ $MKLIST == "Y" ]
	then
		touch ./$LIST_NAME
		echo "File created, please add some websites and re-run the script..."
		exit 0
	else
		echo "Please run the normal script if you wish to monitor a single website..."
		exit 1
	fi

fi


}

# Pre-Script Checks

if [[ ! -z "$1" ]] && [[ `echo $1` == '--list' ]] || [[ `echo $1` == '-lrun' ]]
then
        LIST_MODE
else
		LIST_RUN=0
fi

touch $LOG_PATH/http-watch.log  # Create a new log file
LOG_FILE=$LOG_PATH/http-watch.log # Specify the path used to write

# Script

echo "----- http-watch log file -----" >> $LOG_FILE # New header 
LOG_DATE # Get current time with Hours, Mins, Seconds
echo "Script executed: $log_running_date" >> $LOG_FILE # Write execute time to log
echo "User running: `whoami`" >> $LOG_FILE # Write user that executed the script to the log

if [ $LIST_RUN == "1" ]
then
	echo -e "\nHTTP-WATCH is monitoring the following list: $LIST_SH"
else
	echo -e "\nHTTP-WATCH is monitoring: $URL"
fi

TESTURL # Performs intial test to see if URL is online and get its status code

while [ $STATUSCODE == "200" ]
do
	# echo "200 - OK" # Debugging
	PAUSE # Pauses for x number of seconds (specified by the user)
	#ECHORETRIES # Debugging
	TESTURL # Tests the URL supplied by the user and returns 200 (OK) status code or nothing
	
	while [ $STATUSCODE != "200" ] && [ $NUMBEROFTRIES -gt 0 ]
	do
		LOG_DATE
		echo "$log_running_date - $URL is offline... Trying again..." >> $LOG_FILE
		#NORESPONSE # Debugging
		#ECHORETRIES # Debugging
		PAUSE
		TESTURL
		((NUMBEROFTRIES--))
	done

	if [ $NUMBEROFTRIES == "0" ]
	then
		LOG_DATE
		#NORESPONSE # Debugging
		$ACTION	
		echo "$log_running_date - Action was needed because the $URL was offline, command that was executed: $ACTION" >> $LOG_FILE

		# Dispatch Email Alert
		LOG_DATE
		echo -e "[http-watch] reporting from `hostname` at `date` \n \nDetected that $URL was offline.\n \nThe following action was taken: $ACTION" | mail -s "[http-watch] $URL" $EMAIL
		echo "$log_running_date - Email was dispatched to: $EMAIL" >> $LOG_FILE

		LOG_DATE
		echo && echo "Service Restarted, pausing for $DELAY seconds before retrying..."
		echo "$log_running_date - Service was restarted..." >> $LOG_FILE
		PAUSE
		TESTURL
		if [ $STATUSCODE != "200" ]
		then
			LOG_DATE
			STATE=false
			echo "$log_running_date - $URL is still offline..." >> $LOG_FILE
		fi
		
		while [ $STATE == "false" ]
		do	
			LOG_DATE
			$ACTION
			echo "$log_running_date - $URL is still offline... Re-running action command..." >> $LOG_FILE
			PAUSE
			TESTURL
			if [ $STATUSCODE == "200" ]
			then
				LOG_DATE
				STATE=true
				echo "$log_running_date - $URL is back online!" >> $LOG_FILE
			fi
		done
	fi
	NUMBEROFTRIES=($SAVENUM) # Resets the NUMBEROFTRIES counter backs to its original number
done
