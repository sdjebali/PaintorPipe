#!/usr/bin/env python3

# This script was developped by Michel Fisun in the statistical genetics lab, Pasteur Paris, 
# under the supervision of Hugues Aschard
# This script was modified and deboged by Sarah Djebali and Zoe Gerber in IRSD, Toulouse


# IMPORTS --------------------------------------------------------------------
from sqlite3 import DatabaseError
import pandas as pd
import numpy as np
import time
from pathlib import Path as path
from optparse import OptionParser
import sys
from multiprocess import Pool
# ----------------------------------------------------------------------------


# FUNCTIONS  -----------------------------------------------------------------
# this function outputs a list of 22 dataframes indexed by the chr id
# in fact the index of the list is a tuple (chrnumber, dataframe including the snps present in this chr)
def ChromosomeSplitter_no_files(bank : str, separator : str, cname : str) -> "list[pd.DataFrame]" :    
    """
    data bank file name -> list[CHR1,CHR2,...,CHR22]
    Splits Data bank into chromosomes contained in a dataframe and stored in a list
    """
    print("Starting GWAS dataset splitter...")
    start_time = time.time()
    chr_list = []  # tuple: (chrosome_number, [chromosome])

    #reading data
    print("\nReading data...")
    data_bank = pd.read_csv(bank,index_col=False, sep=separator)
    print("Data read !\n")

    #temporary pandas DataFrame to store snp data corresponding to current chromosome
    chr = pd.DataFrame(None)

    #building chromosome files
    for i in range(1,22+1):
        print("Building chromosome %s file..." % i)
        chr_list.append((i,data_bank[data_bank[cname] == i]))

    print("Done splitting chromosmes !")
    print("--- done splitting chromosomes in %s seconds ---\n" % (time.time() - start_time))
    print("\nChromosomes generated :")
    print([n for (n,chr) in chr_list])
    print("\n\n")

    return chr_list


def SortPerPValue(chr : tuple, Phead : str) -> pd.DataFrame : 
    """
    Quicksorts (and writes) the SNP's of the i-th chromosome file, in ascending order according to the P-Value
    from better to worst pvalue
    """
    start_time = time.time()
    i,chromosome = chr
    quicksorted = chromosome.sort_values(by=Phead, ascending=True, kind = 'quicksort', ignore_index=True)

    print(f"--- chromosome {i} sorted in %s secondes ---\n" % (time.time() - start_time))

    return quicksorted


def SortPerPosition(l : pd.DataFrame, pos : str) -> pd.DataFrame : 
    """
    sorting one locus which is a dataframe by pos
    """
    start_time = time.time()
    quicksorted = l.sort_values(by=pos, ascending=True, kind = 'quicksort', ignore_index=True)

    print(f"--- locus sorted in %s secondes ---\n" % (time.time() - start_time))

    return quicksorted    


def LocusUnion(l1 : pd.DataFrame, l2 : pd.DataFrame,pos) -> pd.DataFrame :
    """
    returns union of 2 loci
    """
    quicksorted_l1 = l1.sort_values(by=pos, ascending=True, kind = 'quicksort', ignore_index=True)
    quicksorted_l2 = l2.sort_values(by=pos, ascending=True, kind = 'quicksort', ignore_index=True)

    return pd.merge(quicksorted_l1,quicksorted_l2, how="outer")


def isIntersected(l1 : pd.DataFrame, l2 : pd.DataFrame) -> bool :
    """
    returns True if there is a common SNP in l1 and l2, returns False otherwise
    """

    return len(pd.merge(l1, l2, how="inner")) != 0


