import uuid
from datetime import datetime
from typing import Dict, List, Any, Optional
from firebase_admin import firestore
from fastapi import HTTPException
from collections import defaultdict

db = firestore.client()

class TeacherExamService:
    
    @staticmethod
    async def create_exam(exam_data: Dict[str, Any], teacher_id: str) -> Dict[str, Any]:
        """Create a new exam with questions."""
        try:
            # Verify teacher has access to the class
            from services.teacher_service import TeacherService
            teacher_classes = TeacherService.get_teacher_allotted_classes(teacher_id)
            if exam_data["class_name"] not in teacher_classes:
                raise HTTPException(status_code=403, detail="Not authorized to create exam for this class")
            
            exam_id = str(uuid.uuid4())
            
            # Prepare exam document
            exam_doc = {
                "id": exam_id,
                "teacher_id": teacher_id,
                "title": exam_data["title"],
                "description": exam_data["description"],
                "class_name": exam_data["class_name"],
                "subject": exam_data["subject"],
                "duration_minutes": exam_data["duration_minutes"],
                "total_marks": exam_data["total_marks"],
                "exam_type": exam_data["exam_type"],
                "instructions": exam_data.get("instructions", ""),
                "scheduled_date": exam_data.get("scheduled_date"),
                "is_published": exam_data.get("is_published", False),
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow(),
                "quiz_questions_count": len(exam_data.get("quiz_questions", [])),
                "subjective_questions_count": len(exam_data.get("subjective_questions", [])),
                "total_questions": len(exam_data.get("quiz_questions", [])) + len(exam_data.get("subjective_questions", []))
            }
            
            # Store exam in Firestore
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_ref.set(exam_doc)
            
            # Add quiz questions
            for i, question in enumerate(exam_data.get("quiz_questions", [])):
                await TeacherExamService._add_quiz_question_internal(exam_id, question, i + 1)
            
            # Add subjective questions
            question_number = len(exam_data.get("quiz_questions", [])) + 1
            for i, question in enumerate(exam_data.get("subjective_questions", [])):
                await TeacherExamService._add_subjective_question_internal(exam_id, question, question_number + i)
            
            return {
                "message": "Exam created successfully",
                "exam_id": exam_id,
                "title": exam_data["title"],
                "total_questions": exam_doc["total_questions"]
            }
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error creating exam: {str(e)}")
    
    @staticmethod
    async def _add_quiz_question_internal(exam_id: str, question_data: Dict, question_number: int):
        """Internal method to add quiz question."""
        question_id = str(uuid.uuid4())
        question_doc = {
            "id": question_id,
            "exam_id": exam_id,
            "question_number": question_number,
            "question_type": "quiz",
            "question_text": question_data["question_text"],
            "options": question_data["options"],
            "correct_answer": question_data["correct_answer"],
            "marks": question_data.get("marks", 1),
            "created_at": datetime.utcnow()
        }
        
        db.collection("teacher_exams").document(exam_id).collection("questions").document(question_id).set(question_doc)
    
    @staticmethod
    async def _add_subjective_question_internal(exam_id: str, question_data: Dict, question_number: int):
        """Internal method to add subjective question."""
        question_id = str(uuid.uuid4())
        question_doc = {
            "id": question_id,
            "exam_id": exam_id,
            "question_number": question_number,
            "question_type": "subjective",
            "question_text": question_data["question_text"],
            "marks": question_data["marks"],
            "expected_answer_length": question_data.get("expected_answer_length", "short"),
            "rubric": question_data.get("rubric", ""),
            "created_at": datetime.utcnow()
        }
        
        db.collection("teacher_exams").document(exam_id).collection("questions").document(question_id).set(question_doc)
    
    @staticmethod
    async def get_teacher_exams(teacher_id: str, class_name: str = None) -> List[Dict[str, Any]]:
        """Get all exams created by teacher."""
        try:
            query = db.collection("teacher_exams").where("teacher_id", "==", teacher_id)
            if class_name:
                query = query.where("class_name", "==", class_name)
            
            exams_ref = query.stream()
            exams = []
            
            for exam_doc in exams_ref:
                exam_data = exam_doc.to_dict()
                
                # Get submission count
                submissions_count = len(list(
                    db.collection("exam_submissions")
                    .where("exam_id", "==", exam_doc.id)
                    .stream()
                ))
                
                exam_summary = {
                    "id": exam_data["id"],
                    "title": exam_data["title"],
                    "description": exam_data["description"],
                    "class_name": exam_data["class_name"],
                    "subject": exam_data["subject"],
                    "exam_type": exam_data["exam_type"],
                    "total_marks": exam_data["total_marks"],
                    "total_questions": exam_data["total_questions"],
                    "duration_minutes": exam_data["duration_minutes"],
                    "is_published": exam_data["is_published"],
                    "scheduled_date": exam_data.get("scheduled_date"),
                    "created_at": exam_data["created_at"],
                    "submissions_count": submissions_count
                }
                
                exams.append(exam_summary)
            
            return sorted(exams, key=lambda x: x["created_at"], reverse=True)
            
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching exams: {str(e)}")
    
    @staticmethod
    async def get_exam_details(exam_id: str, teacher_id: str) -> Dict[str, Any]:
        """Get detailed exam information with all questions."""
        try:
            # Get exam document
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            
            # Verify teacher ownership
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized to view this exam")
            
            # Get all questions
            questions_ref = exam_ref.collection("questions").order_by("question_number").stream()
            questions = []
            
            for question_doc in questions_ref:
                question_data = question_doc.to_dict()
                questions.append(question_data)
            
            exam_details = {
                **exam_data,
                "questions": questions,
                "questions_count": len(questions)
            }
            
            return exam_details
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching exam details: {str(e)}")
    
    @staticmethod
    async def add_quiz_question(exam_id: str, question_data: Dict, teacher_id: str) -> Dict[str, Any]:
        """Add a quiz question to an existing exam."""
        try:
            # Verify exam ownership
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Get next question number
            questions_count = len(list(exam_ref.collection("questions").stream()))
            next_question_number = questions_count + 1
            
            # Add question
            await TeacherExamService._add_quiz_question_internal(exam_id, question_data, next_question_number)
            
            # Update exam totals
            exam_ref.update({
                "quiz_questions_count": exam_data.get("quiz_questions_count", 0) + 1,
                "total_questions": exam_data.get("total_questions", 0) + 1,
                "total_marks": exam_data.get("total_marks", 0) + question_data.get("marks", 1),
                "updated_at": datetime.utcnow()
            })
            
            return {"message": "Quiz question added successfully", "question_number": next_question_number}
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding question: {str(e)}")
    
    @staticmethod
    async def add_subjective_question(exam_id: str, question_data: Dict, teacher_id: str) -> Dict[str, Any]:
        """Add a subjective question to an existing exam."""
        try:
            # Verify exam ownership
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Get next question number
            questions_count = len(list(exam_ref.collection("questions").stream()))
            next_question_number = questions_count + 1
            
            # Add question
            await TeacherExamService._add_subjective_question_internal(exam_id, question_data, next_question_number)
            
            # Update exam totals
            exam_ref.update({
                "subjective_questions_count": exam_data.get("subjective_questions_count", 0) + 1,
                "total_questions": exam_data.get("total_questions", 0) + 1,
                "total_marks": exam_data.get("total_marks", 0) + question_data.get("marks", 5),
                "updated_at": datetime.utcnow()
            })
            
            return {"message": "Subjective question added successfully", "question_number": next_question_number}
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding question: {str(e)}")
    
    @staticmethod
    async def publish_exam(exam_id: str, teacher_id: str) -> Dict[str, Any]:
        """Publish an exam to make it available to students."""
        try:
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Check if exam has questions
            questions_count = len(list(exam_ref.collection("questions").stream()))
            if questions_count == 0:
                raise HTTPException(status_code=400, detail="Cannot publish exam without questions")
            
            # Publish exam
            exam_ref.update({
                "is_published": True,
                "published_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            })
            
            return {"message": "Exam published successfully"}
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error publishing exam: {str(e)}")
    
    @staticmethod
    async def get_exam_submissions(exam_id: str, teacher_id: str) -> Dict[str, Any]:
        """Get all submissions for an exam."""
        try:
            # Verify exam ownership
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Get submissions
            submissions_ref = db.collection("exam_submissions").where("exam_id", "==", exam_id).stream()
            submissions = []
            
            for submission_doc in submissions_ref:
                submission_data = submission_doc.to_dict()
                
                # Get student info
                student_ref = db.collection("users").document(submission_data["student_id"])
                student_doc = student_ref.get()
                student_name = "Unknown Student"
                if student_doc.exists:
                    student_name = student_doc.to_dict().get("name", "Unknown Student")
                
                submission_summary = {
                    "submission_id": submission_doc.id,
                    "student_id": submission_data["student_id"],
                    "student_name": student_name,
                    "submitted_at": submission_data["submitted_at"],
                    "status": submission_data["status"],
                    "quiz_score": submission_data.get("quiz_score", 0),
                    "total_score": submission_data.get("total_score", 0),
                    "is_graded": submission_data.get("is_graded", False)
                }
                
                submissions.append(submission_summary)
            
            return {
                "exam_title": exam_data["title"],
                "total_submissions": len(submissions),
                "submissions": sorted(submissions, key=lambda x: x["submitted_at"], reverse=True)
            }
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching submissions: {str(e)}")
    
    @staticmethod
    async def get_exam_analytics(exam_id: str, teacher_id: str) -> Dict[str, Any]:
        """Get analytics for an exam."""
        try:
            # Verify exam ownership
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Get submissions for analytics
            submissions_ref = db.collection("exam_submissions").where("exam_id", "==", exam_id).stream()
            submissions = [doc.to_dict() for doc in submissions_ref]
            
            if not submissions:
                return {
                    "exam_title": exam_data["title"],
                    "total_students_attempted": 0,
                    "analytics": "No submissions yet"
                }
            
            # Calculate analytics
            total_attempts = len(submissions)
            completed_submissions = [s for s in submissions if s.get("status") == "completed"]
            
            quiz_scores = [s.get("quiz_score", 0) for s in completed_submissions if s.get("quiz_score") is not None]
            total_scores = [s.get("total_score", 0) for s in completed_submissions if s.get("total_score") is not None]
            
            analytics = {
                "exam_info": {
                    "title": exam_data["title"],
                    "total_marks": exam_data["total_marks"],
                    "total_questions": exam_data["total_questions"]
                },
                "participation": {
                    "total_attempts": total_attempts,
                    "completed_submissions": len(completed_submissions),
                    "completion_rate": (len(completed_submissions) / total_attempts * 100) if total_attempts > 0 else 0
                },
                "performance": {
                    "average_quiz_score": sum(quiz_scores) / len(quiz_scores) if quiz_scores else 0,
                    "average_total_score": sum(total_scores) / len(total_scores) if total_scores else 0,
                    "highest_score": max(total_scores) if total_scores else 0,
                    "lowest_score": min(total_scores) if total_scores else 0,
                    "pass_rate": len([s for s in total_scores if s >= (exam_data["total_marks"] * 0.6)]) / len(total_scores) * 100 if total_scores else 0
                },
                "score_distribution": {
                    "excellent_90_100": len([s for s in total_scores if s >= exam_data["total_marks"] * 0.9]),
                    "good_80_89": len([s for s in total_scores if exam_data["total_marks"] * 0.8 <= s < exam_data["total_marks"] * 0.9]),
                    "average_60_79": len([s for s in total_scores if exam_data["total_marks"] * 0.6 <= s < exam_data["total_marks"] * 0.8]),
                    "below_average_60": len([s for s in total_scores if s < exam_data["total_marks"] * 0.6])
                }
            }
            
            return analytics
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error generating analytics: {str(e)}")
    
    @staticmethod
    async def delete_exam(exam_id: str, teacher_id: str) -> Dict[str, Any]:
        """Delete an exam if no submissions exist."""
        try:
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Check for existing submissions
            submissions = list(db.collection("exam_submissions").where("exam_id", "==", exam_id).limit(1).stream())
            if submissions:
                raise HTTPException(status_code=400, detail="Cannot delete exam with existing submissions")
            
            # Delete all questions first
            questions_ref = exam_ref.collection("questions").stream()
            for question in questions_ref:
                question.reference.delete()
            
            # Delete exam document
            exam_ref.delete()
            
            return {"message": "Exam deleted successfully"}
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error deleting exam: {str(e)}")
    
    @staticmethod
    async def update_exam(exam_id: str, update_data: Dict[str, Any], teacher_id: str) -> Dict[str, Any]:
        """Update exam information."""
        try:
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Check if exam is published and has submissions
            if exam_data.get("is_published") and update_data.get("is_published") is False:
                submissions = list(db.collection("exam_submissions").where("exam_id", "==", exam_id).limit(1).stream())
                if submissions:
                    raise HTTPException(status_code=400, detail="Cannot unpublish exam with existing submissions")
            
            # Prepare update fields
            update_fields = {k: v for k, v in update_data.items() if v is not None}
            update_fields["updated_at"] = datetime.utcnow()
            
            exam_ref.update(update_fields)
            
            return {"message": "Exam updated successfully", "updated_fields": list(update_fields.keys())}
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error updating exam: {str(e)}")
    
    @staticmethod
    async def remove_question(exam_id: str, question_id: str, teacher_id: str) -> Dict[str, Any]:
        """Remove a question from an exam."""
        try:
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Check if exam has submissions
            submissions = list(db.collection("exam_submissions").where("exam_id", "==", exam_id).limit(1).stream())
            if submissions:
                raise HTTPException(status_code=400, detail="Cannot modify exam with existing submissions")
            
            # Get question to determine type and marks
            question_ref = exam_ref.collection("questions").document(question_id)
            question_doc = question_ref.get()
            
            if not question_doc.exists:
                raise HTTPException(status_code=404, detail="Question not found")
            
            question_data = question_doc.to_dict()
            question_type = question_data["question_type"]
            marks = question_data.get("marks", 1)
            
            # Delete question
            question_ref.delete()
            
            # Update exam counters
            update_data = {
                "total_questions": exam_data.get("total_questions", 1) - 1,
                "total_marks": max(0, exam_data.get("total_marks", marks) - marks),
                "updated_at": datetime.utcnow()
            }
            
            if question_type == "quiz":
                update_data["quiz_questions_count"] = max(0, exam_data.get("quiz_questions_count", 1) - 1)
            else:
                update_data["subjective_questions_count"] = max(0, exam_data.get("subjective_questions_count", 1) - 1)
            
            exam_ref.update(update_data)
            
            return {"message": "Question removed successfully"}
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error removing question: {str(e)}")
    
    @staticmethod
    async def unpublish_exam(exam_id: str, teacher_id: str) -> Dict[str, Any]:
        """Unpublish an exam."""
        try:
            exam_ref = db.collection("teacher_exams").document(exam_id)
            exam_doc = exam_ref.get()
            
            if not exam_doc.exists:
                raise HTTPException(status_code=404, detail="Exam not found")
            
            exam_data = exam_doc.to_dict()
            if exam_data["teacher_id"] != teacher_id:
                raise HTTPException(status_code=403, detail="Not authorized")
            
            # Check for submissions
            submissions = list(db.collection("exam_submissions").where("exam_id", "==", exam_id).limit(1).stream())
            if submissions:
                raise HTTPException(status_code=400, detail="Cannot unpublish exam with existing submissions")
            
            exam_ref.update({
                "is_published": False,
                "updated_at": datetime.utcnow()
            })
            
            return {"message": "Exam unpublished successfully"}
            
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error unpublishing exam: {str(e)}")
        