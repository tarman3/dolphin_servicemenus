#!/bin/bash

old_ifs="$IFS"
IFS=$';'
read -r -a array <<< "$1"
IFS="$old_ifs"

firstFile=${array[0]}
path=${firstFile%/*}
ext=${firstFile##*.}


duration=`ffprobe -i "$firstFile" -show_entries format=duration -v quiet -of csv="p=0" -sexagesimal`
duration=${duration%.*}

parameters=`yad --width=300 --borders=10 --title="Media Cut" --form --item-separator="|" --separator="," \
    --field="Start" --field="Finish" --field="Re-encoding (slowly but precisely):CHK" \
    --field="FadeIn" --field="FadeOut" \
    \
    "0:00:00"    "$duration"    TRUE    0    0`

exit_status=$?
if [ $exit_status != 0 ]; then exit; fi

cutStart=$(echo $parameters | awk -F ',' '{print $1}')
cutFinish=$(echo $parameters | awk -F ',' '{print $2}')
reEncoding=$(echo $parameters | awk -F ',' '{print $3}')

fadeInDuration=$( echo $parameters | awk -F ',' '{print $4}')
fadeOutDuration=$( echo $parameters | awk -F ',' '{print $5}')
if [ "$fadeInDuration" -ne 0] || [ "$fadeOutDuration" -ne 0 ]; then
    startFadeOut=$(($cutFinishTime-$cutStart-$fadeInDuration))
    fadeInOut="-vf fade=t=in:st=0:d=${fadeInDuration}" #,fade=t=out:st=${startFadeOut}:d=${fadeOutDuration}"
fi

sufix="${cutStart/ /_}_${cutFinish/ /_}"

if [ "$cutStart" != "" ]; then start="-ss $cutStart"; fi
if [ "$cutFinish" != "" ]; then finish="-to $cutFinish"; fi
options="$start $finish"

if [ "$reEncoding" = FALSE ] && [ -z "$fadeInOut" ]; then encode="-vcodec copy -acodec copy"; fi


ffmpeg -v quiet -stats $start $finish -i "$firstFile" -y $encode $fadeInOut -strict -2 "${firstFile%.*}_$sufix.$ext"


kdialog --title "Media Cut" --icon "checkbox" --passivepopup "Completed" 3
