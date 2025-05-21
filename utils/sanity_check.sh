#!/bin/sh

############################ Inputs ############################
# $1 --> Training
# $2 --> Test
# $3 --> Validation
# $4 --> Output Folder
# $5 --> mmseqs binary folder


secs_to_human() {
	echo ""
	echo "Elapsed Time: $(( ${1} / 3600 ))h $(( (${1} / 60) % 60 ))m $(( ${1} % 60 ))s"
}

SECONDS=0
cwd=$(pwd)

echo "#######################################################################################################################"
echo "########################################## CHECK OVERLAPPING BETWEEN DATASETS #########################################"
echo "#######################################################################################################################"
echo ""

mkdir -p $4/DataBases

for i in $1 $2 $3
do	
	IFS="/"
	read -a file_name <<< "$i"
	
	echo "Create ${file_name[-1]} database"
	awk -F',' '{printf ">%s\n%s\n", $1,$2}' "$i" > "$4/DataBases/${file_name[-1]}.fasta"
	if [ "$i" = "$1" ]; then
		train="$4/DataBases/${file_name[-1]}.fasta"
	elif [ "$i" = "$2" ]; then
		test="$4/DataBases/${file_name[-1]}.fasta"
	else
                val="$4/DataBases/${file_name[-1]}.fasta"
	fi		
done

echo ""
echo "Run the search code between the Test and Validation Sets"
"$5/"mmseqs easy-search "$test" "$val" Alignment_Results tmp --min-seq-id 0.5 -s 7.0 -c 0.8 --cov-mode 0 --alignment-mode 3 > log
echo "TEST and VALIDATION with pident > 50: $(awk -F"\t" '$3>0.5 {print$2}' Alignment_Results|sort| uniq |wc -l)"
echo "TEST and VALIDATION with pident > 80: $(awk -F"\t" '$3>0.8 {print$2}' Alignment_Results|sort| uniq |wc -l)"
echo "Plot pident histogram"
python utils/histogram_plot.py --input Alignment_Results --output "$4/Test_Val_figure"
awk '{print$2}' Alignment_Results|uniq > val_ids
mv Alignment_Results "$4/Test_Val"

echo ""
echo "Run the search code between the Validation and Training Sets"
"$5/"mmseqs easy-search "$val" "$train" Alignment_Results tmp --min-seq-id 0.5 -s 7.0 -c 0.8 --cov-mode 0 --alignment-mode 3 > log
echo "TRAIN and VALIDATION with pident > 50: $(awk -F"\t" '$3>0.5 {print$2}' Alignment_Results|sort| uniq |wc -l)"
echo "TRAIN and VALIDATION with pident > 80: $(awk -F"\t" '$3>0.8 {print$2}' Alignment_Results|sort| uniq |wc -l)"
echo "Plot pident histogram"
python utils/histogram_plot.py --input Alignment_Results --output "$4/Val_Train_figure"
awk '{print$1}' Alignment_Results|uniq >> val_ids
mv Alignment_Results "$4/Val_Train"

echo ""
echo "Run the search code between the Test and Training Sets"
"$5/"mmseqs easy-search "$test" "$train" Alignment_Results tmp --min-seq-id 0.5 -s 7.0 -c 0.8 --cov-mode 0 --alignment-mode 3 > log
echo "TEST and TRAIN with pident > 50: $(awk -F"\t" '$3>0.5 {print$2}' Alignment_Results|sort| uniq |wc -l)"
echo "TEST and TRAIN with pident > 80: $(awk -F"\t" '$3>0.8 {print$2}' Alignment_Results|sort| uniq |wc -l)"
echo "Plot pident histogram"
python utils/histogram_plot.py --input Alignment_Results --output "$4/Test_Train_figure"
awk '{print$1}' Alignment_Results|uniq > test_ids
mv Alignment_Results "$4/Test_Train"


echo "Removing Sequences with over 50% identity between each set"
grep -v -Fwf test_ids "$2" > "$2_filtered"
cat "$1" > "$1_filtered"
grep -v -Fwf val_ids "$3" > "$3_filtered"
 
rm test_ids val_ids

echo "Filtered Dataset:"
wc -l  "$1_filtered" "$2_filtered" "$3_filtered"

echo "Unfiltered Dataset:"
wc -l "$1" "$2" "$3" 

echo "Command: sanity_check.sh $1 $2 $3 $4 $5"
secs_to_human "$SECONDS"
