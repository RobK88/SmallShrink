#!/bin/sh

cd /tmp/smallshrink
date >> log


astreamid="0x80"
title=""
method="mencoder"
requantize="ifrequired"
dvdsize="4519230769"
demux="mencoder"
remux="mplex"
tempFiles="Delete"

while getopts a:t:s:m:r:d:x:k: o
do case "$o" in
	a)	astreamid="$OPTARG";;
	t)	title="$OPTARG";;
	s)  dvdsize="$OPTARG";;
	m)  method="$OPTARG";;
	r)  requantize="$OPTARG";;
	d)  demux="$OPTARG";;
	x)  remux="$OPTARG";;
	k)  tempFiles="$OPTARG";;
	[?])	echo >&2 "Usage: $0 [-a audio_stream_id] [-t title] [-s maxsize] [-m extraction_method] [-r requantize_option] [-d demux_method] [-x remux_method]"
		exit 1;;
	esac
done

log=/tmp/smallshrink/log

rpath=`dirname "$0"`
echo tools=$rpath >> log

echo Audio stream=$astreamid >> log
echo Max DVD size is $dvdsize >> log
echo Extraction method is $method >> log
echo Requantize option is $requantize >> log
echo Demux method is $demux >> log
echo Remux method is $remux >> log

if [[ -z "$title" ]]; then
title=`$rpath/lsdvd "\`cat input\`" | awk '/^Longest/ { print $3;}'`
fi

echo Title $title >> log


chapters=`$rpath/tcprobe -i "\`cat input\`" -T$title -d 2 2>&1 | awk '/\[Chapter/ {  split($4,a,":"); if (ch != "") ch = ch ","; ch = ch a[1]*60 + a[2]  ":"  a[3]; } END {print ch;}'`
echo Chapters $chapters >> log


if [[ "$method" = "tccat" ]]; then
$rpath/tccat -i "`cat input`" -T$title,-1 -P > fromdvd.mpg 2>> log
fi


if [[ "$method" = "mencoder" ]]; then
$rpath/mencoder -msglevel all=1 -ovc copy -oac copy -of mpeg -mpegopts format=dvd:tsaf -dvd-device "`cat input`" dvdnav://$title -nocache -aid $astreamid -o fromdvd.mpg >> log 2>&1
fi


if [[ $? -ne 0 ]]; then
echo Failed to read from dvd >> log
exit 1
fi


fullvideosize=`ls -l fromdvd.mpg | awk '{print $5}'`

if [ $dvdsize -gt $fullvideosize -a "$requantize" != "Always" -o "$requantize" = "Never" ]
then
echo No requantize >> log
echo Max DVD size is $dvdsize >> log
echo Video size is $fullvideosize >> log
echo Requantize option is $requantize >> log
mv fromdvd.mpg mplex$title.mpg
else

echo Requantizing >> log
echo Max DVD size is $dvdsize >> log
echo Video size is $fullvideosize >> log
echo Requantize option is $requantize >> log

#--- Get audio stream ---

audiostream=`$rpath/ffmpeg -i fromdvd.mpg 2>&1 |  grep $astreamid | sed 's/.*#\(0.*\)\[.*/\1/'`
echo Audio stream $audiostream >> log

echo Demuxing audio with $demux >> log

if [[ "$demux" = "ffmpeg" ]]; then
$rpath/ffmpeg -y -i fromdvd.mpg -map $audiostream -vn -f ac3 audio.ac3  >> log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to extract audio >> log
exit 2
fi
fi

if [[ "$demux" = "mencoder" ]]; then
$rpath/mencoder -msglevel all=1 fromdvd.mpg -ovc copy -oac copy -aid $astreamid -of rawaudio -o audio.ac3 >> log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to extract audio >> log
exit 2
fi
fi

chapteraudiosize=`ls -l audio.ac3 | awk '{print $5}'`
echo Audio uses $chapteraudiosize bytes >> log

echo Demuxing video with $demux >> log
if [[ "$demux" = "ffmpeg" ]]; then
$rpath/ffmpeg -y -i fromdvd.mpg -vcodec copy -an -f mpeg2video video.m2v >> log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to extract video >> log
exit 3
fi
fi

if [[ "$demux" = "mencoder" ]]; then
$rpath/mencoder -msglevel all=1 fromdvd.mpg -ovc copy -oac copy -of rawvideo -o video.m2v >> log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to extract video >> log
exit 3
fi
fi

chaptervideosize=`ls -l video.m2v | awk '{print $5}'`
echo Video uses $chaptervideosize bytes >> log

let videomustfit=$dvdsize-$chapteraudiosize
echo Video must fit $videomustfit bytes 

requantfactor=`echo 'scale=2;' $chaptervideosize / $videomustfit | bc`

echo Requant factor is $requantfactor 


$rpath/M2VRequantiser $requantfactor $chaptervideosize < video.m2v > rq.m2v  2>> log
if [[ "$tempFiles" != "Keep all" ]]; then
rm video.m2v
fi


echo Remuxing with $remux >> log

if [[ "$remux" = "mplex" ]]; then
$rpath/mplex -S 0 -v 0 -f 8 -M -o mplex$title.mpg rq.m2v audio.ac3 >> log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to remultiplex >> log
exit 4
fi
fi

if [[ "$remux" = "ffmpeg" ]]; then
$rpath/ffmpeg -i rq.m2v -i audio.ac3 -target dvd -vcodec copy -acodec copy mplex$title.mpg >> log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to remultiplex >> log
exit 4
fi
fi

if [[ "$remux" = "mencoder" ]]; then
$rpath/mencoder -msglevel all=1  -ovc copy -oac copy -of mpeg -mpegopts format=dvd:tsaf rq.m2v -audiofile audio.ac3 -o mplex$title.mpg >> log 2>&1
if [[ $? -ne 0 ]]; then
echo Failed to remultiplex >> log
exit 4
fi
fi
if [[ "$tempFiles" != "Keep all" ]]; then
rm audio.ac3 rq.m2v 
fi
fi

if [[ "$tempFiles" != "Keep all" ]]; then
rm fromdvd.mpg
fi

echo '<vob file="'mplex$title'.mpg" chapters="'$chapters'"/>' >> dvd.xml

date >> log
