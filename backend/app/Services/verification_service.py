import re
from sqlalchemy.orm import Session
from app.models.merchant import Merchant
from app.models.pending_merchant import PendingMerchant
from app.models.verification_log import VerificationLog

#Conversion of risk score to risk category
def get_risk_level(score: int) -> str:
    if 0 <= score <= 20:
        return "Very Safe"
    elif 21 <= score <= 40:
        return "Safe"
    elif 41 <= score <= 60:
        return "Suspicious"
    elif 61 <= score <= 80: 
        return "Risky"
    else:
        return "Dangerous"
    
#extract fields from QR payload
def extract_fields(qr_payload: str) -> dict:
    """Example expected format:
    MERCHANT_CODE=M001;MERCHANT_NAME=ABC Traders;ACCOUNT=1234567890;BANK=BOC;AMOUNT=2500
    """

    #Initiate extracted fields
    extracted = {
        "merchant_code": None,
        "merchant_name": None,
        "account_number": None,
        "bank_name": None,
        "amount": None,
        "url": None,
    }

    #split payload into key-value pairs

    parts = qr_payload.replace(",", ";").split(";")

    for part in parts:
        if "=" in part:
            key, value = part.split("=", 1)
            key = key.strip().upper()
            value = value.strip()

            #Map extracted values
            if key == "MERCHANT_CODE":
                extracted["merchant_code"] = value
            elif key == "MERCHANT_NAME":
                extracted["merchant_name"] = value
            elif key in ("ACCOUNT", "ACCOUNT_NUMBER"):
                extracted["account_number"] = value
            elif key == "BANK":
                extracted["bank_name"] = value
            elif key == "AMOUNT":
                extracted["amount"] = value
            elif key == "URL":
                extracted["url"] = value

    #Detect URL automatically if present in text
    url_match = re.search(r'(https?://\S+)', qr_payload)
    if url_match and not extracted["url"]:
        extracted["url"] = url_match.group(0)

    return extracted

#main verification function
def verify_qr_payload(qr_payload: str, db: Session) -> dict:
    
    #Initialize score and resons list
    score = 0
    reasons = []

    #Extract structured data from QR payload
    extracted = extract_fields(qr_payload)

    #Basic Field Validation
    if not extracted["merchant_code"]:
        reasons.append("Missing merchant code")
        score += 15

    if not extracted["merchant_name"]:
        reasons.append("Missing merchant name")
        score += 10

    if not extracted["account_number"]:
        reasons.append("Missing account number")
        score += 15

    #URL SECURITY CHECKS

    if extracted["url"]:
        if extracted["url"].startswith("http://"):
            score += 15
            reasons.append("non_https_url")

        elif extracted["url"].startswith("https://"):
            reasons.append("secure_url")

    #Merchant Verification

    matched_merchant = None

    #Try to find merchant using merchant_code
    if extracted["merchant_code"]:
        matched_merchant = (
            db.query(Merchant)
            .filter(Merchant.merchant_code == extracted["merchant_code"])
            .first()

        )

    if matched_merchant:
        reasons.append("known_merchant")

        # Check account mistmatch
        if extracted["account_number"] and matched_merchant.account_number != extracted["account_number"]:
            score += 35
            reasons.append("account_mismatch")
            
        #check name mismatch
        if extracted["merchant_name"] and matched_merchant.merchant_name.lower() != extracted["merchant_name"].lower():
            score += 15
            reasons.append("merchant_name_mismatch")

        merchant_data = {
            "merchant_code": matched_merchant.merchant_code,
            "merchant_name": matched_merchant.merchant_name,
            "account_number": matched_merchant.account_number,
            "bank_name": matched_merchant.bank_name,
        }

    #Unknown merchant scenario
    else:
        score += 20
        reasons.append("unknown_merchant")

        merchant_data = {
            "merchant_code": extracted["merchant_code"],
            "merchant_name": extracted["merchant_name"],
            "account_number": extracted["account_number"],
            "bank_name": extracted["bank_name"],
        }

    #Payload Validation

    if len(qr_payload.strip()) < 10:
        score += 20
        reasons.append("payload_too_short")


    #Finalize Score

    score = max(0, min(score, 100))  #keep within 0-100


    #Auto save low risk unknown merchants to pending list
    if "unknown_merchant" in reasons and score <= 30:
        existing_pending = (
            db.query(PendingMerchant)
            .filter(PendingMerchant.merchant_code == extracted["merchant_code"])
            .first()
        )
        #only insert if not already in pending table
        if not existing_pending:
            pending_merchant = PendingMerchant(
                merchant_code=extracted["merchant_code"],
                merchant_name=extracted["merchant_name"],
                account_number=extracted["account_number"],
                bank_name=extracted["bank_name"],
                note="Auto added to the low risk unknown merchant list"
            )
            db.add(pending_merchant)
            db.commit()

            #add explanation to reasons list
            reasons.append("saved_to_pending_merchants")

    #save verification log
    log_entry = VerificationLog(
        qr_payload=qr_payload,
        risk_score=score,
        risk_level=get_risk_level(score),
        reasons=";".join(reasons),
        merchant_code=extracted["merchant_code"],
        merchant_name=extracted["merchant_name"],
        account_number=extracted["account_number"],
        bank_name=extracted["bank_name"],
    )

    print("DEBUG: about to save verification log")
    db.add(log_entry)
    db.commit()

    print("DEBUG: verification log saved")

    return {
        "status": "success",
        "risk_score": score,
        "risk_level": get_risk_level(score),
        "reasons": reasons,
        "merchant": merchant_data,
        "extracted_fields": extracted,
    }

