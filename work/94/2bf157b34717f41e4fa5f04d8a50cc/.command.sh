#!/bin/bash -ue
awk 'NR>=2' CHR10locus1 | sort -k2,2n > tmp 
head -1 CHR10locus1 > header
cat header tmp > CHR10locus1.sorted
rm header tmp
