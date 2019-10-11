#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Return error and stop execution if variable is unset
set -u

function convert {
  scriptPath=$1
  importFile=$2
  tempFile=$3
  lstemplate=$4
  mergeFile=$5
  addFile=$6
  finalFile=$7

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

  echo
  echo "+--------------------------+--------------------------+"
  echo "|       Input Field       -->     Output Field        |"
  echo "+--------------------------+--------------------------+"
  echo

  # For each header in import file, replace with corresponding Lightspeed inventory field
  sed -i -e "1 s/Item #/Custom SKU/" $tempFile
  echo "                Item #    -->    Custom SKU"

  echo "           Description    -->    Description"

  sed -i -e "1 s/Qty/Shop Quantity on Hand/" $tempFile
  echo "                   Qty    -->    Shop Quantity on Hand"

  sed -i -e "1 s/Net Price/Default Cost/" $tempFile
  echo "             Net Price    -->    Default Cost"

  sed -i -e "1 s/MSRP/MSRP - Price/" $tempFile
  echo "                  MSRP    -->    MSRP - Price"

  echo "                   UPC    -->    UPC"

  echo "                   EAN    -->    EAN"

  # Remove invalid columns
  echo "$(csvcut -C "Net Amount" $tempFile)" > $tempFile
  echo "            Net Amount    -->    -- REMOVED --"

  echo "$(csvcut -C "Label Price" $tempFile)" > $tempFile
  echo "           Label Price    -->    -- REMOVED --"

  echo "$(csvcut -C "U/M" $tempFile)" > $tempFile
  echo "                   U/M    -->    -- REMOVED --"

  echo "$(csvcut -C "Regular Price" $tempFile)" > $tempFile
  echo "         Regular Price    -->    -- REMOVED --"

  echo "$(csvcut -C "Dealer Bar Code" $tempFile)" > $tempFile
  echo "       Dealer Bar Code    -->    -- REMOVED --"

  # Begin final output file
  cp $lsTemplate $mergeFile

  # Get rows to loop over using Custom SKU as unique identifier
  IFS=$'\n'
  customSkus=( $(csvcut -c 'Custom SKU' $tempFile) )
  msrpPrices=( $(csvcut -c 'MSRP - Price' $tempFile) )
  defaultCosts=( $(csvcut -c 'Default Cost' $tempFile) )

  # Drop MSRP - Prices and replace with dollar sign removed
  echo "$(csvcut -C "MSRP - Price" $tempFile)" > $tempFile

  # Drop Default Cost and replace with dollar sign removed
  echo "$(csvcut -C "Default Cost" $tempFile)" > $tempFile

  # Add additional headers to a file that we'll merge later
  echo "Custom SKU,Vendor,Default Cost,Default - Price,MSRP - Price,Online - Price" > $addFile

  # Loop for rows, ommitting first row containing header
  for s in "${!customSkus[@]}"; do

    # Trim dollar signs and whitespace from msrp prices
    m=$(echo "${msrpPrices[$s]/$/}" | xargs)
    c=$(echo "${defaultCosts[$s]/$/}" | xargs)

    # add row values
    echo "${customSkus[$s]},HLC,$c,$m,$m,$m" >> $addFile
  done

  # Echo results
  echo "           -- ADDED --    -->    Vendor"
  echo "           -- ADDED --    -->    Default - Price"
  echo "           -- ADDED --    -->    Online - Price"

  # Merge temp file into add file
  echo "$(csvjoin -c 'Custom SKU' --no-inference $tempFile $addFile)" > $tempFile

  # Remove duplicate fields
  echo "$(csvcut -C \
    'Custom SKU,Description,Shop Quantity on Hand,Default Cost,MSRP - Price,UPC,EAN,Vendor,Default - Price,Online - Price' \
    $mergeFile)" > $mergeFile

  # Join temp file with merge file
  echo "$(csvjoin --no-inference $tempFile $mergeFile)" > $finalFile

}

