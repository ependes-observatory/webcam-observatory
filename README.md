# Webcam scripts for Astronomical observatory of Épendes

This projects collects some scripts allowing to publish images and movies taken by the webcam of Épendes astronomical observatory, Fribourg, Switzerland.

[http://www.observatoire-observatoire-naef.ch/](http://www.observatoire-observatoire-naef.ch/)

## License

Copyright @ 2012 Nicolas Martignoni <nicolas@martignoni.net>

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

## Contents

### Goals

This project contains 4 scripts to process the images take by the webcam of the Astronomical observatory of Épendes, Fribourg, Switzerland,

Goals:

1. Publish on a [web page](http://www.observatoire-naef.ch/fr/visite/webcam) an image of the actual sky
2. Publish a timelapse movie of the day before today from images taken every minute
3. Publish a timelapse movie of the night before today from images taken every minute

### Scripts

__Warning__ ! These scripts use the syntax of the GNU `date` command (and not the BSD one) for relative dates and do not run on Darwin or FreeBSD.

* `process-images.sh`

  Main script, for processing the raw images uploaded by the video server and publishing every minute an actual image of the sky above the observatory. The script should run every minute, ideally via cron. It calls the other scripts when appropriate.

* `process-day-movie.sh`

  Script to process the daily images to produce a timelapse movie of the previous day. Should run every day, minutes after midnight. This script is launched appropriately by `process-images.sh`.

* `process-night-movie.sh`

  Script to process the daily images to produce a timelapse movie of the previous night, between two consecutive civil twilights. The begin and end civil twilight times are computed by the `twilight.php` script. Should run every day, after end of civil twilight. At Épendes, running after 08:00 is fine. This script is launched appropriately by `process-images.sh`.

* `process-pastnight-movie.sh`

  Script to process the daily images to produce a timelapse movie of a past night, between two consecutive civil twilights. The begin and end civil twilight times are computed by the `twilight.php` script. This should be launched manually, giving a timestamp as a parameter to determine the night for which to produce the movie, e.g. `process-pastnight-movie.sh -t 1341021600`

* `twilight.php`

  Used by `process-night-movie.sh` and `process-pastnight-movie.sh` to compute begin and end civil twilight times.