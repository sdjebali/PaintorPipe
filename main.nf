#!/usr/bin/env nextflow

nextflow.enable.dsl = 2 // to enable DSL2 syntax

/*  
    Usage:
       nextflow run wc.nf --input <input_file>

       nextflow run main.nf \
        -c nextflow.config,genologin.config \
        --gwasFile <input_file> \
        --outputDir_locus <output_locus_dir> \
        -dsl2 \
        -profile slurm,singularity \
        -resume 
*/

// CHECK PARAMETERS ------------------------------------------------------------



// PIPELINE PARAMETERS ---------------------------------------------------------

// inputs
params.gwasFile = "$projectDir/data/input/CAD_META"
params.mapFile = "$projectDir/data/input/integrated_call_samples_v3.20130502.ALL.panel"
params.ldFile = "$projectDir/data/input/ld.txt"
params.annotations = "$projectDir/data/input/annotations.txt"
params.population = "EUR"
params.pvalue_header = "Pvalue"
params.stderr_header = "StdErr"
params.effect_header = "Effect"
params.chromosome_header = "CHR"
params.effectallele_header = "Allele1"
params.altallele_header = "Allele2"
params.position_header = "BP"
params.zheader_header = "Zscore"
params.kb = "500"
params.pvalue_treshold = "5e-08"
params.snp = "20"

// outputs
params.outputDir_locus = "data/output_locus"
params.outputDir_sorted_locus = "data/output_sorted_locus"
params.outputDir_ld = "data/output_ld"
params.outputDir_bed = "data/output_bed"
params.outputDir_overlapping = "data/output_overlapping"
params.outputDir_paintor = "data/output_paintor"
params.outputDir_results = "data/output_results"
params.outputDir_posteriorprob = "data/output_posteriorprob"
params.outputDir_plot = "data/output_plot"
params.outputDir_canvis = "data/output_canvis"

// PIPELINE  ---------------------------------------------------------

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
         Number of kb       : ${params.kb}
         Pvalue treshold    : ${params.pvalue_treshold}
         Population         : ${params.population}
         Number of SNPs     : ${params.snp}
         ~~~~~~~~~~~ 

         """
         .stripIndent()

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
} from './modules/overlappingannotations.nf'

include {
  PAINTOR_run
} from './modules/paintor.nf'

include {
  RESULTS_statistics
  RESULTS_posteriorprob
  RESULTS_plot
} from './modules/results.nf'

include {
  CANVIS_run
} from './modules/canvis.nf'

// WORKFLOW --------------------------------------------------------------------

workflow {

  // Create channel for the GWAS input file
  gwas_input_channel = Channel.fromPath(params.gwasFile) 

  // main
  split_channel = PREPPAINTOR_splitlocus(gwas_input_channel, params.pvalue_treshold,  params.kb, params.pvalue_header,   params.stderr_header, params.effect_header,   params.chromosome_header, params.effectallele_header, params.altallele_header , params.position_header, params.zheader_header)


  """
  ch = split_channel.flatten()
  ch
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1], it] }
    .set { ch }

  ldsort_channel = LDCALCULATION_sortlocus(ch)
  ldcalc_channel = LDCALCULATION_calculation(ldsort_channel, params.mapFile, params.ldFile, params.population)
  overlapbed_channel = OVERLAPPINGANNOTATIONS_bedfiles(ldcalc_channel.flatten())
  overlap_channel = OVERLAPPINGANNOTATIONS_overlapping(overlapbed_channel.flatten(), params.annotations)
  
  ch_ldcalc = ldcalc_channel.flatten()
  ch_ldcalc
    .filter { it -> it.toString().endsWith('.ld_out.ld') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.sorted.ld_out')[0], it] }
    .set { ch_ldcalc }
  
  ch_overlap = overlap_channel.flatten()
  ch_overlap
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.sorted.ld_out')[0], it] }
    .set { ch_overlap }

  paintor_channel = PAINTOR_run(ldcalc_channel.collect(), overlap_channel.collect(), params.annotations)
  res_channel = RESULTS_statistics(paintor_channel, params.annotations)
  snps = RESULTS_posteriorprob(paintor_channel, params.snp)

  ch_res = res_channel.flatten()
  ch_res
    .filter { it -> it.toString().endsWith('.canvis') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.results')[0], it] }
    .set { ch_res }

  ch_res_plot = res_channel.flatten()
  ch_res_plot
    .filter { it -> it.toString().endsWith('snp.ppr.txt') }
    .set { ch_res_plot }
  
  plot = RESULTS_plot(ch_res_plot)

  ch_res
    .combine(ch_ldcalc, by:0)
    .combine(ch_overlap, by:0)
    .map{ id, res, ld, allannots -> [res, ld, allannots] }
    .set{ ch_res }

  CANVIS_run(ch_res)
  """


  // views
   gwas_input_channel.view{ it }
   //ch.view{ it }
   //split_channel.view{ it }
   //ldsort_channel.view{ it }
   //ldcalc_channel.view{ it }
   //overlapbed_channel.view{ it }
   //overlap_channel.view{ it }
   //ch_ldcalc.view{ it }
   //ch_overlap.view{ it }
   //ch_res.view{ it }
   //paintor_channel.view{ it }
}


















