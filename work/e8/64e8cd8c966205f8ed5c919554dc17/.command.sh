#!/bin/bash -ue
awk 'NR>=2' CHR03locus3 | sort -k2,2n > tmp 
head -1 CHR03locus3 > header
cat header tmp > CHR03locus3.sorted
rm header tmp
