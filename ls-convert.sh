#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Get script home path
scriptPath="$( cd "$(dirname "$0")" ; pwd -P )"

# Check for correct number of arguments. We are looking for one argument,
# which should be the path to the CSV file we want to convert.
if [[ $# -lt 1 ]]; then
  echo "Missing parameter: Input file"
fi

if [[ $# -gt 1 ]]; then
  echo "Invalid number of parameters"
  exit 2
fi

inputFile="$1"

# Check in put file exists and is in the correct format
if [ ! -f "$inputFile" ]; then
  echo "File not found: $inputFile"
fi

# Validate input file mime-type and extension
if [[ ! $(file --mime-type -b "$inputFile") == "text/plain" ]] && [[ ! $(file "$inputFile") == "ASCII text, with CRLF line terminators" ]]; then
  echo "Error: Not a valid csv file"
fi

# Select format of import file according to Vendor
echo
echo "+----------------------------------+-------+"
echo "|             Vendor               |  ID   |"
echo "+----------------------------------+--------"
echo "| HLC (Hawley-Lambert Cycles)      |   1   |"
echo "| LTP (Live To Play Sports)        |   2   |"
echo "| OGC (Outdoor Gear Canada)        |   3   |"
echo "+----------------------------------+-------+"
echo

read -r -p "ID of import file vendor: " vendorId
echo

case $vendorId in
  1)
    echo "Converting HLC file to compatible Lightspeed Retail import file..."

    echo "..done"
    ;;
  2)
    echo "Support for LTP coming soon!"
    ;;
  3)
    echo "Support for OGC coming soon!"
    ;;

esac



