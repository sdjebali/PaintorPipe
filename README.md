# PaintorPipe
Pipeline to run the Paintor program and its associated visualization tools on GWAS summary statistics data

# Table of Contents
- [CONDA](#conda)
    - [Install conda](#install-conda)
    - [Create and activate conda environment](#create-and-activate-conda-environment)
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
```bash
name: paintor
channels:
  - defaults
  - bioconda
dependencies:
  - python=3.7.4
  - multiprocess
  - pandas
  - bedtools
```

Once the file is created, the environment is created using the command shown below:
```bash
time conda env create --force --name paintor -f environment.yml
```

To enable the environment, use the activate command :
```bash
conda activate paintor
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
sbatch --mem=8G --cpus-per-task=22 -J PaintorPipe --mail-user=zoe.gerber@inserm.fr --mail-type=END,FAIL -D $PWD --export=ALL -p workq launch_pp.sh

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

Required **folders** and **files** in working directory :
+ bin
    + CalcLD_1KG_VCF.py  
    + CANVIS.py
    + main.py
+ data
    + input
        + dataset
        + panel
        + ld.txt
        + annotations
            + annot.id.file.txt
            + all annot bed files
+ environment.yml
+ main.nf
+ (optional : launch_pp.sh)
