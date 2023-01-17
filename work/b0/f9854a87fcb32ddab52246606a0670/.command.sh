#!/bin/bash -ue
awk \
    'BEGIN{OFS="\t"} NR>=2{print $1, $2, $2+1}' CHR10locus1.sorted.ld_out.processed \
    > CHR10locus1.sorted.ld_out.processed.bed
awk \
    -f $(which ens2ucsc.awk) CHR10locus1.sorted.ld_out.processed.bed \
    > CHR10locus1.sorted.ld_out.processed.ucsc.bed
