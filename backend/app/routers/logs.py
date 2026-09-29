from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.deps import get_db

from app.models.verification_log import VerificationLog

#Create Router
router = APIRouter(
    prefix="/logs",
    tags=["logs"]
)

#Endpoint to fetch all verification logs

@router.get("/")
def get_all_logs(db: Session = Depends(get_db)):
    logs = db.query(VerificationLog).order_by(VerificationLog.id.desc()).limit(100).all()
    return [
        {
            "timestamp": log.timestamp,
            "id": log.id,
            "qr_payload": log.qr_payload,
            "risk_score": log.risk_score,
            "risk_level": log.risk_level,
            "reasons": log.reasons,
            "merchant_code": log.merchant_code,
        }
        for log in logs
    ]