# this function is the most important of all (contains the intelligence of the whole process)
# it is done for a given chromosome
# chr is a tuple (chrid, dataframe with snps of the chr)
# Phead and pos are the way pvalue and position are called in the header of the gwas file
# outputs a list with as many elements as loci in the chromosome entered
# the output is in fact a list of tuples where
# each tuple 1st element is the chromosome id and tuple second element is the dataframe including the snps of the locus defined 
def LocusList(chr : tuple, Phead : str, pos, kb, Pseuil) -> "list(tuple)":
    """
    returns a list of all locus in given chromosome

    Splits SNP's in the data bank (in one chromosome):
    After SNP's were sorted by SortPerPValue(), takes the first most significative SNP in the list, takes a region of +- kb number (500 by default)
    around the SNP in the non-pv-sorted file (but sorted according to position) and writes them into a file.
    Then, repeats the same process for the next most significative SNP if it is not already in the previous locus
    """
    start_time = time.time()
    locus = pd.DataFrame(None)

    # i is the chr number, chromosome is a dataframe with all the snps of chr i
    i,chromosome = chr
    #print(f"\nStarting splitting chromosome {i} into loci...")
    print(f"\nliste de SNP du chr {i} non triée:\n {chromosome}\n")
    
    # sorted is a tuple (chrid, sorted dataframe of the snps of the chr)
    sorted = SortPerPValue(chr,Phead)

    print(f"liste de SNP du chr {i} triée par pvalue: \n{sorted}")

    locus_nb = 0
    test = True
    liste = []
    
    # len(sorted) is the number of snp in the list, for one chr
    for snp_index in range(len(sorted)):
        test = True
        #print(f"snp index: {snp_index} \n")
        
        # first, we only keep snp that have a significant pvalue
        if sorted.iloc[snp_index][Phead] > float(Pseuil):
            print(f"\nNo more significant SNP pvalues in the chromosome {i}\n")
            break
    
        # the 1st time, line contains the whole line of the best SNP : line = (chrid,snp with best pvalue)
        line = sorted[snp_index:snp_index+1]
        #print(f"\n line : \n{line} \n")
      
        # pos_line extracts from line the position on chrid of the snp with the best pvalue
        pos_line = int(line[pos])
        
        # kb_nb is the number of bases upstream and downstream we want to search around our best SNP
        # kb_range is this computed interval (500kb +/- by default) around the position on chrid of the snp with the best pvalue
        kb_nb = int(kb) * 1000
        kb_range = range(pos_line - kb_nb, pos_line + kb_nb + 1)
        
        # new_locus is a tuple : (chrid , dataframe of snps at 500kb from +/- best pvalue snp)
        # the dataframes are ordered by SNP position
        new_locus : tuple = (i,chromosome.loc[chromosome[pos].isin(kb_range)])

        print(f"new locus :\n {new_locus}")
    
        #first time len(liste) is 0
        if len(liste)==0:
            liste.append(new_locus)
            #count of the locus created
            locus_nb = locus_nb + 1
            print(f"\nCHR{i}locus{locus_nb} created !\n")
            continue
        # after the if we have only one locus in the list (one locus created)
        
        else:
            for new_locus_index in range(len(liste)):
                # _ and ii are the chrid (the same)
                # prev_locus is the locus (list of SNP) we appened is the list of loci
                # nnew_locus is the locus (list of SNP) following in the list
                # new locus is the tuple containing (chrid, nnew_locus)
                ii,prev_locus = liste[new_locus_index]   
                _,nnew_locus = new_locus

                print(f"\nii,prev_locus : {ii}, {prev_locus}")
                print(f"\n_,nnew_locus : {_}, {nnew_locus}")     
        
                if isIntersected(prev_locus, nnew_locus):
                    print("Overlapping loci found !\n")
                    print("Merging the loci...")
                    liste[new_locus_index] = (ii, SortPerPosition(LocusUnion(prev_locus, nnew_locus, pos),pos))
                    print("Done merging the loci !\n")
                    print(f"\nNew locus {new_locus_index} created after merging : {liste[new_locus_index]}\n")
                    print(f"liste of locus at this point : {liste}")
                    test = False
                    break

        # if no intersection (test still true):
        # this is not done at the 1st iteration (see continue after if len(liste)==0)
        if test:
            # REPETITION due to TEST which is true so 2 APPEND per new locus
            # at the fisrt time we have 2 locus in the list
            print("No intersection, appended new locus")
            liste.append(new_locus)  
            locus_nb = locus_nb + 1
            print(f"\nCHR{i}locus{locus_nb} is created !\n")
            print(f"\n\n\n\nWe have {locus_nb} loci in our list : {liste}\n\n\n\n\n\n")

    #checking if no overlaping loci
    new_liste = checkListLocus(liste, pos)

    print("len final : " + str(len(new_liste))+"\n\n")
    print(f"nb locus final : {locus_nb}\n\n")

    print(f"\nliste after LocusList():{new_liste} \n")
    print(f"\nDone splitting chromosome {i} into loci ! ")
    return new_liste


