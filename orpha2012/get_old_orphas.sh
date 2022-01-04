#! /usr/bin/env bash

current=`pwd`
global_path=$current/..
dataset_path=$global_path'/datasets'

intersect_columns.rb -a orphas_2012.txt -b get_inactive_codes/inactive_codes -k a | tail -n +2 | awk '{print "ORPHA:" $0}' > $dataset_path/orphas_2012.txt
