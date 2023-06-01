#!/usr/bin/env Rscript

options(stringsAsFactors=FALSE)
library("ggplot2")
library("optparse")

# ============== #
# OPTION PARSING #
# ============== #

option_list <- list(
    make_option(c("-i", "--inputfile"), default="snp.ppr.txt"),
    make_option(c("-o", "--outputdir"), default="data/output_plot")
)

parser <- OptionParser(usage = "%prog [options] file", option_list=option_list)
arguments <- parse_args(parser, positional_arguments = TRUE)
opt <- arguments$options


# ============== #
#      PLOT      #
# ============== #

theme_set(theme_bw(base_size = 16))
df=read.delim(opt$inputfile, sep="\t", h=TRUE)
head(df)
ggplot(df, aes(ppr)) + stat_ecdf(geom = "point") + xlab("Maximum variant posterior probability (x)") + ylab("% of variants with PP < x")
ggsave(filename="snp.ppr.png")
dev.off()