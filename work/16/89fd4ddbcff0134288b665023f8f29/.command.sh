#!/bin/bash -ue
awk 'NR>=2' CHR10locus2 | sort -k2,2n > tmp 
head -1 CHR10locus2 > header
cat header tmp > CHR10locus2.sorted
rm header tmp
