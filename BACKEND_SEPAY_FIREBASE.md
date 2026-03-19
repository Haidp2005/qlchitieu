# Backend SePay + Firebase

Tai lieu nay thiet ke backend nhan thong bao giao dich SePay va luu vao Firestore.

Luu y:
- Tai lieu nay danh cho phuong an Firebase Functions (can goi Blaze).
- Neu ban dung Spark (mien phi), xem tai lieu `BACKEND_SEPAY_SPARK_WORKER.md`.

## Kien truc

- Endpoint webhook: `sepayWebhook`
  - Nhan HTTP POST tu SePay.
  - Xac thuc bang secret trong callback URL (`?secret=...`).
  - Chuan hoa payload va upsert vao collection `sepay_transactions`.
- Endpoint dong bo thu cong: `syncSepayTransactions`
  - HTTP POST co header `x-sync-api-key`.
  - Goi SePay API de lay danh sach giao dich va upsert vao Firestore.
- Dong bo dinh ky: `syncSepayTransactionsScheduled`
  - Chay moi 5 phut.
  - Dung SePay API token de dong bo du lieu.
- Firestore:
  - `sepay_transactions`: luu giao dich da chuan hoa + raw payload.
  - `sepay_sync_state/main`: luu thong tin dong bo gan nhat.

## Cac file da tao

- `firebase.json`
- `.firebaserc`
- `firestore.rules`
- `firestore.indexes.json`
- `functions/package.json`
- `functions/index.js`
- `functions/.env.example`

## Buoc chay bang Firebase CLI

Dieu kien bat buoc:
- Project Firebase phai o goi Blaze (pay-as-you-go) de dung Cloud Functions v2 va Secret Manager.
- Neu dang o Spark, can nang cap truoc khi set secrets/deploy.

1. Cai Firebase CLI (neu chua co):

```bash
npm i -g firebase-tools
firebase --version
```

2. Dang nhap:

```bash
firebase login
```

3. Chon project Firebase:

```bash
firebase use --add
```

4. Cai dependencies cho functions:

```bash
cd functions
npm install
cd ..
```

5. Set Secret Manager (quan trong):

```bash
firebase functions:secrets:set SEPAY_API_TOKEN
firebase functions:secrets:set SEPAY_API_URL
firebase functions:secrets:set SEPAY_WEBHOOK_SECRET
firebase functions:secrets:set SYNC_API_KEY
```

Gia tri goi y:
- `SEPAY_API_TOKEN`: token SePay cua ban.
- `SEPAY_API_URL`: endpoint API lich su giao dich tu tai lieu SePay.
- `SEPAY_WEBHOOK_SECRET`: chuoi bi mat manh, vi du 32+ ky tu.
- `SYNC_API_KEY`: chuoi bi mat de goi endpoint sync thu cong.

6. Deploy:

```bash
firebase deploy --only "functions,firestore"
```

## Cau hinh webhook tren SePay

Sau khi deploy, ban se co URL ham:

`https://asia-southeast1-<PROJECT_ID>.cloudfunctions.net/sepayWebhook`

Dat callback URL tren SePay theo mau:

`https://asia-southeast1-<PROJECT_ID>.cloudfunctions.net/sepayWebhook?secret=<SEPAY_WEBHOOK_SECRET>`

Luu y:
- Neu SePay ho tro custom header chu ky/HMAC, ban nen bat them de tang bao mat.
- Token API KHONG duoc dua vao app Flutter.

## Test nhanh

### Test webhook local (sau deploy)

```bash
curl -X POST "https://asia-southeast1-<PROJECT_ID>.cloudfunctions.net/sepayWebhook?secret=<SEPAY_WEBHOOK_SECRET>" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "demo-001",
    "amount": 150000,
    "direction": "in",
    "description": "Nap vi",
    "created_at": "2026-03-19T10:00:00+07:00",
    "account_number": "123456789",
    "bank_code": "VCB"
  }'
```

### Trigger sync thu cong

```bash
curl -X POST "https://asia-southeast1-<PROJECT_ID>.cloudfunctions.net/syncSepayTransactions" \
  -H "x-sync-api-key: <SYNC_API_KEY>"
```

## Doc du lieu tu Flutter (goi y)

Ban co the doc collection `sepay_transactions` qua Firebase SDK trong app de hien thi giao dich realtime.

## Bao mat

- Khuyen nghi doi (rotate) SePay API token vi token da tung xuat hien trong doan chat.
- Khong hardcode token vao source code hoac app Flutter.
- Chi cap quyen read cho nguoi dung da dang nhap trong `firestore.rules`.
