from needlr import auth, FabricClient
from needlr.auth import FabricInteractiveAuth

fc = FabricClient(auth=auth.FabricInteractiveAuth())
for ws in fc.workspace.ls():
    print(f"{ws.name}: Id:{ws.id} Capacity:{ws.capacityId}")
