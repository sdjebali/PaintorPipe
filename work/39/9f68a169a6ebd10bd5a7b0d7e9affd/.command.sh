#!/bin/bash -ue
awk \
    'BEGIN{OFS="\t"} NR>=2{print $1, $2, $2+1}' CHR03locus1.sorted.ld_out.processed \
    > CHR03locus1.sorted.ld_out.processed.bed
awk \
    -f $(which ens2ucsc.awk) CHR03locus1.sorted.ld_out.processed.bed \
    > CHR03locus1.sorted.ld_out.processed.ucsc.bed
