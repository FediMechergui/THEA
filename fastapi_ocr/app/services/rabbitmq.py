import aio_pika
from ..core.config import settings

async def get_rabbitmq_connection():
    return await aio_pika.connect_robust(settings.RABBITMQ_URL)

async def init_rabbitmq():
    connection = await get_rabbitmq_connection()
    channel = await connection.channel()
    
    # Declare exchanges
    ocr_exchange = await channel.declare_exchange(
        "ocr_exchange",
        aio_pika.ExchangeType.DIRECT
    )
    
    # Declare queues
    ocr_queue = await channel.declare_queue(
        "ocr_tasks",
        durable=True
    )
    
    # Bind queues to exchanges
    await ocr_queue.bind(ocr_exchange, "ocr_task")
    
    return connection, channel