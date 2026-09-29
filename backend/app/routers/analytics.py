from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.deps import get_db

from app.models.verification_log import VerificationLog

from app.schemas.analytics import AnalyticsSummaryResponse

#Create router
router = APIRouter(
    prefix="/analytics",
    tags=["Analytics"]
)

#Endpoint to return summery counts of verification results
@router.get("/summary", response_model=AnalyticsSummaryResponse)
def get_analytics_summary(db: Session = Depends(get_db)):
    #count all verifications
    total = db.query(VerificationLog).count()

    #count by risk level
    very_safe = db.query(VerificationLog).filter(VerificationLog.risk_level == "Very Safe").count()
    safe = db.query(VerificationLog).filter(VerificationLog.risk_level == "Safe").count()
    suspicious = db.query(VerificationLog).filter(VerificationLog.risk_level == "Suspicious").count()
    risky = db.query(VerificationLog).filter(VerificationLog.risk_level == "Risky").count()
    dangerous = db.query(VerificationLog).filter(VerificationLog.risk_level == "Dangerous").count()

    return{
        "total_verifications": total,
        "very_safe_count": very_safe,
        "safe_count": safe,
        "suspicious_count": suspicious,
        "risky_count": risky,
        "dangerous_count": dangerous
    }