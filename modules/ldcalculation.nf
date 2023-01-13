
process LDCALCULATION_sortlocus {
    cpus 1
    memory 8.GB

    publishDir params.outputDir_sorted_locus, mode: 'copy'

    input:
        path locus

    output:
        path '*.sorted'

    script:
    """
        awk 'NR>=2' $locus | sort -k2,2n > tmp 
        head -1 $locus > header
        cat header tmp > ${locus}.sorted
        rm header tmp
    """
}

process LDCALCULATION_calculation {
    cpus 1
    memory 16.GB

    publishDir params.outputDir_ld, mode: 'copy'

    input:
        path sortedlocus
        val mapFile
        val ldFile
        val population

    output:
        path "${sortedlocus}.ld_out*"


    shell:
    '''
        chr=`awk 'NR==2{print $1}' !{sortedlocus}`
        ldfile=`awk -v chr=$chr '$1==chr{print $2}' !{ldFile}`
        echo $ldfile 

        CalcLD_1KG_VCF.py \\
        --locus !{sortedlocus} \\
        --reference $ldfile \\
        --map_file !{mapFile} \\
        --effect_allele Allele1 \\
        --alt_allele Allele2 \\
        --population !{population} \\
        --Zhead Zscore \\
        --out_name !{sortedlocus}.ld_out \\
        --position BP > CalcLD_1KG_VCF.!{sortedlocus}.out 2> CalcLD_1KG_VCF.!{sortedlocus}.err
    '''
}
