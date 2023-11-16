#!/usr/bin/env nextflow

/*  
 *    Authors:
 *      Zoé Gerber
 *      Sarah Djebali
 *
 *    IRSD - 2022-2023
 *
 *    Usage:
 *      nextflow run main.nf \
 *        -c nextflow.config \
 *        --gwasFile /work/project/regenet/workspace/zgerber/pipelines/Nextflow/data/input/CAD_META \
 *        --annotations /work/project/regenet/workspace/zgerber/pipelines/Nextflow/data/input/annotations.txt \
 *        -profile slurm,singularity \
 *        -with-trace reports/trace.txt \
 *        -with-timeline 'reports/timeline.html \
 *        -with-report reports/report.html \
 *        -resume 
 */


// DSL2 ------------------------------------------------------------------------

nextflow.enable.dsl = 2 

// CHECK PARAMETERS ------------------------------------------------------------

error = ''

// Check required parameters
if (!params.gwasFile) {
  error += '\nNo --gwasFile provided\n'
}
if (!params.annotationsFile) {
  error += '\nNo --annotationsFile provided\n'
}

// Check valid values for ref_genome
if (params.ref_genome != "hg19" && params.ref_genome != "hg38") {
  error += "\nInvalid value for  --ref_genome   parameter: ${params.ref_genome}. Must be 'hg19' or 'hg38'\n"
}

// Display Error message
if (error) {
  println "\n\nERROR : Missing required parameter(s) or invalid value(s) :${error}"
  exit 1
}


// PIPELINE PARAMETERS ---------------------------------------------------------

// inputs
params.gwasFile = "$projectDir/GWAS_FILE"
params.annotationsFile = "$projectDir/ANNOTATIONS_FILE"
params.ref_genome = "hg19"
params.population = "EUR"
params.pvalue_header = "Pvalue"
params.stderr_header = "StdErr"
params.effect_header = "Effect"
params.chromosome_header = "CHR"
params.effectallele_header = "Allele1"
params.altallele_header = "Allele2"
params.position_header = "BP"
params.rsid_header = "rsID"
params.zheader_header = "Zscore"
params.kb = "500"
params.pvalue_lead = "5e-08"
params.pvalue_nonlead = "1"
params.pp_threshold = "0"
params.snp = "100000000"

// outputs
params.outputDir_locus = "data/output_locus"
params.outputDir_sorted_locus = "data/output_sorted_locus"
params.outputDir_VCFandMAPfrom1000G = "data/output_VCF_map_files"
params.outputDir_ld = "data/output_ld"
params.outputDir_bed = "data/output_bed"
params.outputDir_annotations = "data/output_annotations"
params.outputDir_annotated_locus = "data/output_annotated_locus"
params.outputDir_paintor = "data/output_paintor"
params.outputDir_results = "data/output_results"
params.outputDir_posteriorprob = "data/output_posteriorprob"
params.outputDir_plot = "data/output_plot"
params.outputDir_canvis = "data/output_canvis"

// ressources
params.max_cpus = '22'
params.max_memory = '60GB'

// PIPELINE  ---------------------------------------------------------

log.info """\

         =======================================
            P A I N T O R     P I P E L I N E    
         =======================================

               Fine-mapping pipeline

         PaintorPipe : a pipeline for genetic 
         variant fine-mapping using functional 
         annotations.

         Pipeline to run the Paintor program 
         and its associated visualization 
         tools on GWAS summary statistics data.

         =======================================
         REQUIRED :
            --gwasFile
            --annotationsFile
            
         GIVEN PARAMETERS :
            GWAS file                                     : ${params.gwasFile}
            GWAS file columns (no matter to the order)    : ${params.rsid_header}, ${params.chromosome_header}, ${params.position_header}, ${params.effectallele_header}, ${params.altallele_header}, ${params.effect_header}, ${params.stderr_header}, ${params.pvalue_header}
            Annotations file                              : ${params.annotationsFile}
            Reference Genome                              : ${params.ref_genome}
            Number of kb (up/down from lead SNP)          : ${params.kb}
            Pvalue threshold for lead SNP                 : ${params.pvalue_lead}
            Pvalue threshold for all SNPs around lead SNP : ${params.pvalue_nonlead}
            Population                                    : ${params.population}
            Number of SNPs to keep                        : ${params.snp}
            Posterior probability threshold               : ${params.pp_threshold}
           

         USAGE EXAMPLE :
            nextflow run main.nf 
              -c nextflow.config
              --gwasFile /work/project/regenet/workspace/zgerber/Nextflow/data/input/CAD_META
              --annotationsFile /work/project/regenet/workspace/zgerber/Nextflow/data/input/annotations_encode.txt 
              --chromosome_header Chr
              --pvalue_lead 5e-08
              --pvalue_nonlead 0.01
              --kb 500
              --snp 100000
              --pp_threshold 0.001
              -profile slurm,singularity 
              -with-trace reports/trace.txt
              -with-timeline reports/timeline.html 
              -with-report reports/report.html
              -resume 
         =======================================

         """
         .stripIndent()


// INCLUDE MODULES -------------------------------------------------------------

include {
  PREPPAINTOR_splitlocus
} from './modules/preppaintor.nf'

include {
  LDCALCULATION_sortlocus
  LDCALCULATION_getVCFandMAPfilesfrom1000GP
  LDCALCULATION_calculation
} from './modules/ldcalculation.nf'

include {
  ANNOTATIONS_bedfiles
  ANNOTATIONS_mergeannotations
} from './modules/annotations.nf'

