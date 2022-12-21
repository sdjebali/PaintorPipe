// PROCESS

process PREPPAINTOR_splitlocus {
    cpus 22
    memory 60.GB

    publishDir '.', mode: 'copy'

    input:
        path gwasFile

    output:
        path "$params.outputDir_locus/*"

    script:
    """
    mkdir -p ${params.outputDir_locus}
    main.py \\
    -d $gwasFile  \\
    --od ${params.outputDir_locus}
    """
}
