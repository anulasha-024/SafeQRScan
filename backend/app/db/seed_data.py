from app.db.session import SessionLocal
from app.models.merchant import Merchant


#insert sample merchants into the database
def seed_merchants():

    from app.db.base import Base
    from app.db.session import engine
    Base.metadata.create_all(bind=engine)

    #Create Database Session
    db = SessionLocal()

    try:
        #check if merchants already exist

        existing = db.query(Merchant).first()
        if existing:
            print("Merchants already exist. Skipping Seeding.")
            return
        
        #create sample merchant records
        merchants = [
            Merchant(
                merchant_code="M001",
                merchant_name="ABC Traders",
                account_number="1234567890",
                bank_name="Commercial Bank"
            ),
            Merchant(
                merchant_code="M002",
                merchant_name="Chalo Stores",
                account_number="9876543210",
                bank_name="BOC"
            ),
            Merchant(
                merchant_code="M003",
                merchant_name="XYZ Enterprises",
                account_number="5555555555",
                bank_name="Sampath Bank"
            ),
        ]

        #add merchants to the database
        db.add_all(merchants)
        db.commit()

        print("Merchant inserted successfully.")

    finally:
        db.close()

#Run seeding when script is executed
if __name__ == "__main__":
    seed_merchants()