
process PAINTOR_run {
    publishDir params.outputDir_paintor, mode: 'copy'

    input:
        path ldfiles
        path allannots
        path annotationsfile

    output:
        path '*.{results,Values,BayesFactor}'

    shell:
    '''
        ls !{allannots} | while read annfile; do echo ${annfile%.sorted.*} ; done | sort | uniq > filename.files 
        
        ls !{allannots} | while read annfile; do str=`echo $annfile | awk '{split($1,a,"."); print a[1]".annotations"}'` ; mv $annfile $str ; done
        ls !{ldfiles} | while read ld ; do \\
            str=`echo $ld | awk '{split($1,a,"."); if($1~/ld_out.ld/) {print a[1]".ld"} else {print a[1]}}'` ;\\
                mv $ld $str ; 
        done
        
        allannotations=$(awk '{print $1}' !{annotationsfile} | tr '\\n' ' ' )   

        PAINTOR \\
            -input filename.files \\
            -in . \\
            -out . \\
            -Zhead Zscore \\
            -LDname ld \\
            -mcmc  \\
            -annotations $allannotations \\
            > PAINTOR.out \\
            2> PAINTOR.err
    '''
}


