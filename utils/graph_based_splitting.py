from argparse import ArgumentParser
import matplotlib.pyplot as plt
import re
from tqdm import tqdm
from copy import deepcopy
import networkx as nx
from collections import Counter
from collections import OrderedDict
import pandas as pd
import numpy as np
import os 
from pathlib import Path

parser = ArgumentParser()
parser.add_argument("--thermo_domains", help="Alignment Results for the domains", type=str)
parser.add_argument("--thermo_sequences", help="Alignment Results for the sequences", type=str)
parser.add_argument("--classifier_dataset",help="Classifier Dataset",type=str)
parser.add_argument("--output",help="Define ouput directory",type=str)
parser.add_argument("--ratio",help="The splitting ratio (0,1)",type=float,default=0.7)
parser.add_argument("--threshold",help="Minimum cluster size that will directly go to training set", type=int,default=7)
parser.add_argument("--mode",help="0: for Meso and 1: for Thermo")
args = parser.parse_args()

thermo_seq = pd.read_csv(args.thermo_sequences, sep="\t", names=["CentroidID", "SeqID"])
thermo_domains = pd.read_csv(args.thermo_domains, sep="\t", names=["DomainCentroidID", "DomainID"])

dataset = pd.read_csv(args.classifier_dataset,header=None)
dataset_seq = dict(zip(dataset[0],dataset[1]))

thermo_seq = thermo_seq[ (thermo_seq.CentroidID.isin(dataset[0])) & (thermo_seq.SeqID.isin(dataset[0])) ]
thermo_domains = thermo_domains[ (thermo_domains.DomainCentroidID.isin(dataset[0])) & (thermo_domains.DomainID.isin(dataset[0])) ]

Path(args.output + "/redundant").mkdir(parents=True, exist_ok=True)
Path(args.output + "/non_redundant").mkdir(parents=True, exist_ok=True)

def extract_singleton(df):
    v = df.CentroidID.value_counts()
    return df[df.CentroidID.isin(v.index[v.eq(1)])]

def build_seq_graph(df_seq):
    G = nx.Graph()
    G.add_nodes_from(df_seq['SeqID'].tolist())
    attrs = {}
    for i,s in tqdm(df_seq.iterrows(), total=len(df_seq)):
        node = s['SeqID']
        centroid = s['CentroidID']
        attrs[node] = {'centroid': centroid == node, 'domain': False}
        G.add_edge(node, centroid)
    nx.set_node_attributes(G, attrs)
    return G

def add_domain_graph(df_domain, G):
    H = G.copy()
    H.add_nodes_from(df_domain['DomainID'].tolist())
    attrs = {}
    for i,s in tqdm(df_domain.iterrows(), total=len(df_domain)):
        node = s['DomainID'] # unique domain id --> seqid__domain__start__end
        seq = s['DomainID'].split("__")[0]
        centroid = s['DomainCentroidID'].split("__")[0]
        domain_centroid = s['DomainCentroidID']
        attrs[node] = {'centroid_dom': centroid == seq, 'domain': True, 'centroid_domain': node == domain_centroid}
        H.add_edge(node, centroid)
        H.add_edge(node, seq)
    nx.set_node_attributes(H, attrs)
    return H

def keys_from_values(mydict, condition):
    return [k for k,v in mydict.items() if float(v) == condition]

def from_graph_return_info(subgraph):
    centroids = keys_from_values(nx.get_node_attributes(subgraph,"centroid"),True)
    sequences = list(nx.get_node_attributes(subgraph,"centroid").keys())
    domains_centroids = keys_from_values(nx.get_node_attributes(subgraph,"centroid_domain"),True)
    domains = keys_from_values(nx.get_node_attributes(subgraph,"domain"),True)  
    return {'centroids': centroids, 'sequences': sequences, 'domain_centroids': domains_centroids, 'domains': domains, 'size': len(sequences)}

def split_list(original_list, size):
    if size > len(original_list): return original_list, []
    np.random.seed(100)
    indeces = list(range(0,len(original_list)))
    sample_indeces = np.random.choice(indeces, size, replace=False)
    sample_list = [original_list[i] for i in sample_indeces]
    rest_indeces = list(set(indeces) - set(sample_indeces))
    rest_list = [original_list[i] for i in rest_indeces]
    return sample_list, rest_list

def non_redundant_data(set_, output_file):
    with open(output_file + "_sequences","w") as f:
        for i in set_:
            f.write("\n".join(i['centroids']))
            f.write("\n")
        f.close()
    df = pd.read_csv(output_file + "_sequences",header=None)
    df.to_csv(output_file + "_sequences",index=False,header=False)

    with open(output_file + "_domains","w") as f:
        for i in set_:
            f.write("\n".join(i['domain_centroids']))
            f.write("\n")
        f.close()
    df = pd.read_csv(output_file + "_domains",header=None)
    df.to_csv(output_file + "_domains",index=False,header=False)

