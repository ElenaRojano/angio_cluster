#! /usr/bin/env bash

current=`pwd`
global_path=$current/..
scripts_path=$global_path/scripts
dataset_path=$global_path'/datasets'
list_path=$global_path'/lists'
temp_files=$global_path'/executions/temp_files'
ontology_file=$dataset_path'/mondo.obo'
export PATH=$scripts_path:$PATH
source ~soft_bio_267/initializes/init_pets


if [ "$1" == "1" ]; then
	mkdir $list_path
	#MP%3A0000260 => MPO: abnormal angiogenesis
	#MP%3A0000259 => MPO: abnormal vascular development
	#HP%3A0002597 => HPO: Abnormality of the vasculature
	wget 'https://api.monarchinitiative.org/api/bioentity/phenotype/MP%3A0000259/diseases?rows=10000&facet=false&unselect_evidence=false&exclude_automatic_assertions=false&fetch_objects=false&use_compact_associations=false&direct_taxon=false' -O $list_path/MP_3A0000260.json
	get_items.rb -i $list_path/MP_3A0000260.json > $list_path/MP_3A0000260.mondo 
	get_disease_mondo.rb -i $list_path/MP_3A0000260.mondo -k 'Orphanet:[0-9]*' -s -f $ontology_file -o $list_path/MP_3A0000260.dict
	cut -f 2 $list_path/MP_3A0000260.dict | sort -u > $list_path/MP_3A0000260.txt
fi

if [ "$1" == "2" ]; then

	wget https://archive.monarchinitiative.org/latest/tsv/gene_associations/gene_disease.9606.tsv.gz -O $temp_files'/gene_disease.9606.tsv.gz'
	gunzip $temp_files'/gene_disease.9606.tsv.gz'
	wget http://geneontology.org/gene-associations/goa_human.gaf.gz -O $temp_files'/goa_human.gaf.gz'
	gunzip $temp_files'/goa_human.gaf.gz'

fi

if [ "$1" == "3" ]; then

	cut -f 2,5 $temp_files'/gene_disease.9606.tsv' > $temp_files'/gene_MONDO4go.txt'
	grep -w 'GO:0001525' $temp_files'/goa_human.gaf' | cut -f 3 | sort -u > $temp_files/go_gene.lst
	grep -w -F -f $temp_files/go_gene.lst $temp_files'/gene_MONDO4go.txt' > $temp_files'/gene_MONDO4go_filt.txt'
	cut -f 1 $temp_files'/gene_MONDO4go_filt.txt' | sort -u > $temp_files'/go_genes.txt'
	cut -f 2 $temp_files'/gene_MONDO4go_filt.txt' | sort -u > $temp_files'/go_mondo.txt'
	get_disease_mondo.rb -i $temp_files'/go_mondo.txt' -k 'Orphanet:[0-9]*' -s -f $ontology_file -o $list_path/go_query.dict
	cut -f 2 $list_path/go_query.dict | sort -u > $list_path/go_query.txt
fi
