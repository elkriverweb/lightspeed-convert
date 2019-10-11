!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Return error and stop execution if variable is unset
set -u

# Set path to output file
outputPath="$HOME/Lightspeed Imports"

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
lsTemplate=$scriptPath/src/templates/lightspeed-items-import-template.csv

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

# Clean tmp/ folder
rm $scriptPath/tmp/*

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
# echo "| OGC (Outdoor Gear Canada)        |   3   |"
echo "| O.R. (Outdoor Research Canada)   |   4   |"
echo "+----------------------------------+-------+"
echo

read -r -p "ID of import file vendor: " vendorId
echo

# Beginning conversion message
echo "Converting file to compatible Lightspeed Retail import file..."

case $vendorId in
  1) ######### HLC #########

    outputFilePath="$outputPath/Item Imports/HLC"
    outputFileName="hlc-items-import"
    source $scriptPath/src/convert-hlc-items.sh
    convert $scriptPath $inputFile $tempFile $lsTemplate $mergeFile $addFile $finalFile

    ;;
  2) ######## LTP ###########

    outputFilePath="$outputPath/Item Imports/Live to Play"
    outputFileName="ltp-items-import"
    source $scriptPath/src/convert-ltp-items.sh
    convert $scriptPath $inputFile $tempFile $lsTemplate $mergeFile $addFile $finalFile

      ;;
  # 3) ######## OGC ###########
    #   echo "Support for OGC coming soon!"
    #   ;;
  4) ######## O.R. ##########

    outputFilePath="$outputPath/Item Imports/Outdoor Research"
    outputFileName="or-itemes-import"
    source $scriptPath/src/convert-or-items.sh
    convert $scriptPath $inputFile $tempFile $lsTemplate $mergeFile $addFile $finalFile

    ;;

  esac

  # Copy converted file to home directory
  mkdir -p $outputFilePath
  fileDate=$(date '+%Y%m%d_%H%M%S')

  cp $finalFile "$outputFilePath"/"$outputFileName"_"$fileDate.csv"

  # Conversion completed message
  echo
  echo "..done"
  echo
  echo "Output File: $outputFilePath/$outputFileName"_"$fileDate.csv"
  echo

  # Clean up tmp/ directory
  # rm $scriptPath/tmp/*



