
process PREPPAINTOR_splitlocus {
    publishDir '.', mode: 'copy'

    input:
        path gwasFile
        val pvalue_lead
        val pvalue_nonlead
        val kb
        val pvalue_header
        val stderr_header
        val effect_header
        val chromosome_header
        val effectallele_header
        val altallele_header 
        val position_header
        val zheader_header
        

    output:
        path "$params.outputDir_locus/*"

    script:
    """
        mkdir -p ${params.outputDir_locus}
        main_V2.py \\
        --data $gwasFile  \\
        --separator '\t' \\
        --pvalue-header $pvalue_header \\
        --stderr $stderr_header \\
        --effect  $effect_header \\
        --chromosome $chromosome_header \\
        --effect-allele $effectallele_header \\
        --alt-allele  $altallele_header \\
        --position $position_header \\
        --Zheader $zheader_header \\
        --kb $kb \\
        --pv-lead $pvalue_lead \\
        --pv-nonlead $pvalue_nonlead \\
        --od ${params.outputDir_locus}
    """
}