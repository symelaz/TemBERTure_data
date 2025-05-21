---

# 🧬 TemBERTure: Protein Thermostability Dataset Creation Pipeline

TemBERTure is a **comprehensive and reproducible pipeline** for building machine learning-ready datasets focused on **protein thermostability classification**. It distinguishes **thermophilic** and **mesophilic** proteins and enables flexible **fragmentation**, **domain-based extraction**, **clustering**, and **intelligent dataset splitting**.

The pipeline is especially suited for training **transformer-based models** or other protein-specific deep learning frameworks. It was developed as part of the research for the **TemBERTure** study.

---

## 🚀 Features

* ✅ Balancing of thermophilic and mesophilic input sequences
* 🔬 Domain-aware fragmentation using Pfam and HMMER
* 🔗 Sequence clustering using MMseqs2
* 🧠 Graph-based dataset splitting to reduce redundancy and information leakage
* 📦 Final output includes both sequence-level and domain-level datasets (train/val/test)

---

## 🔧 Requirements

* [Conda](https://docs.conda.io)
* Python ≥ 3.8
* Tools installed via script or manually:

  * [`mmseqs2`](https://github.com/soedinglab/MMseqs2) – for sequence clustering
  * [`hmmer`](http://hmmer.org/) – for identifying Pfam domains
  * [`Pfam database`](https://ftp.ebi.ac.uk/pub/databases/Pfam/releases/) – for domain annotation

---

## ⚙️ Installation

You can create and configure the necessary environment with:

```bash
bash create_env.sh conda_environment_name /path/to/install/mmseqs /path/to/install/hmmer
```

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

## 📖 Related Publication

This dataset was used in the study:

**TemBERTure: advancing protein thermostability prediction with deep learning and attention mechanisms**
*Authors:* Chiara Rodella, Symela Lazaridi, and Thomas Lemmin
*Journal/Conference:* Bioinformatics Advances 2024
*Doi:* 10.1093/bioadv/vbae103


```bibtex
@article{10.1093/bioadv/vbae103,
    author = {Rodella, Chiara and Lazaridi, Symela and Lemmin, Thomas},
    title = {TemBERTure: advancing protein thermostability prediction with deep learning and attention mechanisms},
    journal = {Bioinformatics Advances},
    volume = {4},
    number = {1},
    pages = {vbae103},
    year = {2024},
    month = {07},
    issn = {2635-0041},
    doi = {10.1093/bioadv/vbae103},
    url = {https://doi.org/10.1093/bioadv/vbae103},
    eprint = {https://academic.oup.com/bioinformaticsadvances/article-pdf/4/1/vbae103/58610069/vbae103.pdf},
}



```

---

## 🤝 Contributing

Contributions, issues, and suggestions are welcome. Please open an issue or submit a pull request.

---

## 📜 License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

---
