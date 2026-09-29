from sqlalchemy import Column, Integer, String, Text
from app.db.base import Base

from datetime import datetime
from sqlalchemy import DateTime




#storing every verification requst/result

class VerificationLog(Base):
    __tablename__ = "verification_logs"

    # Primary key for the verification log
    id = Column(Integer, primary_key=True, index=True)

    #merchant details extracted from QR payload
    qr_payload = Column(Text, nullable=False)

    #Final result
    risk_score = Column(Integer, nullable=False)
    risk_level = Column(String, nullable=False)  

    #Reason
    reasons = Column(Text, nullable=True) 

    #Merchant information extracted from QR
    merchant_code = Column(String, nullable=True)
    merchant_name = Column(String, nullable=True)
    account_number = Column(String, nullable=True)
    bank_name = Column(String, nullable=True)

    #Timestamp of verification
    timestamp = Column(DateTime, default=datetime.utcnow)