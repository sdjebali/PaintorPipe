#!/bin/bash -ue
base=`basename CHR03locus1.sorted.ld_out.processed.ucsc.bed`
cat /work/project/regenet/workspace/zgerber/Nextflow/data/input/annotations/annot.id.file.txt | while read annid annfile
do
intersectBed \
    -a CHR03locus1.sorted.ld_out.processed.ucsc.bed -b $annfile -wao | awk \
         'BEGIN{OFS="\t"} {seen[$1,$2]++; \
         if(seen[$1,$2]==1){i++; pos[i]=$1":"$2} if($NF==1){ok[i]=1}} \
         END{for(k=1; k<=i; k++){split(pos[k],a,":");\
        print a[1], a[2], (ok[k]==1 ? 1 : 0)}}' \
        > $base.coord.over.$annid.tsv
done
s1=`cat /work/project/regenet/workspace/zgerber/Nextflow/data/input/annotations/annot.id.file.txt | awk '{s=(s)($1)(" ")} END{print s}'`
s2=`cat /work/project/regenet/workspace/zgerber/Nextflow/data/input/annotations/annot.id.file.txt | while read annid annfile; \
    do echo $base.coord.over.$annid.tsv ; done | awk '{s=(s)($1)(" ")} END{print s}'`
echo $s2 | xargs paste  | awk \
    -v s1="$s1" 'BEGIN{OFS="\t"; \
    print s1} {s=""; for(i=3; i<=(NF-3); i+=3){s=(s)($i)(" ")} print (s)($NF)}' \
    > $base.coord.over.allannots.txt
check_simple.sh $base.coord.over.allannots.txt
