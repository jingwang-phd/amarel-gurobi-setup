# Gurobi on Amarel

Dear Professor Jonathan,

How I got Gurobi and Open MPI running on Amarel, with the batch scripts I used to check it. Everything sits in my home directory; nothing needed root.

## What Amarel gives you

Login is `ssh <netid>@amarel.rutgers.edu`, VPN off campus. Slurm, with a `main` partition of 500-odd nodes (32+ cores, 3-day limit, can be preempted by node owners) and a `nonpre` partition that isn't preempted.

No solver modules at all, no Gurobi, CPLEX or Xpress, and no conda module either. The system Python is 3.8 and the system Open MPI 2.1, both old, so I built my own environment.

The thing that makes this easy: compute nodes have outbound internet access, so Gurobi's Web License Service works. A WLS license is fetched over the network when the job runs and isn't tied to a machine, which is the right kind of license for a cluster. An academic account can hold one Gurobi WLS license alongside the usual named-user license.

`srun --mpi=list` shows `pmix` and `pmi2`, so a conda-installed Open MPI runs across nodes with `srun --mpi=pmix`.

## Python environment

Miniforge (a minimal conda that defaults to conda-forge), then one environment with Python, Open MPI, mpi4py and gurobipy. `setup_env.sh` does all of it; run it once on a login node:

```bash
bash setup_env.sh
```

The lines that matter:

```bash
curl -L -o Miniforge3.sh \
  https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
bash Miniforge3.sh -b -p $HOME/miniforge3
source $HOME/miniforge3/etc/profile.d/conda.sh
conda create -y -n sppy python=3.12 openmpi mpi4py numpy scipy pandas
conda activate sppy
pip install gurobipy
```

Open MPI and mpi4py both come from conda-forge, so mpi4py is built against the MPI it actually runs with.

## Gurobi license

On <https://portal.gurobi.com>, under Licenses, request an Academic WLS license and download `gurobi.lic`. It has three lines (`WLSACCESSID`, `WLSSECRET`, `LICENSEID`) and no host key. Valid for three months, renewed from the same page.

Copy it to Amarel and point Gurobi at it (jw1723 is my NetID):

```bash
scp gurobi.lic jw1723@amarel.rutgers.edu:~/gurobi.lic
export GRB_LICENSE_FILE=$HOME/gurobi.lic
```

I keep that export together with the conda activation in `~/amarel/env.sh`:

```bash
source $HOME/miniforge3/etc/profile.d/conda.sh
conda activate sppy
export GRB_LICENSE_FILE=$HOME/gurobi.lic
export OMP_NUM_THREADS=1
```

Every batch script starts with `source $HOME/amarel/env.sh`.

## Tests

Copy the files here to `~/amarel/` and submit from there.

```bash
sbatch test_gurobi.sbatch
sbatch test_mpi.sbatch
```

`test_gurobi`: a two-variable MIP on one node. The output should contain `Academic license <id> - for non-commercial use only` and then `status 2 obj 2.5`.

`test_mpi`: four ranks on two nodes, launched once with `srun --mpi=pmix` and once with `mpirun`. Each rank prints its rank and host name.

## Things worth knowing

Gurobi defaults to 32 threads on a compute node. With several ranks on one node you have to set `Threads` yourself, otherwise they fight over cores.

The WLS token is requested when a process builds its first model, once per process, about a second each. Six at the same time was no problem.

Importing MPI on a login node prints a UCX warning. Ignore it.

## Full Gurobi installation, only for the C++ hub

If you also want to compile the C++ hub from PR #942 (`aphfw_cpp`), a full Gurobi installation is needed in addition to gurobipy, since the module links against Gurobi's C library. The same WLS license works for it.

1. Get the PR branch of mpi-sppy.

   ```bash
   mkdir -p $HOME/src && cd $HOME/src
   git clone https://github.com/Pyomo/mpi-sppy.git
   cd mpi-sppy
   git fetch origin pull/942/head:aphfw
   git checkout aphfw
   pip install -e .
   ```

2. Download `gurobi13.0.3_linux64.tar.gz` from the Gurobi download page and unpack it to `$HOME/opt`.

   ```bash
   mkdir -p $HOME/opt && tar -xzf gurobi13.0.3_linux64.tar.gz -C $HOME/opt
   ```

3. Gurobi ships `libgurobi_c++.a` built with an older GCC. Rebuild it with the compiler you link with and point the library name at the new file.

   ```bash
   conda install -y gxx=14
   cd $HOME/opt/gurobi1303/linux64/src/build && make
   cp libgurobi_c++.a ../../lib/libgurobi_g++14.a
   cd ../../lib && ln -sf libgurobi_g++14.a libgurobi_c++.a
   ```

4. Pin gurobipy to the same version. The PR's build script looks for Gurobi 12 or 13.

   ```bash
   pip install gurobipy==13.0.3
   ```

5. Add to `env.sh`:

   ```bash
   export GUROBI_HOME=$HOME/opt/gurobi1303/linux64
   ```

6. Build.

   ```bash
   python -m mpisppy.aphfw_cpp.build --solver gurobi --solver-home $GUROBI_HOME
   ```

After this, `--aphfw-hub` works in `mpisppy.generic_cylinders`.

## Files

| File | Purpose |
|---|---|
| `setup_env.sh` | one-time install of Miniforge and the `sppy` environment |
| `env.sh` | activation and license variable, sourced by every batch script |
| `test_gurobi.py`, `test_gurobi.sbatch` | Gurobi license check on one node |
| `test_mpi.py`, `test_mpi.sbatch` | MPI launch across two nodes |
