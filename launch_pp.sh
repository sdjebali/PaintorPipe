#!/bin/sh

#module load system/Miniconda3-4.4.10
#conda activate paintor

module load bioinfo/Nextflow-v21.10.6

export PATH=/work/project/fragencode/tools/multi/Scripts/:$PATH
nextflow run main.nf --gwasFile 'data/input/CAD_META_small_12' --outputDir_locus 'data/output_locus' -dsl2 -with-conda ~/.conda/envs/paintor/
