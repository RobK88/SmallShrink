#!/bin/sh


cd /tmp/smallshrink
date >> log

tempFiles="Delete";

while getopts o:k: o
do case "$o" in
	o)	output="$OPTARG";;
	k)  tempFiles="$OPTARG";;
	[?])	echo >&2 "Usage: $0 -o output"
		exit 1;;
	esac
done

rpath=`dirname "$0"`
echo tools=$rpath >> log

if [[ -z "$output" ]]; then
echo No output specified >> log
exit 1
fi

echo output=$output  >> log
outputname=`basename "$output" .iso`
echo volume id=$outputname >> log

echo '</pgc>' >> dvd.xml
echo '</titles>' >> dvd.xml
echo '</titleset>' >> dvd.xml
echo '</dvdauthor>' >> dvd.xml



$rpath/dvdauthor -o dvdfiles -x dvd.xml >> log 2>&1
if [[ "$tempFiles" = "Delete" ]]; then
rm mplex*.mpg
fi

$rpath/dvdauthor -T -o dvdfiles
$rpath/mkisofs -dvd-video -udf -o "$output" -V "$outputname" 'dvdfiles' >> log 2>&1

date >> log

cd ~
if [[ "$tempFiles" = "Delete" ]]; then
rm -rf /tmp/smallshrink
fi





