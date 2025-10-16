#!/bin/bash
set -e

VAR=$1
VAL=$2
FILE="${3:-.config}"

CONF_LINE="$VAR=$VAL"

# Try to modify existing line (either set or commented out)
sed -E -i -e "s|($VAR)=.*|\1=$VAL|;s|# ($VAR) is not set|\1=$VAL|" "$FILE"

# Check if the variable exists in the file now
if ! grep -q "^$VAR=" "$FILE"; then
    # Variable doesn't exist, add it
    echo "$CONF_LINE" >> "$FILE"
fi
