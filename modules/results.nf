process RESULTS_statistics {
    '''
    This process generates various summary statistics and output files based on the results of some analysis.
    The inputs to this process include a path to res, which likely contains the results of the analysis, 
    as well as a path to allannots and various other parameters. 
    The outputs include several text files with names ending in .txt, .tsv, or .canvis.

    The script first generates a text file annot.probsnpcausal.given.baseline.txt that contains the annotation 
    names and their corresponding posterior probabilities using the awk command. 
    Then, it creates a file pcent_snp_in_each_annot.txt that contains the percentage of SNPs in each annotation 
    using the awk, ls, and paste commands.
    The script then generates a file all.loci.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt that contains 
    the number and percentage of variants achieving 50%, 80%, and 95% of the total posterior probability mass 
    using the awk, ls, sort, and grep commands.
    The script also creates individual files for each result file that contains the variants that achieve 
    95% posterior probability mass (base.credibleset.95pcent.tsv) and a file that summarizes the locus, variant, 
    and percentage of variants that achieve 95% posterior probability mass (locus.variant.achieving.95pcent.sumppri.nb.pcent.txt).
    The script then uses a script called stats.sh to generate a file locus.variant.achieving.95pcent.sumppri.stats.txt 
    that contains the mean, standard deviation, minimum, and maximum of the posterior probabilities of the variants that 
    achieve 95% posterior probability mass.
    Finally, the script generates a file snp.ppr.txt that contains the SNP IDs and their corresponding posterior 
    probabilities for each result file and creates a file base.for.canvis for each result file that adds a "pos" 
    column to the beginning of the file, which will be used for CANVIS's loci visualisation.
    '''

    publishDir params.outputDir_results, mode: 'copy'

    input:
        path res
        path allannots
        val annotations
        val chromosome_header

    output:
        path '*.{txt,tsv,canvis}'

    shell:
    '''
        awk 'NR==1{for(i=1; i<=NF; i++){lid[i]=$i}} NR==2{OFS="\\t"; \\
            print lid[1], 1/(1+exp($1)); for(i=2; i<=NF; i++){print lid[i], 1/(1+exp($1+$i))}}' Enrichment.Values \\
                > annot.probsnpcausal.given.baseline.txt
        
        awk '{print $1}' !{annotations} > annotnames
        ls !{allannots} | while read f; do awk 'NR>=2' $f ; done | \\
            awk '{for(i=1; i<=NF; i++) s[i]+=$i} END {for(i=1; i<=NF; i++) printf("%.2f%%\\n",s[i]/NR*100)}'\\
                > tmp
        paste annotnames tmp > pcent_snp_in_each_annot.txt

        cat CHR* | awk '$1!="$chromosome_header"' | sort -k10,10gr | awk 'BEGIN{OFS="\\t"} {n++; s+=$NF; si[n]=s} \\
            END{print "all", n, s; i=1; \\
                while(ok50!=1&&i<=n){if(si[i]>=(50*s/100)){ok50=1} i++} print "ok50", i-1, (i-1)/n*100; i=1; \\
                while(ok80!=1&&i<=n){if(si[i]>=(80*s/100)){ok80=1} i++} print "ok80", i-1, (i-1)/n*100; i=1; \\
                while(ok95!=1&&i<=n){if(si[i]>=(95*s/100)){ok95=1} i++} print "ok95", i-1, (i-1)/n*100}' \\
                    > all.loci.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt 

        ls !{res} | grep .results | grep -v LogFile.results | while read f ; do base=${f%.results} ; \\
            awk 'NR>=2' $f | sort -k10,10gr | awk -v base=$base 'BEGIN{OFS="\\t"} {n++; s+=$NF; si[n]=s; snp[n]=$0} \\
                END{print "all", n, s; i=1; 
                    while(ok50!=1&&i<=n){if(si[i]>=(50*s/100)){ok50=1} i++} print "ok50", i-1, (i-1)/n*100; i=1; \\
                    while(ok80!=1&&i<=n){if(si[i]>=(80*s/100)){ok80=1} i++} print "ok80", i-1, (i-1)/n*100; i=1; \\
                    while(ok95!=1&&i<=n){if(si[i]>=(95*s/100)){ok95=1} print snp[i] > (base".credibleset.95pcent.tsv"); i++} print "ok95", i-1, (i-1)/n*100}' \\
                        > $base.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt ; done

        ls !{res} | grep .results | grep -v LogFile.results | while read f; do base=${f%.results}; \\
            awk -v base=$base '$1=="ok95"{print base"\t"$2"\t"$3}' $base.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt; done \\
                > locus.variant.achieving.95pcent.sumppri.nb.pcent.txt
        
        stats.sh \\
            locus.variant.achieving.95pcent.sumppri.nb.pcent.txt 3 \\
                > locus.variant.achieving.95pcent.sumppri.stats.txt

        ls !{res} | grep .results | grep -v LogFile.results | while read f ;\\
                do awk 'BEGIN{OFS="\\t"} NR>=2{print $1":"$2, $NF}' $f ; \\
                    done | awk 'BEGIN{OFS="\\t"; print "snp", "ppr"} {print}' \\
                        > snp.ppr.txt

        ls !{res} | grep .results | grep -v LogFile.results | \\
            while read f ; do base=${f%.result} ; \\
                awk 'NR==1{$2="pos"; print} NR>=2{print}' $f \\
                    > $base.for.canvis ; done
    '''
}



