#!/bin/bash
if [ $1 ]
then
    FILE=./$1
else
    FILE=./releaseNotes.txt
fi
cmd='flag{ if (/---/){printf "%s", buf; flag=0; buf=""} else buf = buf $0 ORS}; /---/{flag=1}'
echo "$(awk "$cmd" $FILE)" > /tmp/deploy.out
regex='https://github.com'
while IFS= read -r line
do
  if [[ $line =~ $regex ]]; then
    echo "${line/$regex/}"
  else
    echo $line
  fi
done</tmp/deploy.out