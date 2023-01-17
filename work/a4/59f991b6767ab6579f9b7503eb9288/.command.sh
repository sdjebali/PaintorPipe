#!/bin/bash -ue
awk 'NR>=2' CHR03locus2 | sort -k2,2n > tmp 
head -1 CHR03locus2 > header
cat header tmp > CHR03locus2.sorted
rm header tmp
