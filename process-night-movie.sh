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
testmode=false
while getopts ":htd" flag
do
 case $flag in
  h) echo "help";;
  d) debugmode=true;; # developing or
  t) testmode=true;; # testing
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
twilightbegin=`php $homepath/twilight.php | cut -d ' ' -f 1 | awk '{print $1 + 0}'`
twilightend=`php $homepath/twilight.php | cut -d ' ' -f 2 | awk '{print $1 + 0}'`

## FOR TESTING PURPOSES
if $testmode ; then # Run only when not testing
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
rm -r "$tmppath"/*
# Empty previous file with image names
> "$tmppath/hours.txt"

# Create list of image names to combine and store it in a temp file "hours.txt"
for (( time=$twilightbegin - 1; time < 2359; )); do
    time="$(date --date="$time + 1 minutes" +'%H%M')"
    echo "$inpathyesterday/"`printf "%04d" "$time"`".jpg" >> $tmppath/hours.txt
done
for (( time=0; time <= $twilightend; )); do
    echo "$inpathtoday/"`printf "%04d" "$time"`".jpg" >> $tmppath/hours.txt
    time=$((10#$time))
    time="$(date --date="$time + 1 minutes" +'%H%M')"
    time=$((10#$time))
done

# exit 0

# for h in `seq $twilightbegin 2359`;
# do
#   echo "$inpathyesterday/"`printf "%04d" "$h"`".jpg" >> $tmppath/hours.txt
# done
# for h in `seq 0 $twilightend`;
# do
#   echo "$inpathtoday/"`printf "%04d" "$h"`".jpg" >> $tmppath/hours.txt
# done

# Create numbered soft links pointing to image files in source folder
# Necessary to cope with avconv requirements to process consecutive numbers in file names
count=0
while read -r the_filename
do
    new=$(printf "%04d.jpg" $count) # 04 pads to length of 3 max 9999 images
    ln -s $the_filename $tmppath/$new
#     echo $tmppath/$new
    let count=count+1
done < "$tmppath/hours.txt"

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