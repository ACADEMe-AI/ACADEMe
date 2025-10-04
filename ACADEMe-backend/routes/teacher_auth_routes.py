from typing import List
from fastapi import APIRouter, HTTPException
from firebase_admin import firestore
from pydantic import BaseModel, EmailStr

router = APIRouter(prefix="/auth", tags=["Authentication"])

db = firestore.client()

class TeacherEmailResponse(BaseModel):
    emails: List[str]

@router.get("/teacher-emails", response_model=TeacherEmailResponse)
async def get_teacher_emails():
    """Get all teacher email addresses for verification during registration."""
    try:
        # Get all teacher emails from teacher_profiles collection
        teacher_profiles = db.collection("teacher_profiles").stream()
        emails = []
        
        for teacher_doc in teacher_profiles:
            # Document ID is the email
            emails.append(teacher_doc.id)
        
        # Also check for teachers in users collection with role = "teacher"
        teachers_in_users = db.collection("users").where("role", "==", "teacher").stream()
        for teacher in teachers_in_users:
            teacher_data = teacher.to_dict()
            if teacher_data.get("email") and teacher_data["email"] not in emails:
                emails.append(teacher_data["email"])
        
        # If no teachers found, you can return a predefined list or empty list
        # For development, you might want to add some default teacher emails
        if not emails:
            # Add default teacher emails for development (remove in production)
            default_teachers = [
                
            ]
            emails.extend(default_teachers)
        
        return TeacherEmailResponse(emails=emails)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching teacher emails: {str(e)}")
    