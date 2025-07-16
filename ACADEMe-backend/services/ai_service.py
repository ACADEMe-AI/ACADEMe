import os
import json
import google.generativeai as genai
from services.quiz_service import QuizService
from services.course_service import CourseService
from config.settings import GOOGLE_GEMINI_API_KEY
from services.progress_service import fetch_student_performance
from services.firebase_service import FirebaseService

genai.configure(api_key=GOOGLE_GEMINI_API_KEY)

# ✅ Initialize Firebase service
firebase_service = FirebaseService()

async def get_recommendations(user_id: str, target_language: str = "en"):
    """
    Fetch student progress, analyze it using Gemini AI, and return personalized recommendations.
    Automatically translates the response into the specified target language.
    """
    try:
        # ✅ Fetch student progress data
        progress_data = await fetch_student_performance(user_id)

        # ✅ Parse progress data if it's a JSON string
        if isinstance(progress_data, str):
            try:
                progress_data = json.loads(progress_data)
            except json.JSONDecodeError:
                raise ValueError(f"Invalid JSON format in progress data: {progress_data}")

        # ✅ Ensure progress_data is a list
        if isinstance(progress_data, dict):
            progress_data = [progress_data]

        if not isinstance(progress_data, list):
            raise ValueError(f"Expected a list, but got: {type(progress_data)}")

        # ✅ Extract unique IDs from progress data
        unique_ids = extract_unique_ids(progress_data)
        
        # ✅ Fetch only the required mappings from Firebase
        data_mappings = await fetch_mappings_from_firebase(unique_ids)
        
        # ✅ Enrich progress data with actual names
        enriched_progress_data = enrich_progress_data(progress_data, data_mappings)

        # ✅ Construct a focused prompt for Gemini AI with only relevant data
        prompt = f"""
        You are an advanced AI tutor analyzing student learning progress.
        You have access to the following relevant course data:

        - Courses: {json.dumps(data_mappings["courses"], indent=2, ensure_ascii=False)}
        - Topics: {json.dumps(data_mappings["topics"], indent=2, ensure_ascii=False)}
        - Subtopics: {json.dumps(data_mappings["subtopics"], indent=2, ensure_ascii=False)}
        - Quizzes: {json.dumps(data_mappings["quizzes"], indent=2, ensure_ascii=False)}
        - Materials: {json.dumps(data_mappings["materials"], indent=2, ensure_ascii=False)}

        The student's progress data is as follows:
        {json.dumps(enriched_progress_data, indent=2, ensure_ascii=False)}

        Based on the student's performance and learning history, provide personalized recommendations.
        Include:
        - Areas where the student is struggling.
        - A learning roadmap tailored to their progress.
        - Suggested topics, subtopics, and quizzes they should focus on.
        - Any extra study materials they should review.

        Make your recommendations concise, structured, and easy to follow. 
        Always use actual course, topic, subtopic, quiz, and material names instead of IDs.
        Each quiz is worth 100 points.
        """

        # ✅ Generate AI recommendations
        model = genai.GenerativeModel("gemini-2.0-flash")
        response = model.generate_content(prompt)

        # ✅ Translate the recommendations into the target language
        translated_text = await CourseService.translate_text(response.text, target_language)

        return {"recommendations": translated_text}
    
    except Exception as e:
        print(f"Error in get_recommendations: {e}")
        return {"error": f"Failed to generate recommendations: {str(e)}"}


