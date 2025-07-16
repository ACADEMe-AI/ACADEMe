import json
import os
from typing import Dict, Any
from dotenv import load_dotenv
import firebase_admin
from firebase_admin import credentials, firestore

class DataMigration:
    def __init__(self):  # Fixed: double underscores
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
    
    def load_json_file(self, file_path: str) -> Dict[str, Any]:
        """
        Load JSON file and return parsed data
        """
        if os.path.exists(file_path):
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except json.JSONDecodeError as e:
                print(f"Error parsing JSON file {file_path}: {e}")
                return {}
            except Exception as e:
                print(f"Error reading file {file_path}: {e}")
                return {}
        else:
            print(f"Warning: File {file_path} not found")
            return {}
    
    def migrate_to_subcollection(self, parent: str, collection: str, data: Dict[str, str]):
        """
        Migrate data to subcollection under 'id-mapping'/{parent}/{collection}
        """
        if not data:
            print(f"No data to migrate for {collection}")
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
    
    def migrate_all_data(self):
        """
        Migrate all assets/*.json files under id-mapping/{collection}/{id}
        """
        json_files = {
            "courses": "assets/courses.json",
            "topics": "assets/topics.json",
            "subtopics": "assets/subtopics.json",
            "quizzes": "assets/quizzes.json",
            "materials": "assets/materials.json",
        }
        
        print("Starting data migration to Firebase under 'id-mapping'...")
        
        for collection_name, file_path in json_files.items():
            print(f"\n--- Processing {collection_name} ---")
            data = self.load_json_file(file_path)
            
            if data:
                print(f"Migrating {len(data)} {collection_name}...")
                self.migrate_to_subcollection("default", collection_name, data)
            else:
                print(f"No data found in {file_path}")
        
        print("\n✅ Data migration completed successfully!")

if __name__ == "__main__":  # Fixed: double underscores
    try:
        migration = DataMigration()
        migration.migrate_all_data()
    except Exception as e:
        print(f"Migration failed: {e}")
        exit(1)