from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from app.db.deps import get_db
from app.models.report import Report

router = APIRouter(prefix="/reports", tags=["reports"])

class ReportRequest(BaseModel):
    qr_payload: str = Field(min_length=1, max_length=8192)
    reason: str = Field(min_length=1, max_length=2000)

@router.post("/", status_code=201)
def create_report(request: ReportRequest, db: Session = Depends(get_db)):
    db.add(Report(qr_payload=request.qr_payload, reason=request.reason))
    db.commit()
    return {"message": "QR reported successfully!"}
