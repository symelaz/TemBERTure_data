################ Inputs ################
# 1 --> Name of the conda environment to create
# 2 --> 

conda create -n DATASET
conda activate DATASET

conda install conda-forge::biopython
pip install tqdm pandas networkx matplotlib

# Installing mmseqs from source 
wget https://mmseqs.com/latest/mmseqs-linux-avx2.tar.gz
tar xvfz mmseqs-linux-avx2.tar.gz
export PATH=$(pwd)/mmseqs/bin/:$PATH

# Installing hmmer
wget http://eddylab.org/software/hmmer/hmmer.tar.gz 
tar zxf hmmer.tar.gz
cd hmmer-3.3.2
./configure --prefix /your/install/path
make
make check
make install

