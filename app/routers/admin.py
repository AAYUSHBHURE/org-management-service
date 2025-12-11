from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer
from app.models.admin import AdminLogin, Token
from app.core.database import get_master_db
from app.core.security import verify_password, create_access_token

router = APIRouter(prefix="/admin", tags=["admin"])

@router.post("/login", response_model=Token)
async def login_for_access_token(form_data: AdminLogin):
    master_db = await get_master_db()
    # Find org by email (assuming admin email is unique across system OR we need org name too?)
    # The spec input for login is: email, password.
    # It assumes email is unique for admin or we search across orgs?
    # Usually email is unique.
    
    user = await master_db["organizations"].find_one({"email": form_data.email})
    if not user:
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    if not verify_password(form_data.password, user["admin_password_hash"]):
        raise HTTPException(status_code=401, detail="Incorrect email or password")
    
    access_token = create_access_token(
        data={"sub": user["email"], "org": user["organization_name"]}
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "admin_email": user["email"],
        "org_name": user["organization_name"]
    }
