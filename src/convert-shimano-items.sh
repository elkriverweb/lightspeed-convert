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
  sed -i -e "1 s/Sku/Custom SKU/I" $tempFile
  echo "                   Sku    -->    Custom SKU"

  sed -i -e "1 s/Name/Description/I"
  echo "                  Name    -->    Description"

  sed -i -e "1 s/Quantity/Shop Quantity on Hand/I" $tempFile
  echo "              Quantity    -->    Shop Quantity on Hand"

  sed -i -e "1 s/Unit/Default Cost/" $tempFile
  echo "                  Unit    -->    Default Cost"

  # Remove invalid columns
  # echo "$(csvcut -C "Ext Price" $tempFile)" > $tempFile
  # echo "             Ext Price    -->    -- REMOVED --"
  #
  # echo "$(csvcut -C "WHSL" $tempFile)" > $tempFile
  # echo "                  WHSL    -->    -- REMOVED --"
  #
  # echo "$(csvcut -C "Tracking Number" $tempFile)" > $tempFile
  # echo "       Tracking Number    -->    -- REMOVED --"

  # Begin final output file
  cp $lsTemplate $mergeFile

  # Get rows to loop over using Custom SKU as unique identifier
  IFS=$'\n'
  customSkus=( $(csvcut -c 'Custom SKU' $tempFile) )

  # Add additional headers to a file that we'll merge later
  echo "Custom SKU,Vendor" > $addFile

  # Loop for rows, ommitting first row containing header
  for s in "${!customSkus[@]}"; do

    # add row values
    echo "${customSkus[$s]},Shimano (Canada)" >> $addFile
  done

  # Echo results
  echo "           -- ADDED --    -->    Vendor"

  # Merge temp file into add file
  echo "$(csvjoin -c 'Custom SKU' --no-inference $tempFile $addFile)" > $tempFile

  # Remove duplicate fields
  echo "$(csvcut -C \
    'Custom SKU,Description,Shop Quantity on Hand,Default Cost,Vendor' \
    $mergeFile)" > $mergeFile

  # Join temp file with merge file
  echo "$(csvjoin --no-inference $tempFile $mergeFile)" > $finalFile

}

