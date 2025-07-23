import json
import os
from typing import Dict, Any, Set
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

class FirestoreDataExtractor:
    def __init__(self):
        """
        Initialize Firebase Admin SDK from .env variable FIREBASE_CRED_PATH
        """
        load_dotenv()
        service_account_path = os.getenv("FIREBASE_CRED_PATH")

        if not service_account_path or not os.path.exists(service_account_path):
            raise FileNotFoundError("FIREBASE_CRED_PATH not found or invalid in .env")

        # Initialize Firebase Admin SDK only if not already initialized
        if not firebase_admin._apps:
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)

        self.db = firestore.client()

    def get_existing_ids(self, collection_name: str) -> Set[str]:
        """
        Get existing IDs from id-mapping/{parent}/{collection} to avoid duplicates
        """
        existing_ids = set()
        try:
            docs = self.db.collection("id-mapping").document("default").collection(collection_name).stream()
            for doc in docs:
                existing_ids.add(doc.id)
            print(f"Found {len(existing_ids)} existing {collection_name} in id-mapping")
        except Exception as e:
            print(f"Error getting existing {collection_name}: {e}")

        return existing_ids

    def extract_english_text(self, languages_map: Dict) -> str:
        """
        Extract English text from languages map, fallback to first available language
        """
        if not languages_map:
            return ""

        # Try to get English first
        if "en" in languages_map:
            lang_data = languages_map["en"]
            if isinstance(lang_data, dict):
                return lang_data.get("title", lang_data.get("content", ""))
            return str(lang_data)

        # Fallback to first available language
        first_lang = list(languages_map.keys())[0]
        lang_data = languages_map[first_lang]
        if isinstance(lang_data, dict):
            return lang_data.get("title", lang_data.get("content", ""))
        return str(lang_data)

    def extract_courses(self) -> Dict[str, str]:
        """
        Extract course IDs and titles from courses collection
        """
        courses_data = {}
        existing_ids = self.get_existing_ids("courses")

        try:
            courses = self.db.collection("courses").stream()
            for course in courses:
                course_id = course.id
                if course_id in existing_ids:
                    print(f"Skipping existing course: {course_id}")
                    continue

                course_data = course.to_dict()
                title = self.extract_english_text(course_data.get("languages", {}))

                if title:
                    courses_data[course_id] = title
                    print(f"Extracted course: {course_id} -> {title[:50]}...")

        except Exception as e:
            print(f"Error extracting courses: {e}")

        return courses_data

    def extract_topics(self) -> Dict[str, str]:
        """
        Extract topic IDs and titles from all courses
        """
        topics_data = {}
        existing_ids = self.get_existing_ids("topics")

        try:
            courses = self.db.collection("courses").stream()
            for course in courses:
                topics = self.db.collection("courses").document(course.id).collection("topics").stream()

                for topic in topics:
                    topic_id = topic.id
                    if topic_id in existing_ids:
                        print(f"Skipping existing topic: {topic_id}")
                        continue

                    topic_data = topic.to_dict()
                    title = self.extract_english_text(topic_data.get("languages", {}))

                    if title:
                        topics_data[topic_id] = title
                        print(f"Extracted topic: {topic_id} -> {title[:50]}...")

        except Exception as e:
            print(f"Error extracting topics: {e}")

        return topics_data

    def extract_subtopics(self) -> Dict[str, str]:
        """
        Extract subtopic IDs and titles from all courses/topics
        """
        subtopics_data = {}
        existing_ids = self.get_existing_ids("subtopics")

        try:
            courses = self.db.collection("courses").stream()
            for course in courses:
                topics = self.db.collection("courses").document(course.id).collection("topics").stream()

                for topic in topics:
                    subtopics = (self.db.collection("courses").document(course.id)
                               .collection("topics").document(topic.id)
                               .collection("subtopics").stream())

                    for subtopic in subtopics:
                        subtopic_id = subtopic.id
                        if subtopic_id in existing_ids:
                            print(f"Skipping existing subtopic: {subtopic_id}")
                            continue

                        subtopic_data = subtopic.to_dict()
                        title = self.extract_english_text(subtopic_data.get("languages", {}))

                        if title:
                            subtopics_data[subtopic_id] = title
                            print(f"Extracted subtopic: {subtopic_id} -> {title[:50]}...")

        except Exception as e:
            print(f"Error extracting subtopics: {e}")

        return subtopics_data

    def extract_quizzes(self) -> Dict[str, str]:
        """
        Extract quiz IDs and titles from all courses/topics/subtopics
        """
        quizzes_data = {}
        existing_ids = self.get_existing_ids("quizzes")

        try:
            courses = self.db.collection("courses").stream()
            for course in courses:
                topics = self.db.collection("courses").document(course.id).collection("topics").stream()

                for topic in topics:
                    subtopics = (self.db.collection("courses").document(course.id)
                               .collection("topics").document(topic.id)
                               .collection("subtopics").stream())

                    for subtopic in subtopics:
                        quizzes = (self.db.collection("courses").document(course.id)
                                 .collection("topics").document(topic.id)
                                 .collection("subtopics").document(subtopic.id)
                                 .collection("quizzes").stream())

                        for quiz in quizzes:
                            quiz_id = quiz.id
                            if quiz_id in existing_ids:
                                print(f"Skipping existing quiz: {quiz_id}")
                                continue

                            quiz_data = quiz.to_dict()
                            # Try to get title from languages first, then fallback to direct title field
                            title = self.extract_english_text(quiz_data.get("languages", {}))
                            if not title:
                                title = quiz_data.get("title", "")

                            if title:
                                quizzes_data[quiz_id] = title
                                print(f"Extracted quiz: {quiz_id} -> {title[:50]}...")

        except Exception as e:
            print(f"Error extracting quizzes: {e}")

        return quizzes_data

    def extract_materials(self) -> Dict[str, str]:
        """
        Extract material IDs and content from all courses/topics/subtopics
        """
        materials_data = {}
        existing_ids = self.get_existing_ids("materials")

        try:
            courses = self.db.collection("courses").stream()
            for course in courses:
                topics = self.db.collection("courses").document(course.id).collection("topics").stream()

                for topic in topics:
                    subtopics = (self.db.collection("courses").document(course.id)
                               .collection("topics").document(topic.id)
                               .collection("subtopics").stream())

                    for subtopic in subtopics:
                        materials = (self.db.collection("courses").document(course.id)
                                   .collection("topics").document(topic.id)
                                   .collection("subtopics").document(subtopic.id)
                                   .collection("materials").stream())

                        for material in materials:
                            material_id = material.id
                            if material_id in existing_ids:
                                print(f"Skipping existing material: {material_id}")
                                continue

                            material_data = material.to_dict()
                            # Try to get content from languages first, then fallback to direct content field
                            content = ""
                            languages = material_data.get("languages", {})
                            if "en" in languages and "content" in languages["en"]:
                                content = languages["en"]["content"]
                            elif languages:
                                # Fallback to first available language
                                first_lang = list(languages.keys())[0]
                                content = languages[first_lang].get("content", "")
                            else:
                                # Fallback to direct content field
                                content = material_data.get("content", "")

                            if content:
                                materials_data[material_id] = content
                                print(f"Extracted material: {material_id} -> {content[:50]}...")

        except Exception as e:
            print(f"Error extracting materials: {e}")

        return materials_data

    def extract_questions(self) -> Dict[str, str]:
        """
        Extract question IDs and question text from all courses/topics/subtopics/quizzes
        """
        questions_data = {}
        existing_ids = self.get_existing_ids("questions")

        try:
            courses = self.db.collection("courses").stream()
            for course in courses:
                topics = self.db.collection("courses").document(course.id).collection("topics").stream()

                for topic in topics:
                    subtopics = (self.db.collection("courses").document(course.id)
                               .collection("topics").document(topic.id)
                               .collection("subtopics").stream())

                    for subtopic in subtopics:
                        quizzes = (self.db.collection("courses").document(course.id)
                                 .collection("topics").document(topic.id)
                                 .collection("subtopics").document(subtopic.id)
                                 .collection("quizzes").stream())

                        for quiz in quizzes:
                            questions = (self.db.collection("courses").document(course.id)
                                       .collection("topics").document(topic.id)
                                       .collection("subtopics").document(subtopic.id)
                                       .collection("quizzes").document(quiz.id)
                                       .collection("questions").stream())

                            for question in questions:
                                question_id = question.id
                                if question_id in existing_ids:
                                    print(f"Skipping existing question: {question_id}")
                                    continue

                                question_data = question.to_dict()
                                # Try to get question_text from languages first, then fallback to direct question_text field
                                question_text = ""
                                languages = question_data.get("languages", {})
                                if "en" in languages and "question_text" in languages["en"]:
                                    question_text = languages["en"]["question_text"]
                                elif languages:
                                    # Fallback to first available language
                                    first_lang = list(languages.keys())[0]
                                    question_text = languages[first_lang].get("question_text", "")
                                else:
                                    # Fallback to direct question_text field
                                    question_text = question_data.get("question_text", "")

                                if question_text:
                                    questions_data[question_id] = question_text
                                    print(f"Extracted question: {question_id} -> {question_text[:50]}...")

        except Exception as e:
            print(f"Error extracting questions: {e}")

        return questions_data

    def migrate_to_subcollection(self, parent: str, collection: str, data: Dict[str, str]):
        """
        Migrate extracted data to subcollection under 'id-mapping'/{parent}/{collection}
        """
        if not data:
            print(f"No new data to migrate for {collection}")
            return

        base_path = self.db.collection("id-mapping").document(parent).collection(collection)

        for doc_id, value in data.items():
            try:
                # Create document data based on collection type
                if collection == "quizzes":
                    doc_data = {
                        "id": doc_id,
                        "title": value,
                        "created_at": firestore.SERVER_TIMESTAMP,
                        "updated_at": firestore.SERVER_TIMESTAMP
                    }
                elif collection == "materials":
                    doc_data = {
                        "id": doc_id,
                        "title": value,
                        "content": value,  # Note: both title and content use same value
                        "created_at": firestore.SERVER_TIMESTAMP,
                        "updated_at": firestore.SERVER_TIMESTAMP
                    }
                elif collection == "questions":
                    doc_data = {
                        "id": doc_id,
                        "question_text": value,
                        "created_at": firestore.SERVER_TIMESTAMP,
                        "updated_at": firestore.SERVER_TIMESTAMP
                    }
                else:  # courses, topics, subtopics
                    doc_data = {
                        "id": doc_id,
                        "name": value,
                        "created_at": firestore.SERVER_TIMESTAMP,
                        "updated_at": firestore.SERVER_TIMESTAMP
                    }

                # Write to Firestore
                base_path.document(doc_id).set(doc_data)
                print(f"Migrated {collection[:-1]}: {doc_id} -> {value[:50]}...")

            except Exception as e:
                print(f"Error migrating {collection} item {doc_id}: {e}")

    def extract_and_migrate_all(self):
        """
        Extract all data from existing Firestore structure and migrate to id-mapping
        """
        print("Starting data extraction and migration from existing Firestore structure...")

        # Extract data from each collection
        extraction_methods = {
            "courses": self.extract_courses,
            "topics": self.extract_topics,
            "subtopics": self.extract_subtopics,
            "quizzes": self.extract_quizzes,
            "materials": self.extract_materials,
            "questions": self.extract_questions,
        }

        for collection_name, extract_method in extraction_methods.items():
            print(f"\n--- Processing {collection_name} ---")
            try:
                data = extract_method()

                if data:
                    print(f"Extracted {len(data)} new {collection_name}")
                    self.migrate_to_subcollection("default", collection_name, data)
                else:
                    print(f"No new {collection_name} to migrate")

            except Exception as e:
                print(f"Error processing {collection_name}: {e}")

        print("\n✅ Data extraction and migration completed successfully!")

if __name__ == "__main__":
    try:
        extractor = FirestoreDataExtractor()
        extractor.extract_and_migrate_all()
    except Exception as e:
        print(f"Extraction and migration failed: {e}")
        exit(1)
