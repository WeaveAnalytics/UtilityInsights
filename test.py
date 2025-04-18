from needlr import auth, FabricClient
from needlr.auth import FabricServicePrincipal
from needlr.models.workspace import Workspace, WorkspaceRole, ServicePrincipal

from dotenv import load_dotenv
import os

# Load variables from the .env file
load_dotenv()

# Access environment variables
api_id = os.getenv("APP_ID")
api_key = os.getenv("APP_SECRET")
tenant = os.getenv("TENANT_ID")
capacity = os.getenv("CAPACITY_NAME")
current_user_id = os.getenv("CURRENT_USER_ID")

# Print them for demonstration (avoid this in production)
print(f"API Id: {api_id}")
print(f"Database Host: {api_key}")
print(f"Database Port: {tenant}")

# Connect
auth = FabricServicePrincipal(api_id, api_key, tenant)
fc = FabricClient(auth=auth)
# Get Capacity
for c in fc.capacity.list_capacities():
    if c.displayName == capaciy:
        c_id = str(c.id)
        break
# Create Workspace
ws = fc.workspace.create(display_name='UtilityInsightsWS',
                             capacity_id= c_id, 
                             description='UtilityInsights WS')
# Check WS creation
for ws in fc.workspace.ls():
    print(f"{ws.name}: Id:{ws.id} Capacity:{ws.capacityId}")

# Assign current user as Admin of newly created WS
fc.workspace.role.assign(workspace_id=workspace_test.id, principal=ServicePrincipal(id=current_user_id), role=WorkspaceRole.Admin)

print("Done")
