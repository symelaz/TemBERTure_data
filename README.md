
---

# 🧬 TemBERTure: Protein Thermostability Dataset Creation Pipeline

This repository contains a **reproducible pipeline** to generate machine learning-ready datasets for classifying and studying **thermophilic vs. mesophilic proteins**. The core script, `main.sh`, handles **balancing**, **fragmentation**, **clustering**, and **intelligent splitting** of input sequences.

---

## 🚀 Getting Started

### 🔧 Requirements

* [Conda](https://docs.conda.io)
* Python ≥ 3.8
* Tools installed in the script:

  * `mmseqs2` (for protein sequence clustering/comparison)
  * `hmmer` (for splitting in domains)
 
### 🔧 How to install

Just run 
```bash
bash create_env.sh conda_environment_name /path/to/install/mmseqs /path/to/install/hmmer /path/to/install/Pfam/database /path/to/install/Pfam/database
```

### 🔧 How to use
Just run
```bash
bash main.sh \
               THERMO.fasta \ # Fasta file of the thermophilic sequences
               MESO.fasta\ # Fasta file of the mesophilic sequences
               /path/to/install/mmseqs/bin \ 
               /path/to/install/hmmer/src \
               /path/to/install/Pfam/database \
               n_jobs \ # Number of cpus available
               splitting_type \  # 1 --> random fragments, 2 --> domains, 3 --> domains from sequences containing exclusively one domain
               splitting_ratio \ # ratio for splitting (e.g. splitting_ratio=0.8 --> 0.8 [training], 0.1 [validation], 0.1 [test] 
               number_of_clusters \ # Number of the biggest clusters to automatically be moved to the training set. 
```
