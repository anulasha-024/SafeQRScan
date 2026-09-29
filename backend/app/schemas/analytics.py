from pydantic import BaseModel

#schema for analytics summary response

class AnalyticsSummaryResponse(BaseModel):
    total_verifications: int
    very_safe_count: int
    safe_count: int
    suspicious_count: int
    risky_count: int
    dangerous_count: int