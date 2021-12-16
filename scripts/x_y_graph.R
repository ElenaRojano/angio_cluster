#! /usr/bin/env Rscript
# x,y graph

library(ggplot2)
library(ggrepel)
library(optparse)

################################################################
# OPTPARSE
################################################################
option_list <- list(
	make_option(c("-d", "--data_file"), type="character",
		help="Tabulated file with information about each sample"),
	make_option(c("-o", "--output"), type="character", default="results",
		help="Output figure file"),
	make_option(c("-x", "--x_values"), type="character", 
		help="Name of column X with values to be plotted"),
	make_option(c("-y", "--y_values"), type="character", 
		help="Name of column Y with values to be plotted"),
	make_option(c("-z", "--z_values"), type="character", 
		help="Name of column Z with values to be plotted"),
	make_option(c("-H", "--header"), action="store_false", default=TRUE,
        help="The input table not have header line"),
	 make_option(c("-X", "--x_title"), type="character", 
	 	help="Name of column to be used for bars titles"), 
	make_option(c("-Y", "--y_title"), type="character", 
	 	help="Title of y axis"),
	make_option(c("-Z", "--z_title"), type="character", 
	 	help="Title of z axis"),	
	make_option(c("-F", "--output_format"), type="character", default="pdf", 
	 	help="pdf or jpeg file output format")	

)
opt <- parse_args(OptionParser(option_list=option_list))


################################################################
## MAIN
################################################################

data <- read.table(opt$data_file, sep="\t", header=opt$header)
if (opt$output_format == "pdf"){
	pdf(paste(opt$output, '.pdf', sep=""))
}else if(opt$output_format == "jpeg"){
	jpeg(paste(opt$output, '.jpeg', sep=""))
}	
	ggplot(data=data, aes(x=data[[opt$x_values]], y=data[[opt$y_values]]))  +
	geom_point(aes(size=data[[opt$z_values]]), alpha = 0.3) +
	geom_label_repel(fill = "white",aes(label=clusterID, hjust=0, vjust=0), xlim = c(NA, Inf), ylim = c(-Inf, Inf)) +
	xlab(opt$x_title) +
	ylab(opt$y_title) +
	theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.title=element_blank()) +
	guides(fill=guide_legend(title=NULL))
dev.off()
