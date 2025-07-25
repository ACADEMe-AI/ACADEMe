import json
import base64
import asyncio
from io import BytesIO
from datetime import datetime
import matplotlib.pyplot as plt
from fastapi import HTTPException
from typing import Dict, Any, List
from collections import defaultdict
from firebase_admin import firestore
from fastapi.encoders import jsonable_encoder
from services.quiz_service import QuizService
from services.course_service import CourseService
from google.cloud.firestore import DocumentReference
from models.graph_model import ProgressVisualResponse

db = firestore.client()

async def log_progress(user_id: str, progress_data: dict):
    """Logs student progress in Firestore."""
    progress_ref = db.collection("users").document(user_id).collection("progress").document()
    progress_id = progress_ref.id  # ✅ Generate a unique progress ID

    # Ensure `course_id` is included
    course_id = progress_data.get("course_id")
    if not course_id:
        raise HTTPException(status_code=400, detail="course_id is required")

    progress_data["progress_id"] = progress_id  # ✅ Include progress ID
    progress_data["course_id"] = course_id  # ✅ Store `course_id`

    progress_ref.set(progress_data)  # Store in Firestore
    return {"progress_id": progress_id, **progress_data}  # ✅ Return progress_id in response

async def get_student_progress_list(user_id: str):
    """Fetches student progress records."""
    progress_ref = db.collection("users").document(user_id).collection("progress")
    docs = progress_ref.stream()

    progress_list = []
    for doc in docs:
        data = doc.to_dict()

        # Add relevant fields to the response
        progress_entry = {
            "progress_id": doc.id,
            "course_id": data.get("course_id"),
            "topic_id": data.get("topic_id"),
            "subtopic_id": data.get("subtopic_id"),
            "material_id": data.get("material_id"),
            "quiz_id": data.get("quiz_id"),
            "question_id": data.get("question_id"),
            "score": data.get("score"),
            "timestamp": data.get("timestamp"),
            "status": data.get("status"),
            "activity_type": data.get("activity_type"),
            "metadata": data.get("metadata", {}),
        }

        progress_list.append(progress_entry)

    return progress_list

async def get_student_progress(user_id: str):
    """Fetches all progress entries for a student using Firestore's `stream()` asynchronously."""
    try:
        progress_ref = db.collection("users").document(user_id).collection("progress")

        # ✅ Run `stream()` in a separate thread to prevent blocking
        loop = asyncio.get_running_loop()
        progress_docs = await loop.run_in_executor(None, lambda: list(progress_ref.stream()))

        # ✅ Convert Firestore documents to JSON serializable format
        progress_list = [{**doc.to_dict(), "id": doc.id} for doc in progress_docs if doc.exists]

        return progress_list
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching progress: {str(e)}")

async def update_progress_status(user_id: str, progress_id: str, update_data: dict):
    """Updates student progress."""
    progress_ref = db.collection("users").document(user_id).collection("progress").document(progress_id)
    progress_doc = progress_ref.get()

    print(f"🔍 Checking progress record: {progress_ref.path}")

    if not progress_doc.exists:
        print(f"❌ Progress {progress_id} not found for user {user_id}")
        return None  # ✅ Return None if progress not found

    # ✅ Store data in Firestore
    json_data = jsonable_encoder(update_data)  # Ensure proper serialization
    progress_ref.update(json_data)

    print(f"✅ Progress {progress_id} updated successfully for user {user_id}")

    return json_data  # Return the updated data

def fetch_quiz_progress(user_id: str):
    """Fetches only quiz-related progress entries for analytics."""
    try:
        progress_ref = db.collection("users").document(user_id).collection("progress")
        progress_docs = progress_ref.where("category", "==", "quiz").stream()

        return [{**doc.to_dict(), "id": doc.id} for doc in progress_docs if doc.exists]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching quiz progress: {str(e)}")

