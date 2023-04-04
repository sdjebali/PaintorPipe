
process LDCALCULATION_sortlocus {
    publishDir params.outputDir_sorted_locus, mode: 'copy'

    input:
        tuple val(id), path(locus)

    output:
        path '*.sorted'

    script:
    """
        awk 'NR>=2' $locus | sort -k2,2n > tmp 
        head -1 $locus > header
        cat header tmp > ${locus}.sorted
    """
}

process LDCALCULATION_getVCFandMAPfilesfrom1000GP {
    publishDir params.outputDir_VCFandMAPfrom1000G, mode: 'copy'

    input:
        val ref_genome

    output:
        path '*.txt'

    shell:
    '''
        touch ld

        wget https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel 
        mv integrated_call_samples_v3.20130502.ALL.panel mapFile.txt
        
        if [ "!{ref_genome}" == "hg19" ]; then
            for chr in {1..22} 
            do
                wget -O ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz   \\
                -P 22 https://hgdownload.cse.ucsc.edu/gbdb/hg19/1000Genomes/phase3/ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz  \\
                && echo "$chr\t$(readlink -f ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz)" >> ld &
            done
            wait


        elif [ "!{ref_genome}" == "hg38" ]; then
            for chr in {1..22} 
            do
                wget -O ALL.chr${chr}.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz   \\
                -P 22 https://hgdownload.cse.ucsc.edu/gbdb/hg38/1000Genomes/ALL.chr${chr}.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz  \\
                && echo "$chr\t$(readlink -f ALL.chr${chr}.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz)" >> ld &
            done
            wait

        fi

        sort -V -k1,1 ld > ldFile.txt

    '''
}


process LDCALCULATION_calculation {
    publishDir params.outputDir_ld, mode: 'copy'

    input:
        path sortedlocus
        path ldFile
        path mapFile
        val population
        val effectallele_header
        val altallele_header 
        val zheader_header
        val position_header

    output:
        path "${sortedlocus}.ld_out*"


    shell:
    '''
        chr=`awk 'NR==2{print $1}' !{sortedlocus}`
        ldfile=`awk -v chr=$chr '$1==chr{print $2}' !{ldFile}`

        CalcLD_1KG_VCF.py \\
        --locus !{sortedlocus} \\
        --reference $ldfile \\
        --map_file !{mapFile} \\
        --effect_allele !{effectallele_header} \\
        --alt_allele !{altallele_header} \\
        --population !{population} \\
        --Zhead !{zheader_header} \\
        --out_name !{sortedlocus}.ld_out \\
        --position !{position_header} \\
        > CalcLD_1KG_VCF.!{sortedlocus}.out \\
        2> CalcLD_1KG_VCF.!{sortedlocus}.err
    '''
}
