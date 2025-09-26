import uuid
from typing import List, Dict, Any
from datetime import datetime
from utils.auth import get_current_user
from services.teacher_service import TeacherService
from services.teacher_course_service import TeacherCourseService
from utils.cloudinary_service import CloudinaryService
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from models.teacher_models import (
    TeacherCourseCreate, TeacherCourseResponse,
    TeacherTopicCreate, TeacherTopicResponse,
    TeacherMaterialCreate, TeacherMaterialResponse,
    LiveClassCreate, LiveClassResponse,
    TeacherProfileResponse, TeacherProfileUpdate, TeacherPreferencesUpdate,
    ClassAnalytics, StudentInfo, StudentProgressSummary, ClassProgressOverview,
    StudentDetailedAnalytics, ClassProgressSummary
)

router = APIRouter(prefix="/teacher", tags=["Teacher"])

# Teacher Authentication & Profile
@router.get("/profile", response_model=TeacherProfileResponse)
async def get_teacher_profile(user: dict = Depends(get_current_user)):
    """Get teacher profile."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.get_teacher_profile(user["id"])

@router.put("/profile/update")
async def update_teacher_profile(
    profile_data: TeacherProfileUpdate,
    user: dict = Depends(get_current_user)
):
    """Update teacher profile."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.update_teacher_profile(user["id"], profile_data)

@router.put("/preferences/update")
async def update_teacher_preferences(
    preferences: TeacherPreferencesUpdate,
    user: dict = Depends(get_current_user)
):
    """Update teacher preferences."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.update_teacher_preferences(user["id"], preferences)

# Teacher Class Management
@router.get("/allotted-classes", response_model=List[str])
async def get_allotted_classes(user: dict = Depends(get_current_user)):
    """Get allotted classes for teacher."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.get_teacher_allotted_classes(user["id"])

@router.get("/students/{class_name}", response_model=List[StudentInfo])
async def get_students_by_class(
    class_name: str,
    user: dict = Depends(get_current_user)
):
    """Get all students in a specific class."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    # Verify teacher has access to this class
    teacher_classes = TeacherService.get_teacher_allotted_classes(user["id"])
    if class_name not in teacher_classes:
        raise HTTPException(status_code=403, detail="Not authorized to view this class")
    
    return TeacherService.get_students_by_class(class_name)

@router.get("/analytics/{class_name}", response_model=ClassAnalytics)
async def get_class_analytics(
    class_name: str,
    user: dict = Depends(get_current_user)
):
    """Get analytics for a specific class."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.get_class_analytics(class_name, user["id"])

# Teacher Course Management
@router.get("/courses", response_model=List[TeacherCourseResponse])
async def get_teacher_courses(
    target_language: str = Query("en"),
    user: dict = Depends(get_current_user)
):
    """Get all courses created by teacher."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    courses = TeacherCourseService.get_teacher_courses(user["id"], target_language)
    return sorted(courses, key=lambda x: x.created_at)

@router.post("/courses/create", response_model=TeacherCourseResponse)
async def create_teacher_course(
    course: TeacherCourseCreate,
    user: dict = Depends(get_current_user)
):
    """Create a new teacher course."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherCourseService.create_teacher_course(course, user["id"])

@router.get("/courses/{course_id}/topics", response_model=List[dict])
async def get_teacher_course_topics(
    course_id: str,
    target_language: str = Query("en"),
    user: dict = Depends(get_current_user)
):
    """Get all topics for a teacher course."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    topics = TeacherCourseService.get_teacher_course_topics(course_id, user["id"], target_language)
    return sorted(topics, key=lambda x: x['created_at'])

@router.post("/courses/{course_id}/topics/create")
async def create_teacher_course_topic(
    course_id: str,
    topic: TeacherTopicCreate,
    user: dict = Depends(get_current_user)
):
    """Create a new topic in teacher course."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherCourseService.create_teacher_topic(course_id, topic, user["id"])

@router.get("/courses/{course_id}/topics/{topic_id}/materials", response_model=List[TeacherMaterialResponse])
async def get_teacher_topic_materials(
    course_id: str,
    topic_id: str,
    target_language: str = Query("en"),
    user: dict = Depends(get_current_user)
):
    """Get all materials for a teacher topic."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    materials = TeacherCourseService.get_teacher_materials(course_id, topic_id, user["id"], target_language)
    return sorted(materials, key=lambda x: x.created_at)

@router.post("/courses/{course_id}/topics/{topic_id}/materials/create", response_model=TeacherMaterialResponse)
async def create_teacher_topic_material(
    course_id: str,
    topic_id: str,
    type: str = Form(...),
    category: str = Form(...),
    optional_text: str = Form(None),
    text_content: str = Form(None),
    file: UploadFile = File(None),
    user: dict = Depends(get_current_user)
):
    """Add material to a teacher topic."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    material_data = await handle_teacher_material_upload(
        course_id, topic_id, type, category, optional_text, text_content, file
    )
    
    return await TeacherCourseService.add_teacher_material(course_id, topic_id, material_data, user["id"])

