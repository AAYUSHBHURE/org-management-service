from pydantic import BaseModel, EmailStr

class AdminLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    admin_email: str
    org_name: str
