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
 *        -dsl2 \
 *        -c nextflow.config,genologin.config \
 *        --gwasFile '/work/project/regenet/workspace/zgerber/pipelines/Nextflow/data/input/CAD_META' \
 *        --annotations '/work/project/regenet/workspace/zgerber/pipelines/Nextflow/data/input/annotations_encode.txt' \
 *        -profile slurm,singularity \
 *        -with-trace 'reports/trace.txt' \
 *        -with-timeline 'reports/timeline.html' \
 *        -with-report 'reports/report.html' \
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

         ===================================
          P A I N T O R     P I P E L I N E    
         ===================================

               Fine-mapping pipeline

         PaintorPipe : Pipeline to run the 
         Paintor program and its associated 
         visualization tools on GWAS summary 
         statistics data.

         ===================================
         REQUIRED :
            --gwasFile
            --annotationsFile
            
         GIVEN PARAMETERS :
            GWAS file                                     : ${params.gwasFile}
            GWAS file columns (no matter to the order)    : ${params.chromosome_header}, ${params.position_header}, ${params.effectallele_header}, ${params.altallele_header}, ${params.effect_header}, ${params.stderr_header}, ${params.pvalue_header}
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
              -dsl2 
              -c nextflow.config,genologin.config 
              --gwasFile '/work/project/regenet/workspace/zgerber/Nextflow/data/input/CAD_META' 
              --annotationsFile '/work/project/regenet/workspace/zgerber/Nextflow/data/input/annotations_encode.txt' 
              --chromosome_header 'Chr' 
              --pvalue_lead '5e-08' 
              --pvalue_nonlead '0.01' 
              --kb '500' 
              --snp '100000' 
              --pp_threshold '0.001' 
              -profile slurm,singularity 
              -with-trace 'reports/trace.txt' 
              -with-timeline 'reports/timeline.html' 
              -with-report 'reports/report.html' 
              -resume 
         ===================================

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
  gwas_split_channel = PREPPAINTOR_splitlocus(gwas_input_channel, params.pvalue_lead, params.pvalue_nonlead, params.kb, params.pvalue_header, params.stderr_header, params.effect_header, params.chromosome_header, params.effectallele_header, params.altallele_header , params.position_header, params.zheader_header)
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

  """
  [CHR01locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus1]
  [CHR01locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus2]
  [CHR01locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus3]
  [CHR01locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus4]
  [CHR01locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR01locus5]
  [CHR02locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus1]
  [CHR02locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus2]
  [CHR02locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus3]
  [CHR02locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus4]
  [CHR02locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/f3/cc04def1b3a2838b10bf32c4b6598a/data/output_locus/CHR02locus5]
  """

  // Sort locus and compute LD matrix + processed files
  locus_sorted = LDCALCULATION_sortlocus(gwas_split_id_locus_channel)

  """
  /work/project/regenet/workspace/zgerber/Nextflow2/work/e3/d7e38f0dafeb7750cfeec87134cd16/CHR01locus2.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/f5/74ff0020de3914a1b7afa7b4cf65b0/CHR01locus1.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/22/6e4685fcb2b5bd13cb6db4b0d1c708/CHR01locus3.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/67/8c0ed2f8c0f80b8fd7cdfad33bea23/CHR01locus5.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/6e/c99f5e90f4c057fabc8402f75eb9a6/CHR01locus4.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/48/248c4333e464aeb582a5df47a55c30/CHR02locus1.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/3d/2fa188844259d35e341818b95e6b10/CHR02locus2.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/18/a7f03e9d0a2a0590fd7cec74d2233c/CHR02locus3.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/43/0f9851ce7b1437e91119c806428c08/CHR02locus5.sorted
  /work/project/regenet/workspace/zgerber/Nextflow2/work/11/fcd1611ed4df5653072bb68e042387/CHR02locus4.sorted
  """
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
  """
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/36/0ea85877cd1ba981f6d3443344cf84/CHR02locus2.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/36/0ea85877cd1ba981f6d3443344cf84/CHR02locus2.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/6f/472bf222c82402d7ca9a2a068c7120/CHR01locus2.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/6f/472bf222c82402d7ca9a2a068c7120/CHR01locus2.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/b1/51a3cbc2851ea9b0a03a483b5401bf/CHR01locus5.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/b1/51a3cbc2851ea9b0a03a483b5401bf/CHR01locus5.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/c3/9a0d07fd943d3bee4495857d894892/CHR02locus4.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/c3/9a0d07fd943d3bee4495857d894892/CHR02locus4.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/94/6dc7205719107dc064e64af370335e/CHR02locus1.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/94/6dc7205719107dc064e64af370335e/CHR02locus1.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/68/61e865578368c9919eecf66cfb10c4/CHR01locus3.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/68/61e865578368c9919eecf66cfb10c4/CHR01locus3.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/97/c0091ccc1404a817229e20eca7654e/CHR01locus4.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/97/c0091ccc1404a817229e20eca7654e/CHR01locus4.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/04/c81c7884bf6a0ae2f07c9008190574/CHR01locus1.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/04/c81c7884bf6a0ae2f07c9008190574/CHR01locus1.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/0a/02221633bcde07df0299ff9a0ac2f2/CHR02locus3.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/0a/02221633bcde07df0299ff9a0ac2f2/CHR02locus3.sorted.ld_out.processed]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/cc/d6763ec6a9bc5cb63bb8b279ccbae5/CHR02locus5.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/cc/d6763ec6a9bc5cb63bb8b279ccbae5/CHR02locus5.sorted.ld_out.processed]
  """

  // Transform processed files into bed files
  // The ANNOTATIONS_bedfiles process will use only LD processed file
  ld_processed_to_bed = ANNOTATIONS_bedfiles(ld_matrix_processed.flatten())
  """
  /work/project/regenet/workspace/zgerber/Nextflow2/work/cd/76cc948c31c7136c561c18f689a4b1/CHR01locus2.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/ca/2757a79a7693471279f9bf26b68b71/CHR01locus1.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/57/531c86077540a494f21862c8b3e0a5/CHR01locus5.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/f2/c88a838bff69bde3f1c24b66d666c8/CHR02locus1.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/66/b5b062542caeb33c5eaeba9eea7c68/CHR01locus3.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/5e/db5b6855969dde0ebdd5d269bfcce9/CHR01locus4.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/53/d7dbc5c3c85882a296933633801e65/CHR02locus2.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/c0/3c8515dbdf86d5ec109ae718b95b57/CHR02locus5.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/62/7ef2fc1bd759339d89c9b66401cfdd/CHR02locus3.sorted.ld_out.processed.ucsc.bed
  /work/project/regenet/workspace/zgerber/Nextflow2/work/90/87cd07865d18b02ba7b9102291272a/CHR02locus4.sorted.ld_out.processed.ucsc.bed
  """

  // Add annotations to bed files
  annotated_bed = ANNOTATIONS_mergeannotations(ld_processed_to_bed.flatten(), params.annotationsFile)
  """  
  /work/project/regenet/workspace/zgerber/Nextflow2/work/42/74eb5318397f22d2d6887651307ef5/CHR01locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/2b/f5bb10cf1965dd7c4fda1c7aa9f7aa/CHR02locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/db/ff90034e9ef63cd170329580dd02e3/CHR02locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/ab/71b3fbb1e9d0ff4952b415a830c0c9/CHR01locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/b4/62ce5b90b15826ee0b23bcc66fad2c/CHR01locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/586337b32bb6f7474025f1fc2ed8b9/CHR01locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/aa/7c0ed4a99f1649a90b4c548c908006/CHR02locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/f9/463e24d42e8692aea851e4f1b9d7cd/CHR02locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/b0/f286ac24a24e7632a215be2994ef6c/CHR01locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  /work/project/regenet/workspace/zgerber/Nextflow2/work/6c/7ad3594951be1cd95b5cd189ecbc5b/CHR02locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt
  """

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
  """
  [CHR01locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus1.results]
  [CHR01locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus2.results]
  [CHR01locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus3.results]
  [CHR01locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus4.results]
  [CHR01locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus5.results]
  [CHR02locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus1.results]
  [CHR02locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus2.results]
  [CHR02locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus3.results]
  [CHR02locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus4.results]
  [CHR02locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus5.results]
  [LogFile, /work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/LogFile.results]
  """

  annotated_bed_channel = annotated_bed.flatten()
  annotated_bed_channel
    .filter { it -> it.toString().endsWith('.processed.ucsc.bed.coord.over.allannots.txt') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt')[0], it] }
    .set { annotated_bed_channel }
  """
  [CHR01locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/42/74eb5318397f22d2d6887651307ef5/CHR01locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR01locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/b4/62ce5b90b15826ee0b23bcc66fad2c/CHR01locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR01locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/ab/71b3fbb1e9d0ff4952b415a830c0c9/CHR01locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR02locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/2b/f5bb10cf1965dd7c4fda1c7aa9f7aa/CHR02locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR01locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/586337b32bb6f7474025f1fc2ed8b9/CHR01locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR02locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/aa/7c0ed4a99f1649a90b4c548c908006/CHR02locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR01locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/b0/f286ac24a24e7632a215be2994ef6c/CHR01locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR02locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/f9/463e24d42e8692aea851e4f1b9d7cd/CHR02locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR02locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/6c/7ad3594951be1cd95b5cd189ecbc5b/CHR02locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [CHR02locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/db/ff90034e9ef63cd170329580dd02e3/CHR02locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  """
  
  // Combine 2 channels to paste the locus corresponding to its annotation file
  paintor_annotated_results_channel = paintor_results_channel
  paintor_annotated_results_channel
    .combine(annotated_bed_channel, by:0)
    .map{ id, res, allannots -> [res, allannots] }
    .set{ paintor_annotated_results_channel }
  """
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus1.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/b4/62ce5b90b15826ee0b23bcc66fad2c/CHR01locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus2.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/ab/71b3fbb1e9d0ff4952b415a830c0c9/CHR01locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus3.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/42/74eb5318397f22d2d6887651307ef5/CHR01locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus4.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/b0/f286ac24a24e7632a215be2994ef6c/CHR01locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR01locus5.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/586337b32bb6f7474025f1fc2ed8b9/CHR01locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus1.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/2b/f5bb10cf1965dd7c4fda1c7aa9f7aa/CHR02locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus2.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/aa/7c0ed4a99f1649a90b4c548c908006/CHR02locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus3.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/6c/7ad3594951be1cd95b5cd189ecbc5b/CHR02locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus4.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/f9/463e24d42e8692aea851e4f1b9d7cd/CHR02locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/a2/87a7ca9fbf30b370e57dac79eca95a/CHR02locus5.results, /work/project/regenet/workspace/zgerber/Nextflow2/work/db/ff90034e9ef63cd170329580dd02e3/CHR02locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  """

  // Add the annotations to paintor results
  paintor_annotated_locus = PAINTOR_annotatedlocus(paintor_annotated_results_channel)
  """
  /work/project/regenet/workspace/zgerber/Nextflow2/work/6e/9f30bc1e337aeee76b08c6358c5c62/CHR01locus1.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/8e/878670ce798620572b694850dc3b82/CHR01locus2.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/31/3323b36688c016d0ee0bad0a6f3b0f/CHR01locus3.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/d1/138daa87f29000b3d3937e2b8641ac/CHR01locus4.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/85/0d947a2a1b3924171b90cad5c04741/CHR01locus5.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/5d/a8d98da2538cd2e2c2f2fd0b518c78/CHR02locus2.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/6c/3d8681293ca47ed4fcb5214d850ae5/CHR02locus3.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/8c/d3a0f7cb55e02136d4a8468195223e/CHR02locus1.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/96/a0e9eb5e4646f528fcf180372be460/CHR02locus5.results.annotated
  /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/de323e0e2ea15c219104efb638baeb/CHR02locus4.results.annotated
  """

  // Interpretation of the PAINTOR results
  statistics = RESULTS_statistics(paintor.collect(), annotated_bed.collect(), params.annotationsFile)
  """
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus1.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus1.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus2.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus2.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus3.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus3.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus4.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus4.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus5.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus5.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus1.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus1.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus2.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus2.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus3.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus3.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus4.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus4.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus5.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus5.variant.achieving.50.80.95pcent.sumppri.nb.pcent.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/annot.probsnpcausal.given.baseline.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/pcent_snp_in_each_annot.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/snp.ppr.txt]
  """

  snps = RESULTS_posteriorprob(paintor_annotated_locus.collect(), params.snp, params.pp_threshold)
  """
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/18/cb8dcc2cd4d2657d10645b1d5ab250/posteriorprob_merged.txt, /work/project/regenet/workspace/zgerber/Nextflow2/work/18/cb8dcc2cd4d2657d10645b1d5ab250/posteriorprob_merged_filtered.txt]
  """

 
  plot_channel = statistics.flatten()
  plot_channel
    .filter { it -> it.toString().endsWith('snp.ppr.txt') }
    .set { plot_channel }
  """
  /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/snp.ppr.txt
  """

  // Make graphic visualisation 
  // % of variants with pp < x according to the pp
  plot = RESULTS_plot(plot_channel)
  """
  /work/project/regenet/workspace/zgerber/Nextflow2/work/d9/89880d97720c0586c32bfd9f5c9afd/snp.ppr.png
  """

  // Make graphic visualiation at each locus with CANVIS
  canvis_channel = statistics.flatten()
  canvis_channel
    .filter { it -> it.toString().endsWith('.canvis') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.results')[0], it] }
    .set { canvis_channel }
  """
  [CHR01locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus1.results.for.canvis]
  [CHR01locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus2.results.for.canvis]
  [CHR01locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus3.results.for.canvis]
  [CHR01locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus4.results.for.canvis]
  [CHR01locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus5.results.for.canvis]
  [CHR02locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus1.results.for.canvis]
  [CHR02locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus2.results.for.canvis]
  [CHR02locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus3.results.for.canvis]
  [CHR02locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus4.results.for.canvis]
  [CHR02locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus5.results.for.canvis]
  """

  ld_matrix_channel = ld_matrix_processed.flatten()
  ld_matrix_channel
    .filter { it -> it.toString().endsWith('.ld_out.ld') }
    .map { it ->
           a = it.toString().split('/')
           l = a.length
           return [a[l-1].split('.sorted.ld_out')[0], it] }
    .set { ld_matrix_channel }
  """
  [CHR01locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/6f/472bf222c82402d7ca9a2a068c7120/CHR01locus2.sorted.ld_out.ld]
  [CHR01locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/04/c81c7884bf6a0ae2f07c9008190574/CHR01locus1.sorted.ld_out.ld]
  [CHR01locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/97/c0091ccc1404a817229e20eca7654e/CHR01locus4.sorted.ld_out.ld]
  [CHR01locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/68/61e865578368c9919eecf66cfb10c4/CHR01locus3.sorted.ld_out.ld]
  [CHR01locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/b1/51a3cbc2851ea9b0a03a483b5401bf/CHR01locus5.sorted.ld_out.ld]
  [CHR02locus1, /work/project/regenet/workspace/zgerber/Nextflow2/work/94/6dc7205719107dc064e64af370335e/CHR02locus1.sorted.ld_out.ld]
  [CHR02locus2, /work/project/regenet/workspace/zgerber/Nextflow2/work/36/0ea85877cd1ba981f6d3443344cf84/CHR02locus2.sorted.ld_out.ld]
  [CHR02locus4, /work/project/regenet/workspace/zgerber/Nextflow2/work/c3/9a0d07fd943d3bee4495857d894892/CHR02locus4.sorted.ld_out.ld]
  [CHR02locus5, /work/project/regenet/workspace/zgerber/Nextflow2/work/cc/d6763ec6a9bc5cb63bb8b279ccbae5/CHR02locus5.sorted.ld_out.ld]
  [CHR02locus3, /work/project/regenet/workspace/zgerber/Nextflow2/work/0a/02221633bcde07df0299ff9a0ac2f2/CHR02locus3.sorted.ld_out.ld]
  """

  canvis_channel
    .combine(ld_matrix_channel, by:0)
    .combine(annotated_bed_channel, by:0)
    .map{ id, res, ld, allannots -> [res, ld, allannots] }
    .set{ canvis_channel }
  """
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus1.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/04/c81c7884bf6a0ae2f07c9008190574/CHR01locus1.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/b4/62ce5b90b15826ee0b23bcc66fad2c/CHR01locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus2.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/6f/472bf222c82402d7ca9a2a068c7120/CHR01locus2.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/ab/71b3fbb1e9d0ff4952b415a830c0c9/CHR01locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus3.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/68/61e865578368c9919eecf66cfb10c4/CHR01locus3.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/42/74eb5318397f22d2d6887651307ef5/CHR01locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus4.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/97/c0091ccc1404a817229e20eca7654e/CHR01locus4.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/b0/f286ac24a24e7632a215be2994ef6c/CHR01locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR01locus5.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/b1/51a3cbc2851ea9b0a03a483b5401bf/CHR01locus5.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/ba/586337b32bb6f7474025f1fc2ed8b9/CHR01locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus1.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/94/6dc7205719107dc064e64af370335e/CHR02locus1.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/2b/f5bb10cf1965dd7c4fda1c7aa9f7aa/CHR02locus1.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus2.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/36/0ea85877cd1ba981f6d3443344cf84/CHR02locus2.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/aa/7c0ed4a99f1649a90b4c548c908006/CHR02locus2.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus3.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/0a/02221633bcde07df0299ff9a0ac2f2/CHR02locus3.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/6c/7ad3594951be1cd95b5cd189ecbc5b/CHR02locus3.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus4.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/c3/9a0d07fd943d3bee4495857d894892/CHR02locus4.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/f9/463e24d42e8692aea851e4f1b9d7cd/CHR02locus4.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  [/work/project/regenet/workspace/zgerber/Nextflow2/work/ba/d44b3528c9a7603879ea17f7ed7f31/CHR02locus5.results.for.canvis, /work/project/regenet/workspace/zgerber/Nextflow2/work/cc/d6763ec6a9bc5cb63bb8b279ccbae5/CHR02locus5.sorted.ld_out.ld, /work/project/regenet/workspace/zgerber/Nextflow2/work/db/ff90034e9ef63cd170329580dd02e3/CHR02locus5.sorted.ld_out.processed.ucsc.bed.coord.over.allannots.txt]
  """

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


















