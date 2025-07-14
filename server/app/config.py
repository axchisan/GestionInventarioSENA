from pydantic_settings import BaseSettings # type: ignore

class Settings(BaseSettings):
    DATABASE_HOST: str = "147.93.178.204"
    DATABASE_PORT: str = "5433"
    DATABASE_USER: str = "postgres"
    DATABASE_PASSWORD: str = "CAMBIAR_EN_LOCAL"
    DATABASE_NAME: str = "gestionInventario"
    DATABASE_URL: str = f"postgresql+psycopg2://{DATABASE_USER}:{DATABASE_PASSWORD}@{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"
    
    SECRET_KEY: str = "CAMBIAR_EN_LOCAL"  
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()