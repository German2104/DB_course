import logging

from fastapi import FastAPI

from app.api.routes import assignments, auth, courses, enrollments, grades, submissions, users
from app.core.config import settings

# Базовое логирование для API-запросов и отладки.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)

app = FastAPI(title=settings.app_name, version=settings.app_version)


@app.get("/health", tags=["System"])
async def healthcheck() -> dict[str, str]:
    # Технический endpoint для проверки, что API поднято.
    return {"status": "ok"}


# Подключение всех модулей API.
app.include_router(users.router)
app.include_router(auth.router)
app.include_router(courses.router)
app.include_router(enrollments.router)
app.include_router(assignments.router)
app.include_router(submissions.router)
app.include_router(grades.router)
