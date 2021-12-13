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
        make_option(c("-H", "--header"), action="store_false", default=TRUE,
        	help="The input table not have header line"),
        make_option(c("-x", "--x_values"), type="character", 
		help="Name of column X with values to be plotted"),
	make_option(c("-X", "--x_legend"), type="character", default="",
        	help="Use for set x axis legend")
	)
opt <- parse_args(OptionParser(option_list=option_list))

#####################
## MAIN
#####################
data <- read.table(opt$data_file, header=opt$header, sep="\t")
pdf(paste(opt$output, '.pdf', sep=""))
	ggplot(data, aes(x=data[[opt$x_values]])) +
	xlab(opt$x_legend) +
	geom_density()
dev.off()
