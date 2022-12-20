
process LDCALCULATION_sortlocus {
    cpus 1
    memory 60.GB

    publishDir params.outputDir, pattern: '*.sorted', mode: 'copy'

    input:
    path locus

    output:
    path '*.sorted'

    script:
    """
    awk 'NR>=2' $locus | sort -k2,2n > tmp 
    head -1 $locus > header
    cat header tmp > ${locus}.sorted
    """
}


/*
process LDCALCULATION_calculation {
    cpus 1
    memory 60.GB

    publishDir '.', mode: 'copy'

    input:
    path '${params.outputDir}/*'

    output:
    path params.outputDir

    script:
    """
    python /home/zgerber/regenet/workspace/sdjebali/finemapping/missionM2_2022/paintor/PAINTOR_V3.0/PAINTOR_Utilities/CalcLD_1KG_VCF.py \
     	  --locus /home/zgerber/regenet/workspace/zgerber/paintor/1_split_GWAS_into_loci/data/output/locus_output/CHR01locus8.sorted \
     	  --reference /home/zgerber/regenet/workspace/sdjebali/finemapping/missionM2_2022/1000genomes/release/20130502/ALL.chr1.phase3_shapeit2_mvncall_integrated_v5b.20130502.genotypes.vcf.gz \
     	  --map /home/zgerber/regenet/workspace/sdjebali/finemapping/missionM2_2022/integrated_call_samples_v3.20130502.ALL.panel \
     	  --effect_allele Allele1 \
     	  --alt_allele Allele2 \
     	  --population EUR \
     	  --Zhead Zscore \
     	  --out_name CHR01locus8.ld_out \
     	  --position BP > output/CalcLD_1KG_VCF.CHR01locus8.out 2> error/CalcLD_1KG_VCF.CHR01locus8.err



    """
}
*/