import asyncio
from datetime import datetime
from typing import Dict, List, Any
from firebase_admin import firestore
from collections import defaultdict

db = firestore.client()

class AccurateProgressService:
    
    @staticmethod
    async def calculate_accurate_completion_rate(student_id: str, class_name: str = None) -> float:
        """Calculate accurate completion rate based on total materials vs completed materials."""
        try:
            # Get all courses for the student's class
            if not class_name:
                student_ref = db.collection("users").document(student_id)
                student_doc = student_ref.get()
                if not student_doc.exists:
                    return 0.0
                class_name = student_doc.to_dict().get("student_class")
            
            # Get all courses for this class
            courses_ref = db.collection("courses").where("class_name", "==", class_name).stream()
            total_materials = 0
            
            # Count total materials across all courses, topics, and subtopics
            for course in courses_ref:
                course_id = course.id
                
                # Count materials in topics
                topics_ref = db.collection("courses").document(course_id).collection("topics").stream()
                for topic in topics_ref:
                    topic_id = topic.id
                    
                    # Materials directly under topic
                    topic_materials = db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("materials").stream()
                    total_materials += len(list(topic_materials))
                    
                    # Materials under subtopics
                    subtopics_ref = db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("subtopics").stream()
                    for subtopic in subtopics_ref:
                        subtopic_id = subtopic.id
                        subtopic_materials = db.collection("courses").document(course_id).collection("topics").document(topic_id).collection("subtopics").document(subtopic_id).collection("materials").stream()
                        total_materials += len(list(subtopic_materials))
            
            if total_materials == 0:
                return 0.0
                
            # Get student's completed materials
            progress_ref = db.collection("users").document(student_id).collection("progress")
            progress_docs = progress_ref.where("activity_type", "==", "reading").where("status", "==", "completed").stream()
            completed_materials = len(list(progress_docs))
            
            completion_rate = (completed_materials / total_materials) * 100
            return min(completion_rate, 100.0)  # Cap at 100%
            
        except Exception as e:
            print(f"Error calculating completion rate: {e}")
            return 0.0
    
    @staticmethod
    async def calculate_accurate_quiz_score(student_id: str) -> Dict[str, float]:
        """Calculate accurate overall quiz performance."""
        try:
            progress_ref = db.collection("users").document(student_id).collection("progress")
            quiz_docs = progress_ref.where("activity_type", "==", "quiz").where("status", "==", "completed").stream()
            
            quiz_scores = []
            total_score = 0
            quiz_count = 0
            
            for doc in quiz_docs:
                data = doc.to_dict()
                score = data.get("score", 0)
                if score is not None and score > 0:
                    quiz_scores.append(score)
                    total_score += score
                    quiz_count += 1
            
            if quiz_count == 0:
                return {"average_score": 0.0, "total_score": 0, "quiz_count": 0, "max_score": 0.0}
            
            average_score = total_score / quiz_count
            max_score = max(quiz_scores) if quiz_scores else 0.0
            
            return {
                "average_score": round(average_score, 2),
                "total_score": total_score,
                "quiz_count": quiz_count,
                "max_score": max_score,
                "all_scores": quiz_scores
            }
            
        except Exception as e:
            print(f"Error calculating quiz scores: {e}")
            return {"average_score": 0.0, "total_score": 0, "quiz_count": 0, "max_score": 0.0}
    
    @staticmethod
    async def get_class_accurate_analytics(class_name: str) -> Dict[str, Any]:
        """Get accurate analytics for entire class."""
        try:
            # Get all students in class
            students_ref = db.collection("users").where("student_class", "==", class_name).stream()
            students_data = []
            class_totals = {
                "total_students": 0,
                "active_students": 0,
                "total_quiz_scores": 0,
                "total_completion_rates": 0,
                "students_with_progress": 0
            }
            
            for student_doc in students_ref:
                student_data = student_doc.to_dict()
                student_id = student_doc.id
                
                # Calculate accurate metrics for each student
                completion_rate = await AccurateProgressService.calculate_accurate_completion_rate(student_id, class_name)
                quiz_data = await AccurateProgressService.calculate_accurate_quiz_score(student_id)
                
                student_summary = {
                    "student_id": student_id,
                    "name": student_data.get("name", "Unknown"),
                    "email": student_data.get("email", ""),
                    "photo_url": student_data.get("photo_url"),
                    "completion_rate": completion_rate,
                    "quiz_performance": quiz_data,
                    "is_active": completion_rate > 0 or quiz_data["quiz_count"] > 0
                }
                
                students_data.append(student_summary)
                
                # Update class totals
                class_totals["total_students"] += 1
                if student_summary["is_active"]:
                    class_totals["active_students"] += 1
                    class_totals["students_with_progress"] += 1
                    
                class_totals["total_quiz_scores"] += quiz_data["average_score"]
                class_totals["total_completion_rates"] += completion_rate
            
            # Calculate class averages
            total_students = class_totals["total_students"]
            if total_students > 0:
                class_avg_quiz_score = class_totals["total_quiz_scores"] / total_students
                class_avg_completion = class_totals["total_completion_rates"] / total_students
            else:
                class_avg_quiz_score = 0
                class_avg_completion = 0
            
            return {
                "class_name": class_name,
                "class_summary": {
                    "total_students": total_students,
                    "active_students": class_totals["active_students"],
                    "average_completion_rate": round(class_avg_completion, 2),
                    "average_quiz_score": round(class_avg_quiz_score, 2),
                    "students_with_progress": class_totals["students_with_progress"]
                },
                "students_details": sorted(students_data, key=lambda x: x["completion_rate"], reverse=True)
            }
            
        except Exception as e:
            print(f"Error getting class analytics: {e}")
            return {"error": str(e)}
    
    @staticmethod
    async def get_student_detailed_progress(student_id: str, teacher_id: str) -> Dict[str, Any]:
        """Get comprehensive student progress with visual analytics."""
        try:
            # Verify student exists and get class
            student_ref = db.collection("users").document(student_id)
            student_doc = student_ref.get()
            
            if not student_doc.exists:
                return {"error": "Student not found"}
            
            student_data = student_doc.to_dict()
            class_name = student_data.get("student_class")
            
            # Verify teacher access
            from services.teacher_service import TeacherService
            teacher_classes = TeacherService.get_teacher_allotted_classes(teacher_id)
            if class_name not in teacher_classes:
                return {"error": "Access denied"}
            
            # Get accurate metrics
            completion_rate = await AccurateProgressService.calculate_accurate_completion_rate(student_id, class_name)
            quiz_data = await AccurateProgressService.calculate_accurate_quiz_score(student_id)
            
            # Get detailed progress for visuals
            from services.progress_service import fetch_progress_from_firestore, get_progress_visuals
            progress_data = fetch_progress_from_firestore(student_id)
            visual_data = get_progress_visuals(progress_data)
            
            return {
                "student_info": {
                    "student_id": student_id,
                    "name": student_data.get("name", "Unknown"),
                    "email": student_data.get("email", ""),
                    "class": class_name,
                    "photo_url": student_data.get("photo_url")
                },
                "accurate_metrics": {
                    "completion_rate": completion_rate,
                    "quiz_performance": quiz_data,
                    "is_active": completion_rate > 0 or quiz_data["quiz_count"] > 0
                },
                "visual_analytics": visual_data,
                "detailed_progress": progress_data[-20:]  # Last 20 activities
            }
            
        except Exception as e:
            return {"error": f"Error getting student details: {str(e)}"}
        