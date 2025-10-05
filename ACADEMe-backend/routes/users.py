import asyncio
from typing import List
import firebase_admin
from firebase_admin import firestore
from utils.auth import get_current_user, verify_refresh_token, create_access_token, revoke_refresh_token, determine_user_role, ACCESS_TOKEN_EXPIRY
from services.auth_service import fetch_admin_ids, send_otp, send_reset_otp, reset_password
from fastapi import APIRouter, Depends, HTTPException
from services.progress_service import delete_user_progress
from services.auth_service import register_user, login_user, fetch_teacher_emails, google_signin_or_signup
from models.user_model import UserCreate, UserLogin, TokenResponse, UserUpdateClass, RefreshTokenRequest
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

router = APIRouter(prefix="/users", tags=["Users & Authentication"])

db = firestore.client()

# Model for OTP request
class OTPRequest(BaseModel):
    email: EmailStr

# Model for user registration with OTP
class UserCreateWithOTP(UserCreate):
    otp: str

# Model for forgot password OTP request
class ForgotPasswordRequest(BaseModel):
    email: EmailStr

# Model for password reset with OTP
class ResetPasswordRequest(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

@router.post("/send-otp")
async def send_otp_endpoint(request: OTPRequest):
    """Send OTP to email for registration verification."""
    try:
        result = await send_otp(request.email)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/forgot-password")
async def forgot_password_endpoint(request: ForgotPasswordRequest):
    """Send OTP to email for password reset."""
    try:
        result = await send_reset_otp(request.email)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/reset-password")
async def reset_password_endpoint(request: ResetPasswordRequest):
    """Reset password after OTP verification."""
    try:
        result = await reset_password(request.email, request.otp, request.new_password)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/signup", response_model=TokenResponse)
async def signup(user: UserCreateWithOTP):
    """Registers a new user with OTP verification and returns an authentication token."""
    try:
        # Extract OTP from the request
        otp = user.otp
        
        # Create UserCreate object without OTP
        user_data = UserCreate(
            name=user.name,
            email=user.email,
            password=user.password,
            student_class=user.student_class,
            photo_url=user.photo_url
        )
        
        # Register user with OTP verification
        created_user = await register_user(user_data, otp)
        if not created_user:
            raise HTTPException(status_code=400, detail="User registration failed")
        return created_user
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/login", response_model=TokenResponse)
async def login(user: UserLogin):
    """Logs in an existing user and returns an authentication token."""
    logged_in_user = await login_user(user)  # Await the async function
    if not logged_in_user:
        raise HTTPException(status_code=401, detail="Invalid email or password")
    return logged_in_user

@router.get("/me")
async def get_current_user_details(user: dict = Depends(get_current_user)):
    """Fetches the currently authenticated user's details with role."""
    if not user:
        raise HTTPException(status_code=401, detail="User not authenticated")

    return {
        "id": user.get("id"),
        "name": user.get("name"),
        "email": user.get("email"),
        "student_class": user.get("student_class"),
        "photo_url": user.get("photo_url"),
        "role": user.get("role", "student")
    }

@router.post("/refresh", response_model=TokenResponse)
async def refresh_access_token(request: RefreshTokenRequest):
    """Generate new access token using refresh token."""
    try:
        # Verify refresh token
        payload = verify_refresh_token(request.refresh_token)
        user_id = payload.get("user_id")

        # Get user data from Firestore
        user_ref = db.collection("users").document(user_id).get()
        if not user_ref.exists:
            raise HTTPException(status_code=404, detail="User not found")

        user_data = user_ref.to_dict()
        email = user_data.get("email")

        # Determine current role
        role = await determine_user_role(email, user_id)

        # Generate new access token
        access_token = create_access_token({
            "id": user_id,
            "email": email,
            "student_class": user_data.get("student_class", "SELECT"),
            "name": user_data.get("name", ""),
            "photo_url": user_data.get("photo_url"),
            "role": role
        })

        return TokenResponse(
            access_token=access_token,
            refresh_token=request.refresh_token,  # Return same refresh token
            token_type="bearer",
            expires_in=ACCESS_TOKEN_EXPIRY,
            created_at=datetime.utcnow(),
            id=user_id,
            email=email,
            student_class=user_data.get("student_class", "SELECT"),
            name=user_data.get("name", ""),
            photo_url=user_data.get("photo_url"),
            role=role
        )

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/logout")
async def logout(user: dict = Depends(get_current_user), refresh_token: str = None):
    """Logout user and revoke refresh token."""
    try:
        if refresh_token:
            await revoke_refresh_token(refresh_token)

        return {"message": "Successfully logged out"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.patch("/update_class/")
async def update_user_class(update_data: UserUpdateClass, user: dict = Depends(get_current_user)):
    """Deletes user progress and updates their class, returns updated user data."""
    user_id = user["id"]
    user_ref = db.collection("users").document(user_id)

    # Check if user exists
    user_doc = user_ref.get()
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")

    # Delete user's progress before updating class
    await delete_user_progress(user_id)

    # Update class field asynchronously
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, lambda: user_ref.update({"student_class": update_data.new_class}))

    # Get updated user data
    updated_user_doc = user_ref.get()
    updated_user_data = updated_user_doc.to_dict()

    # Determine role
    email = updated_user_data.get("email")
    role = await determine_user_role(email, user_id)

    return {
        "message": "Class updated successfully after progress reset.",
        "new_class": update_data.new_class,
        "user_data": {
            "id": user_id,
            "name": updated_user_data.get("name", ""),
            "email": email,
            "student_class": update_data.new_class,
            "photo_url": updated_user_data.get("photo_url"),
            "role": role
        }
    }

@router.get("/admins", response_model=List[str])
async def get_admin_ids():
    """Fetch all document IDs from the 'admins' collection."""
    try:
        admin_ids = await fetch_admin_ids()
        return admin_ids
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class GoogleSignInRequest(BaseModel):
    email: EmailStr
    name: str
    photo_url: Optional[str] = "https://www.w3schools.com/w3images/avatar2.png"

@router.post("/google-signin", response_model=TokenResponse)
async def google_signin_endpoint(request: GoogleSignInRequest):
    """Handle Google Sign-In or Sign-Up automatically."""
    try:
        user_data = {
            "email": request.email,
            "name": request.name,
            "photo_url": request.photo_url
        }
        result = await google_signin_or_signup(user_data)
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))