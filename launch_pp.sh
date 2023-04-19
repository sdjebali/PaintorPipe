#!/bin/sh

module load bioinfo/Nextflow-v21.10.6
module load system/singularity-3.7.3

nextflow run main.nf \
    -dsl2 \
    -config nextflow.config,genologin.config \
    --gwasFile /work/project/regenet/workspace/zgerber/pipelines/Nextflow/data/input/CAD_META_extract \
    --annotationsFile /work/project/regenet/workspace/zgerber/pipelines/Nextflow/data/input/annotations_encode.txt \
    --ref_genome hg19 \
    --chromosome_header Chr \
    --pvalue_lead 5e-08 \
    --kb 500 \
    --snp 100000 \
    --pp_threshold 0.001 \
    -profile slurm,singularity \
    -with-trace reports/trace.txt \
    -with-timeline reports/timeline.html \
    -with-report reports/report.html \
    -with-dag reports/flowchart.png \
    -resume 
    