def checkListLocus(liste : "list[tuple]", pos) -> "list(tuple)":
    """
    checking in the list of locus if there is no overlaping loci 
    if there is, merge the loci and delete the second locus
    """
    list_locus_to_remove = []
    new_liste = []
    for locus_index in range(len(liste)): 
        ii,current_locus = liste[locus_index]
        
        for locus_index2 in range(locus_index+1, len(liste)):
            _,test_locus = liste[locus_index2]

            print(f"\nii,current_locus : {ii}, {current_locus}")
            print(f"\n_,test_locus : {_}, {test_locus}") 

            if current_locus.equals(test_locus) == False and isIntersected(current_locus, test_locus):
                print("Overlapping2\n")
                liste[locus_index] = (ii, SortPerPosition(LocusUnion(current_locus, test_locus, pos),pos))
                
                locus_to_remove : tuple = (ii, test_locus)
                list_locus_to_remove.append(locus_to_remove)
                
                print(f"list_locus_to_remove : {list_locus_to_remove}")
               
                #print(f"\nNew locus {locus_index} created after merging 2: {liste[locus_index]}\n")
                print(f"liste of locus at this point2 : {liste}")

            else:
                print("No overlapping\n")

    # remove elements of the list liste which do not match with the elements of the list list_locus_to_remove
    # store the new tuples in a new list
    new_liste = [x for x in liste if not any(y[1].equals(x[1]) for y in list_locus_to_remove)]
   
    return new_liste



def ZscoreAdder(locus : tuple, Zhead : str, Effect : str, StdErr : str) -> pd.DataFrame:
    #beg,chr_nb,zLocus = locus
    chr_nb,zLocus = locus

    zLocus[Zhead] = (zLocus[Effect]/zLocus[StdErr])

    #Drop all columns that ARE NOT : CHR BP ALLELE1 ALLELE2 EFFECT STDERR PAVLUE ZSCORE
    columns_to_keep = ['CHR','BP', 'Allele1', 'Allele2','Effect', 'StdErr', 'Pvalue','Zscore']
        # Determine columns to drop
    columns_to_drop = zLocus.columns.difference(columns_to_keep)
        # Drop columns
    zLocus.drop(inplace=True, columns=columns_to_drop)
        # Keep specified columns
    zLocus = zLocus[columns_to_keep]
    
    #return (beg,chr_nb,zLocus)
    return (chr_nb,zLocus)



def printLocus(liste : "list[tuple]", Zhead : str, Effect : str, StdErr : str, outdir : str) -> None:
    """
    writes locus files
    """
    for i in range(len(liste)) :
        #beg,chr,_ = liste[i]
        chr,_ = liste[i]

        # liste[i] is the tuple (chrid,locus)
        #_,_,locusZ = ZscoreAdder(liste[i], Zhead, Effect, StdErr)
        _,locusZ = ZscoreAdder(liste[i], Zhead, Effect, StdErr)

        if len(str(chr)) == 1:
            locusZ.to_csv(f"{outdir}/CHR0{chr}locus{i+1}", index=False, sep=' ')
        elif len(str(chr)) == 2:
            locusZ.to_csv(f"{outdir}/CHR{chr}locus{i+1}", index=False, sep=' ')
        print(f"CHR{chr}Locus{i+1} printed !\n")

    return None

# ----------------------------------------------------------------------------



# MAIN  ----------------------------------------------------------------------

