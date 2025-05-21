import pandas as pd
from tqdm import tqdm 
import re
from argparse import ArgumentParser
from multiprocessing import Pool
import os
import numpy as np
from pathlib import Path

parser = ArgumentParser()


parser.add_argument("--input_dataset", help="dataset for the classifier", type=str)
parser.add_argument("--input_domains", help="domains folder of the dataset", type=str)
parser.add_argument("--output", help="Specify the name of the output folder", type=str)
parser.add_argument("--mode", help="1 for adding random noise around the domains, 2 for retrieving only single domain sequences, 3 for retrieving pure domains only", type=int)
parser.add_argument("--filter", help="Specify the length to filter the sequences", type=int)
parser.add_argument("--n_jobs", help="The number of workers for the hmmscan code", type=int)
args = parser.parse_args()

Path(args.output).mkdir(parents=True, exist_ok=True)
input_dataset = pd.read_csv(args.input_dataset,header=None)
input_dataset.columns = ['Protein_ID', 'Sequence', 'Type']


def DomainsOutput_to_pandas(file_name):

    ##### Describe Pandas Output #####
    # Column 0: Domain Name
    # Column 1: Domain ID
    # Column 2: Domain Length
    # Column 3: Query Protein ID
    # Column 5: Query Protein Length
    # Column 19: Start of Domain Matching in Query Protein
    # Column 20: End of Domain Matching in Query Protein
	    
    with open(file_name) as f: content = f.readlines()
    content = content[3:-10]
    if content:
        splitted = [re.split(" ",line) for line in content]
        filtered = [list(filter(None, element)) for element in splitted]
        return pd.DataFrame(filtered)
    else:
        return -1

def left_extension(start_, end_, sequence_len, extension_len):
    if extension_len > start_:
        end_ += extension_len - start_
        start_ = 0
    else:
        start_ = start_ - extension_len
    return start_, end_

def right_extension(start_, end_, sequence_len, extension_len):
    if extension_len > sequence_len - end_ -1:
        start_ = start_ - (extension_len - (sequence_len - end_ -1) )
        end_ = sequence_len - 1 
    else:
        end_ += extension_len
    return start_, end_

def process_domains_with_noise(file_name):
    noise_level = 0.2 #Maximum noise level --> percentage of the domain length
    data = DomainsOutput_to_pandas(file_name)
    if isinstance(data, int):
        return
    query = data[3].unique()[0]
    query_len = int(data[5].unique()[0])
    query_seq = input_dataset.Sequence[input_dataset.Protein_ID == query].values[0]
    query_type = input_dataset.Type[input_dataset.Protein_ID == query].values[0]
    with open(f"{args.output}/cl_{query}", "w") as f:
        for ind in range(len(data)):
            start_= int(data.at[ind,19]) -1 
            end_ = int(data.at[ind,20]) -1
            domain_len = end_ - start_ + 1
            if domain_len > args.filter:
                domain_seq = query_seq[start_:end_+1]
                domain_id = data.at[ind,1]
                noisy_sequence_length = int((query_len - domain_len) * np.random.normal(0, 0.33))
                if noisy_sequence_length > noise_level * domain_len:
                    noisy_sequence_length = int(noise_level * domain_len)
                elif noisy_sequence_length < -noise_level * domain_len:
                    noisy_sequence_length = -int(noise_level * domain_len)                
                if noisy_sequence_length < 0: #Add noise to the left
                    start_, end_ = left_extension(start_, end_, query_len, abs(noisy_sequence_length))
                elif noisy_sequence_length >= 0: #Add noise to the right
                    start_, end_ = right_extension(start_, end_, query_len, abs(noisy_sequence_length))
                noisy_domain_seq = query_seq[start_:end_+1]
                f.write(f"{query}__{domain_id}__{start_}__{end_},{noisy_domain_seq},{query_type}\n")
                print(f"Additive Noise: {tuple((abs(noisy_sequence_length)/query_len, query_len))}")     
        f.close()

if args.mode ==1:
    filenames = f"{args.input_domains}/" + pd.DataFrame(next(os.walk(args.input_domains), (None, None, []))[2])

    with Pool(processes = args.n_jobs) as p:
        max_ = len(filenames[0])
        with tqdm (total=max_) as pbar:
            for _ in p.imap_unordered(process_domains_with_noise,filenames[0]):
                pbar.update()

def single_domain_sequences(file_name):
    data = DomainsOutput_to_pandas(file_name)
    if isinstance(data, int):
        return
    data["Length"] = data[20].astype(int) - data[19].astype(int)
    data = data[data.Length>args.filter]
    if len(data)==1:
        query = data[3].unique()[0]
        query_seq = input_dataset.Sequence[input_dataset.Protein_ID == query].values[0]
        query_type = input_dataset.Type[input_dataset.Protein_ID == query].values[0]
        with open(f"{args.output}/cl_{query}", "w") as f:
            start_= data[19].astype(int).values[0]
            end_ = data[20].astype(int).values[0]
            domain_seq = query_seq[start_:end_+1]
            domain_id = data[1].values[0]
            f.write(f"{query}__{domain_id}__{start_},{domain_seq},{query_type}\n")

if args.mode == 2:
    filenames = f"{args.input_domains}/" + pd.DataFrame(next(os.walk(args.input_domains), (None, None, []))[2])    
    with Pool(processes = args.n_jobs) as p:
        max_ = len(filenames[0])
        with tqdm (total=max_) as pbar:
            for _ in p.imap_unordered(single_domain_sequences,filenames[0]):
                pbar.update()



def process_pure_domains(file_name):
    data = DomainsOutput_to_pandas(file_name)
    if isinstance(data, int):
        return
    query = data[3].unique()[0]
    query_len = int(data[5].unique()[0])
    query_seq = input_dataset.Sequence[input_dataset.Protein_ID == query].values[0]
    query_type = input_dataset.Type[input_dataset.Protein_ID == query].values[0]
    with open(f"{args.output}/cl_{query}", "w") as f:
        for ind in range(len(data)):
            start_= int(data.at[ind,19])
            end_ = int(data.at[ind,20])
            domain_len = end_ - start_ + 1
            if domain_len > args.filter:
                domain_seq = query_seq[start_:end_+1]
                domain_id = data.at[ind,1]
                f.write(f"{query}__{domain_id}__{start_}__{end_},{domain_seq},{query_type}\n")
        f.close()


if args.mode == 3:
    filenames = f"{args.input_domains}/" + pd.DataFrame(next(os.walk(args.input_domains), (None, None, []))[2])
    with Pool(processes = args.n_jobs) as p:
        max_ = len(filenames[0])
        with tqdm (total=max_) as pbar:
            for _ in p.imap_unordered(process_pure_domains,filenames[0]):
                pbar.update()
