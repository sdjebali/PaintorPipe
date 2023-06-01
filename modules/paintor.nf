process PAINTOR_run {
    '''
    This process runs the PAINTOR software to perform Bayesian fine-mapping analysis. 
    The input parameters include ldfiles which is a path to LD files, allannots which is a path to 
    annotation files, annotationsfile which is a file containing annotation names and IDs, and 
    zheader_header which is the name of the column in the LD file containing the Z-scores.
    The output of this process is a set of files with the suffixes .results, .Values, .BayesFactor, and .out 
    which are written to the directory specified by params.outputDir_paintor.

    The script renames the LD files to have the suffix .ld, and the annotation files to have the suffix .annotations. 
    It then runs the PAINTOR command with the specified input and output files, the Z-score header, the name 
    of the LD files, and the annotations file.
    '''

    publishDir params.outputDir_paintor, mode: 'copy'

    input:
        path ldfiles
        path allannots
        path annotationsfile
        val zheader_header

    output:
        path '*.{results,Values,BayesFactor,out}'

    shell:
    '''
        ls !{allannots} | while read annfile; do echo ${annfile%.sorted.*} ; done | sort | uniq > filename.files 
        
        ls !{allannots} | while read annfile; do str=`echo $annfile | awk '{split($1,a,"."); print a[1]".annotations"}'` ; mv $annfile $str ; done
        ls !{ldfiles} | while read ld ; do \\
            str=`echo $ld | awk '{split($1,a,"."); if($1~/ld_out.ld.filtered/) {print a[1]".ld"} else {print a[1]}}'` ;\\
                mv $ld $str ; 
        done
        
        annotationsid=$(awk '{print $1}' !{annotationsfile} | paste -sd ',' )

        PAINTOR \\
            -input filename.files \\
            -in . \\
            -out . \\
            -Zhead !{zheader_header} \\
            -LDname ld \\
            -mcmc  \\
            -annotations $annotationsid \\
            > PAINTOR.out \\
            2> PAINTOR.err
    '''
}


process PAINTOR_annotatedlocus {
    '''
    This process takes a tuple input containing two paths, locusres and allannots. 
    The locusres file contains the results of the PAINTOR run for a single locus, and allannots is 
    a file containing annotations for all loci. The process outputs an annotated file in text format.

    The process uses the paste command to concatenate the two input files into a single output file 
    with the .annotated suffix. The output file is then published to the directory specified by the 
    outputDir_annotated_locus parameter using the publishDir directive. The output file has a .txt suffix 
    in addition to the .annotated suffix.
    '''

    publishDir params.outputDir_annotated_locus, mode: 'copy'

    input:
        tuple path(locusres), path(allannots)


    output:
        path '*.{annotated,txt}'

    shell:
    '''
        paste !{locusres} !{allannots} > !{locusres}.annotated
    '''
}
