#!/bin/bash

############################ Inputs ############################
#$1 --> Input Dataset Classifier Format
#$2 --> Splitting Percentage
#$3 --> Path for mmseqs: data/lazars/mmseqs/bin/mmseqs
#$4 --> Output Folder

echo "#######################################################################################################################"
echo "################################ START SPLITTING INTO VALIDATION TRAINING AND TEST SETS ###############################"
echo "#######################################################################################################################"

secs_to_human() {
	echo ""
	echo "Elapsed Time: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}

SECONDS=0
cwd=$(pwd)

mkdir -p tmp

dataset_size=$(wc -l $1| awk -F' ' '{print$1}')
echo "Dataset Size $dataset_size"

mkdir -p $4/MESO_CASCADED_CLUSTER
mkdir -p $4/THERMO_CASCADED_CLUSTER

grep ",0" $1 | awk -F',' '{printf ">%s\n%s\n", $1,$2}' > $4/MESO_CASCADED_CLUSTER/MESO_fasta
grep ",1" $1 | awk -F',' '{printf ">%s\n%s\n", $1,$2}' > $4/THERMO_CASCADED_CLUSTER/THERMO_fasta


for i in 'MESO' 'THERMO'
do
	echo ""
	echo "Clustering $i Proteins"
	$3/mmseqs easy-cluster $4/$i"_CASCADED_CLUSTER/"$i"_fasta" $4/$i"_CASCADED_CLUSTER/"$i tmp --cluster-reassign > log
		
	echo "Running python splitting code"
	python utils/splitting_optimization.py --lookup $4/$i"_CASCADED_CLUSTER"/$i"_cluster.tsv" --splitting $2 --output tmp/cluster_20_ids --mode 2
	
	grep -Fwf tmp/cluster_20_ids $4/$i"_CASCADED_CLUSTER"/$i"_cluster.tsv" > tmp/cluster_20
	grep -v -Fwf tmp/cluster_20_ids $4/$i"_CASCADED_CLUSTER"/$i"_cluster.tsv" > tmp/cluster_80

	
        awk -F"\t" '{print$2}' tmp/cluster_80 | grep "__"  > tmp/cluster_80_ids_fragments_redundant
        awk -F"\t" '{print$2}' tmp/cluster_80 | grep -v "__"  > tmp/cluster_80_ids_full_sequences_redundant
        
        grep -Fwf tmp/cluster_80_ids_fragments_redundant $1 > $4/$i"_TRAIN_fragments_redundant"
        grep -Fwf tmp/cluster_80_ids_full_sequences_redundant $1 > $4/$i"_TRAIN_full_sequences_redundant"

	awk -F"\t" '{print$1}' tmp/cluster_80 | grep "__"  > tmp/cluster_80_ids_fragments_non_redundant
        awk -F"\t" '{print$1}' tmp/cluster_80 | grep -v "__"  > tmp/cluster_80_ids_full_sequences_non_redundant

        grep -Fwf tmp/cluster_80_ids_fragments_non_redundant $1 > $4/$i"_TRAIN_fragments_non_redundant"
        grep -Fwf tmp/cluster_80_ids_full_sequences_non_redundant $1 > $4/$i"_TRAIN_full_sequences_non_redundant"
	
	python utils/splitting_optimization.py --lookup tmp/cluster_20 --splitting 50 --output tmp/cluster_test_ids --mode 2

        grep -Fwf tmp/cluster_test_ids tmp/cluster_20 > tmp/cluster_test
        grep -v -Fwf tmp/cluster_test_ids tmp/cluster_20 > tmp/cluster_val

        awk -F"\t" '{print$2}' tmp/cluster_test | grep "__"  > tmp/cluster_test_ids_fragments_redundant
        awk -F"\t" '{print$2}' tmp/cluster_test | grep -v "__"  > tmp/cluster_test_ids_full_sequences_redundant

        grep -Fwf tmp/cluster_test_ids_fragments_redundant $1 > $4/$i"_TEST_fragments_redundant"
        grep -Fwf tmp/cluster_test_ids_full_sequences_redundant $1 > $4/$i"_TEST_full_sequences_redundant"

        awk -F"\t" '{print$1}' tmp/cluster_test | grep "__"  > tmp/cluster_test_ids_fragments_non_redundant
        awk -F"\t" '{print$1}' tmp/cluster_test | grep -v "__"  > tmp/cluster_test_ids_full_sequences_non_redundant

        grep -Fwf tmp/cluster_test_ids_fragments_non_redundant $1 > $4/$i"_TEST_fragments_non_redundant"
        grep -Fwf tmp/cluster_test_ids_full_sequences_non_redundant $1 > $4/$i"_TEST_full_sequences_non_redundant"

	
        awk -F"\t" '{print$2}' tmp/cluster_val | grep "__"  > tmp/cluster_val_ids_fragments_redundant
        awk -F"\t" '{print$2}' tmp/cluster_val | grep -v "__"  > tmp/cluster_val_ids_full_sequences_redundant

        grep -Fwf tmp/cluster_val_ids_fragments_redundant $1 > $4/$i"_VAL_fragments_redundant"
        grep -Fwf tmp/cluster_val_ids_full_sequences_redundant $1 > $4/$i"_VAL_full_sequences_redundant"

        awk -F"\t" '{print$1}' tmp/cluster_val | grep "__"  > tmp/cluster_val_ids_fragments_non_redundant
        awk -F"\t" '{print$1}' tmp/cluster_val | grep -v "__"  > tmp/cluster_val_ids_full_sequences_non_redundant

        grep -Fwf tmp/cluster_val_ids_fragments_non_redundant $1 > $4/$i"_VAL_fragments_non_redundant"
        grep -Fwf tmp/cluster_val_ids_full_sequences_non_redundant $1 > $4/$i"_VAL_full_sequences_non_redundant"	
	
done

rm log

echo ""
echo "Command: bash splitting.sh $1 $2 $3 $4"
secs_to_human "$SECONDS"

echo "################################################### END OF SPLITTING ##################################################"
echo ""
