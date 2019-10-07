!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

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
    echo "Converting HLC file to compatible Lightspeed Retail import file..."

    # Get first line of import file
    read -r inputHeader < $inputFile

    # Create temporary csv file using input file
    cp $inputFile $tempFile

    # count number of columns in import file
    importCols=$(head -1 $inputFile | sed 's/[^,]//g'| wc -c)

    # Get lightspeed headers from template
    read -r templateHeader < $lsTemplate

    # Get number of columns in template file
    templateCols=$(head -1 $lsTemplate | sed 's/[^,]//g'| wc -c)

    echo "+--------------------------+--------------------------+"
    echo "|       Import Field      -->    Lightspeed Field     |"
    echo "+--------------------------+--------------------------+"
    echo

    # For each header in import file, replace with corresponding Lightspeed inventory field
    sed -i -e "1 s/Item #/Custom SKU/" $tempFile
    echo "   Item #   -->   Custom SKU"

    echo "   Description   -->   Description"

    sed -i -e "1 s/Qty/Shop Quantity on Hand/" $tempFile
    echo "   Qty   -->   Shop Quantity on Hand"

    echo "$(csvcut -C "U/M" $tempFile)" > $tempFile
    echo "   U/M   -->   <REMOVED>"

    echo "$(csvcut -C "Regular Price" $tempFile)" > $tempFile
    echo "   Regular Price   -->   <REMOVED>"

    sed -i -e "1 s/Net Price/Default Cost/" $tempFile
    echo "   Net Price   -->   Default Cost"

    echo "$(csvcut -C "Net Amount" $tempFile)" > $tempFile
    echo "   Net Amount   -->   <REMOVED>"

    echo "$(csvcut -C "Label Price" $tempFile)" > $tempFile
    echo "   Label Price   -->   <REMOVED>"

    sed -i -e "1 s/MSRP/MSRP - Price/" $tempFile
    echo "   MSRP   -->   MSRP - Price"

    echo "   UPC   -->   UPC"

    echo "   EAN   -->   EAN"

    echo "$(csvcut -C "Dealer Bar Code" $tempFile)" > $tempFile
    echo "   Dealer Bar Code   -->   <REMOVED>"


    # Begin final output file
    cp $lsTemplate $mergeFile

    # Get rows to loop over using Custom SKU as unique identifier
    IFS=$'\n'
    customSkus=( $(csvcut -c 'Custom SKU' $tempFile) )
    msrpPrices=( $(csvcut -c 'MSRP - Price' $tempFile) )

    # Add additional headers to a file that we'll merge later
    echo "Custom SKU,Vendor,Default - Price,Online - Price" > $addFile

    # Loop for rows, ommitting first row containing header
    for s in "${!customSkus[@]}"; do
      # Trim dollar signs and whitespace from msrp prices
      m=$(echo "${msrpPrices[$s]/$/}" | xargs)

      # add row values
      echo "${customSkus[$s]},HLC,$m,$m" >> $addFile
    done

    # Merge temp file into add file
    echo "$(csvjoin -c 'Custom SKU' $tempFile $addFile)" > $tempFile

    # Remove duplicate fields
    echo "$(csvcut -C \
      'Custom SKU,Description,Shop Quantity on Hand,Default Cost,MSRP - Price,UPC,EAN,Vendor,Default - Price,Online - Price' \
      $mergeFile)" > $mergeFile

    # Join temp file with merge file
    echo "$(csvjoin $tempFile $mergeFile)" > $finalFile

    # Copy converted file to home directory
    mkdir -p ~/Lightspeed\ CSV
    fileDate=$(date '+%Y%m%d_%H%M%S')

    cp $finalFile ~/Lightspeed\ CSV/ls_import_hlc_$fileDate.csv

    echo "Output File: ~/Lightspeed\ CSV/ls_import_hlc_$fileDate.csv"

    # Clean up tmp/ directory
    rm $scriptPath/tmp/*.*

    echo "..done"

    ;;
  # 2) ######## LTP ###########
  #   echo "Support for LTP coming soon!"
  #   ;;
  # 3) ######## OGC ###########
  #   echo "Support for OGC coming soon!"
  #   ;;

  esac



