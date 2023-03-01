#! /usr/bin/env python

import networkx as nx
import networkx.convert 
import numpy
from scipy import stats
import random
import time
from operator import itemgetter
import sys
import os
import multiprocessing
from joblib import Parallel, delayed

start_time = time.time()
########Initializing graph with nodes and edges########
def initialize(networkX_obj, pairs_file):
	mylist = []
	file2 = open(pairs_file) #Adding edges
	for line1 in file2:
		line2 = line1.rstrip("\n")
		line3 = line2.split("\t")
		try:
			t = (line3[0], line3[1], 1/(float(line3[2])/1000))
		except:
			0
		mylist.append(t)
	file2.close()
	networkX_obj.add_weighted_edges_from(mylist)

def get_gene_list(gene_file):
	gene_list = []
	file = open(gene_file) #Adding edges
	for line in file:
		name = line.rstrip("\n")
		gene_list.append(name)
	return gene_list

########Saving and plotting graphs########
def get_route(source, target, paths, G):
	counter = 0
	path = paths[target]
	#print path
	temp_str = ""
	for i in path:	
		if (counter == 0):
			temp_str = str(i)
		if (counter > 0):
			weight = G[j][i]['weight']
			#weight = G.edge[j][i]['weight']
			t = (j, i, weight)
			temp_str = temp_str + "[" +  str(weight) + "]" + str(i) 
		counter = counter + 1
		j = i
	return temp_str, (counter - 1)
	
########P-value for distance########
def p_value(length):
	counter = 0
	p_count = 0
	for i in target_random_array:
		#print str(i) + "\t" + str(length)
		if (i <= length):
			p_count = p_count + 1
		counter = counter + 1
	p_val = float(p_count) / float(counter)
	return p_val 

########Array of target p-values########
def target_p_val_array():
	random_sample1 = random.sample(nodes_list, sample_size) #A list of random genes
	random_sample2 = random.sample(nodes_list, sample_size) 
	counter = 0
	max_val = 0
	for i in random_sample1:
		try: 
			temp_length = nx.dijkstra_path_length(G, random_sample1[counter], random_sample2[counter])
			target_random_array[counter] = temp_length
			if temp_length > max_val:
				max_val = temp_length
		except: #Infinite distance - cannot connect two genes
			target_random_array[counter] = 999999999
		counter = counter + 1
	counter = 0
	#print "maximum value: " + str(max_val)
	for j in target_random_array:
		if (target_random_array[counter] == 999999999):
			target_random_array[counter] = max_val * 2
		counter = counter + 1

########Finding average and median########	
def median_average(dist_list):
	counter = 0
	for item in dist_list:
		counter = counter + 1
	dist_array1 = numpy.zeros((counter),int)
	i = 0
	upper_val = 0
	for item in dist_list:
		dist_array1[i] = item[1]
		if ( (upper_val < dist_array1[i]) and (dist_array1[i] < 999999999) ):
			upper_val = dist_array1[i] #Given unconnect the maximum value for averaging
		i = i + 1
	j = 0
	while (j < counter):
		if (dist_array1[j] > upper_val):
			dist_array1[j] = upper_val
		j = j + 1
	median = numpy.median(dist_array1)
	average = numpy.average(dist_array1)
	return median, average


def ranking(num_genes, src, output_path, dist_list):
	i = 0
	file_name = os.path.join(output_path, src + ".txt")
	file44 = open(file_name, 'w')
	aaa=sorted(dist_list, key=itemgetter(1))
	med_avg = median_average(dist_list)
	median = med_avg[0]
	average = med_avg[1]
	header1 = header1 = "Target\tDistance\tRank\tP-value(percentile)\tMedian_ratio\tAverage_ratio\tSphere\tRoute\tDegree_connectivity\n"
	file44.write(header1)
	sphere = 999
	for item in aaa:
		percentile = float(i) / num_genes
		if (percentile < 0.001):
			sphere = 0
		elif (percentile < 0.01):
			sphere = 1
		elif (percentile < 0.05):
			sphere = 2
		elif (percentile < 0.1):
			sphere = 3
		elif (percentile < 0.25):
			sphere = 4
		elif (percentile < 0.5):
			sphere = 5
		elif (percentile < 0.75):
			sphere = 6
		elif (percentile >= 0.75):
			sphere = 7
		med_ratio = float(item[1]) / float(median)
		avg_ratio = float(item[1]) / float(average)
		sphere_str = str(item[0]) + "\t" +str(item[1]) + "\t" + str(i) + "\t" + str(percentile) + "\t"  + str(med_ratio) + "\t" + str(avg_ratio) + "\t" + str(sphere) + "\t" + str(item[2]) + "\t" + str(item[3]) + "\n" #Target gene, scaled length, percentile, sphere, route, degree of connectivity
		#print sphere_str
		file44.write(sphere_str)
		i = i + 1
	file44.close()

def process_gene(src1, G):
	if(not G.has_node(src1)):
		print(src1 + ' node id not exists in network' +'\n')
	else:
		paths = nx.single_source_dijkstra_path(G, src1)
		lengths = nx.single_source_dijkstra_path_length(G, src1)
		dist_list = []
		for tar1 in lengths:
			length = lengths[tar1]
			route_str = get_route(src1, tar1, paths, G)
			length = length*route_str[1]
			to_add = [tar1, length, route_str[0], route_str[1]]
			dist_list.append(to_add)
			#dist_str = src1 + "\t" + tar1 + "\t" + str(length) + "\t" + str(route_str[0]) + "\t" + str(route_str[1]) 
			#time_now = time.time() - start_time
			#print str(counter) + "\t" + dist_str + "\t" + str(time_now)

		ranking(number_of_nodes, src1, output_path, dist_list)

###########Main program#########

pair_file  = sys.argv[1]
genes = sys.argv[2]
output_path = sys.argv[3]
if(len(sys.argv) == 4):
	cpu = 1
elif(len(sys.argv) == 5): 
	cpu = int(sys.argv[4])

if(not os.path.exists(output_path)):
	os.mkdir(output_path)

G = nx.Graph() #Create graph object
initialize(G, pair_file) #Initialize graph
number_of_nodes = G.number_of_nodes()

if(genes == 'all'):
	genes = G.nodes() 
else:
	genes = get_gene_list(genes)

Parallel(n_jobs=cpu)(delayed(process_gene)(i, G) for i in genes)
    