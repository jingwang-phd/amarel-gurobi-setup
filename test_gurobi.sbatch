#!/bin/bash
#SBATCH --job-name=test_gurobi
#SBATCH --partition=main
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:05:00
#SBATCH --output=%x_%j.out
source $HOME/amarel/env.sh
python $HOME/amarel/test_gurobi.py
