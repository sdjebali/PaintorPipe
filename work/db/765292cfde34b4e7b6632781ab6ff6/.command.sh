#!/bin/bash -ue
awk 'NR>=2' CHR16locus1 | sort -k2,2n > tmp 
head -1 CHR16locus1 > header
cat header tmp > CHR16locus1.sorted
rm header tmp
