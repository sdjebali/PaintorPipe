#!/bin/sh

module load devel/java/17.0.6
module load containers/singularity/3.9.9
module load bioinfo/Nextflow/23.04.3

cd /home/sdjebali/regencard/workspace/sdjebali/nextflow/PaintorPipe

nextflow run main.nf \
    -config nextflow.config,genologin.config \
    --gwasFile data/input/CAD_META_200K.tsv \
    --annotationsFile data/input/annotations.txt \
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
    -resume > paintorpipe.test.small.out


