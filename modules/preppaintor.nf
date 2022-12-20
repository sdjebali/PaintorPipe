// PROCESS

process PREPPAINTOR_splitlocus {
    cpus 22
    memory 60.GB

    publishDir '.', mode: 'copy'

    input:
        path params.gwasFile

    output:
        path params.outputDir

    script:
    """
    mkdir -p data
    mkdir -p ${params.outputDir}
    main.py \\
    -d ${params.gwasFile}  \\
    --od ${params.outputDir}
    """
}
