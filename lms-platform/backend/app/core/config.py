from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Метаданные API для OpenAPI/Swagger.
    app_name: str = "LMS API"
    app_version: str = "0.1.0"
    # Основная строка подключения для async SQLAlchemy.
    database_url: str = "postgresql+asyncpg://lms_user:lms_password@localhost:5433/lms_db"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


settings = Settings()
