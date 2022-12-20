// PROCESS

process PREPPAINTOR_splitlocus {
    cpus 22
    memory 60.GB

    publishDir '.', mode: 'copy'

    input:
    path params.inputFile

    output:
    path params.outputDir

    script:
    """
    mkdir -p data
    mkdir -p ${params.outputDir}
    main.py \\
    -d ${params.inputFile}  \\
    --od ${params.outputDir}
    """
}
