#!/bin/bash

     mydir=PaintorPipe-small-run
     codedir=PaintorPipe_code
     cd $mydir
     module load devel/java/17.0.6
     module load containers/singularity/3.9.9
     module load bioinfo/Nextflow/24.04.2
     export NXF_SINGULARITY_CACHEDIR=$mydir
     export SINGULARITY_PULLFOLDER=$mydir
     export SINGULARITY_CACHEDIR=$mydir
     export SINGULARITY_TMPDIR=$mydir

     nextflow run $codedir/main.nf \
    -config $codedir/nextflow.config,$codedir/genologin.config \
    --gwasFile $codedir/data/input/CAD_META_extract \
    --annotationsFile $codedir/data/input/annotations.txt \
    --ref_genome hg19 \
    --chromosome_header Chr \
    -profile slurm,singularity \
    -with-trace reports/trace.txt \
    -with-timeline reports/timeline.html \
    -with-report reports/report.html \
    -with-dag reports/flowchart.png \
    -resume > paintorpipe.test.small.out

