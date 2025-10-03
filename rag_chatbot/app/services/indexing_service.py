from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import JSONLoader
from ..worker import celery
import json
import logging
from typing import Dict, Any, List
import os
import aiohttp
import asyncio

logger = logging.getLogger(__name__)

class IndexingService:
    def __init__(self):
        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.vector_store = Chroma(
            persist_directory="./data/chroma",
            embedding_function=self.embeddings
        )
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200
        )

    @celery.task(bind=True)
    def index_data(self, data_type: str) -> Dict[str, Any]:
        """
        Index data from the Node.js backend into the vector store
        """
        try:
            # Fetch data from Node.js backend
            data = self._fetch_data(data_type)

            # Process and index the data
            documents = self._process_data(data, data_type)
            
            # Add to vector store
            self.vector_store.add_documents(documents)

            return {
                "status": "completed",
                "message": f"Successfully indexed {len(documents)} documents",
                "details": {
                    "document_count": len(documents),
                    "data_type": data_type
                }
            }
        except Exception as e:
            logger.error(f"Error indexing data: {str(e)}")
            return {
                "status": "failed",
                "error": str(e)
            }

    def _fetch_data(self, data_type: str) -> List[Dict[str, Any]]:
        """
        Fetch data from Node.js backend based on data type
        """
        # Implementation depends on your API structure
        # This is a placeholder for the actual implementation
        return []

    def _process_data(
        self,
        data: List[Dict[str, Any]],
        data_type: str
    ) -> List[Dict[str, Any]]:
        """
        Process and structure data for indexing
        """
        documents = []

        for item in data:
            # Convert item to searchable text based on data type
            if data_type == "invoices":
                text = self._process_invoice(item)
            elif data_type == "clients":
                text = self._process_client(item)
            elif data_type == "projects":
                text = self._process_project(item)
            else:
                continue

            # Split text into chunks
            chunks = self.text_splitter.split_text(text)

            # Create documents with metadata
            for chunk in chunks:
                documents.append({
                    "text": chunk,
                    "metadata": {
                        "source": f"{data_type}:{item.get('id')}",
                        "type": data_type,
                        "date": item.get('createdAt')
                    }
                })

        return documents

    def _process_invoice(self, invoice: Dict[str, Any]) -> str:
        """
        Convert invoice data to searchable text
        """
        text_parts = [
            f"Invoice #{invoice.get('invoiceNumber')}",
            f"Date: {invoice.get('date')}",
            f"Due Date: {invoice.get('dueDate')}",
            f"Total Amount: {invoice.get('totalAmount')}",
            f"Status: {invoice.get('status')}",
            f"Description: {invoice.get('description', '')}"
        ]

        # Add items
        items = invoice.get('items', [])
        for item in items:
            text_parts.append(
                f"Item: {item.get('description')} - "
                f"Quantity: {item.get('quantity')} - "
                f"Price: {item.get('unitPrice')}"
            )

        return "\n".join(text_parts)

    def _process_client(self, client: Dict[str, Any]) -> str:
        """
        Convert client data to searchable text
        """
        text_parts = [
            f"Client: {client.get('name')}",
            f"Email: {client.get('email')}",
            f"Address: {client.get('address')}",
            f"Phone: {client.get('phone')}",
            f"Type: {client.get('type')}",
            f"Status: {client.get('status')}"
        ]

        return "\n".join(text_parts)

    def _process_project(self, project: Dict[str, Any]) -> str:
        """
        Convert project data to searchable text
        """
        text_parts = [
            f"Project: {project.get('name')}",
            f"Description: {project.get('description')}",
            f"Status: {project.get('status')}",
            f"Start Date: {project.get('startDate')}",
            f"End Date: {project.get('endDate')}",
            f"Budget: {project.get('budget')}"
        ]

        return "\n".join(text_parts)

    def get_task_status(self, task_id: str) -> Dict[str, Any]:
        """
        Get the status of an indexing task
        """
        try:
            task = self.index_data.AsyncResult(task_id)
            
            if task.ready():
                if task.successful():
                    return {
                        "status": "completed",
                        "task_id": task_id,
                        "details": task.get()
                    }
                else:
                    return {
                        "status": "failed",
                        "task_id": task_id,
                        "error": str(task.result)
                    }
            else:
                return {
                    "status": "processing",
                    "task_id": task_id,
                    "message": "Task is still processing"
                }
        except Exception as e:
            logger.error(f"Error checking task status: {str(e)}")
            raise

def get_indexing_service():
    """
    Factory function for IndexingService (dependency injection)
    """
    return IndexingService()

async def rebuild_index(self, enterprise_id: str):
    """
    Rebuild the entire search index for an enterprise
    """
    try:
        logger.info(f"Rebuilding index for enterprise {enterprise_id}")
        
        # Re-fetch and index all data
        data_types = ["invoices", "clients", "suppliers", "projects"]
        
        for data_type in data_types:
            try:
                self.index_data(data_type)
                logger.info(f"Reindexed {data_type} data")
            except Exception as e:
                logger.error(f"Failed to reindex {data_type}: {e}")
                
        logger.info("Index rebuild completed")
        
    except Exception as e:
        logger.error(f"Failed to rebuild index: {e}")
        raise

# Add method to IndexingService class
IndexingService.rebuild_index = rebuild_index