#!/bin/bash

############################ Inputs ############################
# $1 --> Sequences of the THERMOPHILIC proteins in fasta format
# $2 --> Sequences of the MESOPHILIC proteins in fasta format 
# $3 --> Output Folder 
# $4 --> Folder for mmseqs code 

secs_to_human() {
        echo ""
        echo "Elapsed Time: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}

echo "#######################################################################################################################"
echo "######################################## START THE BALANCING OF THE INPUT DATA ########################################"
echo "#######################################################################################################################"
echo ""

mkdir -p $3/THERMO_CASCADED_CLUSTER
mkdir -p $3/MESO_CASCADED_CLUSTER

echo "Cluster the THERMO Proteins"
sed -i 's/|/.../g' $1
$4/mmseqs easy-cluster $1 $3/THERMO_CASCADED_CLUSTER/THERMO tmp --cluster-reassign > $3/THERMO_CASCADED_CLUSTER/log
echo "Number of Sequences in the THERMOPHILIC dataset: $(grep ">" $1|wc -l)"
echo "Number of Clusters in the THERMOPHILIC dataset: $(grep ">" $3/THERMO_CASCADED_CLUSTER/THERMO_rep_seq.fasta| wc -l)"
echo "Convert THERMO fasta dataset into classifier dataset format"
grep ">" $1 | awk -F">" '{print$2}'| awk -F' ' '{print$1}' >ids
grep -v ">" $1 > sequences
awk -v OFS=',' 'FNR==NR{a[++i]=$0; next} {print a[FNR], $0 ,1}' ids sequences > thermo_centroids
rm ids sequences
echo ""

echo "Cluster the MESO Proteins"
sed -i 's/|/.../g' $2
$4/mmseqs easy-cluster $2 $3/MESO_CASCADED_CLUSTER/MESO tmp --cluster-reassign > $3/MESO_CASCADED_CLUSTER/log
echo "Number of Sequences in the MESOPHILIC dataset: $(grep ">" $2|wc -l)"
echo "Number of Clusters in the MESOPHILIC dataset: $(grep ">" $3/MESO_CASCADED_CLUSTER/MESO_rep_seq.fasta| wc -l)"
echo "Convert the MESO centroid fasta dataset into classifier dataset format"
grep ">" $3/MESO_CASCADED_CLUSTER/MESO_rep_seq.fasta| awk -F">" '{print$2}'| awk -F' ' '{print$1}' >ids
grep -v ">" $3/MESO_CASCADED_CLUSTER/MESO_rep_seq.fasta > sequences
awk -v OFS=',' 'FNR==NR{a[++i]=$0; next} {print a[FNR], $0 ,0}' ids sequences > meso_centroids
rm ids sequences
echo ""

bash utils/shuffle.sh meso_centroids $(grep ">" $1|wc -l) > meso_centroids_selected
mv meso_centroids_selected meso_centroids
cat meso_centroids thermo_centroids > CLASSIFIER_dataset
rm meso_centroids thermo_centroids

echo "The final dataset is saved under the path $(pwd)/CLASSIFIER_dataset"
echo "# THERMOPHILIC proteins in the final dataset: $(grep ",1" CLASSIFIER_dataset|wc -l)"
echo "# MESOPHILIC proteins in the final dataset: $(grep ",0" CLASSIFIER_dataset|wc -l)"
echo ""
echo "Command: bash balancing.sh $1 $2 $3 $4"
secs_to_human "$SECONDS"

echo "################################################## END OF BALANCING ###################################################"
echo ""
