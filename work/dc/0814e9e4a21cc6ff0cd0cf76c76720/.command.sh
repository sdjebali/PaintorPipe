#!/bin/bash -ue
awk 'NR>=2' CHR06locus1 | sort -k2,2n > tmp 
head -1 CHR06locus1 > header
cat header tmp > CHR06locus1.sorted
rm header tmp
