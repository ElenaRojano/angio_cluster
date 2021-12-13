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

#MP%3A0000260 => MPO: abnormal angiogenesis
#MP%3A0000259 => MPO: abnormal vascular development
#HP%3A0002597 => HPO: Abnormality of the vasculature
wget 'https://api.monarchinitiative.org/api/bioentity/phenotype/MP%3A0000259/diseases?rows=10000&facet=false&unselect_evidence=false&exclude_automatic_assertions=false&fetch_objects=false&use_compact_associations=false&direct_taxon=false' -O $list_path/MP_3A0000260.json
get_items.rb -i $list_path/MP_3A0000260.json > $list_path/MP_3A0000260.mondo 
get_disease_mondo.rb -i $list_path/MP_3A0000260.mondo -k 'Orphanet:[0-9]*' -s -f $ontology_file -o $list_path/MP_3A0000260.dict
cut -f 2 $list_path/MP_3A0000260.dict | sort -u > $list_path/MP_3A0000260.txt
