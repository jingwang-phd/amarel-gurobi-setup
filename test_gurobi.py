import socket
import gurobipy as gp
m = gp.Model()
x = m.addVar(ub=1.0)
y = m.addVar(vtype=gp.GRB.BINARY)
m.setObjective(x + 2 * y, gp.GRB.MAXIMIZE)
m.addConstr(x + y <= 1.5)
m.optimize()
print(socket.gethostname(), "status", m.Status, "obj", m.ObjVal)
