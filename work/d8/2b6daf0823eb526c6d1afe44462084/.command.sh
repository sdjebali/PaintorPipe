#!/bin/bash -ue
mkdir -p data/output_locus
main.py \
-d T2D_small.txt  \
--separator '	' \
--chromosome 'CHR' \
--od data/output_locus
