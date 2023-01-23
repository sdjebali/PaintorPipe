process VISUALISATION_canvis {
    publishDir params.outputDir_visualisation, mode: 'copy'

    input:
        path res

    output:
        path '*.canvis*'


    shell:
    '''
        ls !{res} | grep .results | grep -v LogFile.results | while read f ; do base=`${f%.result}` \\
        awk 'NR==1{$2="pos"; print} NR>=2{print}' \\
            > $base.results.for.canvis

        Canvis.py \\
            --locus $base.results.for.canvis \\
            -z Zscore \\
            -r ../2_LD_calculation/$base.ld_out.ld \\
            -a ../3_overlapping_annotations/$base.ld_out.processed.ucsc.coord.over.allannots.txt \\
            -t 90 \\
            -o fig_final \\
            --large_ld y > $base.canvis.out 2> $base.canvis.er

    '''
}
