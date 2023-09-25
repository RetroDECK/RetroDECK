#!/bin/bash

progress_file="progress"
echo "0" > "$progress_file"

for ((i=1; i<=100; i++)); do
  echo -ne "$i" > "$progress_file"
#  echo $i
#  sleep 0.1
  sleep $((RANDOM / 30000))
done

sleep 1

rm "$progress_file"
