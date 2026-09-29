from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.deps import get_db
from app.schemas.verify import VerifyTextRequest, VerifyTextResponse
from app.Services.verification_service import verify_qr_payload

#create router
router = APIRouter(prefix="/verify", tags=["verification"])

#POST endpoint to verify QR payload
@router.post("/text", response_model=VerifyTextResponse)
def verify_text(request: VerifyTextRequest, db: Session = Depends(get_db)):
    """
    Recieves QR payload text and returns:
    -risk score
    -risk level
    -reasons for risk score
    -merchant information
    """

    return verify_qr_payload(request.qr_payload, db)


