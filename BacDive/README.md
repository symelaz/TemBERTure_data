---

# 🧬 TemBERTure: BacDive dataset

This is a **comprehensive and reproducible pipeline** for building the BacDive dataset focused on **protein thermostability classification**. It distinguishes **thermophilic** and **mesophilic** proteins and enables flexible **fragmentation**, **domain-based extraction**, **clustering**, and **intelligent dataset splitting**.

---

## 🚀 Features

* ✅ Balancing of thermophilic and mesophilic input sequences
* 🔬 Domain-aware fragmentation using Pfam and HMMER
* 🔗 Sequence clustering using MMseqs2
* 🧠 Graph-based dataset splitting to reduce redundancy and information leakage
* 📦 Final output includes both sequence-level and domain-level datasets (train/val/test)

---

## 📌 Usage

```bash
bash main.sh \
    THERMO.fasta \               # Fasta file with thermophilic sequences
    MESO.fasta \                 # Fasta file with mesophilic sequences
    /path/to/mmseqs/bin \       # Path to mmseqs binaries
    /path/to/hmmer/src \        # Path to HMMER binaries
    /path/to/pfam/database \    # Path to Pfam-A.hmm and Pfam database
    n_jobs \                    # Number of CPUs to use
    splitting_mode \            # 1=random fragments, 2=domains, 3=single-domain sequences
    splitting_ratio \           # Ratio for train/test/val (e.g., 0.8)
    n_top_clusters              # Number of top clusters to pre-assign to training
```

---

## 📁 Output Structure

* `BALANCING/` – Balanced input sequences
* `FRAGMENTATION/` – Fragmented or domain-split sequences
* `CLUSTER/` – Clustering outputs per class
* `SPLIT/` – Train/val/test sets per class
* `FINAL_DATASET/` – Merged datasets: redundant & non-redundant, sequence- and domain-level
* `SANITY_CHECK/` – Verifies that validation/test splits are non-overlapping

---
