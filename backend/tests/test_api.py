import os
import tempfile
from pathlib import Path

_tmp = tempfile.TemporaryDirectory()
os.environ['DATABASE_URL'] = f'sqlite:///{Path(_tmp.name) / "test.db"}'
from fastapi.testclient import TestClient
from app.main import app
from app.db.seed_data import seed_merchants
from app.db.session import SessionLocal
from app.models.report import Report

client = TestClient(app)

def test_flutter_contract_and_history():
    seed_merchants()
    payload = 'MERCHANT_CODE=M001;MERCHANT_NAME=ABC Traders;ACCOUNT=1234567890;BANK=Commercial Bank'
    result = client.post('/verify/text', json={'qr_payload': payload})
    assert result.status_code == 200
    data = result.json()
    assert data['status'] == 'success'
    assert data['risk_score'] == 0
    assert data['merchant']['merchant_code'] == 'M001'
    assert isinstance(data['reasons'], list)
    assert data['extracted_fields']['account_number'] == '1234567890'
    logs = client.get('/logs/').json()
    assert logs[0]['qr_payload'] == payload
    assert logs[0]['merchant_code'] == 'M001'
    mismatch = client.post('/verify/text', json={'qr_payload': payload.replace('1234567890', '0000000000')}).json()
    assert 'account_mismatch' in mismatch['reasons']
    assert mismatch['risk_score'] > data['risk_score']

def test_json_report_persists():
    result = client.post('/reports/', json={'qr_payload': 'test payload', 'reason': 'Account mismatch'})
    assert result.status_code == 201
    with SessionLocal() as db:
        assert db.query(Report).filter_by(qr_payload='test payload').count() == 1

def test_validation_health_and_cors():
    assert client.get('/health').json() == {'status': 'ok'}
    assert client.post('/verify/text', json={'qr_payload': ''}).status_code == 422
    assert client.post('/verify/text', json={'qr_payload': 'x' * 8193}).status_code == 422
    assert client.post('/reports/', json={'qr_payload': 'x', 'reason': ''}).status_code == 422
    response = client.options('/verify/text', headers={'Origin': 'http://localhost:3000', 'Access-Control-Request-Method': 'POST', 'Access-Control-Request-Headers': 'content-type'})
    assert response.headers['access-control-allow-origin'] == 'http://localhost:3000'
    denied = client.options('/verify/text', headers={'Origin': 'https://untrusted.example', 'Access-Control-Request-Method': 'POST'})
    assert 'access-control-allow-origin' not in denied.headers
