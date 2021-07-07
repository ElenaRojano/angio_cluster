#! /usr/bin/env Rscript

library(ggplot2)
library(optparse)

#####################
## OPTPARSE
#####################
option_list <- list(
        make_option(c("-d", "--data_file"), type="character",
                help="Tabulated file with information about each sample"),
        make_option(c("-o", "--output"), type="character", default="out",
                help="Output figure file"),
	make_option(c("-X", "--x_legend"), type="character", default="",
        	help="Use for set x axis legend")
	)
opt <- parse_args(OptionParser(option_list=option_list))

#####################
## MAIN
#####################

data <- read.table(opt$data_file, header=FALSE, sep="\t")
pdf(paste(opt$output, '.pdf', sep=""))
	ggplot(data, aes(x=V3)) +
	xlab(opt$x_legend) +
	geom_density()
dev.off()
