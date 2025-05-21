import pandas as pd
import numpy as np
from ortools.sat.python import cp_model
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--lookup", help="File with the lookup data from the mmseq clustering", type=str)
parser.add_argument("--splitting", help="Splitting percentage", type=int)
parser.add_argument("--output", help="Spceify the output folder", type=str)
parser.add_argument("--mode", help="Specify the constraintos mode: 1 for ratio of proteins and cluster size and 2 for number of clusters",type=int)
parser.add_argument("--fragments_per_cluster", help="Number of fragments per cluster", type=str)
parser.add_argument("--sequences_per_cluster", help="Number of full sequences per cluster", type=str)
args = parser.parse_args()

def solve_type_1(df, threshold):
        '''
        Uses or-tools module to solve optimization within the pandas dataframe given at the input.
        Objective: The number of proteins within the test set should be around a given number while
        the number of proteins with pdb structure is maximized.
        '''
        proteins = df["Elements"]
        clusters = df['Cluster']
        ids = df['ClusterID']

        # Creates the model.
        model = cp_model.CpModel()

        # Step 1: Create the variables
        # array containing row selection flags i.e. True if row k is selected, False otherwise
        # Note: treated as 1/0 in arithmeetic expressions
        row_selection = [model.NewBoolVar(f'{i}') for i in range(df.shape[0])]

        # Step 2: Define the constraints
        # The sum of the clusters for the selected rows should be equal to the threshold * # of clusters:
        model.Add(proteins.dot(row_selection) == int(threshold * sum(df['Cluster']) * 1.4))

        #model.Add(clusters.dot(row_selection) == int(threshold * sum(df['Cluster'])))
       
        # Step 3: Define the objective function
        # Maximize the total cost (based upon rows selected)
        model.Maximize(proteins.dot(row_selection))

        # Step 4: Creates the solver and solve.
        solver = cp_model.CpSolver()
        solver.Solve(model)
        status = solver.Solve(model)
    
        # Get the rows selected
        rows = [row for row in range(df.shape[0]) if solver.Value(row_selection[row])]

        return list(ids[rows])


def solve_type_2(df, threshold):
        '''
        Uses or-tools module to solve optimization within the pandas dataframe given at the input.
        Objective: The number of proteins within the test set should be around a given number while
        the number of proteins with pdb structure is maximized.
        '''
        proteins = df["Elements"]
        clusters = df['Cluster']
        ids = df['ClusterID']
        seq = df['Sequences']
        frag = df['Fragments']

        # Creates the model.
        model = cp_model.CpModel()

        # Step 1: Create the variables
        # array containing row selection flags i.e. True if row k is selected, False otherwise
        # Note: treated as 1/0 in arithmeetic expressions
        row_selection = [model.NewBoolVar(f'{i}') for i in range(df.shape[0])]

        # Step 2: Define the constraints
        # The sum of the clusters for the selected rows should be equal to the threshold * # of clusters:
        model.Add(clusters.dot(row_selection) == int(threshold * sum(df['Cluster'])))
        model.Add(seq.dot(row_selection) == int(threshold * sum(df['Sequences'])))
        model.Add(frag.dot(row_selection) == int(threshold * sum(df['Fragments'])))
	
        # Step 3: Define the objective function
        # Maximize the total cost (based upon rows selected)
        model.Maximize(proteins.dot(row_selection))

        # Step 4: Creates the solver and solve.
        solver = cp_model.CpSolver()
        solver.Solve(model)
        status = solver.Solve(model)

        # Get the rows selected
        rows = [row for row in range(df.shape[0]) if solver.Value(row_selection[row])]
        
        return list(ids[rows])


clustered = pd.read_csv(args.lookup, header=None, sep="\t")

# Compute the cdf
counter = clustered[0].value_counts()
cdf = pd.DataFrame({"ClusterID": list(counter.keys()), "Elements": list(counter.values)})
cdf['Cluster'] = np.ones(len(cdf)).astype(int)

fragm = pd.read_csv(args.fragments_per_cluster,header=None)
fragm_dict = dict(zip(fragm[1],fragm[0]))
seq = pd.read_csv(args.sequences_per_cluster,header=None)
seq_dict = dict(zip(seq[1],seq[0]))

fragments_list = []
seq_list = []
for i in cdf['ClusterID']:
    if i in fragm_dict.keys(): fragments_list.append(fragm_dict[i])
    else: fragments_list.append(0)
    if i in seq_dict.keys(): seq_list.append(seq_dict[i])
    else: seq_list.append(0)

cdf["Fragments"] = fragments_list
cdf["Sequences"] = seq_list

print(cdf)
args.mode = 2
if args.mode == 1:
    ids = solve_type_1(cdf, args.splitting/100)
else:
    ids = solve_type_2(cdf, args.splitting/100)


with open(args.output,"w") as f:
    f.write("\n".join(ids))
    f.write("\n")
    f.close()
