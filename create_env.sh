#!/bin/bash

################ Inputs ################
# 1 --> Name of the conda environment to create
# 2 --> Name of the path to install hmmer
# 3 --> Name of the path to install mmseqs

# Check inputs
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <env_name> <hmmer_install_path> <mmseqs_install_path>"
  exit 1
fi

ENV_NAME="$1"
HMMER_DIR="$2"
MMSEQS_DIR="$3"

# Create and activate conda environment
conda create -n "$ENV_NAME" python=3.13 -y
source $(conda info --base)/etc/profile.d/conda.sh
conda activate "$ENV_NAME"
# Install Python packages
conda install conda-forge::biopython
pip install tqdm pandas networkx matplotlib

# Install MMseqs2
mkdir -p "$MMSEQS_DIR"
wget https://mmseqs.com/latest/mmseqs-linux-avx2.tar.gz -O mmseqs.tar.gz
tar xvfz mmseqs.tar.gz -C "$MMSEQS_DIR"
export PATH="$MMSEQS_DIR/mmseqs/bin:$PATH"


# Install HMMER
wget http://eddylab.org/software/hmmer/hmmer.tar.gz
tar zxf hmmer.tar.gz
cd hmmer-3.3.2
./configure --prefix="$HMMER_DIR"
make -j$(nproc)
make check
make install
