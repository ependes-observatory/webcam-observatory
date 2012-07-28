<?php
/*
// Copyright 2012 Nicolas Martignoni <nicolas%martignoni.net>
//
// License: This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or (at your
// option) any later version. This program is distributed in the hope that it
// will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
// Public License for more details.
*/

/*
// This script computes the begin and end civil twilight time
// Usage: php twilight.php
// Output: begin and end civil twilight time in 24-hour format,
// separated with a space, e.g. 2146 0530
*/

$opts= array("timestamp::", "long::", "lat::");
$options = getopt("",$opts);

// Default values
// Localisation: Épendes
$lat = 46.762333;    // North
$long = 7.139444;    // East
// Current time
$timestamp = time();

// Override default values if parameters are given
foreach( $options as $key => $value ) {
  ${$key} = $value;
}

if ( date('I', $timestamp) ) { // difference between GMT and local time in hours
  $offset = 2;
} else {
  $offset = 1;
}

$zenith=96; // Sun zenith angle at twilight begin/end, i.e. 6 degrees under horizon

$yesterday_twilightend = date_sunset($timestamp - 60 * 60 * 24, SUNFUNCS_RET_TIMESTAMP, $lat, $long, $zenith, $offset);
$today_twilightbegin = date_sunrise($timestamp, SUNFUNCS_RET_TIMESTAMP, $lat, $long, $zenith, $offset);

if ( PHP_SAPI === 'cli' ) {
  echo date("Hi", $yesterday_twilightend);
  echo " ";
  echo date("Hi", $today_twilightbegin);
  echo "\n";
} else {
  echo "<p>\"Civilian Twilight\" yesterday end: ".date("Hi", $yesterday_twilightend);
  echo "<br>\"Civilian Twilight\" today start: ".date("Hi", $today_twilightbegin);
}

?>