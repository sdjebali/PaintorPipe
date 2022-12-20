#!/usr/bin/env nextflow


/*  
    Usage:
       nextflow run wc.nf --input <input_file>
       
*/


nextflow.enable.dsl = 2 // to enable DSL2 syntax

// CHECK PARAMETERS ------------------------------------------------------------



// PIPELINE PARAMETERS ---------------------------------------------------------

params.gwasFile = "data/CAD_META_small"
params.outputDir = "data/output"

// INCLUDE WORKFLOWS -----------------------------------------------------------



// INCLUDE MODULES -------------------------------------------------------------

include {
  PREPPAINTOR_splitlocus
} from './modules/preppaintor.nf'


include {
  LDCALCULATION_sortlocus
  //LDCALCULATION_calculation
} from './modules/ldcalculation.nf'

// WORKFLOW --------------------------------------------------------------------

workflow {
  gwas_input_channel = Channel.fromPath(params.gwasFile) 
  gwas_input_channel.view{ it }

  locus = PREPPAINTOR_splitlocus(gwas_input_channel)
  locus.view{ it }

  locus_channel = Channel.fromPath(params.outputDir + '/*') 
  locus_channel.view{ it } 

  sorted_locus = LDCALCULATION_sortlocus(locus_channel)
  sorted_locus.view{ it }
// LDCALCULATION_calculation()
}



