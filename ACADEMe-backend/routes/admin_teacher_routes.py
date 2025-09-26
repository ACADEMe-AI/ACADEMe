from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from utils.auth import get_current_user
from services.admin_teacher_service import AdminTeacherService

router = APIRouter(prefix="/admin/teachers", tags=["Admin Teacher Management"])

class AddTeacherRequest(BaseModel):
    email: EmailStr
    name: str
    subject: str
    allotted_classes: List[str]
    bio: str = ""

class RemoveTeacherRequest(BaseModel):
    email: EmailStr
    reason: str = ""

class UpdateTeacherRequest(BaseModel):
    email: EmailStr
    name: str = None
    subject: str = None
    allotted_classes: List[str] = None
    bio: str = None

@router.post("/add")
async def add_teacher(
    teacher_data: AddTeacherRequest,
    user: dict = Depends(get_current_user)
):
    """Add a new teacher (Admin only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    return await AdminTeacherService.add_teacher(teacher_data.dict())

@router.delete("/remove")
async def remove_teacher(
    remove_data: RemoveTeacherRequest,
    user: dict = Depends(get_current_user)
):
    """Remove a teacher (Admin only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    return await AdminTeacherService.remove_teacher(remove_data.email, remove_data.reason)

@router.put("/update")
async def update_teacher(
    update_data: UpdateTeacherRequest,
    user: dict = Depends(get_current_user)
):
    """Update teacher information (Admin only)."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    return await AdminTeacherService.update_teacher(update_data.dict())

@router.get("/all")
async def get_all_teachers(user: dict = Depends(get_current_user)) -> Dict[str, Any]:
    """Get all teachers with comprehensive data for admin dashboard."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    return await AdminTeacherService.get_all_teachers_comprehensive()

@router.get("/{teacher_email}/detailed")
async def get_teacher_detailed_stats(
    teacher_email: str,
    user: dict = Depends(get_current_user)
) -> Dict[str, Any]:
    """Get detailed statistics for a specific teacher."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    return await AdminTeacherService.get_teacher_detailed_statistics(teacher_email)

@router.get("/analytics/overview")
async def get_teachers_analytics_overview(
    user: dict = Depends(get_current_user)
) -> Dict[str, Any]:
    """Get analytics overview of all teachers for dashboard graphs."""
    if user["role"] != "admin":
        raise HTTPException(status_code=403, detail="Permission denied: Admins only")
    
    return await AdminTeacherService.get_teachers_analytics_overview()
