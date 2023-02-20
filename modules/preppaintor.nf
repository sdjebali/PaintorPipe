
process PREPPAINTOR_splitlocus {
    publishDir '.', mode: 'copy'

    input:
        path gwasFile

    output:
        path "$params.outputDir_locus/*"

    script:
    """
        mkdir -p ${params.outputDir_locus}
        main_V2.py \\
        -d $gwasFile  \\
        --separator '\t' \\
        --chromosome 'CHR' \\
        --kb 500 \\
        --pv-threshold 5e-08 \\
        --od ${params.outputDir_locus}
    """
}
