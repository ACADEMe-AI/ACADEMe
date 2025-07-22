from firebase import db
from datetime import datetime

def get_document(collection: str, doc_id: str):
    doc_ref = db.collection(collection).document(doc_id)
    doc = doc_ref.get()
    return doc.to_dict() if doc.exists else None

def create_document(collection: str, doc_id: str, data: dict):
    db.collection(collection).document(doc_id).set(data)

def update_document(collection: str, doc_id: str, data: dict):
    db.collection(collection).document(doc_id).update(data)

def delete_document(collection: str, doc_id: str):
    db.collection(collection).document(doc_id).delete()

class FirestoreUtils:
    @staticmethod
    def store_id_mapping(collection_name: str, doc_id: str, title_or_name: str):
        """
        Store ID mapping in Firestore under id-mapping/default/{collection_name}

        Args:
            collection_name: The type of collection (courses, topics, subtopics, materials, quizzes)
            doc_id: The document ID to store
            title_or_name: The title or name value to store
        """
        try:
            # Reference to the id-mapping collection
            mapping_ref = (
                db.collection("id-mapping")
                .document("default")
                .collection(collection_name)
                .document(doc_id)
            )

            # Create document data based on collection type
            if collection_name == "quizzes":
                doc_data = {
                    "id": doc_id,
                    "title": title_or_name,
                    "created_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow()
                }
            elif collection_name == "materials":
                doc_data = {
                    "id": doc_id,
                    "title": title_or_name,
                    "content": title_or_name,  # Both title and content use same value
                    "created_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow()
                }
            else:  # courses, topics, subtopics
                doc_data = {
                    "id": doc_id,
                    "name": title_or_name,
                    "created_at": datetime.utcnow(),
                    "updated_at": datetime.utcnow()
                }

            # Write to Firestore
            mapping_ref.set(doc_data)
            print(f"📌 Stored ID mapping in Firestore: {collection_name}/{doc_id} → {title_or_name}")

        except Exception as e:
            print(f"⚠️ Failed to store ID mapping for {collection_name}/{doc_id}: {e}")

    @staticmethod
    def get_id_mapping(collection_name: str, doc_id: str = None):
        """
        Retrieve ID mapping(s) from Firestore

        Args:
            collection_name: The type of collection (courses, topics, subtopics, materials, quizzes)
            doc_id: Specific document ID to retrieve (optional, if None returns all)

        Returns:
            Document data or list of documents
        """
        try:
            base_ref = (
                db.collection("id-mapping")
                .document("default")
                .collection(collection_name)
            )

            if doc_id:
                # Get specific document
                doc = base_ref.document(doc_id).get()
                if doc.exists:
                    return doc.to_dict()
                else:
                    return None
            else:
                # Get all documents in collection
                docs = base_ref.stream()
                return [doc.to_dict() for doc in docs]

        except Exception as e:
            print(f"⚠️ Failed to retrieve ID mapping for {collection_name}: {e}")
            return None

    @staticmethod
    def delete_id_mapping(collection_name: str, doc_id: str):
        """
        Delete ID mapping from Firestore

        Args:
            collection_name: The type of collection (courses, topics, subtopics, materials, quizzes)
            doc_id: The document ID to delete
        """
        try:
            mapping_ref = (
                db.collection("id-mapping")
                .document("default")
                .collection(collection_name)
                .document(doc_id)
            )

            mapping_ref.delete()
            print(f"📌 Deleted ID mapping: {collection_name}/{doc_id}")

        except Exception as e:
            print(f"⚠️ Failed to delete ID mapping for {collection_name}/{doc_id}: {e}")

    @staticmethod
    def update_id_mapping(collection_name: str, doc_id: str, title_or_name: str):
        """
        Update existing ID mapping in Firestore

        Args:
            collection_name: The type of collection (courses, topics, subtopics, materials, quizzes)
            doc_id: The document ID to update
            title_or_name: The new title or name value
        """
        try:
            mapping_ref = (
                db.collection("id-mapping")
                .document("default")
                .collection(collection_name)
                .document(doc_id)
            )

            # Update data based on collection type
            if collection_name == "quizzes":
                update_data = {
                    "title": title_or_name,
                    "updated_at": datetime.utcnow()
                }
            elif collection_name == "materials":
                update_data = {
                    "title": title_or_name,
                    "content": title_or_name,
                    "updated_at": datetime.utcnow()
                }
            else:  # courses, topics, subtopics
                update_data = {
                    "name": title_or_name,
                    "updated_at": datetime.utcnow()
                }

            mapping_ref.update(update_data)
            print(f"📌 Updated ID mapping: {collection_name}/{doc_id} → {title_or_name}")

        except Exception as e:
            print(f"⚠️ Failed to update ID mapping for {collection_name}/{doc_id}: {e}")
