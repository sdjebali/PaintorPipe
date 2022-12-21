#!/bin/sh

#module load system/Miniconda3-4.4.10
#conda activate paintor

module load bioinfo/Nextflow-v21.10.6
nextflow run main.nf --gwasFile 'data/input/CAD_META_small' --outputDir_locus 'data/output_locus2' -dsl2 -with-conda ~/.conda/envs/paintor/