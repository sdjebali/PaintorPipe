#!/usr/bin/env python3

# This script was developped by Michel Fisun in the statistical genetics lab, Pasteur Paris, 
# under the supervision of Hugues Aschard

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

#TODO: Full pipeline & locus fusions if intersected
#TODO: threading

# FUNCTIONS  -----------------------------------------------------------------
def ChromosomeSplitter_no_files(bank : str, separator : str, cname : str) -> "list[pd.DataFrame]":    
    """
    data bank file name -> list[CHR1,CHR2,...,CHR22]
    Splits Data bank into chromosomes contained in a dataframe and stored in a list
    """
    print("starting chromosome splitter...")
    start_time = time.time()
    chr_list = []  # tuple: (chrosome_number, [chromosome])

    #reading data
    print("reading data...")
    data_bank = pd.read_csv(bank,index_col=False, sep=separator)
    print("data read !")

    #temporary pandas DataFrame to store snp data corresponding to current chromosome
    chr = pd.DataFrame(None)

    #building chromosome files
    for i in range(1,22+1):
        print("Building chromosome %s file..." % i)
        chr_list.append((i,data_bank[data_bank[cname] == i]))

    print("Done splitting chromosmes !")
    print("--- done splitting chromosomes in %s seconds ---\n" % (time.time() - start_time))
    print("Chromosomes generated :")
    print([n for (n,chr) in chr_list])

    #TODO check if files were actually generated
    print("\n\n")

    return chr_list


def SortPerPValue(chr : tuple, Phead : str) -> pd.DataFrame : 
    #TODO : enlever toutes les colonnes sauf la P-value et la position (voire laisser que la position) ((ID aussi ?))
    """
    Quicksorts (and writes) the SNP's of the i-th chromosome file, in ascending order according to the P-Value
    """
    start_time = time.time()
    i,chromosome = chr
    quicksorted = chromosome.sort_values(by=Phead, ascending=True, kind = 'quicksort', ignore_index=True)

    print(f"--- chromosome {i} sorted in %s secondes ---\n" % (time.time() - start_time))
    print("\n")

    return quicksorted


def LocusUnion(l1 : pd.DataFrame, l2 : pd.DataFrame) -> pd.DataFrame :
    """
    returns union of 2 loci
    """
    return pd.merge(l1,l2, how="outer")


def isIntersected(l1 : pd.DataFrame, l2 : pd.DataFrame) -> bool :
    """
    returns True if there is a common SNP in l1 and l2, returns False otherwise
    """
    return len(pd.merge(l1,l2,how="inner")) != 0


# this function is the most important of all (contains the intelligence of the whole process)
def LocusList(chr : tuple, Phead : str, pos) -> "list(tuple)":
    """
    returns a list of all locus in given chromosome

    Splits SNP's in the data bank (in one chromosome):
    After SNP's were sorted by SortPerPValue(), takes the first most significative SNP in the list, takes a region of +- 500kb 
    around the SNP in the non-pv-sorted file (but sorted according to position) and writes them into a file.
    Then, repeats the same process for the next most significative SNP if it is not already in the previous locus
    """
    print("starting chromosome splitter...")
    start_time = time.time()

    #TODO: Union of loci of 2 are close by 
    pseuil = 5e-08
    locus = pd.DataFrame(None)
    i,chromosome = chr
    sorted = SortPerPValue(chr,Phead)
    locus_nb = 0
    test = True
    liste = []

    for snp_index in range(len(sorted)):
        test = True
        #print(f"snp index: {snp_index} \n")

        if sorted.iloc[snp_index].Pvalue > pseuil:
            print("\n No more significant pvalues \n")
            break

        line = sorted[snp_index:snp_index+1]
        #print(line)
        pos_line = int(line[pos])
        #print(f"\n pos line : {pos_line} \n")
        kb_range = range(pos_line - 500000, pos_line + 500000 + 1)
        #print(f"\n range: {kb_range} \n \n \n")
        new_locus : tuple = (i,chromosome.loc[chromosome[pos].isin(kb_range)])

        if len(liste)==0:
            liste.append(new_locus)
            locus_nb = locus_nb + 1
            #print(f"CHR{i}locus{locus_nb}")
            continue
 
        else:
            for loc_i in range(len(liste)):
                ii,prev_locus = liste[loc_i]
                _,nnew_locus = new_locus

                if isIntersected(prev_locus, nnew_locus):
                    liste[loc_i] = (ii, LocusUnion(prev_locus, nnew_locus))
                    #print("Intersected")
                    test = False
                    break

        if test:
            liste.append(new_locus)  # REPETITION due to TEST which is true so 2 APPEND per new locus
            locus_nb = locus_nb + 1
            #print("No intersection, appended new locus")
            #print(f"CHR{i}locus{locus_nb}")

        #print(locus.loc[snp_index].oldID)
    #print(len(liste))
    print("len final : " + str(len(liste)))
    return liste


