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
params.population = "EUR"
params.outputDir_locus = "data/output_locus"
params.outputDir_sorted_locus = "data/output_sorted_locus"
params.outputDir_ld = "data/output_ld"

/*
params.gwasFile = "data/input/CAD_META_small"
params.mapFile = "data/input/integrated_call_samples_v3.20130502.ALL.panel"
params.ldFile = "data/input/ld.txt"
params.population = "EUR"
params.outputDir_locus = "data/output_locus"
params.outputDir_sorted_locus = "data/output_sorted_locus"
params.outputDir_ld = "data/output_ld"
*/

// INCLUDE WORKFLOWS -----------------------------------------------------------



// INCLUDE MODULES -------------------------------------------------------------

include {
  PREPPAINTOR_splitlocus
} from './modules/preppaintor.nf'


include {
  LDCALCULATION_sortlocus
  LDCALCULATION_calculation
} from './modules/ldcalculation.nf'


/*
include {
  OVERLAPPINGANNOTATIONS_bedfiles
  OVERLAPPINGANNOTATIONS_overlapping
  OVERLAPPINGANNOTATIONS_merge
} from './modules/overlappingannotations.nf'
*/

// WORKFLOW --------------------------------------------------------------------

workflow {

  gwas_input_channel = Channel.fromPath(params.gwasFile) 
  map_input_channel = Channel.fromPath(params.mapFile)
  ld_input_channel = Channel.fromPath(params.ldFile)
  pop_input_channel = Channel.of(params.population)
  
  gwas_input_channel.view{ it }
  map_input_channel.view{ it }
  ld_input_channel.view{ it }
  
  split_channel = PREPPAINTOR_splitlocus(gwas_input_channel)
  
  ld_channel = LDCALCULATION_sortlocus(split_channel.flatten())
  
  //ko sorted_locus_channel = Channel.fromPath(params.outputDir_sorted_locus  + '/*') 
  //ko sorted_locus_channel.view{ it } 

  //LDCALCULATION_calculation(ld_channel, map_input_channel, ld_input_channel, pop_input_channel)
  //LDCALCULATION_calculation(ld_channel, params.mapFile, params.ldFile, params.population) 
  
  LDCALCULATION_calculation(ld_channel, params.mapFile, params.ldFile, params.population)
  LDCALCULATION_calculation.out.view{ it }

}


















