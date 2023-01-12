#!/bin/sh

export PATH=/work/project/fragencode/tools/multi/Scripts/:$PATH
nextflow run main.nf --gwasFile 'data/input/CAD_META_small_12_test_test' \\
--outputDir_locus 'data/output_locus' \\
-dsl2 -with-conda ~/.conda/envs/paintor/
