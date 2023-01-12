#!/usr/bin/env nextflow


/*  
    Usage:
       nextflow run wc.nf --input <input_file>
       
*/


nextflow.enable.dsl = 2 // to enable DSL2 syntax

// CHECK PARAMETERS ------------------------------------------------------------



// PIPELINE PARAMETERS ---------------------------------------------------------

params.gwasFile = "$projectDir/data/input/CAD_META_small_12"
params.mapFile = "$projectDir/data/input/integrated_call_samples_v3.20130502.ALL.panel"
params.ldFile = "$projectDir/data/input/ld.txt"
params.annotations = "$projectDir/data/input/annotations/annot.id.file.txt"
params.population = "EUR"

params.outputDir_locus = "data/output_locus"
params.outputDir_sorted_locus = "data/output_sorted_locus"
params.outputDir_ld = "data/output_ld"
params.outputDir_bed = "data/output_bed"
params.outputDir_overlapping = "data/output_overlapping"


// INCLUDE MODULES -------------------------------------------------------------

include {
  PREPPAINTOR_splitlocus
} from './modules/preppaintor.nf'


include {
  LDCALCULATION_sortlocus
  LDCALCULATION_calculation
} from './modules/ldcalculation.nf'


include {
  OVERLAPPINGANNOTATIONS_bedfiles
  OVERLAPPINGANNOTATIONS_overlapping
  //OVERLAPPINGANNOTATIONS_merge
} from './modules/overlappingannotations.nf'


// WORKFLOW --------------------------------------------------------------------

workflow {

  gwas_input_channel = Channel.fromPath(params.gwasFile) 
  gwas_input_channel.view{ it }

  split_channel = PREPPAINTOR_splitlocus(gwas_input_channel)
  
  ldsort_channel = LDCALCULATION_sortlocus(split_channel.flatten())

  ldcalc_channel = LDCALCULATION_calculation(ldsort_channel, params.mapFile, params.ldFile, params.population)
  //LDCALCULATION_calculation.out.view{ it }

  overlapbed_channel = OVERLAPPINGANNOTATIONS_bedfiles(ldcalc_channel.flatten())
  //OVERLAPPINGANNOTATIONS_bedfiles.out.view{ it }

  OVERLAPPINGANNOTATIONS_overlapping(overlapbed_channel.flatten(), params.annotations)
}


















