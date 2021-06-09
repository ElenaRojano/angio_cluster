#! /usr/bin/env bash

#ORPHA data imported from /mnt/home/users/bio_267_uma/rpagano/proyectos/angiogenesis/disease_hpo_analysis/datos

orpha_codes=aRD_orpha_codes.txt
wget http://purl.obolibrary.org/obo/hp/hpoa/genes_to_phenotype.txt
grep -w -F -f $orpha_codes.txt genes_to_phenotype.txt | cut -f 3,2,9 | sort -u > genes_hpo_orpha.txt