import os
import jwt
import firebase_admin
from passlib.context import CryptContext
from datetime import datetime, timedelta
from firebase_admin import auth, firestore
from fastapi import HTTPException, Depends, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# ✅ Initialize Firebase Admin (Only if not initialized)
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()  # ✅ Move this below Firebase initialization

# ✅ Environment Variables
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your_secret_key_here")
JWT_ALGORITHM = "HS256"
DEFAULT_EXPIRY_SECONDS = 10**9  # 30+ hours

# ✅ Password Hashing Setup
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

security = HTTPBearer()

# ✅ Firebase Token Verification
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

# ✅ JWT Token Generation
def create_jwt_token(data: dict, expiry_seconds: int = DEFAULT_EXPIRY_SECONDS):
    """Creates a JWT token with an optional expiry."""
    payload = data.copy()
    payload["exp"] = datetime.utcnow() + timedelta(seconds=expiry_seconds)

    return jwt.encode(payload, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)

# ✅ JWT Token Verification
def verify_jwt_token(token: str):
    """Verifies and decodes a JWT token."""
    try:
        decoded_token = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return decoded_token
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# ✅ Get Current User (Supports Firebase, JWT & Admin Check)
def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)):
    """Extracts the current user from either Firebase token or JWT token & checks admin/teacher status."""
    token = credentials.credentials
    
    try:
        # Try verifying as a Firebase token
        user = verify_firebase_token(token)
    except HTTPException:
        try:
            # If Firebase fails, try verifying as a JWT token
            user = verify_jwt_token(token)
        except HTTPException:
            raise HTTPException(status_code=401, detail="Invalid authentication token")
    
    email = user.get("email")
    user_id = user.get("uid") or user.get("id")  # Firebase uses 'uid', JWT uses 'id'
    
    if not email:
        raise HTTPException(status_code=401, detail="Email not found in token")
    
    if not user_id:
        raise HTTPException(status_code=401, detail="User ID not found in token")
    
    # Default role
    user["role"] = "student"
    
    # Check if the user is an admin in Firestore (using email as document ID)
    try:
        admin_ref = db.collection("admins").document(email).get()
        if admin_ref.exists:
            user["role"] = "admin"
            return user
    except:
        pass  # Continue to check for teacher role
    
    # Check if the user is an admin using user ID as well
    try:
        admin_ids_ref = db.collection("admins").stream()
        admin_ids = [doc.id for doc in admin_ids_ref]
        if user_id in admin_ids:
            user["role"] = "admin"
            return user
    except:
        pass
    
    # Check if the user is a teacher (using user ID as document ID)
    try:
        teacher_ref = db.collection("teacher_profiles").document(user_id).get()
        if teacher_ref.exists:
            user["role"] = "teacher"
            return user
    except:
        pass
    
    # Check if teacher profile exists using email
    try:
        teacher_profiles = db.collection("teacher_profiles").where("email", "==", email).limit(1).stream()
        teacher_docs = list(teacher_profiles)
        if teacher_docs:
            user["role"] = "teacher"
            return user
    except:
        pass
    
    # Check if user has role field in users collection
    try:
        user_ref = db.collection("users").document(user_id).get()
        if user_ref.exists:
            user_data = user_ref.to_dict()
            stored_role = user_data.get("role")
            if stored_role in ["admin", "teacher"]:
                user["role"] = stored_role
    except:
        pass
    
    return user

# ✅ Password Hashing
def hash_password(password: str):
    """Hashes the password using bcrypt."""
    return pwd_context.hash(password)

# ✅ Password Verification
def verify_password(plain_password: str, hashed_password: str):
    """Verifies the password against the hashed version."""
    return pwd_context.verify(plain_password, hashed_password)
