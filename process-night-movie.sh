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

# Script to create a timelapse movie from images taken every minute of the night,
# between twilight begin and end. Twilight times are computed with external PHP script.
# This script should run every day, after twilight end (8 o'clock is fine)
# Script running duration : depends of night duration, typically 1 to 2 minutes.

debugmode=false

while getopts ":hdt" flag
do
 case $flag in
  h)
    echo "help"
    ;;
  d) # developing 
    debugmode=true
    ;;
  t) # or testing
    debugmode=true
    ;;
 esac
done

# NOTE: the movie to process is the one of the previous day !
# Set vars based on previous day date
year1=`date '+%Y'`
month1=`date '+%m'`
day1=`date '+%d'`
year2=`date --date="yesterday" '+%Y'`
month2=`date --date="yesterday" '+%m'`
day2=`date --date="yesterday" '+%d'`

ymd=$year1$month1$day1

# Set paths
homepath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmppath="$homepath/allskycam/tmpmov"
inpathtoday="$homepath/Documents/sky/$year1/$month1/$day1"
inpathyesterday="$homepath/Documents/sky/$year2/$month2/$day2"
outpath="$homepath/Documents/media/sky/$year1/$month1"
dropboxpath="nightmovies/$year1/$month1"

# Create directory for the month, if not present
# The test should be true only on the first day of each month
if [ ! -d "$outpath" ]; then
  mkdir -p "$outpath"
fi

# Compute twilight begin and end, with twilight.php script
twilightbegin=$(printf "%04d" `php $homepath/twilight.php | cut -d ' ' -f 1 | awk '{print $1 + 0}'`)
twilightend=$(printf "%04d" `php $homepath/twilight.php | cut -d ' ' -f 2 | awk '{print $1 + 0}'`)

## FOR TESTING PURPOSES
if $debugmode ; then # Run only when not testing
  echo "$homepath"
  echo "$tmppath"
  echo "$inpathtoday"
  echo "$inpathyesterday"
  echo "$outpath"
  echo "$twilightbegin"
  echo "$twilightend"
  echo bash "$homepath/dropbox_uploader.sh" -q -f "$homepath/dropbox_uploader.cfg" upload "$outpath/$ymd-night.mp4" "$dropboxpath/$ymd-night.mp4"
  exit 0 ## exit without further action
fi

# Empty temp directory
rm -rf "$tmppath"/*

# Create list of image names to combine and store it in a temp file "hours.txt"
# Idea from http://stackoverflow.com/questions/28226229/bash-looping-through-dates
starttime=$(date -I -d "- 1 day")T${twilightbegin:0:2}:${twilightbegin:2:4}
endtime=$(date -I)T${twilightend:0:2}:${twilightend:2:4}

starttime=$(date -Iminutes -d "$starttime") || exit -1
endtime=$(date -Iminutes -d "$endtime") || exit -1

d="$starttime"
count=0
while [ "$d" != "$endtime" ]; do
    if [ -f $homepath/Documents/sky/$(date -d "$d" +%Y/%m/%d/%H%M).jpg ]; then
        new=$(printf "%04d.jpg" $count) # 04 pads to length of 3 max 9999 images
        ln -s $homepath/Documents/sky/$(date -d "$d" +%Y/%m/%d/%H%M).jpg $tmppath/$new
        let count=count+1
    fi
    d=$(date -Iminutes -d "$d + 1 minute")
done

# Create timelapse movie in appropriate location
# 1. Create mp4 movie file with avconv
avconv -y -r 10 -i "$tmppath/%04d.jpg" -vcodec libx264 -crf 20 -g 5 "$outpath/$ymd-night.mp4" # > /dev/null 2>&1
# 2. Produce ogv version with avconv
avconv -y -i "$outpath/$ymd-night.mp4" -b 1200k -mbd 2 "$outpath/$ymd-night.ogv" # > /dev/null 2>&1
# 3. Copy movies for web publication
cp "$outpath/$ymd-night.mp4" "$homepath/Documents/media/sky/lastnight.mp4"
cp "$outpath/$ymd-night.ogv" "$homepath/Documents/media/sky/lastnight.ogv"
# 4. Copy MP4 movie to Dropbox
bash "$homepath/dropbox_uploader.sh" -q -f "$homepath/dropbox_uploader.cfg" upload "$outpath/$ymd-night.mp4" "$dropboxpath/$ymd-night.mp4" &
# 5. Remove movies older than 60 days, then empty directories, to free space on the server
find "$homepath/Documents/media/sky/" -type f -name "*-night.ogv" -mtime +60 -exec rm {} \;
find "$homepath/Documents/media/sky/" -type f -name "*-night.mp4" -mtime +60 -exec rm {} \;
find "$homepath/Documents/media/sky/" -depth -empty -type d -exec rmdir {} \;
# 6. Empty tmp directory
rm -r "$tmppath"/*

## End of script