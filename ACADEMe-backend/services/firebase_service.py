import os
import firebase_admin
from firebase_admin import credentials, firestore, auth
from typing import List, Dict, Any
import asyncio
from concurrent.futures import ThreadPoolExecutor
from dotenv import load_dotenv
import logging

class FirebaseService:
    def __init__(self):
        # Load environment variables
        load_dotenv()
        
        # Initialize Firebase Admin SDK (do this only once)
        if not firebase_admin._apps:
            service_account_path = os.getenv("FIREBASE_CRED_PATH")
            if not service_account_path or not os.path.exists(service_account_path):
                raise FileNotFoundError("FIREBASE_CRED_PATH not found or invalid in .env")
            
            cred = credentials.Certificate(service_account_path)
            firebase_admin.initialize_app(cred)
        
        self.db = firestore.client()
        self.executor = ThreadPoolExecutor(max_workers=10)
        
        # Base path for id-mapping collections
        self.base_path = self.db.collection("id-mapping").document("default")
    
    async def get_courses_by_ids(self, course_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Fetch courses by their IDs from Firebase subcollection.
        """
        return await self._get_documents_by_ids("courses", course_ids)
    
    async def get_topics_by_ids(self, topic_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Fetch topics by their IDs from Firebase subcollection.
        """
        return await self._get_documents_by_ids("topics", topic_ids)
    
    async def get_subtopics_by_ids(self, subtopic_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Fetch subtopics by their IDs from Firebase subcollection.
        """
        return await self._get_documents_by_ids("subtopics", subtopic_ids)
    
    async def get_quizzes_by_ids(self, quiz_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Fetch quizzes by their IDs from Firebase subcollection.
        """
        return await self._get_documents_by_ids("quizzes", quiz_ids)
    
    async def get_materials_by_ids(self, material_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Fetch materials by their IDs from Firebase subcollection.
        """
        return await self._get_documents_by_ids("materials", material_ids)
    
    async def _get_documents_by_ids(self, collection_name: str, document_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Generic method to fetch documents by IDs from a Firestore subcollection.
        Uses batch operations for better performance.
        """
        if not document_ids:
            return []
        
        # Firestore 'in' query supports up to 10 items, so we need to batch
        documents = []
        batch_size = 10
        
        for i in range(0, len(document_ids), batch_size):
            batch_ids = document_ids[i:i + batch_size]
            batch_docs = await self._fetch_batch_documents(collection_name, batch_ids)
            documents.extend(batch_docs)
        
        return documents
    
    async def _fetch_batch_documents(self, collection_name: str, document_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Fetch a batch of documents using Firestore 'in' query from subcollection.
        """
        def fetch_documents():
            try:
                # Query the subcollection under id-mapping/default/
                collection_ref = self.base_path.collection(collection_name)
                query = collection_ref.where("id", "in", document_ids)
                docs = query.get()
                
                documents = []
                for doc in docs:
                    doc_data = doc.to_dict()
                    documents.append(doc_data)
                
                return documents
            except Exception as e:
                print(f"Error fetching documents from {collection_name}: {e}")
                return []
        
        # Run the synchronous Firestore operation in a thread pool
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self.executor, fetch_documents)
    
    async def get_document_by_id(self, collection_name: str, document_id: str) -> Dict[str, Any]:
        """
        Fetch a single document by ID from a Firestore subcollection.
        """
        def fetch_document():
            try:
                doc_ref = self.base_path.collection(collection_name).document(document_id)
                doc = doc_ref.get()
                
                if doc.exists:
                    doc_data = doc.to_dict()
                    return doc_data
                else:
                    return None
            except Exception as e:
                print(f"Error fetching document {document_id} from {collection_name}: {e}")
                return None
        
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self.executor, fetch_document)
    
    async def batch_get_documents(self, collection_name: str, document_ids: List[str]) -> List[Dict[str, Any]]:
        """
        Alternative method using Firestore batch get (more efficient for large datasets).
        """
        def fetch_batch():
            try:
                batch_refs = [
                    self.base_path.collection(collection_name).document(doc_id) 
                    for doc_id in document_ids
                ]
                docs = self.db.get_all(batch_refs)
                
                documents = []
                for doc in docs:
                    if doc.exists:
                        doc_data = doc.to_dict()
                        documents.append(doc_data)
                
                return documents
            except Exception as e:
                print(f"Error in batch get from {collection_name}: {e}")
                return []
        
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self.executor, fetch_batch)
    
    # NEW METHODS FOR FIREBASE AUTH
    
    async def create_custom_token(self, user_id: str, additional_claims: Dict[str, Any] = None) -> str:
        """
        Create a custom Firebase Auth token for a user.
        
        Args:
            user_id: The unique user identifier from your database
            additional_claims: Optional dict of additional claims to include in the token
        
        Returns:
            Custom token as string (JWT format)
        """
        def generate_token():
            try:
                # Create custom token with optional additional claims
                if additional_claims:
                    custom_token = auth.create_custom_token(user_id, additional_claims)
                else:
                    custom_token = auth.create_custom_token(user_id)
                
                # Decode bytes to string
                token_str = custom_token.decode('utf-8') if isinstance(custom_token, bytes) else custom_token
                logging.info(f"Successfully created custom token for user: {user_id}")
                return token_str
            except Exception as e:
                logging.error(f"Error creating custom token for user {user_id}: {e}")
                raise Exception(f"Failed to create Firebase custom token: {str(e)}")
        
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(self.executor, generate_token)
    
    
    def close(self):
        """
        Close the thread pool executor.
        """
        self.executor.shutdown(wait=True)