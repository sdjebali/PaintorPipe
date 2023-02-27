
process RESULTS_statistics {
    publishDir params.outputDir_results, mode: 'copy'

    input:
        path res
        path annotations

    output:
        path '*.{txt,canvis}'

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

        ls !{res} | grep .results | grep -v LogFile.results | \\
            while read f ; do base=${f%.result} ; \\
                awk 'NR==1{$2="pos"; print} NR>=2{print}' $f \\
                    > $base.for.canvis ; done

    '''
}


process RESULTS_posteriorprob {
    publishDir params.outputDir_posteriorprob, mode: 'copy'

    input :
        path res
        val nbsnp
        val pp_threshold

    output:
        path '*.txt'

    shell:
    '''
        head -n1 !{res} | awk 'BEGIN{OFS="\\t"} $1=="CHR" {print}' | head -n1 > header

        ls !{res} | grep .results | grep -v LogFile | while read f; \\
            do awk 'BEGIN{OFS="\\t"} $1!="CHR" {print}' $f; done \\
                > posteriorprob_merged
        cat header posteriorprob_merged > posteriorprob_merged.txt

        awk -v threshold=!{pp_threshold} 'BEGIN{OFS="\t"} NR==1 {print} NR>1 && $9>threshold {print}' posteriorprob_merged.txt | \\
            sort -k9,9gr | head -n !{nbsnp} \\
                > posteriorprob_merged_filtered

        cat header posteriorprob_merged_filtered > posteriorprob_merged_filtered.txt
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
        plot.r -i !{res}
    '''
}
