#!/usr/bin/env nextflow

<<<<<<< HEAD
=======
nextflow.enable.dsl = 2 // to enable DSL2 syntax
>>>>>>> dev

/*  
    Usage:
       nextflow run wc.nf --input <input_file>
<<<<<<< HEAD
=======
       ./nextflow main.nf -dsl2 -with-conda ~/bin/anaconda3/envs/paintor/
>>>>>>> dev
       
*/


<<<<<<< HEAD
nextflow.enable.dsl = 2 // to enable DSL2 syntax

=======
>>>>>>> dev
// CHECK PARAMETERS ------------------------------------------------------------



// PIPELINE PARAMETERS ---------------------------------------------------------

<<<<<<< HEAD
params.inputFile = "data/CAD_META_small"
params.outputDir = "data/output"

// INCLUDE WORKFLOWS -----------------------------------------------------------

=======
// inputs
params.gwasFile = "$projectDir/data/input/CAD_META"
params.mapFile = "$projectDir/data/input/integrated_call_samples_v3.20130502.ALL.panel"
params.ldFile = "$projectDir/data/input/ld.txt"
params.annotations = "$projectDir/data/input/annotations/annot.id.file.txt"
params.population = "EUR"

// outputs
params.outputDir_locus = "data/output_locus"
params.outputDir_sorted_locus = "data/output_sorted_locus"
params.outputDir_ld = "data/output_ld"
params.outputDir_bed = "data/output_bed"
params.outputDir_overlapping = "data/output_overlapping"
params.outputDir_paintor = "data/output_paintor"
params.outputDir_results = "data/output_results"
params.outputDir_plot = "data/output_plot"
params.outputDir_canvis = "data/output_canvis"

//R
params.df_path = "data/output_results/snp.ppr.txt"


log.info """\

         ===================================
          P A I N T O R     P I P E L I N E    
         ===================================

         Pipeline to run the Paintor program 
         and its associated visualization 
         tools on GWAS summary statistics data

         ~~~~~~~~~~~                
         PARAMETERS:
         GWAS file          : ${params.gwasFile}
         Map file           : ${params.mapFile}
         LD file            : ${params.ldFile}
         Annotations file   : ${params.annotations}
         Population         : ${params.population}
         ~~~~~~~~~~~ 

         """
         .stripIndent()
>>>>>>> dev


// INCLUDE MODULES -------------------------------------------------------------

include {
  PREPPAINTOR_splitlocus
} from './modules/preppaintor.nf'

<<<<<<< HEAD
=======

include {
  LDCALCULATION_sortlocus
  LDCALCULATION_calculation
} from './modules/ldcalculation.nf'


include {
  OVERLAPPINGANNOTATIONS_bedfiles
  OVERLAPPINGANNOTATIONS_overlapping
} from './modules/overlappingannotations.nf'


include {
  PAINTOR_run
} from './modules/paintor.nf'

include {
  RESULTS_statistics
  RESULTS_plot
} from './modules/results.nf'


include {
  CANVIS_run
} from './modules/canvis.nf'


>>>>>>> dev
// WORKFLOW --------------------------------------------------------------------

workflow {

<<<<<<< HEAD
  //  Input data is received through channels
  input_ch = Channel.fromPath(params.inputFile)
  PREPPAINTOR_splitlocus(input_ch)

=======
  // Create channel for the GWAS input file
  gwas_input_channel = Channel.fromPath(params.gwasFile) 

  // main
  split_channel = PREPPAINTOR_splitlocus(gwas_input_channel)
  ldsort_channel = LDCALCULATION_sortlocus(split_channel.flatten())
  ldcalc_channel = LDCALCULATION_calculation(ldsort_channel, params.mapFile, params.ldFile, params.population)
  overlapbed_channel = OVERLAPPINGANNOTATIONS_bedfiles(ldcalc_channel.flatten())
  overlap_channel = OVERLAPPINGANNOTATIONS_overlapping(overlapbed_channel.flatten(), params.annotations)
  paintor_channel = PAINTOR_run(ldcalc_channel.collect(),overlap_channel.collect(),params.annotations)
  res_channel = RESULTS_statistics(paintor_channel,params.annotations)
  plot = RESULTS_plot(res_channel.collect())
  
  CANVIS_run(res_channel.collect(),ldcalc_channel.collect(),overlap_channel.collect())



  // views
   gwas_input_channel.view{ it }
   //ldcalc_channel.view{ it }
   //overlapbed_channel.view{ it }
   //overlap_channel.view{ it }
   //paintor_channel.view{ it }
>>>>>>> dev
}



<<<<<<< HEAD
=======















>>>>>>> dev
