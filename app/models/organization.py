from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class OrganizationBase(BaseModel):
    organization_name: str
    email: EmailStr

class OrganizationCreate(OrganizationBase):
    password: str

class OrganizationUpdate(BaseModel):
    organization_name: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None

class OrganizationResponse(OrganizationBase):
    collection_name: str
    admin_id: str

    class Config:
        from_attributes = True
