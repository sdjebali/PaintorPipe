![](files/logo_PaintorPipe.png)

# PaintorPipe
`PaintorPipe` is a pipeline that perform fine-mapping analysis, using GWAS summary statistics data and diverse functionnal annotations, implemented in [Nextflow](#https://www.nextflow.io/).
This pipeline run the [Paintor program](#https://github.com/gkichaev/PAINTOR_V3.0) and its associated visualization tools and can be run locally or on a slurm cluster and handles containerisation using [Singularity](#https://github.com/sylabs/singularity).

![](files/flowchart_PaintorPipe.png)

# Table of Contents
- [Dependencies](#dependencies)
- [Usage](#usage)
  - [Pull the pre-built container](#pull-the-pre-built-container)
  - [Local Machine](#local-machine)
  - [Slurm compute cluster](#running-on-a-compute-cluster-with-slurm)
- [Pipeline parameters](#pipeline-parameters)
  - [Input options](#input-options)
  - [Output options](#output-options)
  - [Nextflow options](#nextflow-options)
- [Example on a small dataset](#example-on-a-small-dataset)
  - [GWAS summary statistics](#gwas-summary-statistics)
  - [Functionnal Annotations](#functionnal-annotations)
  - [Outputs](#outputs)
- [Citation](#citation)


# Dependencies
To use this pipeline you will need:
- `Nextflow` >= 21.10.6
- `Singularity` >= 3.7.3

First of all, you need to install [GO and singularity](#https://apptainer.org/user-docs/master/quick_start.html#quick-installation-steps).

# Usage
A small dataset `CAD_META_extract` is provided to test this pipeline ([Example on a small dataset](#example-on-a-small-dataset) section). To try it out, use one of the followings commands after pulling the singularity image.

## Pull the pre-built container
You can pull the image we built for the `PaintorPipe` from our repository on [Sylabs cloud](#https://cloud.sylabs.io/) using the command bellow :
```bash
singularity pull --arch amd64 library://zgerber/paintorpipe/mainimage:0.1
```

## Local Machine
If you are running the pipeline on a local machine with limited resources and want to use the default configuration (at least 2 CPUs/4G mem), use this command:
```bash
nextflow run main.nf -config nextflow.config --gwasFile 'data/input/CAD_META_extract' --annotationsFile 'data/input/annotations.txt' --ref_genome 'hg19' --chromosome_header 'Chr' --pvalue_nonlead '1' --snp '100000' --pp_threshold '0.001' -profile singularity -resume
```

## Running on a Compute Cluster with Slurm
If you have access to a compute cluster that uses the Slurm Workload Manager and you want to utilize the resources available there (at least 22 CPUs / 60 G mem), use this command with the slurm profile:
```bash
nextflow run main.nf -config nextflow.config --gwasFile 'data/input/CAD_META_extract' --annotationsFile 'data/input/annotations.txt' --ref_genome 'hg19' --chromosome_header 'Chr' --pvalue_nonlead '1' --snp '100000' --pp_threshold '0.001' -profile singularity, slurm -resume
```

# Pipeline parameters
## Input options

<table>
  <thead>
      <tr>
      <th width=200px>Option</th>
      <th width=200px>By default, example</th>
      <th width=350px>Description</th>
      <th width=90px>Required</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td nowrap><strong><code>--gwasFile</code></strong></td>
      <td nowrap><code>path/to/GWAS_FILE</code></td>
      <td>The GWAS file must contains 7 required columns : Allele1, Allele2, Effect (Beta), StdErr (SE), Pvalue, CHR, BP. The order is not important, but the name of the column is (see header parameters).</td>
      <td align=center>Required</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--annotationsFile</code></strong></td>
      <td nowrap><code>path/to/ANNOTATIONS_FILE</code></td>
      <td>The file should contains 2 columns separeted by tabulation. The first one is the name of the annotation (of the annotation file, or the annotation type for example) and the second is the associated path to the file.</td>
      <td align=center>Required</td>
    </tr>
   <tr>
      <td nowrap><strong><code>--ref_genome</code></strong></td>
      <td nowrap><code>hg19</code></td>
      <td>Only two values are allowed : 'hg19' or 'hg38'. Make sure you are using the correct reference genome for your summary statistics GWAS file, because the results of the pipeline coulb be incorrect.</td>
      <td align=center>Optional</td>
    </tr>
   <tr>
      <td nowrap><strong><code>--population</code></strong></td>
      <td nowrap><code>EUR</code></td>
      <td>Specifies the name of the mainland population : AFR, AMR, EAS, EUR, SAS.</td>
      <td align=center>Optional</td>
    </tr>
   <tr>
      <td nowrap><strong><code>--pvalue_header</code></strong></td>
      <td nowrap><code>Pvalue</code></td>
      <td>Pvalue header column name</td>
      <td align=center>Optional</td>
    </tr>
   <tr>
      <td nowrap><strong><code>--stderr_header</code></strong></td>
      <td nowrap><code>StdErr</code></td>
      <td>Standard Error (SE) header column name</td>
      <td align=center>Optional</td>
    </tr>
   <tr>
      <td nowrap><strong><code>--effect_header</code></strong></td>
      <td nowrap><code>Effect</code></td>
      <td>Effect (BETA) header column name</td>
      <td align=center>Optional</td>
    </tr>
   <tr>
      <td nowrap><strong><code>--chromosome_header</code></strong></td>
      <td nowrap><code>CHR</code></td>
      <td>Chromosome header column name</td>
      <td align=center>Optional</td>
    </tr>
   <tr>
      <td nowrap><strong><code>--effectallele_header</code></strong></td>
      <td nowrap><code>Allele1</code></td>
      <td>Allele with effect header column name</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
      <td nowrap><strong><code>--altallele_header</code></strong></td>
      <td nowrap><code>Allele2</code></td>
      <td>Allele without effect header column name</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
      <td nowrap><strong><code>--position_header</code></strong></td>
      <td nowrap><code>BP</code></td>
      <td>Variant position in base pair in the chromosome header column name</td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--rsID_header</code></strong></td>
      <td nowrap><code>rsID</code></td>
      <td>Unique variant identifiant or markermane header</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
  <tr>
      <td nowrap><strong><code>--zheader_header</code></strong></td>
      <td nowrap><code>Zscore</code></td>
      <td>The computed zscore is added in a new column, corresponding to the Effect/StdErr for each SNP, for each locus.</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
      <td nowrap><strong><code>--kb</code></strong></td>
      <td nowrap><code>500</code></td>
      <td>SNPs selection distance in kilo bases upstream and downstream of the lead SNP during the split of the GWAS file.</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
      <td nowrap><strong><code>--pp_treshold</code></strong></td>
      <td nowrap><code>0</code></td>
      <td>Significant posterior probability threshold.</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
      <td nowrap><strong><code>--snp</code></strong></td>
      <td nowrap><code>10000000</code></td>
      <td>Number of significant SNPs to keep.</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
      <td nowrap><strong><code>--pvalue_lead</code></strong></td>
      <td nowrap><code>5e-08</code></td>
      <td>Significant Pvalue threshold for lead SNP.</td>
      <td align=center>Optional</td>
    </tr>
  <tr>
      <td nowrap><strong><code>--pvalue_nonlead</code></strong></td>
      <td nowrap><code>1</code></td>
      <td>Significant Pvalue threshold for other SNPs around the lead SNP.</td>
      <td align=center>Optional</td>
    </tr>
  </tbody>
</table>

## Output options

<table>
  <thead>
    <tr>
      <th width=200px>Option</th>
      <th width=200px>By default, example</th>
      <th width=350px>Description</th>
      <th width=90px>Required</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td nowrap><strong><code>--outputDir_locus</code></strong></td>
      <td nowrap><code>data/output_locus</code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_sorted_locus</code></strong></td>
      <td nowrap><code>data/output_sorted_locus</code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_VCFandMAPfrom1000G</code></strong></td>
      <td nowrap><code>data/output_VCF_map_files</code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_ld</code></strong></td>
      <td nowrap><code>data/output_ld</code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_bed</code></strong></td>
      <td nowrap><code>data/output_bed</code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_annotations</code></strong></td>
      <td nowrap><code>data/output_annotations<annotations/code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_annotated_locus</code></strong></td>
      <td nowrap><code>data/output_annotated_locus<annotations/code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_paintor</code></strong></td>
      <td nowrap><code>data/output_paintor<annotations/code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_results</code></strong></td>
      <td nowrap><code>data/output_results<annotations/code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_posteriorprob</code></strong></td>
      <td nowrap><code>data/output_posteriorprob<annotations/code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_plot</code></strong></td>
      <td nowrap><code>data/output_plot<annotations/code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>--outputDir_canvis</code></strong></td>
      <td nowrap><code>data/output_canvis<annotations/code></td>
      <td></td>
      <td align=center>Optional</td>
    </tr>
  </tbody>
</table>

## Nextflow options
The pipeline is written in Nextflow, which provides the following default options:

<table>
  <thead>
    <tr>
      <th width=200px>Option</th>
      <th width=200px>By default, example</th>
      <th width=350px>Description</th>
      <th width=90px>Required</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td nowrap><strong><code>-profile</code></strong></td>
      <td nowrap><code>singularity</code></td>
      <td>Profile(s) to use when running the pipeline. Specify the profiles that fit your infrastructure among <code>singularity</code>, <code>slurm</code>.</td>
      <td align=center>Required</td>
    </tr>
    <tr>
      <td nowrap><strong><code>-config</code></strong></td>
      <td nowrap><code>nextflow.config</code></td>
      <td>
        Configuration file tailored to your infrastructure and dataset.
      </td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>-revision</code></strong></td>
      <td nowrap><code>version</code></td>
      <td>Version of the pipeline to launch.</td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>-work-dir</code></strong></td>
      <td nowrap><code>directory</code></td>
      <td>Work directory where all temporary files are written.</td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>-resume</code></strong></td>
      <td nowrap></td>
      <td>Resume the pipeline from the last completed process.</td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>-with-report</code></strong></td>
      <td nowrap></td>
      <td>Nextflow can create an HTML execution report. It is a single document that includes many useful metrics on pipeline execution</td>
      <td align=center>Optional</td>
    </tr>
    <tr>
      <td nowrap><strong><code>-with-timeline</code></strong></td>
      <td nowrap></td>
      <td>Nextflow can display a timeline in HTML format for all processes performed in the pipeline</td>
      <td align=center>Optional</td>
    </tr>
  </tbody>
</table>

For more Nextflow options, see [Nextflow's documentation](https://www.nextflow.io/docs/latest/cli.html#run).




# Example on a small dataset
## GWAS summary statistics
`CAD_META_extract` GWAS file is an extract of the GWAS results from the latest `Coronary Artery Disease` (CAD) meta-analysis involving 122,733 cases and 424,528 controls ([van der Harst P et al, 2018](#https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5805277/)).

```bash
unzip CAD_META_extract.zip
head CAD_META_extract
```
```
MarkerName	Allele1	Allele2	Freq1	FreqSE	MinFreq	MaxFreq	Effect	StdErr	Pvalue	Direction	HetISq	HetChiSq	HetDf	HetPVal	rsID	Chr	BP
9:34486713_A_G	a	g	0.9363	0.0023	0.9346	0.9394	0.0058	0.0115	0.6106	+-	0	0.663	1	0.4156	rs72735241	9	34486713
4:187387354_G_T	t	g	0.0359	0.0045	0.032	0.041	0.009	0.0155	0.5604	-+	0	0.847	1	0.3574	rs73020749	4	187387354
4:76326344_C_G	c	g	0.1743	0.0062	0.1694	0.1823	-3e-04	0.0075	0.9641	-+	69.2	3.252	1	0.07136	rs11727982	4	76326344
1:88710048_C_T	t	c	0.4234	0.008	0.4172	0.4337	-0.0064	0.0057	0.2601	--	0	0.371	1	0.5427	rs6428642	1	88710048
1:189237277_C_T	t	c	0.5217	0.0011	0.5209	0.5232	0.005	0.0056	0.3742	++	0	0.129	1	0.719	rs1578705	1	189237277
```

The `CAD_META_extract` GWAS test file provided contains the 8 required columns : 
- Allele1
- Allele2
- Effect 
- StdErr
- CHR
- BP 
- rsID
- Pvalue

The chromosome column is the only column with an incorrect header entry. We need to provide the correct version of the header: `Chr` instead of `CHR` with the `--chromosome_header` parameter (see [usage](#usage) part).

This is important that the column names are correctly written. If you have supplementary columns like in the exampe above, you can keep them, the pipeline is going to ignore them. If you don't want to change the required column names in the file, like the `Chr`column, you have to indicate the alternative names with the header arguments when launching Nextflow command. Make sure the columns are separated by tabulations.

Be careful when running the pipe, about the reference genome version (`--ref_genome` parameter). By default, the pipeline uses hg19 version (more used). Depending on the GWAS dataset you want to fine map, you can change by hg38 version (more recent).

Additionally, it is important to ensure that the pvalue for non-leader SNPs is correct. Indeed, if you run `PaintorPipe` on a small number of variants, as in the example here, the pipeline will generate errors. We recommend in the testing phases to keep the `--pvalue_nonlead` parameter at 1.

## Functionnal annotations
Concerning the annotation library, you can use the annotations given in the [Paintor github wiki](#https://github.com/gkichaev/PAINTOR_V3.0/wiki/2b.-Overlapping-annotations) or directely following this [link](#https://ucla.box.com/s/x47apvgv51au1rlmuat8m4zdjhcniv2d) (Warning: This is a large 6.7 GB file).

Once the annotation bed files are downloaded, you can write the `annotations.txt` file, to give to the pipeline, pointing to all annotation bed files (use tabulation) looking like:
```
genc.exon       path/to/exons.proj.bed
genc.intron     path/to/introns.proj.bed
```
The first column is the name of the functionnal annotation and the second is the path to the bed file. Above, an example for a run with 2 annotations (exons & introns). We recommand to use no more than 4 or 5 annotations per run.

## Outputs
You should obtain 43 loci in the `output_locus` directory. Check the `slurm-46703827.out` output file in the `files` directory.

# Citation
If you use `PaintorPipe` for your analysis, please cite the publication as follows : 

*Gerber, Z., Fisun, M., Aschard, H., & Djebali, S. (2024). PaintorPipe: a pipeline for genetic variant fine-mapping using functional annotations. Bioinformatics Advances, 4(1), vbad188.*

You can find the publication by following this [link](#https://doi.org/10.1093/bioadv/vbad188) (https://doi.org/10.1093/bioadv/vbad188).