#!/bin/sh

module load bioinfo/Nextflow-v21.10.6
module load compiler/gcc-9.3.0
module load bioinfo/PAINTOR_V3.0
export PATH=/work/project/fragencode/tools/multi/Scripts/:$PATH

nextflow run main.nf \
    -c nextflow.config \
    --gwasFile 'data/input/T2D_small.txt' \
    --outputDir_locus 'data/output_locus' \
    -resume \
    -dsl2 \
    -with-conda ~/.conda/envs/paintor/
