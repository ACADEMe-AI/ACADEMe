import uuid
from datetime import datetime
from typing import List, Dict, Any
from fastapi import HTTPException
from firebase_admin import firestore
from services.accurate_progress_service import AccurateProgressService
from models.teacher_models import (
    LiveClassCreate, LiveClassResponse,
    TeacherProfileResponse, TeacherProfileUpdate, TeacherPreferencesUpdate,
    ClassAnalytics, StudentInfo
)

db = firestore.client()

class TeacherService:
    @staticmethod
    def get_teacher_allotted_classes(teacher_id: str) -> List[str]:
        """Get allotted classes for a teacher."""
        try:
            teacher_ref = db.collection("teacher_profiles").document(teacher_id)
            teacher_doc = teacher_ref.get()
            
            if not teacher_doc.exists:
                raise HTTPException(status_code=404, detail="Teacher profile not found")
            
            teacher_data = teacher_doc.to_dict()
            return teacher_data.get("allotted_classes", [])
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching allotted classes: {str(e)}")

    @staticmethod
    def get_students_by_class(class_name: str) -> List[StudentInfo]:
        """Get all students in a specific class."""
        try:
            users_ref = db.collection("users").where("student_class", "==", class_name).stream()
            students = []
            
            for user in users_ref:
                user_data = user.to_dict()
                # Calculate progress (you can customize this logic)
                progress = TeacherService._calculate_student_progress(user.id)
                
                students.append(StudentInfo(
                    id=user.id,
                    name=user_data.get("name", "Unknown"),
                    email=user_data.get("email", ""),
                    photo_url=user_data.get("photo_url"),
                    progress=progress,
                    last_active=user_data.get("last_active")
                ))
            
            return students
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching students: {str(e)}")

    @staticmethod
    def _calculate_student_progress(student_id: str) -> float:
        """Calculate overall progress for a student."""
        try:
            progress_ref = db.collection("users").document(student_id).collection("progress")
            progress_docs = list(progress_ref.stream())
            
            if not progress_docs:
                return 0.0
            
            completed_count = sum(1 for doc in progress_docs 
                                 if doc.to_dict().get("status") == "completed")
            total_count = len(progress_docs)
            
            return (completed_count / total_count) * 100 if total_count > 0 else 0.0
        except:
            return 0.0

    @staticmethod
    def get_class_analytics(class_name: str, teacher_id: str) -> ClassAnalytics:
        """Get analytics for a specific class."""
        try:
            # Verify teacher has access to this class
            teacher_classes = TeacherService.get_teacher_allotted_classes(teacher_id)
            if class_name not in teacher_classes:
                raise HTTPException(status_code=403, detail="Not authorized to view this class")
            
            students = TeacherService.get_students_by_class(class_name)
            total_students = len(students)
            
            if total_students == 0:
                return ClassAnalytics(
                    class_name=class_name,
                    total_students=0,
                    active_students=0,
                    avg_progress=0.0,
                    completion_rate=0.0
                )
            
            # Calculate active students (those with progress > 0)
            active_students = sum(1 for student in students if student.progress > 0)
            
            # Calculate average progress
            avg_progress = sum(student.progress for student in students) / total_students
            
            # Calculate completion rate (students with progress >= 80%)
            completed_students = sum(1 for student in students if student.progress >= 80.0)
            completion_rate = (completed_students / total_students) * 100
            
            return ClassAnalytics(
                class_name=class_name,
                total_students=total_students,
                active_students=active_students,
                avg_progress=avg_progress,
                completion_rate=completion_rate
            )
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching class analytics: {str(e)}")

    @staticmethod
    def schedule_live_class(class_data: LiveClassCreate, teacher_id: str) -> LiveClassResponse:
        """Schedule a new live class."""
        try:
            class_id = str(uuid.uuid4())
            
            class_dict = {
                "id": class_id,
                "teacher_id": teacher_id,
                "title": class_data.title,
                "description": class_data.description,
                "class_name": class_data.class_name,
                "platform": class_data.platform,
                "scheduled_time": class_data.scheduled_time,
                "meeting_url": class_data.meeting_url,
                "duration": class_data.duration,
                "status": "scheduled",
                "recording_url": None,
                "created_at": datetime.utcnow()
            }
            
            db.collection("live_classes").document(class_id).set(class_dict)
            
            return LiveClassResponse(**class_dict)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error scheduling class: {str(e)}")

    @staticmethod
    def get_upcoming_classes(teacher_id: str) -> List[LiveClassResponse]:
        """Get upcoming live classes for a teacher."""
        try:
            now = datetime.utcnow()
            classes_ref = (
                db.collection("live_classes")
                .where("teacher_id", "==", teacher_id)
                .where("status", "in", ["scheduled", "live"])
                .where("scheduled_time", ">=", now)
                .order_by("scheduled_time")
                .stream()
            )
            
            classes = []
            for cls in classes_ref:
                class_data = cls.to_dict()
                classes.append(LiveClassResponse(**class_data))
            
            return classes
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching upcoming classes: {str(e)}")

    @staticmethod
    def get_recorded_classes(teacher_id: str) -> List[LiveClassResponse]:
        """Get recorded classes for a teacher."""
        try:
            classes_ref = (
                db.collection("live_classes")
                .where("teacher_id", "==", teacher_id)
                .where("status", "==", "completed")
                .where("recording_url", "!=", None)
                .order_by("scheduled_time", direction=firestore.Query.DESCENDING)
                .stream()
            )
            
            classes = []
            for cls in classes_ref:
                class_data = cls.to_dict()
                classes.append(LiveClassResponse(**class_data))
            
            return classes
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching recorded classes: {str(e)}")

    @staticmethod
    def start_class(class_id: str, teacher_id: str) -> Dict[str, Any]:
        """Start a live class."""
        try:
            class_ref = db.collection("live_classes").document(class_id)
            class_doc = class_ref.get()
            
            if not class_doc.exists:
                raise HTTPException(status_code=404, detail="Class not found")
            
            class_data = class_doc.to_dict()
            
            if class_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized to start this class")
            
            if class_data["status"] != "scheduled":
                raise HTTPException(status_code=400, detail="Class cannot be started")
            
            # Update class status to live
            class_ref.update({
                "status": "live",
                "actual_start_time": datetime.utcnow()
            })
            
            return {"message": "Class started successfully", "meeting_url": class_data["meeting_url"]}
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error starting class: {str(e)}")

    @staticmethod
    def share_recording(class_id: str, recording_url: str, teacher_id: str) -> Dict[str, Any]:
        """Share recording of a completed class."""
        try:
            class_ref = db.collection("live_classes").document(class_id)
            class_doc = class_ref.get()
            
            if not class_doc.exists:
                raise HTTPException(status_code=404, detail="Class not found")
            
            class_data = class_doc.to_dict()
            
            if class_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized to update this class")
            
            # Update class with recording URL and mark as completed
            class_ref.update({
                "recording_url": recording_url,
                "status": "completed",
                "completed_at": datetime.utcnow()
            })
            
            return {"message": "Recording shared successfully"}
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error sharing recording: {str(e)}")

    @staticmethod
    def get_teacher_profile(teacher_id: str) -> TeacherProfileResponse:
        """Get teacher profile."""
        try:
            teacher_ref = db.collection("teacher_profiles").document(teacher_id)
            teacher_doc = teacher_ref.get()
            
            if not teacher_doc.exists:
                # Create default profile if doesn't exist
                user_ref = db.collection("users").document(teacher_id)
                user_doc = user_ref.get()
                
                if not user_doc.exists:
                    raise HTTPException(status_code=404, detail="User not found")
                
                user_data = user_doc.to_dict()
                
                default_profile = {
                    "user_id": teacher_id,
                    "name": user_data.get("name", ""),
                    "email": user_data.get("email", ""),
                    "bio": "",
                    "subject": "",
                    "photo_url": user_data.get("photo_url"),
                    "allotted_classes": [],
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
                
                teacher_ref.set(default_profile)
                return TeacherProfileResponse(**default_profile)
            
            teacher_data = teacher_doc.to_dict()
            return TeacherProfileResponse(**teacher_data)
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching teacher profile: {str(e)}")

    @staticmethod
    def update_teacher_profile(teacher_id: str, profile_data: TeacherProfileUpdate) -> Dict[str, Any]:
        """Update teacher profile."""
        try:
            teacher_ref = db.collection("teacher_profiles").document(teacher_id)
            
            # Get current profile or create if doesn't exist
            teacher_doc = teacher_ref.get()
            if not teacher_doc.exists:
                TeacherService.get_teacher_profile(teacher_id)  # This will create default profile
            
            # Update only provided fields
            update_data = profile_data.dict(exclude_unset=True)
            if update_data:
                teacher_ref.update(update_data)
            
            return {"message": "Profile updated successfully"}
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error updating profile: {str(e)}")

    @staticmethod
    def update_teacher_preferences(teacher_id: str, preferences: TeacherPreferencesUpdate) -> Dict[str, Any]:
        """Update teacher preferences."""
        try:
            teacher_ref = db.collection("teacher_profiles").document(teacher_id)
            
            # Update only provided fields
            update_data = preferences.dict(exclude_unset=True)
            if update_data:
                teacher_ref.update(update_data)
            
            return {"message": "Preferences updated successfully"}
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error updating preferences: {str(e)}")

    @staticmethod
    async def get_student_progress_for_teacher(student_id: str, teacher_id: str) -> Dict[str, Any]:
        """Get detailed progress for a specific student (teacher access)."""
        try:
            # First verify the student exists and get their class
            student_ref = db.collection("users").document(student_id)
            student_doc = student_ref.get()
            
            if not student_doc.exists:
                raise HTTPException(status_code=404, detail="Student not found")
            
            student_data = student_doc.to_dict()
            student_class = student_data.get("student_class")
            
            # Verify teacher has access to this student's class
            teacher_classes = TeacherService.get_teacher_allotted_classes(teacher_id)
            if student_class not in teacher_classes:
                raise HTTPException(status_code=403, detail="Not authorized to view this student's progress")
            
            # Get student's progress data
            import asyncio
            loop = asyncio.get_running_loop()
            progress_ref = db.collection("users").document(student_id).collection("progress")
            progress_docs = await loop.run_in_executor(None, lambda: list(progress_ref.stream()))
            
            progress_list = []
            for doc in progress_docs:
                progress_data = doc.to_dict()
                progress_data["id"] = doc.id
                progress_list.append(progress_data)
            
            # Calculate summary statistics
            total_activities = len(progress_list)
            completed_activities = sum(1 for p in progress_list if p.get("status") == "completed")
            quiz_scores = [p.get("score", 0) for p in progress_list if p.get("activity_type") == "quiz" and p.get("score") is not None]
            avg_quiz_score = sum(quiz_scores) / len(quiz_scores) if quiz_scores else 0.0
            
            return {
                "student_id": student_id,
                "student_name": student_data.get("name", "Unknown"),
                "student_class": student_class,
                "total_activities": total_activities,
                "completed_activities": completed_activities,
                "completion_rate": (completed_activities / total_activities * 100) if total_activities > 0 else 0.0,
                "average_quiz_score": avg_quiz_score,
                "recent_activities": sorted(progress_list, key=lambda x: x.get("timestamp", ""), reverse=True)[:10],
                "detailed_progress": progress_list
            }
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching student progress: {str(e)}")

    @staticmethod
    async def get_class_progress_overview(class_name: str, teacher_id: str) -> Dict[str, Any]:
        """Get progress overview for all students in a class."""
        try:
            # Get all students in the class
            students = TeacherService.get_students_by_class(class_name)
            
            if not students:
                return {
                    "class_name": class_name,
                    "total_students": 0,
                    "students_progress": [],
                    "class_averages": {
                        "avg_completion_rate": 0.0,
                        "avg_quiz_score": 0.0,
                        "active_students": 0
                    }
                }
            
            students_progress = []
            completion_rates = []
            quiz_scores = []
            active_count = 0
            
            import asyncio
            loop = asyncio.get_running_loop()
            
            for student in students:
                # Get student progress
                progress_ref = db.collection("users").document(student.id).collection("progress")
                progress_docs = await loop.run_in_executor(None, lambda ref=progress_ref: list(ref.stream()))
                
                total_activities = len(progress_docs)
                completed_activities = sum(1 for doc in progress_docs if doc.to_dict().get("status") == "completed")
                completion_rate = (completed_activities / total_activities * 100) if total_activities > 0 else 0.0
                
                student_quiz_scores = []
                for doc in progress_docs:
                    progress_data = doc.to_dict()
                    if progress_data.get("activity_type") == "quiz" and progress_data.get("score") is not None:
                        student_quiz_scores.append(progress_data["score"])
                
                avg_quiz_score = sum(student_quiz_scores) / len(student_quiz_scores) if student_quiz_scores else 0.0
                
                if completion_rate > 0:
                    active_count += 1
                
                students_progress.append({
                    "student_id": student.id,
                    "student_name": student.name,
                    "student_email": student.email,
                    "photo_url": student.photo_url,
                    "total_activities": total_activities,
                    "completed_activities": completed_activities,
                    "completion_rate": completion_rate,
                    "average_quiz_score": avg_quiz_score,
                    "last_active": student.last_active
                })
                
                completion_rates.append(completion_rate)
                if student_quiz_scores:
                    quiz_scores.extend(student_quiz_scores)
            
            # Calculate class averages
            avg_completion_rate = sum(completion_rates) / len(completion_rates) if completion_rates else 0.0
            avg_quiz_score = sum(quiz_scores) / len(quiz_scores) if quiz_scores else 0.0
            
            return {
                "class_name": class_name,
                "total_students": len(students),
                "students_progress": sorted(students_progress, key=lambda x: x["completion_rate"], reverse=True),
                "class_averages": {
                    "avg_completion_rate": avg_completion_rate,
                    "avg_quiz_score": avg_quiz_score,
                    "active_students": active_count
                }
            }
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching class progress: {str(e)}")

    @staticmethod
    async def get_student_detailed_analytics(student_id: str, teacher_id: str) -> Dict[str, Any]:
        """Get detailed analytics for a specific student including visual data."""
        try:
            # First verify access
            student_ref = db.collection("users").document(student_id)
            student_doc = student_ref.get()
            
            if not student_doc.exists:
                raise HTTPException(status_code=404, detail="Student not found")
            
            student_data = student_doc.to_dict()
            student_class = student_data.get("student_class")
            
            # Verify teacher has access
            teacher_classes = TeacherService.get_teacher_allotted_classes(teacher_id)
            if student_class not in teacher_classes:
                raise HTTPException(status_code=403, detail="Not authorized to view this student's analytics")
            
            # Import progress service functions
            from services.progress_service import get_progress_visuals, fetch_progress_from_firestore
            
            # Get progress data and generate visuals
            progress_data = fetch_progress_from_firestore(student_id)
            visual_data = get_progress_visuals(progress_data)
            
            # Get basic progress info
            basic_progress = await TeacherService.get_student_progress_for_teacher(student_id, teacher_id)
            
            return {
                "student_info": {
                    "student_id": student_id,
                    "name": student_data.get("name", "Unknown"),
                    "email": student_data.get("email", ""),
                    "class": student_class,
                    "photo_url": student_data.get("photo_url")
                },
                "basic_stats": {
                    "total_activities": basic_progress["total_activities"],
                    "completed_activities": basic_progress["completed_activities"],
                    "completion_rate": basic_progress["completion_rate"],
                    "average_quiz_score": basic_progress["average_quiz_score"]
                },
                "visual_analytics": visual_data,
                "recent_activities": basic_progress["recent_activities"]
            }
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching student analytics: {str(e)}")

    @staticmethod
    async def get_class_progress_summary(class_name: str) -> Dict[str, Any]:
        """Get progress summary with visual data for all students in a class."""
        try:
            # Get all students in class
            students_ref = db.collection("users").where("student_class", "==", class_name).stream()
            students_summary = []
            
            from services.progress_service import get_progress_visuals, fetch_progress_from_firestore
            import asyncio
            
            for student_doc in students_ref:
                student_data = student_doc.to_dict()
                student_id = student_doc.id
                
                # Get progress data for each student
                progress_data = fetch_progress_from_firestore(student_id)
                visual_data = get_progress_visuals(progress_data)
                
                # Calculate summary metrics
                total_progress = len(progress_data)
                completed = sum(1 for p in progress_data if p.get("status") == "completed")
                quiz_scores = [p.get("score", 0) for p in progress_data if p.get("activity_type") == "quiz" and p.get("score") is not None]
                avg_score = sum(quiz_scores) / len(quiz_scores) if quiz_scores else 0.0
                
                students_summary.append({
                    "student_id": student_id,
                    "name": student_data.get("name", "Unknown"),
                    "email": student_data.get("email", ""),
                    "photo_url": student_data.get("photo_url"),
                    "summary_stats": {
                        "total_activities": total_progress,
                        "completed_activities": completed,
                        "completion_rate": (completed / total_progress * 100) if total_progress > 0 else 0.0,
                        "average_quiz_score": avg_score
                    },
                    "visual_data": visual_data
                })
            
            # Calculate class-wide statistics
            if students_summary:
                total_students = len(students_summary)
                avg_completion = sum(s["summary_stats"]["completion_rate"] for s in students_summary) / total_students
                avg_quiz_score = sum(s["summary_stats"]["average_quiz_score"] for s in students_summary) / total_students
                active_students = sum(1 for s in students_summary if s["summary_stats"]["completion_rate"] > 0)
            else:
                avg_completion = avg_quiz_score = active_students = total_students = 0
            
            return {
                "class_name": class_name,
                "class_summary": {
                    "total_students": total_students,
                    "active_students": active_students,
                    "average_completion_rate": avg_completion,
                    "average_quiz_score": avg_quiz_score
                },
                "students_details": sorted(students_summary, key=lambda x: x["summary_stats"]["completion_rate"], reverse=True)
            }
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching class progress summary: {str(e)}")
        
    @staticmethod
    async def get_comprehensive_progress(class_name: str, teacher_id: str, student_id: str = None, include_visuals: bool = True):
        """Get comprehensive progress data - either for whole class or specific student."""
        try:
            # Verify teacher access
            teacher_classes = TeacherService.get_teacher_allotted_classes(teacher_id)
            if class_name not in teacher_classes:
                raise HTTPException(status_code=403, detail="Access denied to this class")
            
            if student_id:
                # Return detailed student data
                return await AccurateProgressService.get_student_detailed_progress(student_id, teacher_id)
            else:
                # Return class overview
                return await AccurateProgressService.get_class_accurate_analytics(class_name)
                
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching progress: {str(e)}")
        