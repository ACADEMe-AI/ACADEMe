import uuid
from datetime import datetime
from fastapi import HTTPException
from firebase_admin import firestore
from services.course_service import CourseService
from models.teacher_models import (
    TeacherCourseCreate, TeacherCourseResponse,
    TeacherTopicCreate, TeacherTopicResponse,
    TeacherMaterialCreate, TeacherMaterialResponse
)
import utils.firestore_helpers as firestore_helpers

db = firestore.client()

class TeacherCourseService:
    @staticmethod
    async def create_teacher_course(course: TeacherCourseCreate, teacher_id: str):
        """Creates a new teacher course with multilingual support."""
        course_id = str(uuid.uuid4())
        course_ref = db.collection("teacher_courses").document(course_id)

        if course_ref.get().exists:
            raise HTTPException(status_code=400, detail="Course already exists")

        now = datetime.utcnow()

        # Detect language dynamically
        detected_lang = await CourseService.detect_language([course.title, course.description])
        translations = {
            detected_lang: {
                "title": course.title,
                "description": course.description,
            }
        }

        # Translate into other languages
        target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]
        translation_tasks = {
            lang: {
                "title": CourseService.translate_text(course.title, lang),
                "description": CourseService.translate_text(course.description, lang),
            }
            for lang in target_languages
        }

        for lang in target_languages:
            translations[lang] = {
                "title": await translation_tasks[lang]["title"],
                "description": await translation_tasks[lang]["description"],
            }

        course_data = {
            "id": course_id,
            "teacher_id": teacher_id,
            "class_name": course.class_name,
            "created_at": now,
            "updated_at": now,
            "languages": translations,
        }

        course_ref.set(course_data)
        
        # Store ID mapping
        firestore_helpers.FirestoreUtils.store_id_mapping("teacher_courses", course_id, course.title)

        return TeacherCourseResponse(
            **course_data,
            title=translations[detected_lang]["title"],
            description=translations[detected_lang]["description"]
        )

    @staticmethod
    def get_teacher_courses(teacher_id: str, target_language: str = "en"):
        """Fetches teacher courses in the requested language."""
        courses_ref = db.collection("teacher_courses").where("teacher_id", "==", teacher_id).stream()

        courses = []
        for doc in courses_ref:
            course_data = doc.to_dict()

            if "languages" not in course_data:
                raise HTTPException(status_code=500, detail=f"Missing 'languages' field in course {doc.id}")

            lang_data = course_data["languages"].get(target_language, {}) or course_data["languages"].get("en", {})

            courses.append(TeacherCourseResponse(
                id=course_data["id"],
                title=lang_data.get("title", "Untitled Course"),
                class_name=course_data["class_name"],
                description=lang_data.get("description", "No Description"),
                teacher_id=course_data["teacher_id"],
                created_at=course_data["created_at"],
                updated_at=course_data["updated_at"],
            ))

        return courses

    @staticmethod
    async def create_teacher_topic(course_id: str, topic: TeacherTopicCreate, teacher_id: str):
        """Creates a new topic in teacher course."""
        topic_id = str(uuid.uuid4())
        
        # Verify teacher owns the course
        course_ref = db.collection("teacher_courses").document(course_id)
        course_doc = course_ref.get()
        
        if not course_doc.exists:
            raise HTTPException(status_code=404, detail="Course not found")
        
        course_data = course_doc.to_dict()
        if course_data["teacher_id"] != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized to modify this course")

        detected_lang = await CourseService.detect_language([topic.title, topic.description or ""])

        languages = {
            detected_lang: {"title": topic.title, "description": topic.description or ""}
        }

        target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]
        translation_tasks = {
            lang: {
                "title": CourseService.translate_text(topic.title, lang),
                "description": CourseService.translate_text(topic.description or "", lang),
            }
            for lang in target_languages
        }

        for lang in target_languages:
            languages[lang] = {
                "title": await translation_tasks[lang]["title"],
                "description": await translation_tasks[lang]["description"],
            }

        topic_data = {
            "id": topic_id,
            "course_id": course_id,
            "created_at": datetime.utcnow(),
            "languages": languages,
        }

        db.collection("teacher_courses").document(course_id).collection("topics").document(topic_id).set(topic_data)
        
        firestore_helpers.FirestoreUtils.store_id_mapping("teacher_topics", topic_id, topic.title)

        return {"message": "Topic created successfully", "topic_id": topic_id}

    @staticmethod
    def get_teacher_course_topics(course_id: str, teacher_id: str, target_language: str = "en"):
        """Fetches all topics for a teacher course."""
        # Verify teacher owns the course
        course_ref = db.collection("teacher_courses").document(course_id)
        course_doc = course_ref.get()
        
        if not course_doc.exists:
            raise HTTPException(status_code=404, detail="Course not found")
        
        course_data = course_doc.to_dict()
        if course_data["teacher_id"] != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized to access this course")

        topics_ref = db.collection("teacher_courses").document(course_id).collection("topics").stream()
        topics = []

        for topic in topics_ref:
            topic_data = topic.to_dict()

            if "languages" not in topic_data:
                continue

            lang_data = topic_data["languages"].get(target_language) or topic_data["languages"].get("en", {})

            topics.append({
                "id": topic.id,
                "title": lang_data.get("title", ""),
                "description": lang_data.get("description", ""),
                "course_id": course_id,
                "created_at": topic_data["created_at"],
            })

        return topics

    @staticmethod
    async def add_teacher_material(
        course_id: str,
        topic_id: str,
        material: dict,
        teacher_id: str
    ) -> TeacherMaterialResponse:
        """Adds a material to teacher topic."""
        # Verify teacher owns the course
        course_ref = db.collection("teacher_courses").document(course_id)
        course_doc = course_ref.get()
        
        if not course_doc.exists:
            raise HTTPException(status_code=404, detail="Course not found")
        
        course_data = course_doc.to_dict()
        if course_data["teacher_id"] != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized to modify this course")

        try:
            material_id = str(uuid.uuid4())
            material["id"] = material_id
            material["course_id"] = course_id
            material["topic_id"] = topic_id
            material["created_at"] = datetime.utcnow().isoformat()
            material["updated_at"] = datetime.utcnow().isoformat()

            # Detect language and translate
            detected_lang = "en"
            text_fields = [material.get("content", ""), material.get("optional_text", "")]
            if any(text_fields):
                detected_lang = await CourseService.detect_language(text_fields) or "en"

            languages = {
                detected_lang: {
                    "content": material.get("content", ""),
                    "optional_text": material.get("optional_text", ""),
                }
            }

            target_languages = ["fr", "es", "de", "zh", "ar", "hi", "en"]
            translation_tasks = {
                lang: {
                    "content": CourseService.translate_text(material["content"], lang) if material["type"] == "text" else None,
                    "optional_text": CourseService.translate_text(material["optional_text"], lang) if material.get("optional_text") else None,
                }
                for lang in target_languages
            }

            for lang in target_languages:
                languages[lang] = {
                    "content": await translation_tasks[lang]["content"] if translation_tasks[lang]["content"] else material["content"],
                    "optional_text": await translation_tasks[lang]["optional_text"] if translation_tasks[lang]["optional_text"] else "",
                }

            material["languages"] = languages

            ref = (
                db.collection("teacher_courses")
                .document(course_id)
                .collection("topics")
                .document(topic_id)
                .collection("materials")
                .document(material_id)
            )

            ref.set(material, merge=True)
            
            firestore_helpers.FirestoreUtils.store_id_mapping("teacher_materials", material_id, material["content"])

            return TeacherMaterialResponse(**material)

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error adding material: {str(e)}")

    @staticmethod
    def get_teacher_materials(
        course_id: str, 
        topic_id: str, 
        teacher_id: str,
        target_language: str = "en"
    ) -> list[TeacherMaterialResponse]:
        """Fetches all materials under a teacher topic."""
        # Verify teacher owns the course
        course_ref = db.collection("teacher_courses").document(course_id)
        course_doc = course_ref.get()
        
        if not course_doc.exists:
            raise HTTPException(status_code=404, detail="Course not found")
        
        course_data = course_doc.to_dict()
        if course_data["teacher_id"] != teacher_id:
            raise HTTPException(status_code=403, detail="Not authorized to access this course")

        try:
            ref = (
                db.collection("teacher_courses")
                .document(course_id)
                .collection("topics")
                .document(topic_id)
                .collection("materials")
            )

            materials = ref.stream()
            material_list = []

            for material in materials:
                material_data = material.to_dict()

                if "languages" not in material_data:
                    continue

                lang_data = material_data["languages"].get(target_language, material_data["languages"].get("en", {}))

                material_list.append({
                    "id": material.id,
                    "type": material_data.get("type", ""),
                    "category": material_data.get("category", ""),
                    "content": lang_data.get("content", material_data["content"]),
                    "optional_text": lang_data.get("optional_text", ""),
                    "course_id": course_id,
                    "topic_id": topic_id,
                    "created_at": material_data["created_at"],
                    "updated_at": material_data["updated_at"],
                })

            return [TeacherMaterialResponse(**material) for material in material_list]

        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Error fetching materials: {str(e)}")
        