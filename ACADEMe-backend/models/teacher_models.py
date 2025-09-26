from datetime import datetime
from typing import Optional, List, Dict
from pydantic import BaseModel, EmailStr

# Teacher Course Models
class TeacherCourseCreate(BaseModel):
    title: str
    class_name: str
    description: str

class TeacherCourseResponse(BaseModel):
    id: str
    title: str
    class_name: str
    description: str
    teacher_id: str
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

# Teacher Topic Models
class TeacherTopicCreate(BaseModel):
    title: str
    description: Optional[str] = None

class TeacherTopicResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    course_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# Teacher Material Models
class TeacherMaterialCreate(BaseModel):
    type: str  # "text", "document", "image", "audio", "video"
    category: str
    content: str
    optional_text: Optional[str] = None

class TeacherMaterialResponse(TeacherMaterialCreate):
    id: str
    course_id: str
    topic_id: str
    created_at: str
    updated_at: str
    
    class Config:
        from_attributes = True

# Live Class Models
class LiveClassCreate(BaseModel):
    title: str
    description: Optional[str] = None
    class_name: str
    platform: str = "Zoom"
    scheduled_time: datetime
    meeting_url: str
    duration: str = "45 minutes"

class LiveClassResponse(LiveClassCreate):
    id: str
    teacher_id: str
    status: str  # "scheduled", "live", "completed"
    recording_url: Optional[str] = None
    created_at: datetime
    
    class Config:
        from_attributes = True

# Teacher Profile Models
class TeacherProfileUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    subject: Optional[str] = None
    photo_url: Optional[str] = None

class TeacherPreferencesUpdate(BaseModel):
    notifications_enabled: Optional[bool] = None
    email_notifications: Optional[bool] = None
    auto_record: Optional[bool] = None

class TeacherProfileResponse(BaseModel):
    user_id: str
    name: str
    email: str
    bio: Optional[str] = None
    subject: Optional[str] = None
    photo_url: Optional[str] = None
    allotted_classes: List[str]
    notifications_enabled: bool = True
    email_notifications: bool = True
    auto_record: bool = False
    stats: Dict = {}
    
    class Config:
        from_attributes = True

# Analytics Models
class ClassAnalytics(BaseModel):
    class_name: str
    total_students: int
    active_students: int
    avg_progress: float
    completion_rate: float
    
class StudentInfo(BaseModel):
    id: str
    name: str
    email: str
    photo_url: Optional[str] = None
    progress: float
    last_active: Optional[datetime] = None

# Additional models for student progress viewing
class StudentProgressSummary(BaseModel):
    student_id: str
    student_name: str
    student_email: str
    photo_url: Optional[str] = None
    total_activities: int
    completed_activities: int
    completion_rate: float
    average_quiz_score: float
    last_active: Optional[datetime] = None

class ClassProgressOverview(BaseModel):
    class_name: str
    total_students: int
    students_progress: List[StudentProgressSummary]
    class_averages: Dict[str, float]

class StudentDetailedAnalytics(BaseModel):
    student_info: Dict[str, str]
    basic_stats: Dict[str, float]
    visual_analytics: Dict
    recent_activities: List[Dict]

class ClassProgressSummary(BaseModel):
    class_name: str
    class_summary: Dict[str, float]
    students_details: List[Dict]
    