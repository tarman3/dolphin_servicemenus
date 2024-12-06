#!/bin/bash

oldIFS="$IFS"
IFS=$';'
read -r -a array <<< "$1"
IFS="$oldIFS"

firstFile=${array[0]}
path=${firstFile%/*}

exit_status=$?; if [ $exit_status != 0 ]; then exit; fi


numberFiles=${#array[@]}
dbusRef=`kdialog --title "Decrypt PDF" --progressbar "1 of $numberFiles  =>  ${firstFile##*/}" $numberFiles`

for file in "${array[@]}"; do

    qpdf --decrypt "$file" "${file%.*}-decrypt.pdf"

    counter=$(($counter+1))
    qdbus $dbusRef Set "" value $counter
    qdbus $dbusRef setLabelText "$counter of $numberFiles  =>  ${file##*/}"
    if [ ! `qdbus | grep ${dbusRef% *}` ]; then exit; fi

done

qdbus $dbusRef close

kdialog --title "PDF Decrypt" --icon "checkbox" --passivepopup "Completed" 3