# Live Class Management
@router.post("/classes/schedule", response_model=LiveClassResponse)
async def schedule_class(
    class_data: LiveClassCreate,
    user: dict = Depends(get_current_user)
):
    """Schedule a new live class."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    # Verify teacher has access to this class
    teacher_classes = TeacherService.get_teacher_allotted_classes(user["id"])
    if class_data.class_name not in teacher_classes:
        raise HTTPException(status_code=403, detail="Not authorized to schedule class for this grade")
    
    return TeacherService.schedule_live_class(class_data, user["id"])

@router.get("/classes/upcoming", response_model=List[LiveClassResponse])
async def get_upcoming_classes(user: dict = Depends(get_current_user)):
    """Get upcoming live classes for teacher."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.get_upcoming_classes(user["id"])

@router.get("/classes/recorded", response_model=List[LiveClassResponse])
async def get_recorded_classes(user: dict = Depends(get_current_user)):
    """Get recorded classes for teacher."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.get_recorded_classes(user["id"])

@router.post("/classes/{class_id}/start")
async def start_class(
    class_id: str,
    user: dict = Depends(get_current_user)
):
    """Start a live class."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.start_class(class_id, user["id"])

@router.post("/recordings/share")
async def share_recording(
    class_id: str = Form(...),
    recording_url: str = Form(...),
    user: dict = Depends(get_current_user)
):
    """Share recording of a completed class."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return TeacherService.share_recording(class_id, recording_url, user["id"])

@router.get("/progress/{class_name}", response_model=Dict[str, Any])
async def get_comprehensive_class_progress(
    class_name: str,
    student_id: str = Query(None, description="Optional: Get detailed data for specific student"),
    include_visuals: bool = Query(True, description="Include visual analytics"),
    user: dict = Depends(get_current_user)
):
    """Get comprehensive progress data for class or specific student with accurate calculations."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherService.get_comprehensive_progress(class_name, user["id"], student_id, include_visuals)

@router.get("/classes/{class_name}/students/progress-summary", response_model=Dict[str, Any])
async def get_class_progress_summary(
    class_name: str,
    user: dict = Depends(get_current_user)
):
    """Get progress summary with visual data for all students in a class."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    # Verify teacher has access to this class
    teacher_classes = TeacherService.get_teacher_allotted_classes(user["id"])
    if class_name not in teacher_classes:
        raise HTTPException(status_code=403, detail="Not authorized to view this class")
    
    return await TeacherService.get_class_progress_summary(class_name)

# Utility function for handling teacher material uploads
async def handle_teacher_material_upload(
    course_id: str, topic_id: str, type: str, category: str, 
    optional_text: str, content: str, file: UploadFile = None
):
    """Handles file uploads and prepares teacher material data."""
    
    type = type.lower()
    category = category.lower()
    file_url = None

    if type == "text":
        if not content:
            raise HTTPException(status_code=422, detail="Text content is required for 'text' type materials.")
        file_url = content

    elif type in ["image", "video", "audio", "document"]:  
        if not file:
            raise HTTPException(status_code=422, detail=f"File is required for '{type}' type materials.")

        allowed_types = {
            "image": ["image/jpeg", "image/png", "image/webp"],
            "video": ["video/mp4", "video/mkv", "video/avi"],
            "audio": ["audio/mpeg", "audio/wav", "audio/ogg"],
            "document": ["application/pdf", "application/msword", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
        }
        if file.content_type not in allowed_types.get(type, []):
            raise HTTPException(status_code=415, detail=f"Invalid file type '{file.content_type}' for {type} materials.")

        try:
            file_url = await CloudinaryService.upload_file(file, "teacher_materials")
            if not file_url:
                raise HTTPException(status_code=500, detail="File upload failed. No URL returned.")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"File upload error: {str(e)}")
    
    else:
        raise HTTPException(status_code=400, detail="Invalid request: Provide a valid type (text, image, video, audio, document).")

    if not file_url:
        raise HTTPException(status_code=500, detail="Failed to process material content.")

    return {
        "id": str(uuid.uuid4()),
        "course_id": course_id,
        "topic_id": topic_id,
        "type": type,
        "category": category,
        "content": file_url,
        "optional_text": optional_text or "",
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }
