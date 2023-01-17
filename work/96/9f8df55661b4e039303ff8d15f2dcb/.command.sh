#!/bin/bash -ue
awk 'NR>=2' CHR03locus1 | sort -k2,2n > tmp 
head -1 CHR03locus1 > header
cat header tmp > CHR03locus1.sorted
rm header tmp
