from needlr import auth, FabricClient
from needlr.auth import FabricServicePrincipal
from needlr.models.workspace import Workspace, WorkspaceRole, ServicePrincipal

from dotenv import load_dotenv
import os
import base64

# Load variables from the .env file
load_dotenv()

# Access environment variables
api_id = os.getenv("APP_ID")
api_key = os.getenv("APP_SECRET")
tenant = os.getenv("TENANT_ID")
capacity = os.getenv("CAPACITY_NAME")
workspace = os.getenv("FABRIC_WORKSPACE")
current_user_id = os.getenv("CURRENT_USER_ID")

# Connect
auth = FabricServicePrincipal(api_id, api_key, tenant)
fc = FabricClient(auth=auth)
# Get Capacity
c_id = ""
for c in fc.capacity.list_capacities():
    print(c.displayName)
    if c.displayName == capacity:
        c_id = str(c.id)
        break
print(c_id)
# Create Workspace
ws = fc.workspace.create(display_name=workspace,
                             capacity_id=c_id, 
                             description='Utility Insights')

# Assign current user as Admin of newly created WS
fc.workspace.role.assign(workspace_id=ws.id, principal=ServicePrincipal(id=current_user_id), role=WorkspaceRole.Admin)

# Create Lakehouse
lh = fc.lakehouse.create(display_name='utilityinsightslh', 
                            workspace_id=ws.id, 
                            description='Utility Insights Lakehouse', 
                            enableSchemas=False)
# Create Notebook
nb = fc.notebook.create(display_name='utilityinsightsnb', 
                            workspace_id=ws.id, 
                            description='Utility Insights Notebook')

# Update Notebook Content
nb = fc.notebook.update_definition(workspace_id=ws.id,
                            notebook_id=nb.id,
                            definition={
                                "definition": {
                                    "parts": [
                                        {
                                            "path": "notebook-content.py",
                                            "payload": base64.b64encode(open('./notebook_part0.txt', 'rb').read()).decode('utf-8'),
                                            "payloadType": "InlineBase64"
                                        },
                                        {
                                            "path": ".platform",
                                            "payload": base64.b64encode(open('./notebook_part1.txt', 'rb').read()).decode('utf-8'),
                                            "payloadType": "InlineBase64"
                                        }
                                    ]
                                }
                            },
                            updateMetadata=False)


print("Done")
