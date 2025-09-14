from fastapi import APIRouter, HTTPException, Depends, Body
from fastapi.responses import JSONResponse
from typing import Dict, Any, List
from ...services.chat_service import ChatService
from ...services.indexing_service import IndexingService
from ...models.chat import ChatRequest, ChatResponse
from ...core.auth import get_current_user

router = APIRouter()
chat_service = ChatService()
indexing_service = IndexingService()

@router.post("/query", response_model=ChatResponse)
async def chat_query(
    request: ChatRequest,
    current_user: Dict = Depends(get_current_user)
):
    try:
        # Process the chat query
        response = await chat_service.process_query(
            query=request.query,
            user_id=current_user["id"],
            enterprise_id=current_user["enterpriseId"]
        )
        
        return ChatResponse(
            response=response,
            sources=chat_service.get_sources()
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/index/update")
async def update_index(
    data: Dict[str, Any] = Body(...),
    current_user: Dict = Depends(get_current_user)
):
    try:
        # Update the vector store index
        await indexing_service.update_index(
            data=data,
            enterprise_id=current_user["enterpriseId"]
        )
        
        return JSONResponse({
            "status": "success",
            "message": "Index updated successfully"
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "chatbot"}