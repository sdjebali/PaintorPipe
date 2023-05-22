process ANNOTATIONS_bedfiles {
    '''
    This process takes one input parameter, ldprocessed, which should be the path to a file with a 
    suffix of .processed. The process outputs one or more BED files with the suffix .bed, 
    and these files are written to the directory specified by the outputDir_bed parameter.
    The process first checks whether the input file matches the pattern *.processed using the when 
    directive. If the input file does not match this pattern, the process is skipped.
    If the input file matches the pattern, the process uses awk to convert the LD-processed file into BED 
    format. The input file is assumed to have a header row, and the output BED file has three columns: 
    chromosome, start position, and end position (which is the start position plus one).
    The output BED file is then converted to UCSC format using the ens2ucsc.awk script, 
    which should be located in the user's PATH.
    The final output is one or more BED files with the same base name as the input file, but with a suffix of .bed. 
    These files are written to the directory specified by the outputDir_bed parameter using the publishDir directive.
    '''

    publishDir params.outputDir_bed, mode: 'copy'

    input:
        path ldprocessed

    when:
        ldprocessed.matches("*.processed.filtered")

    output:
        path '*.bed'

    shell:
    '''
        awk 'BEGIN{OFS="\\t"} NR>=2{print $1, $2, $2+1}' !{ldprocessed} | \\
            awk -f $(which ens2ucsc.awk) \\
                > !{ldprocessed}.ucsc.bed
    '''
}


process ANNOTATIONS_mergeannotations {
    '''
    This process takes two input parameters, bedfiles and annotations. 
    bedfiles should be a path to one or more BED files, and annotations should be a path to a file containing a list of 
    annotation IDs and their corresponding BED files.
    The process outputs one or more TSV files with a suffix of .txt, and these files are written to the directory specified 
    by the outputDir_annotations parameter using the publishDir directive.
    The process performs the following steps:
    -Extracts the base name of the input bedfiles using basename.
    -For each annotation listed in annotations, uses intersectBed to find the overlapping regions between the BED files 
    and the annotation BED file. The -wao option outputs the original bedfiles entry for each overlap. 
    awk is then used to count the number of times each position is seen, and to output a binary value indicating 
    whether the position was in an overlap with the annotation or not. The output is written to a TSV file with the 
    format $base.coord.over.$annid.tsv.
    -Concatenates the names of all annotations and the names of all the TSV files produced in step 2 into two strings, s1 and s2.
    -Uses xargs paste and awk to join the TSV files into a single TSV file with columns for each annotation and rows for 
    each position in bedfiles. The final output is written to a TSV file with the name $base.coord.over.allannots.txt.
    '''

    publishDir params.outputDir_annotations, mode: 'copy'
    
    input:
        path bedfiles
        path annotations

    output:
        path '*.txt'

    shell:
    '''
        base=`basename !{bedfiles}`
        cat !{annotations} | while read annid annfile
        do
        intersectBed \\
            -a !{bedfiles} -b $annfile -wao | awk 'BEGIN{OFS="\\t"} {seen[$1,$2]++; \\
                if(seen[$1,$2]==1){i++; pos[i]=$1":"$2} if($NF==1){ok[i]=1}} END{for(k=1; k<=i; k++){split(pos[k],a,":");\\
                    print a[1], a[2], (ok[k]==1 ? 1 : 0)}}' \\
                        > $base.coord.over.$annid.tsv
        done

        s1=`cat !{annotations} | awk '{s=(s)($1)(" ")} END{print s}'`
        s2=`cat !{annotations} | while read annid annfile; do echo $base.coord.over.$annid.tsv; done | awk '{s=(s)($1)(" ")} END{print s}'` 
         
        echo $s2 | xargs paste  | awk -v s1="$s1" 'BEGIN{OFS="\\t"; \\
            print s1} {s=""; for(i=3; i<=(NF-3); i+=3){s=(s)($i)(" ")} print (s)($NF)}' \\
                > $base.coord.over.allannots.txt
    '''

}