
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
bash create_env.sh conda_environment_name install_dir_mmseqs install_dir_hmmer
```
