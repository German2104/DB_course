from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings


# Async engine используется всеми сервисами приложения.
engine = create_async_engine(settings.database_url, echo=False, pool_pre_ping=True)

# Фабрика сессий для dependency get_db.
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)
