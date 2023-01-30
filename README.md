# PaintorPipe
Pipeline to run the Paintor program and its associated visualization tools on GWAS summary statistics data

# Table of Contents
- [CONDA](#conda)
    - [Install conda](#install-conda)
    - [Create and activate conda environment](#create-and-activate-conda-environment)
- [SINGULARITY](#singlularity)
    - [Install Singularity](#install-singularity)
    - [Write recipe file](#write-recipe-file)
    - [Build Singularity image](#build-singularity-image)
    - [Pull the pre-built container](#pull-the-pre-built-container)
- [NEXFLOW](#nextflow)
    - [Install Nextflow](#install-nextflow)
    - [Run the pipeline using Nextflow](#run-the-pipeline-using-nextflow)
    - [Exemple on a small dataset](#exemple-on-a-small-dataset)

# CONDA
## Install conda
```bash
cd /tmp/
wget  https://repo.anaconda.com/archive/Anaconda3-2022.10-Linux-x86_64.sh
sha256sum anaconda.sh #should display : e7ecbccbc197ebd7e1f211c59df2e37bc6959d081f2235d387e08c9026666acd  anaconda.sh
bash anaconda.sh
source ~/.bashrc
```
## Create and activate conda environment

Write your `environment.yaml` file :
```yml
name: paintor
channels:
  - defaults
  - bioconda
  - conda-forge
dependencies:
  - python=3.7.4
  - multiprocess=0.70.14
  - pandas=1.3.5
  - bedtools=2.30.0
  - gcc=12.2.0
```

Once the file is created, the environment is created using the command shown below:
```bash
module load system/Miniconda3-4.7.10
conda update -n base -c defaults conda
time conda env create --force --name paintor -f environment.yml
```

To enable the environment, use the activate command :
```bash
module load system/Miniconda3-4.7.10
conda activate paintor
```

# SINGULARITY
## Install Singularity

Install [go](#https://go.dev/doc/install) and [SingularityCE](#https://github.com/sylabs/singularity/releases)

## Write recipe file 
Write the `Singularity` recipe file :

```bash
Bootstrap: library
From: ubuntu:20.04

%environment
    export LC_ALL=C.UTF-8
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
    cat header /usr/local/src/PAINTOR/CANVIS/CANVIS.py | sed 's/.as_matrix()/.values/g' > /usr/local/bin/CANVIS.py
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
After activating the conda environment, you can run the pipeline locally or on the cluster.

Local :
```bash
./nextflow main.nf -dsl2 -with-conda ~/bin/anaconda3/envs/paintor/
```

Genotoul :
```bash
sbatch --mem=8G --cpus-per-task=2 -J PaintorPipe --mail-user=zoe.gerber@inserm.fr --mail-type=END,FAIL -D $PWD --export=ALL -p workq launch_pp.sh
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
    -dsl2 \
    -profile slurm,singularity \
    -with-trace -with-timeline timeline.html \
    -with-report report.html \
    -resume 
    
```

## Exemple on a small dataset
```
MarkerName	Allele1	Allele2	Freq1	FreqSE	MinFreq	MaxFreq	Effect	StdErr	Pvalue	Direction	HetISq	HetChiSq	HetDf	HetPVal	oldID	CHR	BP
2:177844332_C_T	t	c	0.4732	0.0067	0.4639	0.478	9e-04	0.0058	0.8833	+-	60.4	2.528	1	0.1118	rs1527267	2	177844332
2:231310929_G_T	t	g	0.827	7e-04	0.826	0.8276	6e-04	0.0075	0.9354	+-	12.6	1.145	1	0.2847	rs11694428	2	231310929
1:209658862_G_T	t	g	0.119	0.0049	0.115	0.1249	0.0051	0.0086	0.554	+-	53.5	2.152	1	0.1423	rs12074827	1	209658862
2:59865604_A_C	a	c	0.5555	0.0094	0.5427	0.5625	0.0089	0.0057	0.119	++	0	0.394	1	0.5302	rs11887710	2	59865604
2:113689747_A_G	a	g	0.434	0.0032	0.4298	0.4364	0.0128	0.0057	0.02484	++	0	0.797	
```

Required folders and `files` in working directory :

+ WorkDir :
    + bin
        + `main.py`
    + data
        + input
            + `Gwas_file`
            + `Map_file.panel`
            + `ld.txt`
            + annotations
                + `annot.id.file.txt`
                + all annot bed files
    + `environment.yml` or `container.sif`
    + `main.nf`
    + (optional : `launch_pp.sh`)

