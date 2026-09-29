from app.db.session import SessionLocal

# Dependency to get DB session
def get_db():
    db = SessionLocal() #create a new database session
    try:
        yield db #provide the database session to endpoint
    finally:
        db.close()