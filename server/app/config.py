from pydantic_settings import BaseSettings # type: ignore

class Settings(BaseSettings):
    DATABASE_HOST: str = "147.93.178.204"
    DATABASE_PORT: str = "5433"
    DATABASE_USER: str = "postgres"
    DATABASE_PASSWORD: str = "CAMBIAR_EN_LOCAL"
    DATABASE_NAME: str = "gestionInventario"
    DATABASE_URL: str = None # type: ignore

    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    APP_PORT: int = 8001  # Puerto ajustado para evitar conflicto con Coolify

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"  # Ignora campos no definidos como source_commit y host

    def __init__(self, **data):
        super().__init__(**data)
        if not self.DATABASE_URL:
            self.DATABASE_URL = f"postgresql+psycopg2://{self.DATABASE_USER}:{self.DATABASE_PASSWORD}@{self.DATABASE_HOST}:{self.DATABASE_PORT}/{self.DATABASE_NAME}"

settings = Settings()