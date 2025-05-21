################ Inputs ################
# 1 --> Name of the conda environment to create
# 2 --> Name of the path to install hmmer
# 3 --> Name of the path to install mmseqs

conda create -n DATASET
conda activate DATASET

conda install conda-forge::biopython
pip install tqdm pandas networkx matplotlib

# Installing mmseqs from source 
wget https://mmseqs.com/latest/mmseqs-linux-avx2.tar.gz -O $3
tar xvfz $3/mmseqs-linux-avx2.tar.gz
export PATH=$3/mmseqs/bin/:$PATH

# Installing hmmer
wget http://eddylab.org/software/hmmer/hmmer.tar.gz 
tar zxf hmmer.tar.gz
cd hmmer-3.3.2
./configure --prefix $2
make
make check
make install

