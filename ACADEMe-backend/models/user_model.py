import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr

class UserCreate(BaseModel):
    """Schema for user registration."""
    email: EmailStr
    password: str
    student_class: str
    name: str
    photo_url: Optional[str]

class UserLogin(BaseModel):
    """Schema for user login."""
    email: EmailStr
    password: str

class UserUpdateClass(BaseModel):
    new_class: str

class TokenResponse(BaseModel):
    """Schema for JWT token response with refresh token."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # Access token expiry in seconds
    created_at: datetime.datetime
    id: str
    email: EmailStr
    student_class: str
    name: str
    photo_url: Optional[str]
    role: str  # "student", "teacher", or "admin"

    class Config:
        arbitrary_types_allowed = True
        from_attributes = True

class RefreshTokenRequest(BaseModel):
    """Schema for refresh token request."""
    refresh_token: str
