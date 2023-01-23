

theme_set(theme_bw(base_size = 16))
df=read.delim("/work/project/regenet/workspace/zgerber/Nextflow/data/output_results/snp.ppr.tsv", sep="\t", h=TRUE)
head(df)
ggplot(df, aes(ppr)) + stat_ecdf(geom = "point") + xlab("Variant posterior probability (PP)") + ylab("% of variants with PP < x")
# looks good
ggsave(filename="snp.ppr.png", path="/work/project/regenet/workspace/zgerber/Nextflow/data/output_results")
dev.off()