from celery import Celery
from .config import settings

celery_app = Celery(
    "thea_ocr",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND
)

celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
)

def init_celery():
    celery_app.conf.update()