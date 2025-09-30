from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field
from services.firebase_service import FirebaseService
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

router = APIRouter(tags=["Firebase Auth"])

# Initialize Firebase Service
firebase_service = FirebaseService()

class FirebaseTokenRequest(BaseModel):
    user_id: str = Field(..., description="User ID from your backend database", min_length=1)

class FirebaseTokenResponse(BaseModel):
    token: str
    user_id: str
    message: str

class VerifyTokenRequest(BaseModel):
    id_token: str = Field(..., description="Firebase ID token to verify")

@router.post(
    "/users/firebase-token",
    response_model=FirebaseTokenResponse,
    status_code=status.HTTP_200_OK,
    summary="Generate Firebase Custom Token",
    description="Generate a custom Firebase Auth token for authenticated users to access Realtime Database"
)
async def get_firebase_custom_token(request: FirebaseTokenRequest):
    """
    Generate a custom Firebase Auth token for a user.
    
    This endpoint creates a token that allows users authenticated via your backend
    to access Firebase Realtime Database without maintaining separate Firebase accounts.
    
    **Flow:**
    1. User logs in to your backend
    2. Frontend calls this endpoint with user_id
    3. Backend generates custom Firebase token
    4. Frontend uses token to sign into Firebase Auth
    5. User can now access Realtime Database
    
    **Request Body:**
    - user_id: The unique user identifier from your backend database
    
    **Response:**
    - token: Custom Firebase Auth token (JWT)
    - user_id: The user ID that was used
    - message: Success message
    """
    try:
        # Generate custom token
        logger.info(f"Generating Firebase custom token for user: {request.user_id}")
        custom_token = await firebase_service.create_custom_token(request.user_id)
        
        logger.info(f"Successfully generated token for user: {request.user_id}")
        
        return FirebaseTokenResponse(
            token=custom_token,
            user_id=request.user_id,
            message="Firebase custom token generated successfully"
        )
        
    except Exception as e:
        logger.error(f"Error generating Firebase token for user {request.user_id}: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to generate Firebase token: {str(e)}"
        )
