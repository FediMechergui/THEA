from functools import lru_cache
from langchain.chains import RetrievalQAWithSourcesChain
from langchain_community.embeddings import HuggingFaceEmbeddings
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
        persist_directory = settings.VECTOR_STORE_PATH or "./data/chroma"

        self.vector_store = Chroma(
            persist_directory=persist_directory,
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
            # Validate query input
            if not query or not query.strip():
                return {
                    "response": "I'm sorry, but your query appears to be empty. Please provide a question or request.",
                    "sources": [],
                    "conversation_id": conversation_id or str(uuid4())
                }

            # Generate conversation ID if not provided
            if not conversation_id:
                conversation_id = str(uuid4())

            # Prepare query with context
            enhanced_query = self._enhance_query_with_context(query, context)

            # Get response from QA chain
            response = self.qa_chain({"question": enhanced_query})
            
            logger.info(f"QA Chain response: {response}")
            logger.info(f"Response type: {type(response)}")
            logger.info(f"Response keys: {response.keys() if isinstance(response, dict) else 'Not a dict'}")
            
            # Handle different possible response formats from LangChain
            if isinstance(response, dict):
                # Try different possible key names
                answer = (response.get("answer") or 
                         response.get("result") or 
                         response.get("text") or 
                         response.get("output") or
                         response.get("response") or  # Add this as potential key
                         str(response))
                
                sources = (response.get("sources") or 
                          response.get("source_documents") or 
                          response.get("documents") or 
                          [])
                
                # If we still don't have a proper answer, log the response structure
                if not answer or answer == str(response):
                    logger.warning(f"Unexpected response format. Available keys: {list(response.keys()) if isinstance(response, dict) else 'N/A'}")
                    # Try to extract the first string value from the response
                    for key, value in response.items():
                        if isinstance(value, str) and len(value) > 10:  # Assume meaningful responses are longer than 10 chars
                            answer = value
                            break
                    else:
                        answer = "I apologize, but I encountered an issue processing your request. Please try again."
                        
            else:
                # Fallback for non-dict responses
                answer = str(response)
                sources = []

            # Structure the response
            result = {
                "response": answer,
                "sources": self._process_sources(sources),
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

    def _process_sources(self, sources) -> List[Dict[str, Any]]:
        """
        Process and structure the sources from the QA chain
        """
        try:
            processed_sources = []
            
            # Handle different source formats
            if isinstance(sources, str):
                # If sources is a string, split it
                source_list = sources.split("\n")
                for source in source_list:
                    if source.strip():
                        source_parts = source.split(":")
                        if len(source_parts) >= 2:
                            processed_sources.append({
                                "type": source_parts[0].strip(),
                                "reference": source_parts[1].strip(),
                                "confidence": 0.9
                            })
            elif isinstance(sources, list):
                # If sources is already a list, process each item
                for source in sources:
                    if hasattr(source, 'page_content'):
                        # Document object
                        processed_sources.append({
                            "type": "document",
                            "reference": source.page_content[:200] + "..." if len(source.page_content) > 200 else source.page_content,
                            "confidence": 0.9,
                            "metadata": getattr(source, 'metadata', {})
                        })
                    elif isinstance(source, str):
                        # String in list
                        processed_sources.append({
                            "type": "text",
                            "reference": source,
                            "confidence": 0.9
                        })
            else:
                # Fallback for other types
                processed_sources.append({
                    "type": "unknown",
                    "reference": str(sources),
                    "confidence": 0.5
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

@lru_cache(maxsize=1)
def get_chat_service():
    """
    Factory function for ChatService (dependency injection)
    Reuses a singleton instance to avoid expensive model loads per request.
    """
    return ChatService()