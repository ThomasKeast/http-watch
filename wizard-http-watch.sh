#!/bin/bash

# Variables
STATE=false

# Functions
function TESTURL {
STATUSCODE=(`curl -s -o /dev/null -w "%{http_code}" $SUPPLIEDURL`)
}

# Script

whiptail --title "http-watch" --msgbox "This wizard will help you implement monitoring of a URL and if it goes offline it can alert you and take action (restart your web server) for you." 8 78

# Clears any old config
rm -f config

# Copies blank template in to position to be re-written and editted by the commands below
cp config-template config

while [ $STATE == "false" ]
do
	# Gathers the URL to monitor from the user
	SUPPLIEDURL=$(whiptail --inputbox "Enter the URL to monitor:" 8 78 http:// --title "HTTP-WATCH - URL" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		sed -i s,URLPLACEHOLDER,$SUPPLIEDURL,g config

		TESTURL

		if [ $STATUSCODE == "200" ]
		then
			STATE=true
		fi

		if [ $STATUSCODE != "200" ]
		then
			if (whiptail --title "URL Offline" --yesno "The URL you provided appears to be offline, are you sure you still want to proceed?" 8 78); then
				STATE=true	
			else
				STATE=false
			fi

		fi
	else
		echo "User selected Cancel." && exit 1
	fi
done

# Gathers the delay in seconds from the user
SUPPLIEDDELAY=$(whiptail --inputbox "Enter the delay in seconds between the tests:" 8 78 30 --title "HTTP-WATCH - Delay in Seconds" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
        sed -i s,DELAYPLACEHOLDER,$SUPPLIEDDELAY,g config
else
        echo "User selected Cancel." && exit 1
fi

# Gathers the number of retries from the user
SUPPLIEDRETRIES=$(whiptail --inputbox "Enter the number of retries after failure:" 8 78 3 --title "HTTP-WATCH - Number of Retries" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
        sed -i s,NUMBEROFTRIESPLACEHOLDER,$SUPPLIEDRETRIES,g config
else
        echo "User selected Cancel." && exit 1
fi

# Gathers the desired action / command from the user
SUPPLIEDACTION=$(whiptail --inputbox "Enter the command you wish to execute upon failure:" 8 78 --title "HTTP-WATCH - Action" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
        sed -i "s,ACTIONPLACEHOLDER,$SUPPLIEDACTION,g" config
else
        echo "User selected Cancel." && exit 1
fi

## Reference ##
# URL="URLPLACEHOLDER"
# DELAY=DELAYPLACEHOLDER
# NUMBEROFTRIES=NUMBEROFTRIESPLACEHOLDER
# ACTION='ACTIONPLACEHOLDER'