def redundant_data(set_, output_file):
    with open(output_file + "_sequences","w") as f:
        for i in set_:
            f.write("\n".join(split_list(i['sequences'],min_cl_size)[0]))
            f.write("\n")
        f.close()
    df = pd.read_csv(output_file + "_sequences",header=None)
    df.to_csv(output_file + "_sequences",index=False,header=False)

    with open(output_file + "_domains","w") as f:
        for i in set_:
            f.write("\n".join(split_list(i['domains'],min_cl_size)[0]))
            f.write("\n")
        f.close()
    df = pd.read_csv(output_file + "_domains",header=None)
    df.to_csv(output_file + "_domains",index=False,header=False)

print("\nBuild the graph for the full Sequences\n")
G_seq_thermo = build_seq_graph(thermo_seq)
clusters_seq = sorted(nx.connected_components(G_seq_thermo), key = len, reverse=True)
cluster_sizes = np.array([len(c) for c in clusters_seq])

print('Number of clusters: {}'.format(len(cluster_sizes)))
print('Top 10 clusters: {}'.format(" ".join(cluster_sizes[:10].astype(str))))
print('Number of singletons: {}'.format(np.sum(cluster_sizes == 1)))
print('Number of clusters > 1 and < 20: {}'.format(np.sum(np.logical_and(cluster_sizes >1, cluster_sizes < 20))))

print("\nAdd the domains to the Graph\n")
G_full_thermo = add_domain_graph(thermo_domains, G_seq_thermo)
clusters_full = sorted(nx.connected_components(G_full_thermo), key = len, reverse=True)
cluster_full_sizes = np.array([len(c) for c in clusters_full])

print('Number of clusters: {}'.format(len(cluster_full_sizes)))
print('Top 10 clusters: {}'.format(" ".join(cluster_full_sizes[:10].astype(str))))
print('Number of singletons: {}'.format(np.sum(cluster_full_sizes == 1)))
print('Number of clusters > 1 and < 20: {}'.format(np.sum(np.logical_and(cluster_full_sizes >1, cluster_full_sizes < 20))))
print('Number of clusters w/o domains: {}'.format(np.sum(cluster_full_sizes==1)))

print("\nSplitting Process in 3 steps:")
print("\tStep 1: Split the graph into subgraphs")
info = []
S = [G_full_thermo.subgraph(c).copy() for c in nx.connected_components(G_full_thermo)]
for ind, subgraph in tqdm(enumerate(S), total=len(S)):
    info.append(from_graph_return_info(subgraph))


print("\tStep 2: Move all the big clusters into the training set")
splitting_ratio = args.ratio
min_cl_size = args.threshold
training = []
rest = []
test_size = round((1-splitting_ratio)/2 * len(S))
training_size = len(S) - (2 * test_size)
for cl in info:
    if cl['size'] >= min_cl_size:
        training.append(cl)
    else:
        rest.append(cl)

test = []
validation = []
test, rest = split_list(rest, test_size)
val, rest = split_list(rest, test_size)
training = training + rest

# Creation of Redundant Dataset
redundant_data(training, os.path.join(args.output,"redundant/ids-redundant_training"))
redundant_data(test, os.path.join(args.output,"redundant/ids-redundant_test"))
redundant_data(val, os.path.join(args.output,"redundant/ids-redundant_val"))

# Creation of Non Redundant Dataset
non_redundant_data(training, os.path.join(args.output,"non_redundant/ids-non_redundant_training"))
non_redundant_data(test, os.path.join(args.output,"non_redundant/ids-non_redundant_test"))
non_redundant_data(val, os.path.join(args.output,"non_redundant/ids-non_redundant_val"))

dataset = pd.read_csv(args.classifier_dataset,header=None)
dataset_seq = dict(zip(dataset[0],dataset[1]))

for mypath in ["non_redundant", "redundant"]:
    mypath = os.path.join(args.output,mypath)
    filenames = next(os.walk(mypath), (None, None, []))[2]
    for file in filenames:
        if "ids" in file:
            ids = pd.read_csv(os.path.join(mypath,file),header=None)
            with open(os.path.join(mypath,f"{file.split('-')[-1]}_data"), "w") as g:
                for id_ in ids[0]:
                    g.write(f"{id_},{dataset_seq[id_]},{args.mode}\n")
                g.close()
            os.remove(os.path.join(mypath,file))


print("\n\nFinal Datasets for the Thermophilic Proteins:\n")
print("\nNon Redundant Domains Dataset:")
os.system(f"wc -l {args.output}/non_redundant/*_domains_data")
print("\nNon Redundat Sequences Dataset:")
os.system(f"wc -l {args.output}/non_redundant/*_sequences_data")

print("\nRedundant Domains Dataset:")
os.system(f"wc -l {args.output}/redundant/*_domains_data")
print("\nRedundatn Sequences Dataset:")
os.system(f"wc -l {args.output}/redundant/*_sequences_data")
