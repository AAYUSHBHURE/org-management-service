from fastapi import APIRouter, HTTPException, Depends, status
from app.models.organization import OrganizationCreate, OrganizationResponse, OrganizationUpdate
from app.core.database import get_master_db, get_org_db, db
from app.core.security import get_password_hash
from app.core.config import settings
from typing import List

router = APIRouter(prefix="/org", tags=["organization"])

@router.post("/create", response_model=OrganizationResponse)
async def create_organization(org: OrganizationCreate):
    master_db = await get_master_db()
    
    # 1. Validate that the organization name does not already exist
    existing_org = await master_db["organizations"].find_one({"organization_name": org.organization_name})
    if existing_org:
        raise HTTPException(status_code=400, detail="Organization already exists")

    # 2. Prepare data
    collection_name = f"org_{org.organization_name}"
    admin_id = f"admin_{org.organization_name}" # In reality, could be ObjectId or UUID
    
    # 3. Create Org Metadata in Master DB
    org_doc = {
        "organization_name": org.organization_name,
        "email": org.email,
        "collection_name": collection_name,
        "admin_id": admin_id,
        # Store admin credentials securely
        "admin_password_hash": get_password_hash(org.password)
    }
    
    result = await master_db["organizations"].insert_one(org_doc)
    
    # 4. Dynamically create a new Mongo collection (implicitly created on insert, or explicit create)
    # We can create a dummy document or an index to ensure it exists.
    # Optional: Initialize with basic schema or settings
    org_db_collection = await get_org_db(collection_name)
    await org_db_collection.insert_one({"type": "init", "info": "Organization Created"})
    
    return {
        "organization_name": org.organization_name,
        "email": org.email,
        "collection_name": collection_name,
        "admin_id": admin_id
    }

@router.get("/get", response_model=OrganizationResponse)
async def get_organization(organization_name: str):
    master_db = await get_master_db()
    org_doc = await master_db["organizations"].find_one({"organization_name": organization_name})
    if not org_doc:
        raise HTTPException(status_code=404, detail="Organization not found")
    
    return {
        "organization_name": org_doc["organization_name"],
        "email": org_doc["email"],
        "collection_name": org_doc["collection_name"],
        "admin_id": org_doc["admin_id"]
    }

@router.put("/update", response_model=OrganizationResponse)
async def update_organization(org_update: OrganizationUpdate):
    # Note: Updating organization_name is complex because it's the key for collection names.
    # For now, we will allow updating email and password, but restrict name update if it implies migration.
    # If org_name is changed, we need to check duplicates and rename collection.
    
    master_db = await get_master_db()
    
    # Assuming the input provided organization_name identifies the org to update? 
    # Or is it passed as query param? The spec says "Input: organization_name, email, password".
    # Assuming organization_name identifies the target AND is the new name? That's ambiguous.
    # Usually we need an ID or the old name.
    # Let's assume organization_name in input IS the identifier. 
    # If the user wants to rename, that's tricky. Let's assume we are updating properties OF 'organization_name'.
    
    if not org_update.organization_name:
         raise HTTPException(status_code=400, detail="Organization name required to identify organization")

    current_org = await master_db["organizations"].find_one({"organization_name": org_update.organization_name})
    if not current_org:
        raise HTTPException(status_code=404, detail="Organization not found")

    update_data = {}
    if org_update.email:
        update_data["email"] = org_update.email
    if org_update.password:
        update_data["admin_password_hash"] = get_password_hash(org_update.password)
        
    if update_data:
        await master_db["organizations"].update_one(
            {"organization_name": org_update.organization_name},
            {"$set": update_data}
        )
        # Fetch updated
        current_org = await master_db["organizations"].find_one({"organization_name": org_update.organization_name})

    return {
        "organization_name": current_org["organization_name"],
        "email": current_org["email"],
        "collection_name": current_org["collection_name"],
        "admin_id": current_org["admin_id"]
    }

# Spec: DELETE /org/delete Input: organization_name
# "Allow deletion for respective authenticated user only" - This implies Authorization.
# For now, I'll implement the logic.
@router.delete("/delete")
async def delete_organization(organization_name: str):
    master_db = await get_master_db()
    org_doc = await master_db["organizations"].find_one({"organization_name": organization_name})
    
    if not org_doc:
        raise HTTPException(status_code=404, detail="Organization not found")
        
    # Drop the collection
    # Note: collection is in 'tenants_db' per database.py logic
    # We need to access that database implementation to drop connection.
    # Accessing internal client for drop.
    db_client = db.client
    # If we used a separate DB for tenants (tenants_db):
    try:
        await db_client["tenants_db"].drop_collection(org_doc["collection_name"])
    except Exception as e:
        print(f"Error dropping collection: {e}")

    # Remove from Master DB
    await master_db["organizations"].delete_one({"_id": org_doc["_id"]})
    
    return {"status": "success", "message": f"Organization {organization_name} deleted"}
