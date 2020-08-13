#!/bin/bash
#set -x

############################################################################################
##
## Script to download Desktop Wallpaper
##
###########################################

# Define variables
# wallpaperurl='"https://azstorageaccounts.blob.core.windows.net/wallpaper/Knug.jpg?sp=racwdl&st=2020-08-12T11:05:51Z&se=2021-04-27T11:05:00Z&sv=2019-12-12&sr=b&sig=0LVchCKsPqRhnTtpJE7Av%2Fvp9JQjkS8AC6CC7%2BP4RGo%3D"' NOT IN USE
wallpaperdir="/Library/Ironstone/desktop"
wallpaperfile="Wallpaper.jpg"
logdir="/Library/Ironstone/log"
log="/var/log/fetchdesktopwallpaper.log"

# start logging

exec 1>> $log 2>&1

echo ""
echo "##############################################################"
echo "# $(date) | Starting download of Desktop Wallpaper"
echo "############################################################"
echo ""

##
## Checking if log directory exists and create it if it's missing
##

if [ -d $logdir ]
then
    echo "$(date) | Log directory [$logdir] already exists"
else
    echo "$(date) | Creating [$logdir]"
    mkdir -p $logdir
fi


##
## Checking if Wallpaper directory exists and create it if it's missing
##

if [ -d $wallpaperdir ]
then
    echo "$(date) | Wallpaper dir [$wallpaperdir] already exists"
else
    echo "$(date) | Creating [$wallpaperdir]"
    mkdir -p $wallpaperdir
fi


##
## Attempt to download the image file. No point checking if it already exists since we want to overwrite it anyway
##

echo "$(date) | Downloading Wallpaper from [$wallpaperurl] to [$wallpaperdir/$wallpaperfile]"
curl -L "https://azstorageaccounts.blob.core.windows.net/wallpaper/Knug.jpg?sp=racwdl&st=2020-08-12T11:05:51Z&se=2021-04-27T11:05:00Z&sv=2019-12-12&sr=b&sig=0LVchCKsPqRhnTtpJE7Av%2Fvp9JQjkS8AC6CC7%2BP4RGo%3D" -o $wallpaperdir/$wallpaperfile
if [ "$?" = "0" ]; then
   echo "$(date) | Wallpaper [$wallpaperurl] downloaded to [$wallpaperdir/$wallpaperfile]"
   #killall Dock
   exit 0
else
   echo "$(date) | Failed to download wallpaper image from [$wallpaperurl]"
   exit 1
fi