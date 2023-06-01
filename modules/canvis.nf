process CANVIS_run {
    '''
    This process runs the CANVIS tool to generate a visualization of a genomic locus, 
    including linkage disequilibrium (LD) information. 
    The input parameters include a tuple of paths to the results file, the LD file, 
    and a file containing all annotations; as well as a header for the z-score column. 
    The output is a path to the resulting SVG figure.
    '''

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
