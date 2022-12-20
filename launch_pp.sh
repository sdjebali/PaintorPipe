#!/bin/sh

#module load system/Miniconda3-4.4.10
#conda activate paintor

module load bioinfo/Nextflow-v21.10.6
nextflow run main.nf --inputFile 'data/CAD_META_small' --outputDir 'data/output' -dsl2 -with-conda ~/.conda/envs/paintor/