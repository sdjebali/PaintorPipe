
process OVERLAPPINGANNOTATIONS_bedfiles {
    publishDir params.outputDir_bed, mode: 'copy'

    input:
        path ldprocessed

    when:
    ldprocessed.matches("*.ld_out.processed")

    output:
        path '*.bed'

    shell:
    '''
    awk \\
        'BEGIN{OFS="\\t"} NR>=2{print $1, $2, $2+1}' !{ldprocessed} \\
        > !{ldprocessed}.bed
    awk \\
        -f $(which ens2ucsc.awk) !{ldprocessed}.bed \\
        > !{ldprocessed}.ucsc.bed
    '''

}


process OVERLAPPINGANNOTATIONS_overlapping {
    publishDir params.outputDir_overlapping, mode: 'copy'
    
    input:
        path bedfiles
        val annotations

    output:
        path '*.txt'

    shell:
    '''
        base=`basename !{bedfiles}`
        cat !{annotations} | while read annid annfile
        do
        intersectBed \\
            -a !{bedfiles} -b $annfile -wao | awk \\
                 'BEGIN{OFS="\\t"} {seen[$1,$2]++; \\
                 if(seen[$1,$2]==1){i++; pos[i]=$1":"$2} if($NF==1){ok[i]=1}} \\
                 END{for(k=1; k<=i; k++){split(pos[k],a,":");\\
                print a[1], a[2], (ok[k]==1 ? 1 : 0)}}' \\
                > $base.coord.over.$annid.tsv
        done
        s1=`cat !{annotations} | awk '{s=(s)($1)(" ")} END{print s}'`
        s2=`cat !{annotations} | while read annid annfile; \\
            do echo $base.coord.over.$annid.tsv ; done | awk '{s=(s)($1)(" ")} END{print s}'`
        echo $s2 | xargs paste  | awk \\
            -v s1="$s1" 'BEGIN{OFS="\\t"; \\
            print s1} {s=""; for(i=3; i<=(NF-3); i+=3){s=(s)($i)(" ")} print (s)($NF)}' \\
            > $base.coord.over.allannots.txt
        check_simple.sh $base.coord.over.allannots.txt
    '''

}

