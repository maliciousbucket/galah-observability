#!/bin/bash

BLOCK='\033[1;37m'
RED='\033[1;31m'
BLU='\033[1;34m'
MSG=''


file_count=$(find . -mindepth 1 -type f \( -name "*.yaml" -o -name "*.yml" \) -printf x | wc -c)

if ((file_count==0))
then
  MSG="Woohoo! You're free!"
elif((0<=file_count && file_count<=50))
 then
  MSG="Run from it. Hide from it. You can't escape YAML hell..."
elif((50<file_count))
 then
  MSG="Welcome to YAML Hell! Population: You"
fi

echo -e "${BLU}Number of yaml files found: ${RED}${file_count}${BLOCK}"
echo -e "${RED}${MSG}${BLOCK}"