def main() -> int:
    parser = OptionParser()
    parser.add_option("-d", "--data", dest="data_bank", default="data/input/CAD_META")                  #data bank file directory and name
    parser.add_option("--sp", "--separator", dest="separator", default="\t")                            #separator used in data bank file: ' ',  '\t',  ';'...
    parser.add_option("--pv-header", "--pvalue-header", dest="pvalue_header", default="Pvalue")         #P-value header
    parser.add_option("--st", "--stderr", dest="stderror", default="StdErr")                            #Standart Error header
    parser.add_option("-e", "--effect", dest="effect", default="Effect")                                #Effect header
    parser.add_option("--chr", "--chromosome", dest="chr", default="CHR")                               #Chromosome number header
    parser.add_option("--a1", "--effect-allele", dest="a1", default="Allele1")                          #Effect allele header
    parser.add_option("--a2", "--alt-allele", dest="a2", default="Allele2")                             #Alternative allele header
    parser.add_option("--pos", "--position", dest="pos", default ="BP")                                 #Position of SNP header
    parser.add_option("-z", "--Zheader", dest="Zhead", default="Zscore")                                #Header name of Zscore new column, "Zscore" recommended for PAINTOR
    parser.add_option("--kb", "--up-down-kb", dest="kb", default=500)                                   #Number of kb upstream and downstream of the best SNP(best pvalue) for each locus
    parser.add_option("--pv-threshold", "--pvalue-threshold", dest="pvalue_threshold", default=5e-08)   #Value for the pvalue treshold
    parser.add_option("-o", "--outname", dest="outname", default ="CHRnLocusm")                         #Locus output name format 
    parser.add_option("--od", "--outdir", dest="outdir", default ="data/output/locus_output")           #Locus output directory
    (options, args) = parser.parse_args()


    data_bank = options.data_bank
    sep = options.separator
    pvalue_header = options.pvalue_header
    std = options.stderror
    effect = options.effect
    chr = options.chr
    allele1 = options.a1
    allele2 = options.a2
    pos = options.pos
    zhead = options.Zhead
    kb = options.kb
    pvalue_threshold = options.pvalue_threshold
    out = options.outname
    outdir = options.outdir
    
    #TODO : check CAD_META readme for Header info
    usage = """Usage:  
        -d (required) specify data bank path (default is "data" in the same directory as this programm)
        --sp specifiy the separator character used in data bank file (default is a tab '\t')
        --pv specifiy the P-value header used in data bank file (default is P-Value)
        --st specifiy the Standart Error header used in data bank file (default is StdErr)
        -e specifiy the Effect header used in data bank file (default is Effect)
        --chr specifiy the Chromosome number header used in data bank file (default is CHR)
        --a1 specifiy the Effect Allele header used in data bank file (default is Allele1)
        --a2 specifiy the Alernative Allele used in data bank file (default is Allele2)
        --pos specifiy the SNP Position header used in data bank file (default is BP)
        -z specifiy the wanted Zscore header used in data bank file (default is "Zscore")
        --kb specifiy the wanted number of kilo base upstream and downstream of the best SNP(best pvalue) for each locus
        --pv-threshold specifiy the wanted pvalue threshold
        --od specifiy the wanted output directory (default is the output directory in the data directory)
        -o (WIP) (optional) specifiy output format name
        """

    if(data_bank == None):
        sys.exit(usage)

    debut = time.time()
    
    # makes a lits of 22 dataframes, one for each chromosome, each including the snps of the chromosome in question
    chromosomes_list = ChromosomeSplitter_no_files(data_bank, sep, chr)

    p=Pool(22)
    p.map(lambda c : printLocus(LocusList(c, pvalue_header, pos, kb, pvalue_threshold), zhead, effect, std, outdir),chromosomes_list)

    print("\n\n\n")
    print("~~~~~ main finished in %s seconds ~~~~~\n" % (time.time() - debut))

    return 0
# ----------------------------------------------------------------------------


if __name__ == "__main__": main()