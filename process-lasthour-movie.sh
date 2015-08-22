#!/usr/bin/env bash
# Copyright © 2015 onwards, Nicolas Martignoni <nicolas%martignoni.net>
#
# License: This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or (at your
# option) any later version. This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
# Public License for more details.

# Script to create a timelapse movie from images taken every minute for the last hour
# This script should run every minute
# Script running duration : about 3 seconds for 60 images

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

# Set paths
homepath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tmppath="$homepath/allskycam/tmp"
lasthourpath="$homepath/htdocs/assets/images/sky/lasthour"


## FOR TESTING PURPOSES
if $testmode ; then # Run only when not testing
  echo "$homepath"
  echo "$lasthourpath"
  exit 0 ## exit without further action
fi

# Create timelapse movie in appropriate location
# 1. Create avi movie file with mencoder
mencoder -msglevel all=0 mf://"$lasthourpath/*.jpg" -mf w=704:h=480:fps=10:type=jpg -ovc lavc -lavcopts vcodec=mpeg4:v4mv:mbd=2:trell -oac copy -o "$lasthourpath/lasthour.avi" > /dev/null 2>&1
# 2. Produce mp4 version with ffmpeg
avconv -y -i "$lasthourpath/lasthour.avi" -c:v libx264 -b 1200k -mbd 2 "$lasthourpath/lasthour.mp4" > /dev/null 2>&1
# 3. Produce ogv version with ffmpeg
avconv -y -i "$lasthourpath/lasthour.avi" -b 1200k -mbd 2 "$lasthourpath/lasthour.ogv" > /dev/null 2>&1
# 4. Remove avi version
rm "$lasthourpath/lasthour.avi"

## End of script