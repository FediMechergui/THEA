from fastapi import APIRouter, HTTPException, Depends
from ..models.chat import ChatRequest, ChatResponse
from ..services.chat_service import get_chat_service
from typing import List
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/chat", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    chat_service = Depends(get_chat_service)
):
    """
    Process a chat request and return a response
    """
    try:
        response = await chat_service.process_query(
            query=request.query,
            conversation_id=request.conversation_id,
            context=request.context
        )
        
        return ChatResponse(
            response=response["response"],
            sources=response["sources"],
            conversation_id=response["conversation_id"]
        )
    except Exception as e:
        logger.error(f"Error processing chat request: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing chat request: {str(e)}"
        )

@router.get("/conversations/{conversation_id}", response_model=List[ChatResponse])
async def get_conversation_history(
    conversation_id: str,
    chat_service = Depends(get_chat_service)
):
    """
    Get the history of a conversation
    """
    try:
        history = await chat_service.get_conversation_history(conversation_id)
        return history
    except Exception as e:
        logger.error(f"Error retrieving conversation history: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error retrieving conversation history: {str(e)}"
        )