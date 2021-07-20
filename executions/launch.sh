#! /usr/bin/env bash

#SBATCH --cpus-per-task=1
#SBATCH --mem='20gb'
#SBATCH --time='01:00:00'
#SBATCH --constraint=sd
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out

export PATH=/mnt/scratch/users/bio_267_uma/elenarojano/projects/angiogenesis_raquel/disease_clustering/scripts:$PATH
source ~soft_bio_267/initializes/init_pets

global_path='/mnt/scratch/users/bio_267_uma/elenarojano/projects/angiogenesis_raquel/disease_clustering'
temp_files=$global_path'/executions/temp_files'
output_folder=$global_path'/executions/aRD_workflow'
orpha_codes=$global_path'/datasets/aRD_orpha_codes.txt'

mkdir $temp_files $output_folder

if [ "$1" == "1" ]; then
	echo 'Preparing files'
	#File with Human GeneID codes and STRING IDs (used as dictionary)
	#wget ftp://string-db.org/mapping_files/STRING_display_names/human.name_2_string.tsv.gz -O $temp_files"/human.name_2_string.tsv.gz"
    #gunzip $temp_files"/human.name_2_string.tsv.gz"
	#wget http://purl.obolibrary.org/obo/hp/hpoa/genes_to_phenotype.txt -O $temp_files"/genes_to_phenotype.txt"
	#grep -w -F -f $orpha_codes $temp_files/genes_to_phenotype.txt | cut -f 3,2,9 | sort -u > $temp_files/genes_hpo_orpha.txt
	#wget 'http://purl.obolibrary.org/obo/mondo.obo' -O $global_path'/datasets/mondo.obo'
	ontology_file=$global_path'/datasets/mondo.obo'
	#wget 'https://data.monarchinitiative.org/tsv/all_associations/gene_disease.all.tsv.gz' -O $global_path'/datasets/gene_disease.all.tsv'
	#gunzip gene_disease.all.tsv.gz
	mondo_file=$global_path'/datasets/gene_disease.all.tsv'
	parse_genes_hpo_orpha.rb -i $temp_files/genes_hpo_orpha.txt -g $temp_files/orpha_genes.txt -h $temp_files/orpha_hpos.txt 
	get_orpha_mondo.rb -i $orpha_codes -k Orphanet:[0-9]* -f $ontology_file -o $temp_files/orpha_mondo_codes.txt
	get_mondo_genes.rb -i $temp_files/orpha_mondo_codes.txt -m $mondo_file -o $temp_files/orpha_mondo_genes.txt
	cut -f 1,3 $temp_files/orpha_mondo_genes.txt > $temp_files/disease_genes.txt
fi


if [ "$1" == "2" ]; then
	source ~soft_bio_267/initializes/init_autoflow
	string_network=$global_path'/datasets/string_data.txt'
	#trad_cluster_stringtogen.rb -i $string_network -d $temp_files"/human.name_2_string.tsv" -o temp_files/string_transl_network.txt -n temp_files/untranslated_genes.txt 
	echo 'Launching analysis'
	gene_filter_values=( 0 )
	combined_score_filts=( 900 920 )
	#similarity_measures=( "resnik" "lin" )
	similarity_measures=( "lin" )
	min_groups=( 0 )
	active_interactors=20
	for similarity_measure in "${similarity_measures[@]}"
	do	
		for min_group in "${min_groups[@]}"
		do
			for combined_score in "${combined_score_filts[@]}"
			do
				for gene_filter_value in "${gene_filter_values[@]}"
				do
					execution_name=$similarity_measure"_"$min_group"_"$combined_score"_"$gene_filter_value
					var_info=`echo -e "\\$similarity_measure=$similarity_measure,
					\\$string_network=$temp_files/string_transl_network.txt,
					\\$string_dict=$temp_files/human.name_2_string.tsv,
					\\$combined_score=$combined_score,
					\\$active_interactors=$active_interactors,
					\\$min_group=$min_group,
					\\$gene_filter=$gene_filter_value,
					\\$disease_gene_file=$temp_files/disease_genes.txt,
					\\$disease_hpo_file=$temp_files/orpha_hpos.txt" | tr -d '[:space:]' `
					AutoFlow -w templates/aRD_analysis.txt -t '7-00:00:00' -m '100gb' -c 4 -o $output_folder"/"$execution_name -n 'sd' -e -V $var_info $2
				done
			done
		done
	done
fi
