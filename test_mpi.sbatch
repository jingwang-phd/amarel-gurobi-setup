#!/bin/bash
#SBATCH --job-name=test_mpi
#SBATCH --partition=main
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:05:00
#SBATCH --output=%x_%j.out
source $HOME/amarel/env.sh
echo "== srun pmix"
srun --mpi=pmix python $HOME/amarel/test_mpi.py
echo "== mpirun"
mpirun -np $SLURM_NTASKS python $HOME/amarel/test_mpi.py
