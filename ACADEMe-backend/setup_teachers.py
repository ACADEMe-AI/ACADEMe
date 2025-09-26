"""
Run this script once to set up initial teacher data in Firebase.
Make sure to update the teacher emails and classes according to your needs.
"""

import firebase_admin
from firebase_admin import credentials, firestore
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Firebase Admin SDK
if not firebase_admin._apps:
    service_account_path = os.getenv("FIREBASE_CRED_PATH")
    if not service_account_path or not os.path.exists(service_account_path):
        raise FileNotFoundError("FIREBASE_CRED_PATH not found or invalid in .env")
    
    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)

db = firestore.client()

# Sample teacher data - UPDATE THIS ACCORDING TO YOUR NEEDS
sample_teachers = [
    {
        "email": "darrang48@gmail.com",
        "name": "Subhajit Roy",
        "subject": "Mathematics",
        "allotted_classes": ["5", "6"],
        "bio": "Mathematics teacher with 10 years of experience"
    },
]

def setup_teacher_profiles():
    """Create initial teacher profiles in Firestore."""
    try:
        for teacher in sample_teachers:
            # Create a document with email as ID (you can change this logic)
            doc_id = teacher["email"].replace("@", "_").replace(".", "_")
            
            teacher_data = {
                "user_id": doc_id,  # This should match actual user IDs when teachers register
                "name": teacher["name"],
                "email": teacher["email"],
                "bio": teacher["bio"],
                "subject": teacher["subject"],
                "photo_url": None,
                "allotted_classes": teacher["allotted_classes"],
                "notifications_enabled": True,
                "email_notifications": True,
                "auto_record": False,
                "stats": {
                    "total_students": 0,
                    "classes_held": 0,
                    "content_created": 0,
                    "average_rating": 0.0
                }
            }
            
            db.collection("teacher_profiles").document(doc_id).set(teacher_data)
            print(f"Created teacher profile for: {teacher['name']} ({teacher['email']})")
        
        print("Teacher profiles setup completed!")
        
    except Exception as e:
        print(f"Error setting up teacher profiles: {e}")

if __name__ == "__main__":
    setup_teacher_profiles()
