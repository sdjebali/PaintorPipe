#!/bin/bash -ue
awk \
    'BEGIN{OFS="\t"} NR>=2{print $1, $2, $2+1}' CHR16locus1.sorted.ld_out.processed \
    > CHR16locus1.sorted.ld_out.processed.bed
awk \
    -f $(which ens2ucsc.awk) CHR16locus1.sorted.ld_out.processed.bed \
    > CHR16locus1.sorted.ld_out.processed.ucsc.bed
