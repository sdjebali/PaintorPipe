#!/usr/bin/env nextflow


/*  
    Usage:
       nextflow run wc.nf --input <input_file>
       
*/


nextflow.enable.dsl = 2 // to enable DSL2 syntax

// CHECK PARAMETERS ------------------------------------------------------------



// PIPELINE PARAMETERS ---------------------------------------------------------

params.inputFile = "data/CAD_META_small"
params.outputDir = "data/output"

// INCLUDE WORKFLOWS -----------------------------------------------------------



// INCLUDE MODULES -------------------------------------------------------------

include {
  PREPPAINTOR_splitlocus
} from './modules/preppaintor.nf'

// WORKFLOW --------------------------------------------------------------------

workflow {

  //  Input data is received through channels
  input_ch = Channel.fromPath(params.inputFile)
  PREPPAINTOR_splitlocus(input_ch)

}



