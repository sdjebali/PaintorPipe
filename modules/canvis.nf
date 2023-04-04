
process CANVIS_run {
    publishDir params.outputDir_canvis, mode: 'copy'

    input:
        tuple path(res), path(ld), path(allannots)
        val zheader_header

    output:
        path '*fig.svg'


    script:
    """
        CANVIS.py \\
            --locus ${res} \\
            -z ${zheader_header} \\
            -r ${ld} \\
            -a ${allannots} \\
            -t 90 \\
            -o ${res}_fig \\
            --large_ld n \\
            > ${res}.out \\
            2> ${res}.err
    """
}
