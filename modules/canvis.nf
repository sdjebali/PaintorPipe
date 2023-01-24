process CANVIS_run {
    publishDir params.outputDir_canvis, mode: 'copy'

    input:
        path res
        path ld
        path allannots

    output:
        path '*.{canvis*,fig}'


    shell:
    '''
        ls !{res} | grep .results | grep -v LogFile.results | while read f ; do base=`${f%.result}` \\
        awk 'NR==1{$2="pos"; print} NR>=2{print}' \\
            > $base.results.for.canvis

        Canvis.py \\
            --locus $base.results.for.canvis \\
            -z Zscore \\
            -r $base.!{ld} \\
            -a $base.!{allannots} \\
            -t 90 \\
            -o $base_fig \\
            --large_ld y \\
            > $base.canvis.out \\
            2> $base.canvis.er

    '''
}
