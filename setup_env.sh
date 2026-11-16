#!/bin/bash
set -e
cd $HOME
if [ ! -d $HOME/miniforge3 ]; then
  curl -L -o Miniforge3.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
  bash Miniforge3.sh -b -p $HOME/miniforge3
  rm Miniforge3.sh
fi
source $HOME/miniforge3/etc/profile.d/conda.sh
conda config --set auto_activate_base false
conda create -y -n sppy python=3.12 openmpi mpi4py numpy scipy pandas
conda activate sppy
pip install gurobipy
python -c "import gurobipy, mpi4py; print('gurobipy', gurobipy.gurobi.version()); print('mpi4py', mpi4py.__version__)"
