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

# Script to create a timelapse movie from images taken every minute of a day
# This script should run every night, between 00:02 and 01:00, the sooner the better
# Script running duration : about 50 seconds for 1440 images

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
year=`date --date="yesterday" '+%Y'`
month=`date --date="yesterday" '+%m'`
day=`date --date="yesterday" '+%d'`

## FOR TESTING PURPOSES
if $testmode ; then # Run only when not testing
  year=`date '+%Y'`
  month=`date '+%m'`
  day=`date '+%d'`
fi

ymd="$year$month$day"

# Set paths
homepath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmppath="$homepath/allskycam/tmpmov"
inpath="$homepath/Documents/sky/$year/$month/$day"
outpath="$homepath/Documents/media/sky/$year/$month"
dropboxpath="daymovies/$year/$month"

## FOR TESTING PURPOSES
if $testmode ; then # Run only when not testing
  echo "$homepath"
  echo "$tmppath"
  echo "$inpath"
  echo "$outpath"
  echo "$dropboxpath"
  echo bash "$homepath/dropbox_uploader.sh" -q -f "$homepath/dropbox_uploader.cfg" upload "$outpath/$ymd.mp4" "$dropboxpath/$ymd.mp4"
  exit 0 ## exit without further action
fi

# Create tmp directory for creating timelapse, if not present, and empty it otherwise
if [ ! -d "$tmppath" ]; then
    mkdir -p "$tmppath"
else
    rm -r "$tmppath"/*
fi

# Create numbered soft links pointing to image files in source folder
# Necessary to cope with avconv requirements to process consecutive numbers in file names
count=0
ls "$inpath"/*.jpg |
(
    # do something with the rest of the files
    while read not_the_most_recent_file
    do
        new=$(printf "%04d.jpg" ${count}) # 04 pads to length of 3 max 9999 images
        ln -s ${not_the_most_recent_file} "$tmppath/${new}"
        let count=count+1
    done
)

# Create directory for the day, if not present
# The test should be true only on 00:00 each day
if [ ! -d "$outpath" ]; then
  mkdir -p "$outpath"
fi

# Remove yesterday images input directory
if ! $testmode ; then # Run only when not testing
  rm -r "$homepath/allskycam/$ymd"
fi

# Create timelapse movie in appropriate location
# 1. Create mp4 movie file with avconv
avconv -y -r 10 -i "$tmppath/%04d.jpg" -vcodec libx264 -crf 20 -g 5 "$outpath/$ymd.mp4"
# 2. Produce ogv version with avconv
avconv -y -i "$outpath/$ymd.mp4" -b 1200k -mbd 2 "$outpath/$ymd.ogv" #> /dev/null 2>&1
# 3. Copy movies for web publication
cp "$outpath/$ymd.mp4" "$homepath/Documents/media/sky/yesterday.mp4"
cp "$outpath/$ymd.ogv" "$homepath/Documents/media/sky/yesterday.ogv"
# 4. Copy MP4 movie to Dropbox
bash "$homepath/dropbox_uploader.sh" -q -f "$homepath/dropbox_uploader.cfg" upload "$outpath/$ymd.mp4" "$dropboxpath/$ymd.mp4" &
# 5. Remove movies older than 60 days, then empty directories, to free space on the server
find "$homepath/Documents/media/sky/" -type f \( -not -name "*-night.mp4" -a -name "*.mp4" \) -mtime +60 -exec rm {} \;
find "$homepath/Documents/media/sky/" -type f \( -not -name "*-night.ogv" -a -name "*.ogv" \) -mtime +60 -exec rm {} \;
find "$homepath/Documents/media/sky/" -depth -empty -type d -exec rmdir {} \;

## End of script