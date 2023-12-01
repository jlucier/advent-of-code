#! /bin/bash

cat inp1.txt \
  | sed "s/[a-z]//g" \
  | awk '{ print substr($1, 1, 1) substr($1, length($1)) }' \
  | awk '{s+=$1} END {print s}'
