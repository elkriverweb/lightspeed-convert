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

  priceTableName="ltp-2020-master-pos"
  pricelistPath="$scriptPath/src/pricelists/ltp-2020-master-pos.csv"
  pricelistTableName="ltp-pricelist"
  pricelistDbPath="$scriptPath/tmp/$pricelistTableName.db"

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
  sed -i -e "1 s/item.no/Custom SKU/I" $tempFile
  echo "              Item No.    -->    Custom SKU"

  sed -i -e "1 s/description/Description/I" $tempFile
  sed -i -e "1 s/item.description/Description/I" $tempFile
  echo "           Description    -->    Description"

  sed -i -e "1 s/qty.shipped/Shop Quantity on Hand/I" $tempFile
  echo "           Qty Shipped    -->    Shop Quantity on Hand"

  sed -i -e "1 s/net.price/Shop Unit Cost/I" $tempFile
  echo "             Net Price    -->    Shop Unit Cost"

  sed -i -e "1 s/unit.price/Default Cost/I" $tempFile
  echo "            Unit Price    -->    Default Cost"

  sed -i -e "1 s/upc/UPC/I" $tempFile
  echo "                   UPC    -->    UPC"

  # Remove invalid columns
  # sed -i -e "1 s/backorder.qty/BO/I" $tempFile
  # sed -i -e "1 s/qty b\/o/BO/I" $tempFile
  # echo "$(csvcut -C "BO" $tempFile)" > $tempFile
  # echo "         Backorder Qty    -->    -- REMOVED --"

  # sed -i -e "1 s/qty.alloc/QA/I" $tempFile
  # echo "$(csvcut -C "QA" $tempFile)" > $tempFile

  # sed -i -e "1 s/qty.on.pps/QOP/I" $tempFile
  # echo "$(csvcut -C "QOP" $tempFile)" > $tempFile
  # echo "         Qty Allocated    -->    -- REMOVED --"

  # sed -i -e "1 s/per/Per/I" $tempFile
  # echo "$(csvcut -C "Per" $tempFile)" > $tempFile
  # echo "                   Per    -->    -- REMOVED --"

  # sed -i -e "1 s/..saved/Saved/I" $tempFile
  # echo "$(csvcut -C "Saved" $tempFile)" > $tempFile
  # echo "                 Saved    -->    -- REMOVED --"

  # sed -i -e "1 s/disc../Discount/I" $tempFile
  # echo "$(csvcut -C "Discount" $tempFile)" $tempFile
  # echo "              Discount    -->    -- REMOVED --"

  # sed -i -e "1 s/net.amount/Net Amount/I" $tempFile
  # echo "$(csvcut -C "Net Amount" $tempFile)" $tempFile
  # echo "            Net Amount    -->    -- REMOVED--"

  # Begin final output file
  cp $lsTemplate $mergeFile

  # Get rows to loop over using Custom SKU as unique identifier
  IFS=$'\n'
  customSkus=( $(csvcut -c 'Custom SKU' $tempFile) )


  # Add additional headers to a file that we'll merge later
  echo "Custom SKU,Vendor,Default - Price,MSRP - Price,Online - Price" > $addFile

  # Loop for rows, ommitting first row containing header
  echo "Updating data. This may take a long time..."
  echo

  # Create sqlite3 database
  csvsql --db "sqlite:///$pricelistDbPath" --table "$pricelistTableName" --insert "$pricelistPath"

  for s in "${!customSkus[@]}"; do

    # Get MSRP from master price list
    # m=$(csvsql --query "SELECT [MSRP] FROM '$priceTableName' WHERE [Custom SKU] = '${customSkus[$s]}'" $pricelistPath | sed -n 2p)
    m=$(echo "SELECT MSRP FROM \"$pricelistTableName\" where \"Custom SKU\" = '${customSkus[$s]}'" | sqlite3 $pricelistDbPath)
    printf '*'

    # add row values
    echo "${customSkus[$s]},Live to Play Sports (Canada),$m,$m,$m" >> $addFile
  done
  echo
  echo "...updates complete!"

  # Echo results
  echo "           -- ADDED --    -->    Vendor"
  echo "           -- ADDED --    -->    Default - Price"
  echo "           -- ADDED --    -->    MSRP - Price"
  echo "           -- ADDED --    -->    Online - Price"

  # Merge temp file into add file
  echo "$(csvjoin -c 'Custom SKU' --no-inference $tempFile $addFile)" > $tempFile

  # Remove duplicate fields
  echo "$(csvcut -C \
    'Custom SKU,Description,Shop Quantity on Hand,Shop Unit Cost,Default Cost,MSRP - Price,UPC,Vendor,Default - Price,Online - Price' \
    $mergeFile)" > $mergeFile

  # Join temp file with merge file
  echo "$(csvjoin --no-inference $tempFile $mergeFile)" > $finalFile

  # Clean up temporary files
  rm $pricelistDbPath

}

