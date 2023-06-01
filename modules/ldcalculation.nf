process LDCALCULATION_sortlocus {
    '''
    This process takes as input a tuple consisting of an identifier (id) and a path to a file 
    containing locus information (locus). The output of this process is a file with the same 
    name as the input locus file but with the extension .sorted. The output file contains the 
    same locus information as the input file but sorted by the second column in ascending order.

    The script section of the process uses the awk command to remove the first line of the input 
    file (which contains a header) and then pipes the remaining lines to the sort command, which 
    sorts the lines based on the second column (-k2,2) in ascending order (-n). The output of sort 
    is then redirected to a temporary file (tmp). Next, the header line is extracted from the input 
    file and stored in a file called header. Finally, the cat command is used to concatenate the 
    header file with the tmp file, and the output is redirected to a file with the same name as the 
    input file but with the extension .sorted.
    '''

    publishDir params.outputDir_sorted_locus, mode: 'copy'

    input:
        tuple val(id), path(locus)

    output:
        path '*.sorted'

    script:
    """
        awk 'NR>=2' $locus | sort -k2,2n > tmp 
        head -1 $locus > header
        cat header tmp > ${locus}.sorted
    """
}

process LDCALCULATION_getVCFandMAPfilesfrom1000GP {
    '''
    This process downloads VCF files and MAP files from the 1000 Genomes Project based 
    on the reference genome specified in the input (hg19 or hg38), and creates a text 
    file (ldFile.txt) containing a list of the downloaded files with their corresponding 
    chromosome number. The wget command is used to download the files, and the downloaded 
    files are processed to obtain the chromosome number and file path information, 
    which are then written to the ld file using the echo command. The wait command is 
    used to wait for all the download processes to finish before proceeding with the 
    sorting of the ld file. Finally, the ld file is sorted using the sort command with 
    the -V option, which sorts the file based on version numbers. 
    The resulting ldFile.txt is then used in subsequent processes.
    '''

    publishDir params.outputDir_VCFandMAPfrom1000G, mode: 'copy'

    input:
        val ref_genome

    output:
        path '*.txt'

    shell:
    '''
        touch ld

        wget https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/integrated_call_samples_v3.20130502.ALL.panel 
        mv integrated_call_samples_v3.20130502.ALL.panel mapFile.txt
        
        if [ "!{ref_genome}" == "hg19" ]; then
            for chr in {1..22} 
            do
                wget -O ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz   \\
                -P 22 https://hgdownload.cse.ucsc.edu/gbdb/hg19/1000Genomes/phase3/ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz  \\
                && echo "$chr\t$(readlink -f ALL.chr${chr}.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz)" >> ld &
            done
            wait


        elif [ "!{ref_genome}" == "hg38" ]; then
            for chr in {1..22} 
            do
                wget -O ALL.chr${chr}.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz   \\
                -P 22 https://hgdownload.cse.ucsc.edu/gbdb/hg38/1000Genomes/ALL.chr${chr}.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz  \\
                && echo "$chr\t$(readlink -f ALL.chr${chr}.shapeit2_integrated_snvindels_v2a_27022019.GRCh38.phased.vcf.gz)" >> ld &
            done
            wait

        fi

        sort -V -k1,1 ld > ldFile.txt
    '''
}


process LDCALCULATION_calculation {
    '''
    This process perform the actual calculation of linkage disequilibrium (LD) between SNPs 
    using the CalcLD_1KG_VCF.py script.
    '''

    publishDir params.outputDir_ld, mode: 'copy'

    input:
        path sortedlocus
        path ldFile
        path mapFile
        val population
        val effectallele_header
        val altallele_header 
        val zheader_header
        val position_header

    output:
        path "*{.ld_out.ld.filtered,ld_out.processed.filtered}"


    shell:
    '''
        chr=`awk 'NR==2{print $1}' !{sortedlocus}`
        ldfile=`awk -v chr=$chr '$1==chr{print $2}' !{ldFile}`

        CalcLD_1KG_VCF.py \\
        --locus !{sortedlocus} \\
        --reference $ldfile \\
        --map_file !{mapFile} \\
        --effect_allele !{effectallele_header} \\
        --alt_allele !{altallele_header} \\
        --population !{population} \\
        --Zhead !{zheader_header} \\
        --out_name !{sortedlocus}.ld_out \\
        --position !{position_header} \\
        > CalcLD_1KG_VCF.!{sortedlocus}.out \\
        2> CalcLD_1KG_VCF.!{sortedlocus}.err

        awk '{if(($1":"$2)!=prevkey){print $0}else{print NR > "redundrows.txt" } prevkey=$1":"$2}' !{sortedlocus}.ld_out.processed > !{sortedlocus}.tmp

        awk -v fileRef=redundrows.txt 'BEGIN{while (getline < fileRef >0){ko[$1-1]=1}} \\
            ko[NR]!=1{s=""; for(i=1; i<NF; i++){if(ko[i]!=1){s=(s)($i)(" ")}} if(ko[i]!=1){print (s)($i)}}' !{sortedlocus}.ld_out.ld  \\
                > !{sortedlocus}.tmp2
        
        mv !{sortedlocus}.tmp !{sortedlocus}.ld_out.processed.filtered
        mv !{sortedlocus}.tmp2 !{sortedlocus}.ld_out.ld.filtered
    '''
}
