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

  echo "Converting OR file to compatible Lightspeed Retail import file..."

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
  echo "|       Import Field      -->    Lightspeed Field     |"
  echo "+--------------------------+--------------------------+"
  echo

  # For each header in import file, replace with corresponding Lightspeed inventory field
  sed -i -e "1 s/SKU/Custom SKU/" $tempFile
  echo "                   SKU    -->    Custom SKU"

  sed -i -e "1 s/Style Name/Matrix Description/" $tempFile
  echo "            Style Name    -->    Matrix Description"

  sed -i -e "1 s/Color Name/Attribute 1/" $tempFile
  echo "            Color Name    -->    Attribute 1"

  sed -i -e "1 s/Size/Attribute 2/" $tempFile
  echo "                  Size    -->    Attribute 2"

  echo "                   UPC    -->    UPC"

  sed -i -e "1 s/Wholesale Price/Default Cost/" $tempFile
  echo "       Wholesale Price    -->    Default Cost"

  sed -i -e "1 s/Retail Price/MSRP - Price/" $tempFile
  echo "          Retail Price    -->    MSRP - Price"

  sed -i -e "1 s/Quantity/Shop Quantity on Hand/" $tempFile
  echo "              Quantity    -->    Shop Quantity on Hand"

  sed -i -e "1 s/Segment/Category/" $tempFile
  echo "               Segment    -->    Category"

  sed -i -e "1 s/Workbook Category/Subcategory 1/" $tempFile
  echo "     Workbook Category    -->    Subcategory 1"

  sed -i -e "1 s/Sub Category/Subcategory 2/" $tempFile
  echo "          Sub Category    -->    Subcategory 2"

  # Drop invalid fields
  echo "$(csvcut -C "Style Number" $tempFile)" > $tempFile
  echo "          Style Number    -->    -- REMOVED --"

  echo "$(csvcut -C "Color Code" $tempFile)" > $tempFile
  echo "            Color Code    -->    -- REMOVED --"

  echo "$(csvcut -C "Alt Size" $tempFile)" > $tempFile
  echo "              Alt Size    -->    -- REMOVED --"

  echo "$(csvcut -C "Quantity Available" $tempFile)" > $tempFile
  echo "    Quantity Available    -->    -- REMOVED --"

  echo "$(csvcut -C "Start Ship Date" $tempFile)" > $tempFile
  echo "       Start Ship Date    -->    -- REMOVED --"

  echo "$(csvcut -C "Cancel Date" $tempFile)" > $tempFile
  echo "           Cancel Date    -->    -- REMOVED --"

  echo "$(csvcut -C "Gender" $tempFile)" > $tempFile
  echo "                Gender    -->    -- REMOVED --"

  echo "$(csvcut -C "Collection" $tempFile)" > $tempFile
  echo "            Collection    -->    -- REMOVED --"

  echo "$(csvcut -C "Draft" $tempFile)" > $tempFile
  echo "                 Draft    -->    -- REMOVED --"

  echo "$(csvcut -C "New/Bestseller" $tempFile)" > $tempFile
  echo "        New/Bestseller    -->    -- REMOVED --"

  echo "$(csvcut -C "Special Program" $tempFile)" > $tempFile
  echo "       Special Program    -->    -- REMOVED --"

  echo "$(csvcut -C "Technology" $tempFile)" > $tempFile
  echo "             Technology   -->    -- REMOVED --"

  echo "$(csvcut -C "Color" $tempFile)" > $tempFile
  echo "                 Color    -->    -- REMOVED --"

  # Begin final output file
  cp $lsTemplate $mergeFile

  # Get rows to loop over using Custom SKU as unique identifier
  IFS=$'\n'
  customSkus=( $(csvcut -c 'Custom SKU' $tempFile) )
  msrpPrices=( $(csvcut -c 'MSRP - Price' $tempFile) )

  # Add additional headers to a file that we'll merge later
  echo "Custom SKU,Matrix Attribute Set,Vendor,Default - Price,Online - Price" > $addFile

  # Loop for rows, ommitting first row containing header
  for s in "${!customSkus[@]}"; do
    # Trim dollar signs and whitespace from msrp prices
    m=$(echo "${msrpPrices[$s]/$/}" | xargs)

    # add row values
    echo "${customSkus[$s]},Color/Size,Outdoor Research,$m,$m" >> $addFile
  done

  # Echo results
  echo "           -- ADDED --    -->    Vendor"
  echo "           -- ADDED --    -->    Matrix Attribute Set"
  echo "           -- ADDED --    -->    Default - Price"
  echo "           -- ADDED --    -->    Online - Price"

  # Merge temp file into add file
  echo "$(csvjoin -c 'Custom SKU' --no-inference $tempFile $addFile)" > $tempFile

  # Remove duplicate fields
  echo "$(csvcut -C \
    'Custom SKU,Matrix Description,Shop Quantity on Hand,Default Cost,MSRP - Price,UPC,Vendor,Default - Price,Online - Price,Matrix Attribute Set,Attribute 1,Attribute 2,Category,Subcategory 1,Subcategory 2' \
    $mergeFile)" > $mergeFile

  # Join temp file with merge file
  echo "$(csvjoin --no-inference $tempFile $mergeFile)" > $finalFile

  # Copy converted file to home directory
  mkdir -p $HOME/Lightspeed/Outdoor\ Research\ Canada
  fileDate=$(date '+%Y%m%d_%H%M%S')

  cp $finalFile $HOME/Lightspeed/Outdoor\ Research\ Canada/ls_import_orc_$fileDate.csv

  echo
  echo "..done"
  echo
  echo "Output File: $HOME/Lightspeed/Outdoor\ Research\ Canada/ls_import_orc_$fileDate.csv"
  echo

}

