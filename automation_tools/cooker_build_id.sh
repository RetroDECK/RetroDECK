#!/bin/bash

word1=$(shuf -n 1 ${GITHUB_WORKSPACE}/automation_tools/codename_wordlist.txt)
capitalized_word1="$(tr '[:lower:]' '[:upper:]' <<< ${word1:0:1})${word1:1}"
word2=$(shuf -n 1 ${GITHUB_WORKSPACE}/automation_tools/codename_wordlist.txt)
capitalized_word2="$(tr '[:lower:]' '[:upper:]' <<< ${word2:0:1})${word2:1}"
result=$capitalized_word1$capitalized_word2
echo $result > ${GITHUB_WORKSPACE}/buildid
echo "buildid=$result" >> $GITHUB_ENV
echo "VersionID is $result"