!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Return error and stop execution if variable is unset
set -u

# Get script home path
scriptPath="$( cd "$(dirname "$0")" ; pwd -P )"

# Temporary file path
tempFile=$scriptPath/tmp/temp.csv

# Merge file path
mergeFile=$scriptPath/tmp/merge.csv

# Add file path
addFile=$scriptPath/tmp/add.csv

# Final file path
finalFile=$scriptPath/tmp/final.csv

# Get path to Lightspeed template file
lsTemplate=$scriptPath/src/lightspeed-item-import-template.csv

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

# Clean tmpp/ folder
rm $scriptPath/tmp/*.*

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
# echo "| LTP (Live To Play Sports)        |   2   |"
# echo "| OGC (Outdoor Gear Canada)        |   3   |"
echo "+----------------------------------+-------+"
echo

read -r -p "ID of import file vendor: " vendorId
echo

case $vendorId in
  1) ######### HLC #########

    source $scriptPath/src/hlc-func.sh
    convert $scriptPath $inputFile $tempFile $lsTemplate $mergeFile $addFile $finalFile

    ;;
  # 2) ######## LTP ###########
  #   echo "Support for LTP coming soon!"
  #   ;;
  # 3) ######## OGC ###########
  #   echo "Support for OGC coming soon!"
  #   ;;

  esac



