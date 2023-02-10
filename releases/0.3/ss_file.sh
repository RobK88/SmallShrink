#!/bin/sh

astreamid="0x80"
title=""
method="mencoder"
log=~/Desktop/smallshrink.log

while getopts a:t:s:m:r:d:x:i:o:f:l: o
do case "$o" in
	a)	astreamid="$OPTARG";;
	t)	title="$OPTARG";;
	m)  method="$OPTARG";;
	o)  outputFolder="$OPTARG";;
	f)  outputFilename="$OPTARG";;
	i)	inputname="$OPTARG";;
	l)  log="$OPTARG";;
	[?])	echo >&2 "Usage: $0 [-a audio_stream_id] [-t title] [-m extraction_method] [-o output_folder] [-f output_filename] [-i input_source] [-l logfile]"
		exit 1;;
	esac
done

date >> $log
rpath=`dirname "$0"`
echo tools=$rpath >> $log


echo Audio stream=$astreamid >> $log
echo Extraction method is $method >> $log
echo Output folder is $outputFolder >> $log
echo Output filename is $outputFilename >> $log

realinput=`mount | grep "$inputname" | cut -d' ' -f1`
if [[ -z "$realinput" ]]; then
realinput=$inputname 
fi
echo realinput=$realinput >> $log


if [[ -z "$title" ]]; then
title=`$rpath/lsdvd "$realinput" | awk '/^Longest/ { print $3;}'`
fi

echo Title $title >> $log


if [[ "$method" = "tccat" ]]; then
$rpath/tccat -i "$realinput" -T$title,-1 -P > "$outputFolder/$outputFilename.$title.mpg" 2>> $log
if [[ $? -ne 0 ]]; then
echo Failed to read from dvd >> $log
exit 1
fi
fi


if [[ "$method" = "mencoder" ]]; then
$rpath/mencoder -ovc copy -oac copy -of mpeg -mpegopts format=dvd:tsaf -dvd-device "$realinput" dvdnav://$title -nocache -aid $astreamid -o "$outputFolder/$outputFilename.$title.mpg"  >> $log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to read from dvd >> $log
exit 1
fi
fi

date >> $log


