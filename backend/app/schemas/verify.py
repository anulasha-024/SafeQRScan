from pydantic import BaseModel, Field
from typing import List, Optional, Dict

#Request Schema
class VerifyTextRequest(BaseModel):
    qr_payload: str = Field(min_length=1, max_length=8192)

#Merchant Information Structure for Response
class MerchantInfo(BaseModel):
    merchant_code: Optional[str] = None
    merchant_name: Optional[str] = None
    account_number: Optional[str] = None
    bank_name: Optional[str] = None

#Response Schema
class VerifyTextResponse(BaseModel):
    status: str
    risk_score: int
    risk_level: str
    reasons: List[str]
    merchant: Optional[MerchantInfo] = None
    extracted_fields: Dict[str, Optional[str]]