def get_progress_visuals(progress_data):
    try:
        visual_data = defaultdict(lambda: {
            "quizzes": 0,
            "materials_read": 0,
            "avg_score": 0.0,
            "max_quiz_score": 0.0,  # ✅ Added max_quiz_score initialization
            "quiz_count": 0,  # ✅ Temporary count of completed quizzes
            "quiz_scores": [],
            "score_timeline": [],
            "time_spent_per_day": defaultdict(int)  # ✅ Track time spent per day
        })

        for entry in progress_data:
            topic_id = entry["topic_id"]
            activity_type = entry["activity_type"]
            status = entry["status"]
            score = entry.get("score")
            metadata = entry.get("metadata", {})

            # ✅ Ensure topic_id exists
            if topic_id not in visual_data:
                visual_data[topic_id] = {
                    "quizzes": 0,
                    "materials_read": 0,
                    "avg_score": 0.0,
                    "max_quiz_score": 0.0,  # ✅ Added max_quiz_score initialization
                    "quiz_count": 0,
                    "quiz_scores": [],
                    "score_timeline": [],
                    "time_spent_per_day": defaultdict(int)
                }

            # ✅ Extract time spent
            time_spent = 0
            if "duration" in metadata or "time_spent" in metadata:
                time_str = metadata.get("duration") or metadata.get("time_spent")
                time_spent = int(time_str.split()[0])  # Convert '10 min' → 10

            # ✅ Extract date for daily tracking
            timestamp = entry["timestamp"]
            if isinstance(timestamp, datetime):
                timestamp = timestamp.isoformat()  # Convert to string for JSON
            date_key = timestamp.split("T")[0]  # Extract 'YYYY-MM-DD'

            # ✅ Store time spent per day
            visual_data[topic_id]["time_spent_per_day"][date_key] += time_spent

            # ✅ Store reading materials count
            if activity_type == "reading" and entry["material_id"] is not None:
                visual_data[topic_id]["materials_read"] += 1

            # ✅ Handle quizzes
            if activity_type == "quiz":
                visual_data[topic_id]["quizzes"] += 1
                if status == "completed" and score is not None:
                    # Update avg_score
                    current_avg = visual_data[topic_id]["avg_score"]
                    count = visual_data[topic_id]["quiz_count"]
                    new_avg = ((current_avg * count) + score) / (count + 1)
                    visual_data[topic_id]["avg_score"] = new_avg
                    visual_data[topic_id]["quiz_count"] += 1

                    # ✅ Store discrete quiz scores for line graph
                    visual_data[topic_id]["quiz_scores"].append(score)

                    # ✅ Update max_quiz_score
                    current_max = visual_data[topic_id]["max_quiz_score"]
                    visual_data[topic_id]["max_quiz_score"] = max(current_max, score)

                    # ✅ Store timestamped score for avg_score over time
                    visual_data[topic_id]["score_timeline"].append({
                        "timestamp": timestamp,
                        "score": score,
                        "time_spent": time_spent  # ✅ Time spent in this session
                    })

        # ✅ Convert defaultdict to dict before returning
        for topic_id in visual_data:
            # Convert nested defaultdict to normal dict
            visual_data[topic_id]["time_spent_per_day"] = dict(visual_data[topic_id]["time_spent_per_day"])

            # ✅ Fix: Calculate total `time_spent` from `time_spent_per_day`
            visual_data[topic_id]["time_spent"] = sum(visual_data[topic_id]["time_spent_per_day"].values())

            # ✅ Calculate max_quiz_score from quiz_scores if not already set
            if visual_data[topic_id]["quiz_scores"]:
                visual_data[topic_id]["max_quiz_score"] = max(visual_data[topic_id]["quiz_scores"])
            else:
                visual_data[topic_id]["max_quiz_score"] = 0.0  # Default to 0.0 if no quiz scores

            # Remove temporary fields
            visual_data[topic_id].pop("quiz_count", None)

        return dict(visual_data)

    except Exception as e:
        print(f"🔥 Error in get_progress_visuals: {str(e)}")
        return {}

async def fetch_student_performance(user_id: str):
    """Fetches student performance for AI-driven recommendations, replacing quiz IDs with titles."""
    try:
        progress_data = await get_student_progress(user_id)

        if not isinstance(progress_data, list):
            raise ValueError(f"get_student_progress() returned {type(progress_data)}, expected list.")

        quiz_progress = [p for p in progress_data if p.get("activity_type") == "quiz"]
        if not quiz_progress:
            return {"recommendations": "No quiz progress data available for analysis."}

        # ✅ Call `get_all_quizzes()` correctly (NO await)
        quizzes = QuizService.get_all_quizzes()

        if not isinstance(quizzes, dict):
            raise ValueError(f"get_all_quizzes() returned {type(quizzes)}, expected dict.")

        for p in quiz_progress:
            quiz_id = p.get("quiz_id")
            p["quiz_title"] = quizzes.get(quiz_id, f"Unknown Quiz ({quiz_id})")

        total_score = sum(p.get("score", 0) or 0 for p in quiz_progress)
        avg_score = total_score / len(quiz_progress) if quiz_progress else 0
        completed_topics = sum(1 for p in quiz_progress if p.get("status") == "completed")

        return {
            "total_score": total_score,
            "average_score": avg_score,
            "completed_topics": completed_topics,
            "progress_details": quiz_progress
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching student performance: {str(e)}")

def fetch_progress_from_firestore(user_id):
    try:
        db = firestore.client()
        print(f"Fetching Firestore Progress for user ID: {user_id}")  # ✅ Log User ID

        progress_ref = db.collection("users").document(user_id).collection("progress")
        progress_docs = progress_ref.stream()  # ✅ Fetch multiple documents

        progress_data = []
        for doc in progress_docs:
            progress_entry = doc.to_dict()
            progress_entry["id"] = doc.id  # ✅ Add Firestore document ID
            progress_data.append(progress_entry)

        print(f"✅ Fetched {len(progress_data)} progress records for {user_id}")  # ✅ Log Count
        return progress_data

    except Exception as e:
        print(f"🔥 Error fetching progress from Firestore: {str(e)}")
        return []

async def delete_user_progress(user_id: str):
    """Deletes all progress records for a user."""
    progress_ref = db.collection("users").document(user_id).collection("progress")
    docs = list(progress_ref.stream())  # Convert to list to avoid iterator issues

    loop = asyncio.get_running_loop()
    
    # Properly pass the callable `delete` method using a lambda
    await asyncio.gather(*(loop.run_in_executor(None, lambda doc=doc: doc.reference.delete()) for doc in docs))

    return {"message": f"All progress records deleted for user {user_id}"}
