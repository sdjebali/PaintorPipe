#!/bin/sh

#module load system/Miniconda3-4.7.10
module load bioinfo/Nextflow-v21.10.6
#module load bioinfo/PAINTOR_V3.0
module load system/singularity-3.7.3
#module load compiler/gcc-9.3.0
#export PATH=/work/project/fragencode/tools/multi/Scripts/:$PATH

nextflow run main.nf \
    -c nextflow.config,genologin.config \
    --gwasFile 'data/input/CAD_META' \
    --chromosome_header 'Chr' \
    --pvalue_treshold '5e-08' \
    --kb '500' \
    --outputDir_locus 'data/output_locus' \
    --snp '100' \
    --pp_threshold '0.001' \
    -dsl2 \
    -profile slurm,singularity \
    -with-trace 'reports/trace.txt' \
    -with-timeline 'reports/timeline.html' \
    -with-report 'reports/report.html' \
    -resume 
    