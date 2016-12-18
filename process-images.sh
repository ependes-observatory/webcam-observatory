#!/usr/bin/env bash
# Copyright © 2012 onwards, Nicolas Martignoni <nicolas%martignoni.net>
#
# License: This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at your
# option) any later version. This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.

# Script to process the images take by the webcam of the Astronomical observatory of Épendes,
# Fribourg, Switzerland, http://www.observatoire-observatoire-naef.ch/
# Goals:
# 1. Publish on a web page an image of the actual sky
# 2. Publish a timelapse movie of the day before today from images taken every minute
# 3. Publish a timelapse movie of the night before today from images taken every minute
# The two latter tasks are done with two external scripts (see below)
# This script should run every minute of the day, ideally launched by cron

debugmode=false
testmode=false
while getopts ":htd" flag
do
 case $flag in
  h) echo "help";;
  d) debugmode=true;; # developing or
  t) testmode=true;; # testing
 esac
done

# Set vars based on date/time, one minute earlier than the actual date and time
# We process the images of one minute ago
year=`date --date="1 minute ago" '+%Y'`
month=`date --date="1 minute ago" '+%m'`
day=`date --date="1 minute ago" '+%d'`
hour=`date --date="1 minute ago" '+%H'`
hour1=`date --date="61 minute ago" '+%H'`
minute=`date --date="1 minute ago" '+%M'`
ymd="$year$month$day"
hm="$hour$minute"
hm1="$hour1$minute"

# Set paths
homepath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmppath="$homepath/allskycam/tmp"
inpath="$homepath/allskycam/$ymd/$hour"
outpath="$homepath/Documents/sky/$year/$month/$day"
lasthourpath="$homepath/htdocs/assets/images/sky/lasthour"
dropboxpath="images/$year/$month/$day"

## FOR TESTING PURPOSES
if $testmode ; then # Run only when testing
  echo "$homepath"
  echo "$tmppath"
  echo "$inpath"
  echo "$outpath"
  echo "$dropboxpath"
  exit 0 ## exit without further action
fi

# Create directory for the day, if not present
# The test should be true only at 00:00 each day
if [ ! -d "$outpath" ]; then
  mkdir -p "$outpath"
fi

# Create and copy image of the current minute in appropriate location
# We check first that the download is totally finished before processing the files
# 1. Average uploaded images to tmp image for removing noise
while true
do
  # Test if an upload by user "observatoire" is going on and wait until done
  ## if [ "`lsof -a -u observatoire -c proftpd +D $inpath | wc -l`" -eq 0 ]; then  ## This does work only as root :-(
  if [ "`lsof -a -u observatoire -c proftpd | wc -l`" -eq 0 ]; then
  ## if [[ `ls -1U $inpath/*.jpg 2>/dev/null | wc -l` -gt 0 && `fuser -u $inpath 2>/dev/null | wc -c ` -eq 0 ]]; then
    # there is at least one file in $inpath dir and $inpath is not used by a process (upload is done)
    # we can then process the files in $inpath
    convert -average "$inpath/*.jpg" "$homepath/allskycam/temp_$hm.jpg"
    break
  else
    # no upload or upload not completed; we wait a while and retry
    sleep 2
  fi
done

# 2. Rescale oval-shaped image to circular one, crop it, add date/time and orientation stamps
#    and place it in appropriate location
# 2.1 First rescale image and copy it
convert "$homepath/allskycam/temp_$hm.jpg" \
  -resize 704x535\! \
  -gravity South -crop 510x510-19+0\! \
  -bordercolor "#272528" -border 95x5 \
  -pointsize 18 -fill white \
  -gravity North -annotate 0 "N" \
  -gravity South -annotate 0 "S" \
  -gravity East -annotate 0 "W" \
  -gravity West -annotate 0 "E" \
  -gravity NorthEast -undercolor black -annotate 0 "`date --date='1 minute ago' '+%F %R %Z'`" \
  "$outpath/$hm.jpg"
# 2.2 Second copy it to dropbox, using script "dropbox_uploader" from
#     https://github.com/andreafabrizi/Dropbox-Uploader
bash "$homepath/dropbox_uploader.sh" -q -f "$homepath/dropbox_uploader.cfg" upload "$outpath/$hm.jpg" "$dropboxpath/$hm.jpg" &
# 3. Copy image for web publication
# 3.1 First as latest.jpg
cp "$outpath/$hm.jpg" "$homepath/htdocs/assets/images/sky/latest.jpg"
# 3.2 Second in lasthour folder
cp "$outpath/$hm.jpg" "$lasthourpath/$hm.jpg"
# 3.3 Remove from lasthour folder files older than one hour
find "$lasthourpath" -mmin +59 -exec rm {} \;
# 3.4 Rename jpg files to sequential numbers, based on date
# http://stackoverflow.com/questions/3211595/renaming-files-in-a-folder-to-sequential-numbers
ls -tr $lasthourpath/*.jpg | cat -n | while read n f; do mv "$f" "$lasthourpath/$n.jpg"; done
# 4. Move uploaded images to tmp location and remove empty directories
find "$inpath" -maxdepth 1 -name "*.jpg" -exec mv {} "$tmppath" \;
# 5. Delete from tmp location images older than 2 days
find "$tmppath" -maxdepth 1 -mtime +2 -name "*.jpg" -exec rm {} \;
# 6. Remove tmp image
rm "$homepath/allskycam/temp_$hm.jpg"
# 7. Remove images older than 60 days, then empty directories, to free space on the server
find "$homepath/Documents/sky/" -type f -name "*.jpg" -mtime +60 -exec rm {} \;
find "$homepath/Documents/sky/" -depth -empty -type d -exec rmdir {} \;

# Launch the script to get IP address of Observatoire d'Épendes, every hour
# Running every hour at 00:50
if [ $minute -eq 51 ]; then
#if [ $hour -eq 22 ]; then
  # echo "get-ip run at $hour:$minute" >> $homepath/log.txt &
  bash "$homepath/get-ip.sh" &
fi

# Launch the daily movie processing script and cleanup, should run after 00:00, the sooner the better
# Running at 00:06
if [ $hour -eq 0 ] && [ $minute -eq 5 ]; then
  # echo `date +"%F %T"` "process-day-movie launched" >> $homepath/log.txt &
  bash "$homepath/process-day-movie.sh" &
fi

# Launch the night movie processing script and cleanup, should run after 08:00, the sooner the better
# Running at 08:06
if [ $hour -eq 8 ] && [ $minute -eq 5 ]; then
  # echo `date +"%F %T"` "process-night-movie launched" >> $homepath/log.txt &
  bash "$homepath/process-night-movie.sh" &
fi

## End of script