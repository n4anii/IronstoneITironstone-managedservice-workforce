#!/bin/bash
#set -x

############################################################################################
##
## Script to install Connectwise Automate
## Based upon Microsoft Install script
## https://github.com/microsoft/shell-intune-samples/tree/master/Apps/Office%20for%20Mac
##
## We tried using variables on the url for Automate installer and config but it looks like it can't parse it with curl.
###########################################

# Define variables
##############################

tempdir="/tmp" # Not in use
tempfile="/Library/Ironstone/software/LTSvc.mpkg"
#AutomateUrl='"https://azstorageaccounts.blob.core.windows.net/connectwiseautomate/LTSvc.mpkg?sp=racwdl&st=2020-08-11T10:51:08Z&se=2025-01-12T10:51:00Z&sv=2019-12-12&sr=c&sig=wclV6xxJEexqndMkZwGg7QgfgfHHG3AeVg6WKjCQT3I%3D"' # This is where the script queries the Storage Account for installer
#ConfigUrl='"https://azstorageaccounts.blob.core.windows.net/connectwiseautomate/config.sh?sp=racwdl&st=2020-08-11T10:51:08Z&se=2025-01-12T10:51:00Z&sv=2019-12-12&sr=c&sig=wclV6xxJEexqndMkZwGg7QgfgfHHG3AeVg6WKjCQT3I%3D"'    # This is where the script queries the Storage Account for config file
appname="Connectwise Automate"
softwaredir="/Library/Ironstone/software"
logdir="/Library/Ironstone/log"
log="/Library/Ironstone/log/installConnectwiseAutomate.log" # Location to logs. 

# start logging

exec 1>> $log 2>&1

echo ""
echo "##############################################################"
echo "# $(date) | Starting install of $appname"
echo "############################################################"
echo ""

consoleuser=$(ls -l /dev/console | awk '{ print $3 }')

echo "$(date) | logged in user is" $consoleuser

##
## Checking if Ironstone directory exists and create it if it's missing
##

if [ -d $logdir ]
then
    echo "$(date) | Log directory [$logdir] already exists"
else
    echo "$(date) | Creating [$logdir]"
    mkdir -p $logdir
fi

##
## Checking if Ironstone log directory exists and create it if it's missing
##

if [ -d $softwaredir ]
then
    echo "$(date) | Software directory [$softwaredir] already exists"
else
    echo "$(date) | Creating [$softwaredir]"
    mkdir -p $softwaredir
fi


#
# Check to see if we can access our local copy of Connectwise Automate
#


if [ -f $tempfile ]; then
     echo "$(date) | Local copy of $appname found at $tempfile"

else
	
	echo "$(date) | Couldn't find local copy of $appname, need to fetch from storage account"
	
	echo "$(date) | Downloading Connectwise Automate Installer"
    curl -L "https://azstorageaccounts.blob.core.windows.net/connectwiseautomate/LTSvc.mpkg?sp=racwdl&st=2020-08-11T10:51:08Z&se=2025-01-12T10:51:00Z&sv=2019-12-12&sr=c&sig=wclV6xxJEexqndMkZwGg7QgfgfHHG3AeVg6WKjCQT3I%3D" -o $softwaredir/LTSvc.mpkg
    
	if [ $? == 0 ]; then
         echo "$(date) | Success"
	else 
		 echo "$(date) | Failure"	
    exit 3
	fi


    echo "$(date) | Downloading Configuration file"
    curl -L "https://azstorageaccounts.blob.core.windows.net/connectwiseautomate/config.sh?sp=racwdl&st=2020-08-11T10:51:08Z&se=2025-01-12T10:51:00Z&sv=2019-12-12&sr=c&sig=wclV6xxJEexqndMkZwGg7QgfgfHHG3AeVg6WKjCQT3I%3D" -o $softwaredir/config.sh

    if [ $? == 0 ]; then
         echo "$(date) | Success"
    else
         echo "$(date) | Failure"
         exit 4
		fi
fi

echo "$(date) | Installing $appname"
installer -pkg $tempfile -target /Applications

if [ $? == 0 ]; then
     echo "$(date) | Success"
else
     echo "$(date) | Failure"
     exit 6
fi

echo "$(date) | Removing installation files"
rm -rf $tempfile
rm -rf $softwaredir/config.sh

exit 0