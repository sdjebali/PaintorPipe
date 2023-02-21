# PaintorPipe
Pipeline to run the Paintor program and its associated visualization tools on GWAS summary statistics data

# Table of Contents
- [RELEASES](#releases)
- [SINGULARITY](#singlularity)
    - [Install Singularity](#install-singularity)
    - [Write recipe file](#write-recipe-file)
    - [Build Singularity image](#build-singularity-image)
    - [Pull the pre-built container](#pull-the-pre-built-container)
- [NEXFLOW](#nextflow)
    - [Install Nextflow](#install-nextflow)
    - [Run the pipeline using Nextflow](#run-the-pipeline-using-nextflow)
    - [Pipeline parameters](#pipeline-parameters)
- [Example on a small dataset](#example-on-a-small-dataset)
    - [Inputs and required files](#inputs-and-required-files)


# Releases

## PaintorPipe_V0.1
All the steps until Canvis.
But Canvis is not parallelised and locus IDs are not taken into account in the channels.

## PaintorPipe_V0.2
Canvis parallelised with combined channels.
Locus IDs are taken into account in the channels.

## PaintorPipe_V0.3
The number of SNP with the best posterior probability can be choosen.
The `main.py` script was modified to correct the overlapping loci issue.
Added parameters to the `main.nf` script.


# SINGULARITY
## Install Singularity
Install [go](#https://go.dev/doc/install) and [SingularityCE](#https://github.com/sylabs/singularity/releases)

## Write recipe file 
Write the `Singularity` recipe file :
```bash
Bootstrap: library
From: ubuntu:20.04

%environment
    export LC_ALL=C
    export LANG=C.UTF-8

%post
    ln -fns /usr/share/zoneinfo/Europe/Paris /etc/localtime
    echo Europe/Paris > /etc/timezone
    apt-get update
    apt-get install -y python3 python3-pip curl default-jre tzdata git bedtools gcc \
    vcftools tabix bcftools r-base
    pip3 install --upgrade pip
    pip3 install multiprocess==0.70.14 pandas matplotlib seaborn scipy \
    svgutils numpy==1.23
    curl -s https://get.nextflow.io | bash
    mv nextflow /usr/local/bin/
    dpkg-reconfigure --frontend noninteractive tzdata
    
    # Install R packages
    R -e "install.packages(c('optparse', 'ggplot2'), repos='https://cran.rstudio.com/')"

    # Sarah's scripts
    git clone --branch v0.8 --depth 1 https://github.com/sdjebali/Scripts.git /usr/local/src/Scripts
    ln -s /usr/local/src/Scripts/* /usr/local/bin

    # Install PAINTOR 
    git clone --depth 1 https://github.com/gkichaev/PAINTOR_V3.0.git /usr/local/src/PAINTOR
    cd /usr/local/src/PAINTOR
    bash install.sh
    ln -s /usr/local/src/PAINTOR/PAINTOR /usr/local/bin/PAINTOR
    printf "#!/usr/bin/env python3\n\n" > header
    cat header /usr/local/src/PAINTOR/CANVIS/CANVIS.py | sed 's/.as_matrix()/.values/g' | sed 's/np.bool/bool/g' | sed 's/scale=/scale_x=/g' > /usr/local/bin/CANVIS.py
    chmod 775 /usr/local/bin/CANVIS.py
    cat header /usr/local/src/PAINTOR/PAINTOR_Utilities/CalcLD_1KG_VCF.py > /usr/local/bin/CalcLD_1KG_VCF.py
    chmod 775 /usr/local/bin/CalcLD_1KG_VCF.py

%runscript
    exec "$@"
```

## Build Singularity image
Then build (you must be root) :

```bash
sudo singularity build container.sif Singularity
```

## Pull the pre-built container
In case you are not root, you can also pull the image we built for the PaintorPipe from our repository on [Sylabs cloud](#https://cloud.sylabs.io/) using the command bellow :
```bash
singularity pull -U library://zgerber/paintorpipe/mainimage:0.1
```

# NEXTFLOW
## Install Nextflow
Follow the steps in [Nextflow documentation](#https://www.nextflow.io/index.html#GetStarted).

## Run the pipeline using Nextflow
After building the singularity image, you can run the pipeline locally or on the cluster.

Local :
```bash
./nextflow main.nf -dsl2 
```

Genotoul :
```bash
sbatch --mem=8G --cpus-per-task=1 -J PaintorPipe --mail-user=zoe.gerber@inserm.fr --mail-type=END,FAIL -D $PWD --export=ALL -p workq launch_pp.sh
```

With the `launch_pp.sh` looking like :
```bash
#!/bin/sh

module load bioinfo/Nextflow-v21.10.6
module load system/singularity-3.7.3

nextflow run main.nf \
    -c nextflow.config,genologin.config \
    --gwasFile 'data/input/CAD_META_small_12' \
    --outputDir_locus 'data/output_locus' \
    --snp '30' \
    -dsl2 \
    -profile slurm,singularity \
    -with-trace 'reports/trace.txt' \
    -with-timeline 'reports/timeline.html' \
    -with-report 'reports/report.html' \
    -resume 
```

## Pipeline parameters
```
--gwasFile CAD_META
--mapFile integrated_call_samples_v3.20130502.ALL.panel
--ldFile = ld.txt
--annotations annotations.txt
--population EUR
--pvalue_header Pvalue
--stderr_header StdErr
--effect_header Effect
--chromosome_headerCHR
--effectallele_header Allele1
--altallele_header Allele2
--position_header BP
--zheader_header Zscore
--kb 500
--pvalue_treshold 5e-08
--.snp 20
--outputDir_locus output_locus
--outputDir_sorted_locus output_sorted_locus
--outputDir_ld output_ld
--outputDir_bed output_bed
--outputDir_overlapping output_overlapping
--outputDir_paintor output_paintor
--outputDir_results output_results
--outputDir_posteriorprob output_posteriorprob
--outputDir_plot output_plot
--outputDir_canvis output_canvis
```

# Example on a small dataset
## Inputs and required files
The GWAS file must contains required columns : 
- Allele1
- Allele2
- Effect 
- StdErr
- CHR
- BP 
```
MarkerName	Allele1	Allele2	Freq1	FreqSE	MinFreq	MaxFreq	Effect	StdErr	Pvalue	Direction	HetISq	HetChiSq	HetDf	HetPVal	oldID	CHR	BP
2:177844332_C_T	t	c	0.4732	0.0067	0.4639	0.478	9e-04	0.0058	0.8833	+-	60.4	2.528	1	0.1118	rs1527267	2	177844332
2:231310929_G_T	t	g	0.827	7e-04	0.826	0.8276	6e-04	0.0075	0.9354	+-	12.6	1.145	1	0.2847	rs11694428	2	231310929
1:209658862_G_T	t	g	0.119	0.0049	0.115	0.1249	0.0051	0.0086	0.554	+-	53.5	2.152	1	0.1423	rs12074827	1	209658862
2:59865604_A_C	a	c	0.5555	0.0094	0.5427	0.5625	0.0089	0.0057	0.119	++	0	0.394	1	0.5302	rs11887710	2	59865604
2:113689747_A_G	a	g	0.434	0.0032	0.4298	0.4364	0.0128	0.0057	0.02484	++	0	0.797	
```
This is important that the column names are correctly written, the same way that above. If you have supplementary columns like in the exampe above, you can keep them, the pipeline is going to ignore them.

If you don't want to change the required column names, you have to indicate the alternative names with the header arguments when launching Nextflow command. Make sure the columns are separated by tabulations.

To compute reference LD, you have to download the latest release of the [1000 Genomes Project (Phase 3)](#http://hgdownload.cse.ucsc.edu/gbdb/hg19/1000Genomes/phase3/) in VCF format and the map file that contains sample and population ID's. This can takes a long time.
```bash
wget -r --no-parent -R '.vcf.gz.tbi' ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/
```

Then write the `ld.txt` file pointing to all VCF files on your computer:
```bash
for i in $(seq 1 22); do printf $i"\t"path/to/VCF/ALL.chr$i.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz"\n"; done > ld.txt
``` 
``` 
1   path/to/vcf/ALL.chr1.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz
...
22	path/to/vcf/ALL.chr22.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz
```

Concerning the annotation library, you can use the annotations given in the [Paintor github wiki](#https://github.com/gkichaev/PAINTOR_V3.0/wiki/2b.-Overlapping-annotations) or directely following this [link](#https://ucla.box.com/s/x47apvgv51au1rlmuat8m4zdjhcniv2d) (Warning: This is a large 6.7 GB file).

Once the annotation files are downloaded, you can write the `annotations.txt` file pointing to all annotation bed files (use tabulation) looking like:
```
genc.exon   path/to/exons.proj.bed
genc.intron path/to/introns.proj.bed
```

Required folders and files in working directory :

```bash
.
|-- bin
|   |-- main_V2.py
|   `-- plot.r
|-- data
|   |-- input
|   |   |-- Gwas_file
|   |   |-- annot.id.file.txt
|   |   |-- Map_file.panel
|   |   `-- ld.txt
|-- modules
|   |-- canvis.nf
|   |-- ldcalculation.nf
|   |-- overlappingannotations.nf
|   |-- paintor.nf
|   |-- preppaintor.nf
|   `-- results.nf
|-- launch_pp.sh (optional)
|-- main.nf
|-- nextflow.config
|-- genologin.config
|-- README.md
|-- container.sif
`-- reports
```
