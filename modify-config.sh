#!/bin/bash
set -e

VAR=$1
VAL=$2
FILE="${3:-.config}"

CONF_LINE="$VAR=$VAL"

echo "Modifying $VAR to $VAL on $FILE"
sed -E -i -e "s|($VAR)=.*|\1=$VAL|;s|# ($VAR) is not set|\1=$VAL|" "$FILE"
