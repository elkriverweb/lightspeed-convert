#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

if [[ $# -lt 1 ]]; then
  echo "Missing parameter: Input file"
fi

if [[ $# -gt 1 ]]; then
  echo "Invalid number of parameters"
  exit 2
fi


