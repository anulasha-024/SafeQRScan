import os
from fastapi.middleware.cors import CORSMiddleware
from fastapi import FastAPI
from app.db.base import Base
from app.db.session import engine

from app.models.merchant import Merchant
from app.models import pending_merchant
from app.models import verification_log

from app.routers.verify import router as verify_router
from app.routers.analytics import router as analytics_router
from app.routers.logs import router as logs_router
from app.routers.report import router as report_router

#FastAPI application Instance
app = FastAPI(
    title="SafeScanQR API",
    description="QR Payment Verification Framework",
    version="1.0.0"
)

# Only explicitly configured web origins can access the API from browsers.
origins = [x.strip() for x in os.getenv("CORS_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000").split(",") if x.strip()]
app.add_middleware(CORSMiddleware, allow_origins=origins,
                   allow_methods=["GET", "POST"], allow_headers=["Content-Type"])

# Create database tables
Base.metadata.create_all(bind=engine)

#Register routers
app.include_router(verify_router)
app.include_router(analytics_router)
app.include_router(logs_router)
app.include_router(report_router)


#root endpoint
@app.get("/")
def root():
    return {"message": "SafeScanQR API is running!"}

#health check endpoint
@app.get("/health")
def health_check():
    return {"status": "ok"}