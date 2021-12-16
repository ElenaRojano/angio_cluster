#! /usr/bin/env bash

#SBATCH --cpus-per-task=1
#SBATCH --mem='20gb'
#SBATCH --time='01:00:00'
#SBATCH --constraint=sd
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out


current=`pwd`
global_path=$current/..
scripts_path=$global_path/scripts
dataset_path=$global_path'/datasets'
temp_files=$global_path'/executions/temp_files'
output_folder=$global_path'/executions/aRD_workflow'
orpha_codes=$dataset_path'/aRD_orpha_codes.txt' #antiguo: raquel_aRD_orpha_codes.txt
#orpha_codes='/mnt/home/users/pab_001_uma/pedro/proyectos/angio/results/orpha_codes'
export PATH=$scripts_path:$PATH
source ~soft_bio_267/initializes/init_pets



mkdir -p $temp_files $output_folder


if [ "$1" == "1" ]; then
	echo 'Downloading files'
	
	wget https://stringdb-static.org/download/protein.links.v11.5/9606.protein.links.v11.5.txt.gz -O $dataset_path"/9606.protein.links.v11.5.txt.gz"
	gunzip $dataset_path'/9606.protein.links.v11.5.txt.gz'
	mv $dataset_path'/9606.protein.links.v11.5.txt' $dataset_path'/string_data.txt' # copied from original execution
	
	### File with Human GeneID codes and STRING IDs (used as dictionary)
	wget ftp://string-db.org/mapping_files/STRING_display_names/human.name_2_string.tsv.gz -O $temp_files"/human.name_2_string.tsv.gz"
    gunzip $temp_files"/human.name_2_string.tsv.gz"

    ### File with HPO phenotypes
	wget http://purl.obolibrary.org/obo/hp/hpoa/genes_to_phenotype.txt -O $temp_files"/genes_to_phenotype.txt"
	wget http://purl.obolibrary.org/obo/hp/hpoa/phenotype.hpoa -O $temp_files'/phenotype.hpoa'
	
    ### MONDO File with genes and diseases
	wget 'http://purl.obolibrary.org/obo/mondo.obo' -O $dataset_path'/mondo.obo'
	wget 'https://data.monarchinitiative.org/tsv/all_associations/gene_disease.all.tsv.gz' -O $dataset_path'/gene_disease.all.tsv.gz'
	gunzip $dataset_path'/gene_disease.all.tsv.gz'
fi

if [ "$1" == "1b" ]; then
	echo 'preparing files'
	
	ontology_file=$dataset_path'/mondo.obo'
	mondo_file=$dataset_path'/gene_disease.all.tsv'
	string_network=$dataset_path'/string_data.txt'

	grep -v '#' $temp_files/phenotype.hpoa | grep -v -w 'NOT' | cut -f 1,2,4 > $temp_files/dis_name_phen.txt
	echo -e "DiseaseID\tHPOID" > $temp_files/disease_hpos.txt
	grep -w -F -f $orpha_codes $temp_files/dis_name_phen.txt | cut -f 1,3 | sort -u | aggregate_column_data.rb -i - -s '|' -x 0 -a 1 >> $temp_files/disease_hpos.txt
	grep -w -F -f $orpha_codes $temp_files/genes_to_phenotype.txt | cut -f 3,2,9 | sort -u > $temp_files/genes_hpo_disease.txt
	parse_genes_hpo_disease.rb -i $temp_files/genes_hpo_disease.txt -g $temp_files/disease_genes.txt
	get_disease_mondo.rb -i $orpha_codes -k 'Orphanet:[0-9]*|OMIM:[0-9]*' -f $ontology_file -o $temp_files/disease_mondo_codes.txt
	get_mondo_genes.rb -i $temp_files/disease_mondo_codes.txt -m $mondo_file -o $temp_files/disease_mondo_genes.txt
	cut -f 1,3 $temp_files/disease_mondo_genes.txt > $temp_files/disease_genes.txt
	trad_cluster_stringtogen.rb -i $string_network -d $temp_files"/human.name_2_string.tsv" -o temp_files/string_transl_network.txt -n temp_files/untranslated_genes.txt 
fi


if [ "$1" == "2" ]; then
	source ~soft_bio_267/initializes/init_autoflow
	echo 'Launching analysis'
	gene_filter_values=( 0 )
	combined_score_filts=( 900 )
	similarity_measures=( 'lin' 'resnik' 'jiang_conrath' )
	min_groups=( 0 )
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
					\\$hub_zscore=3,
					\\$string_dict=$temp_files/human.name_2_string.tsv,
					\\$combined_score=$combined_score,
					\\$min_group=$min_group,
					\\$gene_filter=$gene_filter_value,
					\\$disease_gene_file=$temp_files/disease_genes.txt,
					\\$phenotype_annotation=$temp_files'/dis_name_phen.txt',
					\\$disease_mondo_genes=$temp_files/disease_mondo_genes.txt,
					\\$disease_hpo_file=$temp_files/disease_hpos.txt,
					\\$scripts_path=$scripts_path" | tr -d '[:space:]' `
					AutoFlow -w templates/aRD_analysis.txt -t '7-00:00:00' -m '100gb' -c 4 -o $output_folder"/"$execution_name -n 'sd' -e -V $var_info $2
				done
			done
		done
	done
fi


if [ "$1" == "3" ]; then
	. ~soft_bio_267/initializes/init_R
	mkdir -p ../similarity_matrix/matrices
	cd ../similarity_matrix/matrices
	ln -s ../../executions/aRD_workflow/jiang_conrath_0_900_0/coPatReporter.rb_0000/temp/similarity_matrix_jiang_conrath.npy jiang_conrath
	ln -s ../../executions/aRD_workflow/lin_0_900_0/coPatReporter.rb_0000/temp/similarity_matrix_lin.npy lin
	ln -s ../../executions/aRD_workflow/resnik_0_900_0/coPatReporter.rb_0000/temp/similarity_matrix_resnik.npy resnik 
	cd ..
	correlate_matrices.R -d 'matrices/*' -o ./	

fi