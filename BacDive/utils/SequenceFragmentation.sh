#!/bin/bash

############################ Inputs ############################
# $1 --> Dataset in fasta format
# $2 --> N_jobs for the domain splitting 
# $3 --> Classifier Dataset
# $4 --> Output Folder
# $5 --> hmmer code path: /data/lazars/hmmer/src
# $6 --> Pfam Database Path: /data/lazars/DataBases/Pfam
# $7 --> Fragmentation: Mode 1, Fragments: Mode 2, Pure Domains: Mode 3
# $8 --> "yes" if you want to run the splitting of sequences into domains

secs_to_human() {
	echo ""
	echo "Elapsed Time: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}

echo "#######################################################################################################################"
echo "####################################### START THE FRAGMENTATION OF THE SEQUENCES ######################################"
echo "#######################################################################################################################"
echo ""

parentdir="$(dirname "$4")"

wd=$(pwd) # Get working directory
mkdir -p $4 

if [ $8 = 'yes' ]; then

	echo "Splitting the input fasta file into one protein fasta files for faster manipulation"
	#Remember the input file must end with .fasta or .fa
	cp $1 "$parentdir/$1"
	cd $parentdir
	splitfasta $1
	cd $wd
	
	# Get filename ---> The folder name with all the fasta files is named automatically as filename_split_files
	IFS='.'
	read -a file_name <<< "$1"
	echo "Filename: ${file_name[0]}"

	echo "Run the hmmscan domain splitting code"
	python utils/run_hmmscan.py --input_folder "$parentdir/${file_name[0]}_split_files" --prefix "$parentdir/${file_name[0]}_domains" --n_jobs $2 --hmmer $5 --pfam_db $6


	# Concatenate all the hmmscan output files and remove any additional lines by the hmmscan code 
	find "$parentdir/${file_name[0]}_domains_out" -type f -exec cat {} + | sed '/^#/d'> "$parentdir/${file_name[0]}_domains_output_tmp"
	files=($parentdir/${file_name[0]}_domains_out/*) 
	head -3 "${files[0]}" > heads # Get a proper header for the domains output file
	tail -10 "${files[0]}" > tails # Get a proper tail for the domains output file 
	cat heads "$parentdir/${file_name[0]}_domains_output_tmp" tails > "$parentdir/${file_name[0]}_domains_output" # Add the proper header and tail to the domains concatenated file 

	rm heads tails "$parentdir/${file_name[0]}_domains_output_tmp" # Remove all the temporary files created just for this process 
	
fi

# Run the domains processing python code to process the domains and we have three modes:
# 		1. Fragments --> Domains with additive noise
#		2. Single_domain_proteins --> Proteins with exactly one domain
#		3. Domains --> pure domains 

if [[ $7 -eq 1 ]]
then
	echo "Run domains processing code"
	echo "     1. Splits sequences into domains if detected domains are over the specified threshold"
	echo "     2. Adds noise to the domains"
	python utils/processing_domains.py --input_dataset $3 --input_domains "$parentdir/${file_name[0]}_domains_out" --output "$4/${file_name[0]}_fragments_processed" --filter 30 --n_jobs $2 --mode 1
	echo "Concatenate processed domain files and save under the name $3_fragmented"
	find "$4/${file_name[0]}_fragments_processed" -type f -exec cat {} + > $4/$3_fragmented

elif [[ $7 -eq 2 ]]
then
	echo "Run domains processing code"
        echo "     1. Splits sequences into domains if detected domains are over the specified threshold"
        echo "     2. Selects only the single domain proteins"
        python utils/processing_domains.py --input_dataset $3 --input_domains "$parentdir/${file_name[0]}_domains_out" --output "$4/${file_name[0]}_single_domain_processed" --filter 30 --n_jobs $2 --mode 2
        echo "Concatenate single domain files and save under the name $3_single_domain_proteins"
        find "$4/${file_name[0]}_single_domain_processed" -type f -exec cat {} + > $4/$3_single_domain_proteins

elif [[ $7 -eq 3 ]]
then
        echo "Run domains processing code"
        echo "     1. Splits sequences into domains if detected domains are over the specified threshold"
        python utils/processing_domains.py --input_dataset $3 --input_domains "$parentdir/${file_name[0]}_domains_out" --output "$4/${file_name[0]}_domain_processed" --filter 30 --n_jobs $2 --mode 3
        echo "Concatenate domain files and save under the name $4/$3_domain"
        find "$4/${file_name[0]}_domain_processed" -type f -exec cat {} + > $4/$3_domain
fi



echo ""
echo "Command: bash utils/run_hmmscan_next.sh $1 $2 $3 $4 $5 $6 $7 $8"
secs_to_human "$SECONDS"

echo "################################################ END OF FRAGMENTATION #################################################"
echo ""
