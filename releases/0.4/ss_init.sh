#! /bin/bash

rm -rf /tmp/smallshrink
mkdir /tmp/smallshrink
cd /tmp/smallshrink

log=/tmp/smallshrink/smallshrink.log

while getopts l:i: o
do case "$o" in
	l)	log="$OPTARG";;
	i)	inputname="$OPTARG";;
	[?])	echo >&2 "Usage: $0 [-l $log] -i input"
		exit 1;;
	esac
done


date > "$log"
ln -s "$log" log

if [[ -z "$inputname" ]]; then
	echo No input file >> "$log"
	exit 1
fi



rpath=`dirname "$0"`
echo tools=$rpath >> "$log"

echo input=$inputname
realinput=`mount | grep "$inputname" | cut -d' ' -f1`
if [[ -z "$realinput" ]]; then
realinput=$inputname 
fi
echo realinput=$realinput >> "$log"
echo $realinput > input


echo '<dvdauthor dest="dvdfiles">' > dvd.xml
echo '<titleset>' >> dvd.xml
echo '<titles>' >> dvd.xml
echo '<pgc>' >> dvd.xml