process RESULTS_posteriorprob {
    '''
    This process that takes in an annotated results file (annoted_res) containing SNP 
    (single-nucleotide polymorphism) data, a number of SNPs to output (nbsnp), and a 
    posterior probability threshold (pp_threshold). It produces three output files: 
    posteriorprob_merged_filtered.txt, all.annotated.SNP.sorted.by.pp.txt, and posteriorprob_merged.txt.

    The script processes the input file by removing the first line  (header) of each file in the directory 
    and concatenating them into a single file. It then filters the SNPs based on a specified posterior 
    probability threshold and sorts them by posterior probability, taking only the top SNPs. 
    Finally, it concatenates the header and filtered SNPs into a final output file and creates a file
    of all SNPs sorted by posterior probability. 
    The output files are written to the directory specified in the params.outputDir_posteriorprob parameter.
    '''

    publishDir params.outputDir_posteriorprob, mode: 'copy'

    input :
        path annoted_res
        val nbsnp
        val pp_threshold

    output:
        path '*.txt'

    shell:
    '''
        ls !{annoted_res} | while read f; do awk 'NR>=2' $f; done | sort -k10,10gr > all.annotated.SNP.sorted.by.pp

        cat !{annoted_res} | head -n1 |  awk 'BEGIN{OFS="\\t"} NR==1 {print}' > header

        ls !{annoted_res} | while read f; \\
            do awk 'BEGIN{OFS="\\t"}  NR>1{print}' $f; done \\
                > posteriorprob_merged
        cat header posteriorprob_merged > posteriorprob_merged.txt

        awk -v threshold=!{pp_threshold} 'BEGIN{OFS="\\t"} NR>1 && $10>threshold {print}' posteriorprob_merged.txt | \\
            sort -k10,10gr | head -n !{nbsnp} \\
                > posteriorprob_merged_filtered

        cat header posteriorprob_merged_filtered > posteriorprob_merged_filtered.txt
        cat header all.annotated.SNP.sorted.by.pp > all.annotated.SNP.sorted.by.pp.txt
    '''
}


process RESULTS_plot {
    '''
    This process generate a plot using R, which will take a single input file res as a parameter. 
    The output of the process is a single PNG file.
    In the shell block of the process, the command plot.r is executed with the -i option and the 
    value of res interpolated into the command with !{res}. The plot.r script is likely a custom 
    R script that generates the plot using the data in the res file. The publishDir directive 
    specifies where the output PNG file should be copied to once it is generated (outputDir_plot).
    '''

    publishDir params.outputDir_plot, mode: 'copy'

    input :
        val res

    output:
        path '*.png'

    shell:
    '''
        plot.r -i !{res}
    '''
}
