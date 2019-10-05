#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Get script home path
scriptPath="$( cd "$(dirname "$0")" ; pwd -P )"

# Temporary file path
tempFile=$scriptPath/tmp/temp.csv

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
  1) ######### HLC #########
    echo "Converting HLC file to compatible Lightspeed Retail import file..."

    # Get first line of import file
    read -r inputHeader < $inputFile

    # Create temporary csv file using this eader
    echo $inputHeader > $tempFile

    # count number of columns in import file
    importCols=$(head -1 $inputFile | sed 's/[^,]//g'| wc -c)

    # Get lightspeed headers from template
    read -r templateHeader < $lsTemplate

    # Get number of columns in template file
    templateCols=$(head -1 $lsTemplate | sed 's/[^,]//g'| wc -c)

    # Define empty array of columns to remove

    # Change internal field separator
    OIFS=$IFS;
    IFS=","

    # Convert headers to array
    arr=($inputHeader)

    # Define array of columns that we'll remove from the output file
    rem=()
  
    echo "+--------------------------+--------------------------+"
    echo "|       Import Field      -->    Lightspeed Field     |"      
    echo "+--------------------------+--------------------------+"
    echo 

    for i in ${arr[@]}; do

      # For each header in import file, replace with corresponding Lightspeed inventory field
      if [[ "$i" == "Item #" ]]; then
	sed -i -e "s/$i/Custom SKU/" $tempFile
	echo "   $i   -->   Custom SKU"

      elif [[  "$i" == "Description" ]]; then
	echo "   $i   -->   Description"

      elif [[  "$i" == "Qty" ]]; then
	sed -i -e "s/$i/Shop Quantity on Hand/" $tempFile
	echo "   $i   -->   Shop Quantity on Hand"

      elif [[ "$i" == "U/M" ]]; then
	# sed -i -e "s~$i~~" $tempFile
	rem+=($i)
	echo "   $i   -->   <REMOVED>"

      elif [[  "$i" == "Regular Price" ]]; then
	# sed -i -e "s/$i//" $tempFile
	rem+=($i)
	echo "   $i   -->   <REMOVED>"

      elif [[  "$i" == "Net Price" ]]; then
	sed -i -e "s/$i/Default Cost/" $tempFile
	echo "   $i   -->   Default Cost"

      elif [[  "$i" == "Net Amount" ]]; then
	# sed -i -e "s/$i//" $tempFile
	rem+=($i)
	echo "   $i   -->   <REMOVED>"

      elif [[  "$i" == "Label Price" ]]; then
	# sed -i -e "s/$i//" $tempFile
	rem+=($i)
	echo "   $i   -->   <REMOVED>"

      elif [[  "$i" == "MSRP" ]]; then
	sed -i -e "s/$i/MSRP - Price/" $tempFile
	echo "   $i   -->   MSRP - Price"

      elif [[  "$i" == "UPC" ]]; then
	echo "   $i   -->   UPC"
	
      elif [[  "$i" == "EAN" ]]; then
	echo "   $i   -->   EAN"

      elif [[  "$i" == "Dealer Bar Code" ]]; then
	# sed -i -e "s/$i//" $tempFile
	rem+=($i)
	echo "   $i   -->   <REMOVED>"
      fi

    done

    # Import rest of data into temp file
    tail -n +2 "$inputFile" >> $tempFile 

    # Remove invalid columns 
    

    # Removing temporary file
    # rm $tempFile

    echo "..done"
    ;;
  2) ######## LTP ###########
    echo "Support for LTP coming soon!"
    ;;
  3) ######## OGC ###########
    echo "Support for OGC coming soon!"
    ;;

  esac



