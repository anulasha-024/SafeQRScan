from sqlalchemy import Column, Integer, String, Text
from app.db.base import Base

#Report model for storing user-reported QR codes and reasons
class Report(Base):
    __tablename__ = "reports"

    #Primary key
    id = Column(Integer, primary_key=True, index=True)

    #QR payload that user reported
    qr_payload = Column(Text)

    #Reason provided by user for reporting this QR code
    reason = Column(String)