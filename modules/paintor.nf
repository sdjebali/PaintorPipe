process PAINTOR_run {
    publishDir params.outputDir_paintor, mode: 'copy'

    input:
        path ldfiles
        path allannots

    when:
    allannots.any{ it.endsWith('.ucsc.coord.over.allannots.txt')}
    

    output:
        path '*.results'

    shell:
    '''
        ls !{allannots} | while read annfile; do echo ${annfile%.sorted.ld_out.processed*.bed.coord.over.allannots.txt} ; done | sort | uniq > filename.files 

        ls !{allannots} | while read annfile; do f=`echo sed 's/.ld_out.processed.ucsc.coord.over.allannots.txt/.annotations/'` ; mv "$annfile" "$f" ; done
        ls !{ldfiles} | while read ldfile; do f=`echo $ldfile | sed 's/.sorted.ld_out.ld/.ld/'` ; mv "$ldfile" "$f" ; done 
        ls !{ldfiles} | while read ldprocessedfile; do f=`echo sed 's/.sorted.ld_out.processed//'` ; mv "$ldfile" "$f" ; done 

        PAINTOR \\
            -input filename.files \\
            -in . \\
            -out . \\
            -Zhead Zscore  \\
            -LDname ld  \\
            -mcmc  \\
            -annotations genc.exon,genc.intron,genc.tss500up,genc.tts500dw,elscardiot1  \\
            > PAINTOR.out \\
            2> PAINTOR.err
    
    '''
}