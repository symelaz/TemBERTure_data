#!/bin/bash

############################ Inputs ############################
# $1 --> Sequences of the THERMOPHILIC proteins in fasta format
# $2 --> Sequences of the MESOPHILIC proteins in fasta format 
# $3 --> Folder for the mmseqs code 
# $4 --> Folder for the hmmer code 
# $5 --> Folder of the Pfam database
# $6 --> Number of workers available
# $7 --> Fragmentation Mode: 1 --> Fragments with Noise,  2 --> Singe Domain Proteins, 3 --> Pure Domains
# $8 --> The splitting percentage 

secs_to_human() {
	echo ""
	echo "Elapsed Time: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}


echo "#######################################################################################################################"
echo "########################################## START THE CREATION OF THE DATASETS #########################################"
echo "#######################################################################################################################"
echo ""
echo "Warning: Please make sure that you enter the arguments in the correct order!"

mkdir -p tmp # For temporary files 

# Balancing the input data so that they have the same number of sequences
if [ -d "BALANCING" ]; then
	echo "BALANCING exists."
    	read -p "Do you want to run the balancing again? Write yes or no: " ans
else
    	ans='yes'
fi

if [ $ans = 'yes' ]; then
	bash utils/balancing.sh $1 $2 BALANCING $3
fi

# Convert the dataset from the CLASSIFIER format into FASTA format
awk -F',' '{printf ">%s\n%s\n", $1,$2}' CLASSIFIER_dataset > CLASSIFIER_dataset.fasta

# Fragmentation of the dataset
if [ -d "FRAGMENTATION" ]; then
	echo "FRAGMENTATION exists."
    	read -p "Do you want to run the fragmentation again? Write yes or no: " ans
else
    	ans='yes'
fi

if [ $ans = 'yes' ]; then

	if [[ $7 -eq 1 ]]; then
                mkdir -p FRAGMENTATION/FRAGMENTS
                bash utils/SequenceFragmentation.sh CLASSIFIER_dataset.fasta $6 CLASSIFIER_dataset FRAGMENTATION/FRAGMENTS $4 $5 1 "yes"
                file_name_fr="FRAGMENTATION/FRAGMENTS/CLASSIFIER_dataset_fragmented"
        elif [[ $7 -eq 2 ]]; then
                mkdir -p FRAGMENTATION/SINGLE_DOMAIN_PROTEINS
                bash utils/SequenceFragmentation.sh CLASSIFIER_dataset.fasta $6 CLASSIFIER_dataset FRAGMENTATION/SINGLE_DOMAIN_PROTEINS $4 $5 2 "yes"
                file_name_fr="FRAGMENTATION/SINGLE_DOMAIN_PROTEINS/CLASSIFIER_dataset_single_domain_proteins"
        elif [[ $7 -eq 3 ]]; then
                mkdir -p FRAGMENTATION/DOMAINS
                bash utils/SequenceFragmentation.sh CLASSIFIER_dataset.fasta $6 CLASSIFIER_dataset FRAGMENTATION/DOMAINS $4 $5 3 "yes"
                file_name_fr="FRAGMENTATION/DOMAINS/CLASSIFIER_dataset_domain"
        fi
        
else
	if [[ $7 -eq 1 ]]; then
                file_name_fr="FRAGMENTATION/FRAGMENTS/CLASSIFIER_dataset_fragmented"
        elif [[ $7 -eq 2 ]]; then
                file_name_fr="FRAGMENTATION/SINGLE_DOMAIN_PROTEINS/CLASSIFIER_dataset_single_domain_proteins"
        elif [[ $7 -eq 3 ]]; then
                file_name_fr="FRAGMENTATION/DOMAINS/CLASSIFIER_dataset_domain"
        fi
fi

# Start the splitting of the datasets into training and test and validation sets
# 1. Merge the fragmented and the full sequence datasets
# 2. Cluster them seperately for meso and thermo
# 3. Split with 80 10 10 ratio
# 4. Seperate fragments from full sequences
# 5. Concatenate thermo and meso

if [ -d "SPLIT" ]; then
        echo "SPLIT exists."
        read -p "Do you want to run the splitting into training validation and test sets again? Write yes or no: " ans
else
        ans='yes'
fi

if [ $ans = 'yes' ]; then
        mkdir -p SPLIT
        cat CLASSIFIER_dataset $file_name_fr| awk -F, 'length($2) > 20 { print }'| awk -F, '!seen[$2]++' > SPLIT/CLASSIFIER_dataset_merged

	for TYPE in "THERMO" "MESO"
	do
		echo "Working with the $TYPE dataset"
		splitted_cluster="FRAGMENTATION/CLUSTER/$TYPE"
		mkdir -p $splitted_cluster

		if [ $TYPE = 'THERMO' ]; then
			prefix="$splitted_cluster/THERMO"
			grep ",1" $file_name_fr |awk -F, '{printf">%s\n%s\n", $1,$2}' > $prefix.fasta
			MODE=1
		else
			prefix="$splitted_cluster/MESO"
			grep ",0" $file_name_fr |awk -F, '{printf">%s\n%s\n", $1,$2}' > $prefix.fasta
			MODE=0
		fi
		echo "Clustering the $TYPE dataset"
		$3/mmseqs easy-cluster $prefix.fasta $prefix tmp --cluster-reassign > $prefix.log
		echo "Splitting the $TYPE dataset"
		python utils/graph_based_splitting.py \
			--thermo_domains ${prefix}_cluster.tsv \
        		--thermo_sequences BALANCING/${TYPE}_CASCADED_CLUSTER/${TYPE}_cluster.tsv \
        		--classifier_dataset SPLIT/CLASSIFIER_dataset_merged \
			--output SPLIT/$TYPE/ \
			--ratio $8 \
			--threshold 7 \
			--mode $MODE 

	done
	
	# Merging the final datasets and running a sanity check
	for TYPE in "redundant" "non_redundant"
        do
                for seqs_type in "domains" "sequences"
                do
                        output_dir=FINAL_DATASET/${TYPE}_${seqs_type}
                        mkdir -p $output_dir

                        for split in "training" "test" "val"
                        do
                                cat SPLIT/*/$TYPE/${TYPE}_${split}_${seqs_type}_data > $output_dir/${split}.csv
                        done

			echo "Run sanity check for the $output_dir dataset"
			bash utils/splits_sanity_check.sh $output_dir/training.csv $output_dir/test.csv $output_dir/val.csv $output_dir/SANITY_CHECK $3
		done
	done
fi

rm Alignment_Results log

secs_to_human "$SECONDS"
echo "Command: bash dataset_creation.sh $1 $2 $3 $4 $5 $6 $7 $8"