def ZscoreAdder(locus : tuple, Zhead : str, Effect : str, StdErr : str) -> pd.DataFrame:
    chr_nb,zLocus = locus
    zLocus[Zhead] = zLocus[Effect]/zLocus[StdErr]

    #Drop all columns that ARE NOT : CHR BP ALLELE1 ALLELE2 EFFECT STDERR PAVLUE ZSCORE

    #### modifs by Zoe Gerber ###
    columns_to_keep = ['CHR','BP', 'Allele1', 'Allele2','Effect', 'StdErr', 'Pvalue','Zscore']
        # Determine columns to drop
    columns_to_drop = zLocus.columns.difference(columns_to_keep)
        # Drop columns
    zLocus.drop(inplace=True, columns=columns_to_drop)
        # Keep specified columns
    zLocus = zLocus[columns_to_keep]
    return (chr_nb,zLocus)
    ######

    ### Michel Fisun version, works ###
    #zLocus.drop(inplace=True, columns=['MarkerName', 'Freq1', 'FreqSE', 'MinFreq', 'MaxFreq', 'Effect', 'StdErr',  'Pvalue', 'Direction', 'HetISq', 'HetChiSq', 'HetDf', 'HetPVal'])
    #zLocus = zLocus[['CHR','BP','oldID', 'Allele1', 'Allele2','Zscore']]
    #return (chr_nb,zLocus)
    ######
    

def printLocus(liste : "list[tuple]", Zhead : str, Effect : str, StdErr : str, outdir : str) -> None:
    """
    writes locus files
    """
    for i in range(len(liste)) :
        chr,_ = liste[i]

        #TODO : custom output path
        _,locusZ = ZscoreAdder(liste[i], Zhead, Effect, StdErr)

        if len(str(chr)) == 1:
            locusZ.to_csv(f"{outdir}/CHR0{chr}locus{i+1}", index=False, sep=' ')
        elif len(str(chr)) == 2:
            locusZ.to_csv(f"{outdir}/CHR{chr}locus{i+1}", index=False, sep=' ')
        print("locus printed")

    return None


def main() -> int:
    #TODO use programme without writing tons of files + give choice to user if want to write
    parser = OptionParser()
    parser.add_option("-d", "--data", dest="data_bank", default="data/input/CAD_META")   #data bank file directory and name
    parser.add_option("--sp", "--separator", dest="separator", default="\t")             #separator used in data bank file: ' ',  '\t',  ';'...
    parser.add_option("--pv", "--pvalue", dest="pvalue", default="Pvalue")               #P-value header
    parser.add_option("--st", "--stderr", dest="stderror", default="StdErr")             #Standart Error header
    parser.add_option("-e", "--effect", dest="effect", default="Effect")                 #Effect header
    parser.add_option("--chr", "--chromosome", dest="chr", default="CHR")                #Chromosome number header
    parser.add_option("--a1", "--effect-allele", dest="a1", default="Allele1")           #Effect allele header
    parser.add_option("--a2", "--alt-allele", dest="a2", default="Allele2")              #Alternative allele header
    parser.add_option("--pos", "--position", dest="pos", default ="BP")                  #Position of SNP header
    parser.add_option("-z", "--Zheader", dest="Zhead", default="Zscore")                 #header name of Zscore new column, "Zscore" recommended for PAINTOR
    parser.add_option("-o", "--outname", dest="outname", default ="CHRnLocusm")          #locus output name format #TODO
    parser.add_option("--od", "--outdir", dest="outdir", default ="data/output/locus_output")          #locus output directory
    (options, args) = parser.parse_args()


    data_bank = options.data_bank
    sep = options.separator
    pval = options.pvalue
    std = options.stderror
    effect = options.effect
    chr = options.chr
    allele1 = options.a1
    allele2 = options.a2
    pos = options.pos
    zhead = options.Zhead
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
        --od specifiy the wanted output directory (default is the output directory in the data directory)
        -o (WIP) (optional) specifiy output format name
        """

    if(data_bank == None):
        sys.exit(usage)

    debut = time.time()
    chromosomes_list = ChromosomeSplitter_no_files(data_bank, sep, chr)

    """
    # to do it chr by chr
    for c in chromosomes_list:
        printLocus(LocusList(c, pval, pos), zhead, effect, std, outdir)
    """
    
    p=Pool(22)
    p.map((lambda c : printLocus(LocusList(c, pval, pos), zhead, effect, std, outdir)),chromosomes_list)
    
    print("\n\n\n")
    print("~~~~~ main finished in %s seconds ~~~~~\n" % (time.time() - debut))

    return 0

if __name__ == "__main__": main()


