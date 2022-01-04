#! /usr/bin/env bash
. ~soft_bio_267/initializes/init_ruby
wget http://www.orphadata.org/data/RD-CODE/Packs/Orphanet_Nomenclature_Pack_EN.zip
unzip Orphanet_Nomenclature_Pack_EN.zip
./get_inactive.rb -i Orphanet_Nomenclature_Pack_EN/ORPHAnomenclature_en.xml > inactive_codes
