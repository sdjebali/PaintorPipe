
process OVERLAPPINGANNOTATIONS_bedfiles {
    cpus 1
    memory 8.GB

    publishDir params.outputDir_bed, mode: 'copy'

    input:
        path ldprocessed

    when:
    //ldprocessed.name = "*.ld_out.processed"
    ldprocessed.matches("*.ld_out.processed")

    output:
        path '*.bed'

    shell:
    '''
    awk 'BEGIN{OFS="\\t"} NR>=2{print $1, $2, $2+1}' !{ldprocessed} > !{ldprocessed}.bed
    awk -f $(which ens2ucsc.awk) !{ldprocessed}.bed > !{ldprocessed}.ucsc.bed
    '''

}


process OVERLAPPINGANNOTATIONS_overlapping {
    cpus 1
    memory 8.GB

    publishDir params.outputDir_overlapping, mode: 'copy'
    
    input:
        path bedfiles
        val annotations

    output:
        path '*.tsv'

    shell:
    '''
        base=`basename !{bedfiles}`
        cat !{annotations} | while read annid annfile
        do
        intersectBed -a !{bedfiles} -b $annfile -wao | awk 'BEGIN{OFS="\\t"} {seen[$1,$2]++; if(seen[$1,$2]==1){i++; pos[i]=$1":"$2} if($NF==1){ok[i]=1}} END{for(k=1; k<=i; k++){split(pos[k],a,":"); print a[1], a[2], (ok[k]==1 ? 1 : 0)}}' > $base.coord.over.$annid.tsv
        check_simple.sh $base.coord.over.$annid.tsv
        done
    '''

}

/*
process OVERLAPPINGANNOTATIONS_merge {
    cpus 1
    memory 8.GB

    input:
    

    output:
    

    script:
    """
    """

}

*/