def extract_unique_ids(progress_data):
    """
    Extract unique IDs from progress data to minimize Firebase queries.
    """
    unique_ids = {
        "course_ids": set(),
        "topic_ids": set(),
        "subtopic_ids": set(),
        "quiz_ids": set(),
        "material_ids": set()
    }
    
    for record in progress_data:
        if isinstance(record, dict):
            # Extract course_id
            if "course_id" in record and record["course_id"]:
                unique_ids["course_ids"].add(record["course_id"])
            
            # Extract topic_id
            if "topic_id" in record and record["topic_id"]:
                unique_ids["topic_ids"].add(record["topic_id"])
            
            # Extract subtopic_id
            if "subtopic_id" in record and record["subtopic_id"]:
                unique_ids["subtopic_ids"].add(record["subtopic_id"])
            
            # Extract quiz_id
            if "quiz_id" in record and record["quiz_id"]:
                unique_ids["quiz_ids"].add(record["quiz_id"])
            
            # Extract material_id
            if "material_id" in record and record["material_id"]:
                unique_ids["material_ids"].add(record["material_id"])
    
    # Convert sets to lists for easier handling
    return {key: list(value) for key, value in unique_ids.items()}


async def fetch_mappings_from_firebase(unique_ids):
    """
    Fetch only the required ID-to-name mappings from Firebase.
    """
    data_mappings = {
        "courses": {},
        "topics": {},
        "subtopics": {},
        "quizzes": {},
        "materials": {}
    }
    
    try:
        # ✅ Fetch courses
        if unique_ids["course_ids"]:
            courses = await firebase_service.get_courses_by_ids(unique_ids["course_ids"])
            data_mappings["courses"] = {course["id"]: course.get("name", "Unknown Course") for course in courses}
        
        # ✅ Fetch topics
        if unique_ids["topic_ids"]:
            topics = await firebase_service.get_topics_by_ids(unique_ids["topic_ids"])
            data_mappings["topics"] = {topic["id"]: topic.get("name", "Unknown Topic") for topic in topics}
        
        # ✅ Fetch subtopics
        if unique_ids["subtopic_ids"]:
            subtopics = await firebase_service.get_subtopics_by_ids(unique_ids["subtopic_ids"])
            data_mappings["subtopics"] = {subtopic["id"]: subtopic.get("name", "Unknown Subtopic") for subtopic in subtopics}
        
        # ✅ Fetch quizzes
        if unique_ids["quiz_ids"]:
            quizzes = await firebase_service.get_quizzes_by_ids(unique_ids["quiz_ids"])
            data_mappings["quizzes"] = {quiz["id"]: quiz.get("title", "Unknown Quiz") for quiz in quizzes}
        
        # ✅ Fetch materials
        if unique_ids["material_ids"]:
            materials = await firebase_service.get_materials_by_ids(unique_ids["material_ids"])
            data_mappings["materials"] = {material["id"]: material.get("title", "Unknown Material") for material in materials}
    
    except Exception as e:
        print(f"Error fetching mappings from Firebase: {e}")
        # Return empty mappings if there's an error
        pass
    
    return data_mappings


def enrich_progress_data(progress_data, data_mappings):
    """
    Enrich progress data with actual names instead of IDs.
    """
    enriched_data = []
    
    for record in progress_data:
        if isinstance(record, dict):
            enriched_record = record.copy()
            
            # ✅ Replace IDs with actual titles/content
            if "quiz_id" in record and record["quiz_id"] in data_mappings["quizzes"]:
                enriched_record["quiz_title"] = data_mappings["quizzes"][record["quiz_id"]]
            
            if "course_id" in record and record["course_id"] in data_mappings["courses"]:
                enriched_record["course_title"] = data_mappings["courses"][record["course_id"]]
            
            if "topic_id" in record and record["topic_id"] in data_mappings["topics"]:
                enriched_record["topic_title"] = data_mappings["topics"][record["topic_id"]]
            
            if "subtopic_id" in record and record["subtopic_id"] in data_mappings["subtopics"]:
                enriched_record["subtopic_title"] = data_mappings["subtopics"][record["subtopic_id"]]
            
            if "material_id" in record and record["material_id"] in data_mappings["materials"]:
                enriched_record["material_title"] = data_mappings["materials"][record["material_id"]]
            
            enriched_data.append(enriched_record)
        else:
            print(f"Warning: Unexpected progress data format: {record}")
            # Still add the record even if it's not a dict
            enriched_data.append(record)
    
    return enriched_data
