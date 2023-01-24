process RESULTS_statistics {
    publishDir params.outputDir_results, mode: 'copy'

    input:
        path res
        path annotations

    output:
        path '*.txt'

    shell:
    '''
        awk 'NR==1{for(i=1; i<=NF; i++){lid[i]=$i}} NR==2{OFS="\\t"; \\
            print lid[1], 1/(1+exp($1)); for(i=2; i<=NF; i++){print lid[i], 1/(1+exp($1+$i))}}' Enrichment.Values \\
                > annot.probsnpcausal.given.baseline.txt
        
        ls !{res} | grep .annotations | awk -v fileRef=!{annotations} 'BEGIN{while (getline < fileRef > 0) {nl++ ; cat[nl]=$1} }\\
            NR>=2 {n++; for(i=1; i<=NF; i++){n1[i]+=$i}} \\
                END{OFS="\\t"; for(i=1; i<=7; i++){print cat[i], n, n1[i], n1[i]/n*100}}' \\
                    > pcent_snp_in_each_annot.txt

        ls !{res} | grep .results | grep -v LogFile.results | while read f ; do base=${f%.results} ; \\
            awk 'NR>=2' $f | sort -k7,7gr | awk 'BEGIN{OFS="\\t"} {n++; s+=$7; si[n]=s} \\
                END{print "all", n, s; i=1; while(ok50!=1&&i<=n){if(si[i]>=(50*s/100)){ok50=1} i++} \\
                    print "ok50", i-1, (i-1)/n*100; i=1; while(ok80!=1&&i<=n){if(si[i]>=(80*s/100)){ok80=1} i++} \\
                        print "ok80", i-1, (i-1)/n*100; i=1; while(ok95!=1&&i<=n){if(si[i]>=(95*s/100)){ok95=1} i++} \\
                            print "ok95", i-1, (i-1)/n*100}' \\
                                > $base.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt ; done
        
        ls !{res} | grep .results | grep -v LogFile.results | while read f ;\\
                do awk 'BEGIN{OFS="\\t"} NR>=2{print $1":"$2, $7}' $f ; \\
                    done | awk 'BEGIN{OFS="\\t"; print "snp", "ppr"} {print}' \\
                        > snp.ppr.txt

    '''
}


process RESULTS_plot {
    publishDir params.outputDir_plot, mode: 'copy'

    input :
        path res

    output:
        path '*.png'

    shell:
    '''
        input_file=`ls !{res} | grep snp.ppr.txt`
        plot.r -i $input_file -o !{params.outputDir_plot}
    '''

}
