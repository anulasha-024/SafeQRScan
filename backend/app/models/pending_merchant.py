from sqlalchemy import Column, Integer, String
from app.db.base import Base


#Model for pending merchants awaiting verification
class PendingMerchant(Base):
    __tablename__ = "pending_merchants"

    # Primary key for the pending merchant
    id = Column(Integer, primary_key=True, index=True)
    #merchant details extracted from QR payload
    merchant_code = Column(String, unique=True, index=True)
    merchant_name = Column(String, nullable=False)
    account_number = Column(String, nullable=False)
    bank_name = Column(String, nullable=False)

    note = Column(String, nullable=True)  # Optional field for admin notes
