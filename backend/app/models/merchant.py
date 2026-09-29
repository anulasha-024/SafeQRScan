from sqlalchemy import Column, Integer, String
from app.db.base import Base

class Merchant(Base):
    __tablename__ = "merchants"

    id = Column(Integer, primary_key=True, index=True)
    merchant_code = Column(String, unique=True, index=True)
    merchant_name = Column(String)
    account_number = Column(String)
    bank_name = Column(String)