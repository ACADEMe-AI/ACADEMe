from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from datetime import datetime
from utils.auth import get_current_user
from services.teacher_exam_service import TeacherExamService

router = APIRouter(prefix="/teacher/exams", tags=["Teacher Exams"])

class QuizQuestionCreate(BaseModel):
    question_text: str
    options: List[str]
    correct_answer: str
    marks: int = 1

class SubjectiveQuestionCreate(BaseModel):
    question_text: str
    marks: int
    expected_answer_length: str = "short"  # short, medium, long
    rubric: str = ""

class ExamCreate(BaseModel):
    title: str
    description: str
    class_name: str
    subject: str
    duration_minutes: int
    total_marks: int
    exam_type: str = "mixed"  # quiz, subjective, mixed
    quiz_questions: List[QuizQuestionCreate] = []
    subjective_questions: List[SubjectiveQuestionCreate] = []
    instructions: str = ""
    scheduled_date: Optional[datetime] = None
    is_published: bool = False

class ExamUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    duration_minutes: Optional[int] = None
    instructions: Optional[str] = None
    scheduled_date: Optional[datetime] = None
    is_published: Optional[bool] = None

@router.post("/create")
async def create_exam(
    exam_data: ExamCreate,
    user: dict = Depends(get_current_user)
):
    """Create a new exam with quiz and/or subjective questions."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.create_exam(exam_data.dict(), user["id"])

@router.get("/my-exams")
async def get_teacher_exams(
    class_name: str = Query(None),
    user: dict = Depends(get_current_user)
):
    """Get all exams created by the teacher."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.get_teacher_exams(user["id"], class_name)

@router.get("/{exam_id}")
async def get_exam_details(
    exam_id: str,
    user: dict = Depends(get_current_user)
):
    """Get detailed exam information including all questions."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.get_exam_details(exam_id, user["id"])

@router.put("/{exam_id}/update")
async def update_exam(
    exam_id: str,
    update_data: ExamUpdate,
    user: dict = Depends(get_current_user)
):
    """Update exam information."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.update_exam(exam_id, update_data.dict(), user["id"])

@router.post("/{exam_id}/questions/quiz")
async def add_quiz_question(
    exam_id: str,
    question: QuizQuestionCreate,
    user: dict = Depends(get_current_user)
):
    """Add a quiz question to an exam."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.add_quiz_question(exam_id, question.dict(), user["id"])

@router.post("/{exam_id}/questions/subjective")
async def add_subjective_question(
    exam_id: str,
    question: SubjectiveQuestionCreate,
    user: dict = Depends(get_current_user)
):
    """Add a subjective question to an exam."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.add_subjective_question(exam_id, question.dict(), user["id"])

@router.delete("/{exam_id}/questions/{question_id}")
async def remove_question(
    exam_id: str,
    question_id: str,
    user: dict = Depends(get_current_user)
):
    """Remove a question from an exam."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.remove_question(exam_id, question_id, user["id"])

@router.post("/{exam_id}/publish")
async def publish_exam(
    exam_id: str,
    user: dict = Depends(get_current_user)
):
    """Publish an exam to make it available to students."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.publish_exam(exam_id, user["id"])

@router.post("/{exam_id}/unpublish")
async def unpublish_exam(
    exam_id: str,
    user: dict = Depends(get_current_user)
):
    """Unpublish an exam."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.unpublish_exam(exam_id, user["id"])

@router.get("/{exam_id}/submissions")
async def get_exam_submissions(
    exam_id: str,
    user: dict = Depends(get_current_user)
):
    """Get all student submissions for an exam."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.get_exam_submissions(exam_id, user["id"])

@router.get("/{exam_id}/analytics")
async def get_exam_analytics(
    exam_id: str,
    user: dict = Depends(get_current_user)
):
    """Get analytics for an exam including performance statistics."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.get_exam_analytics(exam_id, user["id"])

@router.delete("/{exam_id}")
async def delete_exam(
    exam_id: str,
    user: dict = Depends(get_current_user)
):
    """Delete an exam (only if no submissions exist)."""
    if user["role"] != "teacher":
        raise HTTPException(status_code=403, detail="Permission denied: Teachers only")
    
    return await TeacherExamService.delete_exam(exam_id, user["id"])
