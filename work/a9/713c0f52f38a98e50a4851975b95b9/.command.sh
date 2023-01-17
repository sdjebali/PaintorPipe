#!/bin/bash -ue
chr=`awk 'NR==2{print $1}' CHR16locus1.sorted`
ldfile=`awk -v chr=$chr '$1==chr{print $2}' /work/project/regenet/workspace/zgerber/Nextflow/data/input/ld.txt`
echo $ldfile 

CalcLD_1KG_VCF.py \
--locus CHR16locus1.sorted \
--reference $ldfile \
--map_file /work/project/regenet/workspace/zgerber/Nextflow/data/input/integrated_call_samples_v3.20130502.ALL.panel \
--effect_allele Allele1 \
--alt_allele Allele2 \
--population EUR \
--Zhead Zscore \
--out_name CHR16locus1.sorted.ld_out \
--position BP > CalcLD_1KG_VCF.CHR16locus1.sorted.out 2> CalcLD_1KG_VCF.CHR16locus1.sorted.err
