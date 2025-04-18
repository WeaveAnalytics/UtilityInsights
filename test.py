from needlr import auth, FabricClient
from needlr.auth import FabricServicePrincipal
from dotenv import load_dotenv
import os

# Load variables from the .env file
load_dotenv()

# Access environment variables
api_id = os.getenv("APP_ID")
api_key = os.getenv("APP_SECRET")
tenant = os.getenv("TENANT_ID")

# Print them for demonstration (avoid this in production)
print(f"API Id: {api_id}")
print(f"Database Host: {api_key}")
print(f"Database Port: {tenant}")

# Connect
auth = FabricServicePrincipal(api_id, api_key, tenant)
fc = FabricClient(auth=auth)
# Get Capacity
for c in fc.capacity.list_capacities():
    if c.displayName.startswith("Trial"):
        c_id = str(c.id)
        break
# Create Workspace
ws = fc.workspace.create(display_name='TestWS',
                             capacity_id= c_id, 
                             description='UtilityInsights WS')
# Check WS creation
for ws in fc.workspace.ls():
    print(f"{ws.name}: Id:{ws.id} Capacity:{ws.capacityId}")
        
print("Done")
