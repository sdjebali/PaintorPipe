
process PAINTOR_run {
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
            str=`echo $ld | awk '{split($1,a,"."); if($1~/ld_out.ld/) {print a[1]".ld"} else {print a[1]}}'` ;\\
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
