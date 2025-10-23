import os
import jwt
import uuid
import firebase_admin
from passlib.context import CryptContext
from datetime import datetime, timedelta
from firebase_admin import auth, firestore
from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import asyncio

# Initialize Firebase Admin (Only if not initialized)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()

# Environment Variables
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your_secret_key_here")
REFRESH_SECRET_KEY = os.getenv("REFRESH_SECRET_KEY", "your_refresh_secret_key_here")
JWT_ALGORITHM = "HS256"

# Token expiry settings (industry standard)
ACCESS_TOKEN_EXPIRY = 3600  # 1 hour
REFRESH_TOKEN_EXPIRY = 2592000  # 30 days

# Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

# Firebase Token Verification
def verify_firebase_token(token: str):
    """Verifies Firebase ID token."""
    try:
        decoded_token = auth.verify_id_token(token, check_revoked=True)
        return decoded_token
    except auth.RevokedIdTokenError:
        raise HTTPException(status_code=401, detail="Firebase token has been revoked")
    except auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Expired Firebase token")
    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid Firebase token")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Firebase token error: {str(e)}")

# JWT Access Token Generation
def create_access_token(data: dict) -> str:
    """Creates a short-lived JWT access token."""
    payload = data.copy()
    payload["exp"] = datetime.utcnow() + timedelta(seconds=ACCESS_TOKEN_EXPIRY)
    payload["iat"] = datetime.utcnow()
    payload["type"] = "access"

    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

# JWT Refresh Token Generation
def create_refresh_token(user_id: str) -> str:
    """Creates a long-lived JWT refresh token."""
    payload = {
        "user_id": user_id,
        "token_id": str(uuid.uuid4()),  # Unique token ID for revocation
        "exp": datetime.utcnow() + timedelta(seconds=REFRESH_TOKEN_EXPIRY),
        "iat": datetime.utcnow(),
        "type": "refresh"
    }

    return jwt.encode(payload, REFRESH_SECRET_KEY, algorithm=JWT_ALGORITHM)

# Verify Access Token
def verify_access_token(token: str) -> dict:
    """Verifies and decodes an access token."""
    try:
        decoded = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM], options={"verify_exp": False})
        if decoded.get("type") != "access":
            raise HTTPException(status_code=401, detail="Invalid token type")
        return decoded
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Access token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid access token")

# Verify Refresh Token
def verify_refresh_token(token: str) -> dict:
    """Verifies and decodes a refresh token."""
    try:
        decoded = jwt.decode(token, REFRESH_SECRET_KEY, algorithms=[JWT_ALGORITHM], options={"verify_exp": False})
        if decoded.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")

        # Check if token is revoked
        token_id = decoded.get("token_id")
        user_id = decoded.get("user_id")

        if not token_id or not user_id:
            raise HTTPException(status_code=401, detail="Invalid token structure")

        # Check blacklist in Firestore
        blacklist_ref = db.collection("token_blacklist").document(token_id).get()
        if blacklist_ref.exists:
            raise HTTPException(status_code=401, detail="Refresh token has been revoked")

        return decoded
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Refresh token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")

# Revoke Refresh Token
async def revoke_refresh_token(token: str):
    """Revokes a refresh token by adding it to blacklist."""
    try:
        decoded = jwt.decode(token, REFRESH_SECRET_KEY, algorithms=[JWT_ALGORITHM], options={"verify_exp": False})
        token_id = decoded.get("token_id")

        if token_id:
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(
                None,
                lambda: db.collection("token_blacklist").document(token_id).set({
                    "revoked_at": datetime.utcnow(),
                    "expires_at": datetime.utcnow() + timedelta(seconds=REFRESH_TOKEN_EXPIRY)
                })
            )
    except Exception as e:
        print(f"Error revoking token: {e}")

# Get Current User
async def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)) -> dict:
    """Extracts the current user from access token & determines role."""
    token = credentials.credentials

    try:
        # Try verifying as Firebase token first
        user = verify_firebase_token(token)
    except HTTPException:
        try:
            # If Firebase fails, verify as JWT access token
            user = verify_access_token(token)
        except HTTPException:
            raise HTTPException(status_code=401, detail="Invalid authentication token")

    email = user.get("email")
    user_id = user.get("uid") or user.get("id")

    if not email:
        raise HTTPException(status_code=401, detail="Email not found in token")

    if not user_id:
        raise HTTPException(status_code=401, detail="User ID not found in token")

    # If role already in token, use it
    if "role" in user and user["role"] in ["admin", "teacher", "student"]:
        return user

    # Otherwise, determine role dynamically
    user["role"] = await determine_user_role(email, user_id)
    user["id"] = user_id

    return user

# Determine User Role
async def determine_user_role(email: str, user_id: str) -> str:
    """
    Determine user role by checking collections:
    1. teacher_profiles (by user_id and email)
    2. admins (by user_id and email)
    3. Default to student
    """
    try:
        loop = asyncio.get_event_loop()

        # Concurrent checks for performance
        teacher_by_id_future = loop.run_in_executor(
            None,
            lambda: db.collection("teacher_profiles").document(user_id).get()
        )

        teacher_by_email_future = loop.run_in_executor(
            None,
            lambda: list(db.collection("teacher_profiles").where("email", "==", email).limit(1).stream())
        )

        admin_by_id_future = loop.run_in_executor(
            None,
            lambda: db.collection("admins").document(email).get()
        )

        admin_by_email_future = loop.run_in_executor(
            None,
            lambda: list(db.collection("admins").where("email", "==", email).limit(1).stream())
        )

        # Wait for all checks
        teacher_by_id, teacher_by_email, admin_by_id, admin_by_email = await asyncio.gather(
            teacher_by_id_future,
            teacher_by_email_future,
            admin_by_id_future,
            admin_by_email_future
        )

        # Check teacher first
        if teacher_by_id.exists or teacher_by_email:
            return "teacher"

        # Then check admin
        if admin_by_id.exists or admin_by_email:
            return "admin"

        # Default to student
        return "student"

    except Exception as e:
        print(f"Error determining role: {e}")
        return "student"

# Store Refresh Token
async def store_refresh_token(user_id: str, token_id: str, expires_at: datetime):
    """Store refresh token metadata in Firestore."""
    try:
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(
            None,
            lambda: db.collection("refresh_tokens").document(token_id).set({
                "user_id": user_id,
                "created_at": datetime.utcnow(),
                "expires_at": expires_at
            })
        )
    except Exception as e:
        print(f"Error storing refresh token: {e}")

# Password Hashing
def hash_password(password: str) -> str:
    """Hashes the password using bcrypt."""
    return pwd_context.hash(password)

# Password Verification
def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies the password against the hashed version."""
    return pwd_context.verify(plain_password, hashed_password)