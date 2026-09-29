import os
from pathlib import Path
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

BASE_DIR = Path(__file__).resolve().parent.parent.parent
load_dotenv(BASE_DIR / '.env')
DATABASE_URL = os.getenv('DATABASE_URL', f'sqlite:///{BASE_DIR / "safescanqr.db"}')
engine = create_engine(
    DATABASE_URL,
    connect_args={'check_same_thread': False} if DATABASE_URL.startswith('sqlite:') else {},
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
