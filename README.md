# Safe Scan QR

Flutter QR payment verification demo with a Python FastAPI backend. Scan a QR,
choose a gallery image on mobile, or paste QR text to see a rule-based risk
score, reasons and merchant details. Results can be reported as suspicious;
the history page shows the latest 100 server records.

## Structure

| Path | Purpose |
| --- | --- |
| `lib/` | Flutter scanner, results, history and API client |
| `backend/app/` | FastAPI, SQLAlchemy models and verification rules |
| `backend/tests/` | API contract and persistence checks |
| `lib/config/api_config.dart` | Backend address configuration |

Both parts live in this repo. The backend runs as a separate process.
Publishing code on GitHub does not host the API.

## Backend: Windows PowerShell

Install Python 3.12 or newer. From the repository root:

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe -m app.db.seed_data
.\.venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Seeding creates fictional demo merchants and is optional. For macOS/Linux,
create the environment with `python3 -m venv .venv` and use `.venv/bin/python`
in place of `.\.venv\Scripts\python.exe` in the remaining commands.

Check `http://127.0.0.1:8000/health` or open `http://127.0.0.1:8000/docs`.
SQLite tables are created automatically. Do not commit the generated database.

## Flutter: second terminal at the repository root

Use a Flutter SDK compatible with the Dart SDK constraint in `pubspec.yaml`.

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

| Device | Backend address |
| --- | --- |
| Android emulator | `http://10.0.2.2:8000` |
| Physical Android phone over USB | `http://127.0.0.1:8000` after `adb reverse` |
| Browser / iOS simulator on backend computer | `http://127.0.0.1:8000` |
| Release build | Your separately hosted HTTPS API URL |

For a physical Android phone connected by USB, enable USB debugging and run:

```bash
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Debug Android builds allow cleartext HTTP only for `localhost`, `127.0.0.1`
and the emulator address `10.0.2.2`. Use an HTTPS API for Wi-Fi testing,
release builds and physical iOS devices. No broad transport exception is added.
Restart/rebuild after changing the URL; hot reload does not change it.

For a browser demo with a fixed CORS origin:

```bash
flutter run -d chrome --web-hostname localhost --web-port 3000 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Gallery decoding is unavailable on web. Use camera or manual text entry.

## Sample QR payload

Tap the centre button to paste this fictional text or encode it as a QR image:

```text
MERCHANT_CODE=M001;MERCHANT_NAME=ABC Traders;ACCOUNT_NUMBER=1234567890;BANK=Commercial Bank;AMOUNT=2500
```

After seeding, this returns score 0 and `known_merchant`. Change the account
number to exercise the mismatch rule. `ACCOUNT` and `ACCOUNT_NUMBER` are
both accepted. The app sends JSON to `POST /verify/text`, displays the result,
reads `GET /logs/`, and sends reports as JSON to `POST /reports/`.

## Scope and hosting

- Academic/portfolio prototype: scores do not guarantee payment or URL safety.
  Rules use a custom key/value QR format and local merchant records. Bank
  validation, EMV/LankaQR parsing and malware/reputation checks are not implemented.
- History is shared across users of the same server. The API has no user
  authentication. Use fictional data locally. Add authentication, per-user
  access controls and rate limits before exposing it for real users.
- The original uploaded database, virtual environments, `.env` and caches are
  excluded from public source.
- To host later, run the API on an HTTPS host with persistent database storage.
  Configure `DATABASE_URL` and `CORS_ORIGINS` using `backend/.env.example`, then
  build Flutter with the real HTTPS URL. This change does not deploy a live API.

## Checks

```bash
cd backend
python -m pip install -r requirements.txt pytest httpx
python -m pytest -q
cd ..
flutter pub get
flutter analyze
flutter test
```

Backend tests cover verification, account mismatches, history, report storage,
input validation and CORS. Flutter builds and physical camera/gallery behavior
still need verification with a Flutter SDK and devices.
