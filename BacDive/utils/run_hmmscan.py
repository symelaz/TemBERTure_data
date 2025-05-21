import os 
from multiprocessing import Pool
from tqdm import tqdm
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument("--input_folder", help="The folder where all the fasta files are saved", type=str)
parser.add_argument("--prefix", help="Prefix for all the output folders of the experiment", type=str)
parser.add_argument("--n_jobs", help="The number of workers for the hmmscan code", type=int)
parser.add_argument("--hmmer", help="Path for hmmer script", type=str)
parser.add_argument("--pfam_db", help="Path for pfam database (Pfam-A.hmm)", type=str)
args = parser.parse_args()

filenames = next(os.walk(args.input_folder), (None, None, []))[2]
Path(f"{args.prefix}_out").mkdir(parents=True, exist_ok=True)
Path(f"{args.prefix}_log").mkdir(parents=True, exist_ok=True)

def run_domains(input):
    com = f"{args.hmmer}/hmmscan --domtblout {args.prefix}_out/{input}.out  --cut_ga --cpu 1 {args.pfam_db}/Pfam-A.hmm {args.input_folder}/{input} > {args.prefix}_log/{input}.log"
    os.system(com)

with Pool(processes = args.n_jobs) as p:
    max_ = len(filenames)
    with tqdm (total=max_) as pbar:
        for _ in p.imap_unordered(run_domains,filenames):
                    pbar.update()
