process CANVIS_run {
    publishDir params.outputDir_canvis, mode: 'copy'

    input:
        path res
        path ld
        path allannots

    output:
        path '*fig.svg'


    shell:
    '''
        for i in $(ls !{res} | grep .results.for.canvis);\\
            do j=$(ls !{ld} | grep $(basename $i .results.for.canvis).sorted.ld_out.ld)\\
                k=$(ls !{allannots} | grep $(basename $i .results.for.canvis).sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt) \\
        
            CANVIS.py \\
                --locus $i \\
                -z Zscore \\
                -r $j \\
                -a $k \\
                -t 90 \\
                -o ${i}_fig \\
                --large_ld y \\
                > ${i}.out \\
                2> ${i}.err
            done
  
    '''
}
