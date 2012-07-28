#! /bin/bash
# Copyright 2012 Nicolas Martignoni <nicolas%martignoni.net>
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
homepath="/Data/www/ecoles/www.observatoire-naef.ch"
tmppath="$homepath/allskycam/tmp"
inpathtoday="$homepath/Documents/sky/$year1/$month1/$day1"
inpathyesterday="$homepath/Documents/sky/$year2/$month2/$day2"
outpath="$homepath/htdocs/assets/media/sky/$year1/$month1/"

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
fi

# Remove previous file with image names, if present
if [ -f "$tmppath/hours.txt" ]; then
  rm "$tmppath/hours.txt"
fi
touch "$tmppath/hours.txt"

# Create list of image names to combine and store it in a temp file "hours.txt"
for h in `seq $twilightbegin 2359`;
do
  echo "$inpathyesterday/"`printf "%04d" "$h"`".jpg" >> $tmppath/hours.txt
done
for h in `seq 0 $twilightend`;
do
  echo "$inpathtoday/"`printf "%04d" "$h"`".jpg" >> $tmppath/hours.txt
done

# Create timelapse movie in appropriate location
# 1. Create avi movie file with mencoder
mencoder -msglevel all=0 mf://@"$tmppath/hours.txt" -mf w=704:h=480:fps=10:type=jpg -ovc lavc -lavcopts vcodec=mpeg4:v4mv:mbd=2:trell -oac copy -o "$outpath/$ymd-night.avi" > /dev/null 2>&1
# 2. Produce mp4 version with ffmpeg
ffmpeg -y -i "$outpath/$ymd-night.avi" -vcodec mpeg4 -b 1200kb -mbd 2 "$outpath/$ymd-night.mp4" > /dev/null 2>&1
# 3. Produce ogv version with ffmpeg
ffmpeg -y -i "$outpath/$ymd-night.avi" -b 1200kb -mbd 2 "$outpath/$ymd-night.ogv" > /dev/null 2>&1
# 4. Copy movies for web publication
cp "$outpath/$ymd-night.mp4" "$homepath/htdocs/assets/media/sky/lastnight.mp4"
cp "$outpath/$ymd-night.ogv" "$homepath/htdocs/assets/media/sky/lastnight.ogv"

## End of script