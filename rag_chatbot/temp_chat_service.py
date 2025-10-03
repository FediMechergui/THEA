from langchain.chains import RetrievalQAWithSourcesChain
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import Chroma
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import JSONLoader
from langchain_community.llms import Ollama
from ..worker import celery
from ..core.config import settings
import chromadb
import os
import json
import logging
from typing import Dict, Any, List
from uuid import uuid4

logger = logging.getLogger(__name__)

class ChatService:
    def __init__(self):
        self.embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        self.vector_store = Chroma(
            persist_directory="./data/chroma",
            embedding_function=self.embeddings
        )
        self.llm = Ollama(
            base_url=settings.OLLAMA_BASE_URL,
            model=settings.OLLAMA_MODEL,
            temperature=settings.LLM_TEMPERATURE
        )
        self.qa_chain = RetrievalQAWithSourcesChain.from_llm(
            llm=self.llm,
            retriever=self.vector_store.as_retriever()
        )

    async def process_query(
        self,
        query: str,
        conversation_id: str = None,
        context: Dict[str, Any] = None
    ) -> Dict[str, Any]:
        """
        Process a chat query and return a response with sources
        """
        try:
            # Generate conversation ID if not provided
            if not conversation_id:
                conversation_id = str(uuid4())

            # Prepare query with context
            enhanced_query = self._enhance_query_with_context(query, context)

            # Get response from QA chain
            response = self.qa_chain({"question": enhanced_query})

            # Structure the response
            result = {
                "response": response["answer"],
                "sources": self._process_sources(response["sources"]),
                "conversation_id": conversation_id
            }

            # Store conversation in Redis for history
            await self._store_conversation(conversation_id, query, result)

            return result
        except Exception as e:
            logger.error(f"Error processing query: {str(e)}")
            raise

    def _enhance_query_with_context(
        self,
        query: str,
        context: Dict[str, Any] = None
    ) -> str:
        """
        Enhance the query with any provided context
        """
        if not context:
            return query

        # Add relevant context to the query
        context_str = ". ".join([
            f"{key}: {value}"
            for key, value in context.items()
            if value is not None
        ])

        return f"{query} Context: {context_str}"

    def _process_sources(self, sources: str) -> List[Dict[str, Any]]:
        """
        Process and structure the sources from the QA chain
        """
        try:
            # Split sources into individual references
            source_list = sources.split("\n")
            processed_sources = []

            for source in source_list:
                if source.strip():
                    # Extract source details (customize based on your source format)
                    source_parts = source.split(":")
                    if len(source_parts) >= 2:
                        processed_sources.append({
                            "type": source_parts[0].strip(),
                            "reference": source_parts[1].strip(),
                            "confidence": 0.9  # Add actual confidence scoring if available
                        })

            return processed_sources
        except Exception as e:
            logger.error(f"Error processing sources: {str(e)}")
            return []

    async def _store_conversation(
        self,
        conversation_id: str,
        query: str,
        response: Dict[str, Any]
    ):
        """
        Store conversation in Redis for history
        """
        try:
            # Implementation depends on your Redis setup
            # This is a placeholder for the actual implementation
            pass
        except Exception as e:
            logger.error(f"Error storing conversation: {str(e)}")

    async def get_conversation_history(
        self,
        conversation_id: str
    ) -> List[Dict[str, Any]]:
        """
        Retrieve conversation history from Redis
        """
        try:
            # Implementation depends on your Redis setup
            # This is a placeholder for the actual implementation
            return []
        except Exception as e:
            logger.error(f"Error retrieving conversation history: {str(e)}")
            raise

def get_chat_service():
    """
    Factory function for ChatService (dependency injection)
    """
    return ChatService()