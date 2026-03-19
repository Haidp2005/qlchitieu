# SePay + Firestore (Spark, khong can Blaze)

Tai lieu nay dung cho Firebase Spark (mien phi) va Cloudflare Worker de nhan webhook SePay.

## Muc tieu

- App co nut them giao dich thu cong -> luu vao collection `transactions` tren Firestore.
- SePay gui webhook -> Worker xu ly -> tu dong them giao dich vao `transactions` voi:
  - `source = "sepay"`
  - `category = "Khac"`

## Kien truc

- Flutter app
  - `TransactionProvider` dong bo realtime tu Firestore.
  - Them/xoa giao dich thu cong tren collection `transactions`.
- Cloudflare Worker
  - Nhan POST webhook tu SePay.
  - Xac thuc secret.
  - Dung service account de ghi Firestore qua REST API.

## Cac file lien quan

- App:
  - `lib/main.dart`
  - `lib/features/transactions/data/transaction_provider.dart`
  - `lib/features/transactions/presentation/transactions_screen.dart`
- Firestore:
  - `firestore.rules`
- Worker:
  - `sepay-worker/wrangler.toml`
  - `sepay-worker/src/index.js`

## Buoc 1: Firebase phia app

1. Bat Firestore tren Firebase Console.
2. Cau hinh Flutter Firebase:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Kiem tra app da khoi tao Firebase trong `main.dart`.

## Buoc 2: Tao Service Account cho Worker

Khong can Service Account cho phuong an Spark nay.

Worker se ghi Firestore qua REST API bang Firebase Web API key, va quyen duoc kiem soat boi `firestore.rules`.

## Buoc 3: Deploy Worker

1. Cai Wrangler:

```bash
cd sepay-worker
npm install
npm i -g wrangler
wrangler login
```

2. Set secrets cho Worker:

```bash
wrangler secret put WEBHOOK_SECRET
```

3. Kiem tra `wrangler.toml`:
- `FIREBASE_PROJECT_ID = "quanlychitieu-2e7f1"`
- `FIRESTORE_COLLECTION = "transactions"`
- `DEFAULT_CATEGORY = "Khac"`
- `FIREBASE_WEB_API_KEY = "<api-key-tu-lib/firebase_options.dart>"`

4. Deploy:

```bash
wrangler deploy
```

Sau deploy ban nhan URL dang:
`https://sepay-webhook-firestore.<subdomain>.workers.dev`

## Buoc 4: Cau hinh webhook tren SePay

Dat callback URL:

`https://sepay-webhook-firestore.<subdomain>.workers.dev?secret=<WEBHOOK_SECRET>`

## Cau truc du lieu luu tren Firestore

Collection: `transactions`

Field toi thieu:
- `title` (string)
- `amount` (number)
- `category` (string)
- `type` (`income` | `expense`)
- `source` (`manual` | `sepay`)
- `transactionTime` (timestamp)

Worker se bo sung:
- `provider` = `SEPAY`
- `description`
- `providerTxId`
- `accountNumber`
- `bankCode`
- `createdAt`, `updatedAt`

## Test webhook nhanh

```bash
curl -X POST "https://sepay-webhook-firestore.<subdomain>.workers.dev?secret=<WEBHOOK_SECRET>" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "tx-demo-001",
    "amount": 120000,
    "direction": "in",
    "description": "Nap vi",
    "created_at": "2026-03-19T10:00:00+07:00",
    "account_number": "123456789",
    "bank_code": "VCB"
  }'
```

## Bao mat

- Token SePay da tung xuat hien trong chat, hay rotate token moi tren SePay.
- Khong luu token SePay trong Flutter app.
- Secret webhook va private key chi dat trong Worker secrets.

## Gioi han Spark

- Khong dung duoc Secret Manager + Cloud Functions v2 (do do backend webhook chay o Cloudflare Worker).
- Van luu duoc giao dich vao Firestore binh thuong.