include {
  PAINTOR_run
  PAINTOR_annotatedlocus
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
  """
  /work/project/regenet/workspace/zgerber/Nextflow2/data/input/CAD_META_small_12
  """

  // main
  // Split GWAS file into loci
  gwas_split_channel = PREPPAINTOR_splitlocus(gwas_input_channel, params.pvalue_lead, params.pvalue_nonlead, params.kb, params.pvalue_header, params.stderr_header, params.effect_header, params.chromosome_header, params.effectallele_header, params.altallele_header , params.position_header, params.rsid_header ,params.zheader_header)
  """
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus5]
  """

 // Create a channel with the locus id and the locus(+path)
  gwas_split_id_locus_channel = gwas_split_channel.flatten()
  gwas_split_id_locus_channel
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1], it] }
    .set { gwas_split_id_locus_channel }


  // Sort locus and compute LD matrix + processed files
  locus_sorted = LDCALCULATION_sortlocus(gwas_split_id_locus_channel)
  ld_map_files = LDCALCULATION_getVCFandMAPfilesfrom1000GP(params.ref_genome)

  ld_file = ld_map_files.flatten()
  ld_file 
    .filter { it -> it.toString().endsWith('ldFile.txt') }
    .set { ld_file }

  map_file = ld_map_files.flatten()
  map_file 
    .filter { it -> it.toString().endsWith('mapFile.txt') }
    .set { map_file }
  

  ld_matrix_processed = LDCALCULATION_calculation(locus_sorted.flatten(), ld_file.collect(), map_file.collect(), params.population, params.effectallele_header, params.altallele_header, params.zheader_header, params.position_header)


  // Transform processed files into bed files
  // The ANNOTATIONS_bedfiles process will use only LD processed file
  ld_processed_to_bed = ANNOTATIONS_bedfiles(ld_matrix_processed.flatten())

  // Add annotations to bed files
  annotated_bed = ANNOTATIONS_mergeannotations(ld_processed_to_bed.flatten(), params.annotationsFile)

  // Run PAINTOR program
  paintor = PAINTOR_run(ld_matrix_processed.collect(), annotated_bed.collect(), params.annotationsFile, params.zheader_header)
  """
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus1.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus2.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus3.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus4.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus5.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus1.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus2.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus3.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus4.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus5.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/Enrichment.Values, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/Log.BayesFactor, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/LogFile.results]
  """

  // Create a channel to add the annotations to paintor results
  paintor_results_channel = paintor.flatten()
  paintor_results_channel
    .filter { it -> it.toString().endsWith('.results') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.results')[0], it] }
    .set { paintor_results_channel }

  annotated_bed_channel = annotated_bed.flatten()
  annotated_bed_channel
    .filter { it -> it.toString().endsWith('.processed.filtered.ucsc.bed.coord.over.allannots.txt') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.sorted.ld_out.processed.filtered.ucsc.bed.coord.over.allannots.txt')[0], it] }
    .set { annotated_bed_channel }
  
  // Combine 2 channels to paste the locus corresponding to its annotation file
  paintor_annotated_results_channel = paintor_results_channel
  paintor_annotated_results_channel
    .combine(annotated_bed_channel, by:0)
    .map{ id, res, allannots -> [res, allannots] }
    .set{ paintor_annotated_results_channel }

  // Add the annotations to paintor results
  paintor_annotated_locus = PAINTOR_annotatedlocus(paintor_annotated_results_channel)

  // Interpretation of the PAINTOR results
  statistics = RESULTS_statistics(paintor.collect(), annotated_bed.collect(), params.annotationsFile,params.chromosome_header)

  snps = RESULTS_posteriorprob(paintor_annotated_locus.collect(), params.snp, params.pp_threshold)
 
  plot_channel = statistics.flatten()
  plot_channel
    .filter { it -> it.toString().endsWith('snp.ppr.txt') }
    .set { plot_channel }


  // Make graphic visualisation 
  // % of variants with pp < x according to the pp
  plot = RESULTS_plot(plot_channel)

  // Make graphic visualiation at each locus with CANVIS
  canvis_channel = statistics.flatten()
  canvis_channel
    .filter { it -> it.toString().endsWith('.canvis') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.results')[0], it] }
    .set { canvis_channel }

  ld_matrix_channel = ld_matrix_processed.flatten()
  ld_matrix_channel
    .filter { it -> it.toString().endsWith('.ld_out.ld.filtered') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.sorted.ld_out')[0], it] }
    .set { ld_matrix_channel }

  canvis_channel
    .combine(ld_matrix_channel, by:0)
    .combine(annotated_bed_channel, by:0)
    .map{ id, res, ld, allannots -> [res, ld, allannots] }
    .set{ canvis_channel }

  //Run Canvis
  CANVIS_run(canvis_channel, params.zheader_header)
  

  // Views
    //gwas_input_channel.view{ it }
    //gwas_split_channel.view{ it }
    //gwas_split_id_locus_channel.view{ it }
    //locus_sorted.view{ it }
    //map_file.view{ it }
    //ld_file.view{ it }
    //ld_matrix_processed.view{ it }
    //ld_processed_to_bed.view{ it }
    //annotated_bed.view{ it }
    //paintor.view{ it }
    //paintor_results_channel.view{ it }
    //annotated_bed_channel.view{ it }
    //paintor_annotated_results_channel.view{ it }
    //paintor_annotated_locus.view{ it }
    //statistics.view{ it }
    //snps.view{ it }
    //plot_channel.view{ it }
    //plot.view{ it }
    //canvis_channel.view{ it }
    //ld_matrix_channel.view{ it }
  }


















