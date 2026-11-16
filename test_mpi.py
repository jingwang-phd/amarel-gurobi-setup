import socket
from mpi4py import MPI
comm = MPI.COMM_WORLD
print("rank", comm.Get_rank(), "of", comm.Get_size(), "on", socket.gethostname(), flush=True)
