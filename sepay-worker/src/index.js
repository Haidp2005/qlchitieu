function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

function normalizeArrayPayload(body) {
  if (Array.isArray(body)) return body;
  if (body && Array.isArray(body.transactions)) return body.transactions;
  if (body && body.data && Array.isArray(body.data.transactions)) {
    return body.data.transactions;
  }
  if (body && Array.isArray(body.data)) return body.data;
  return body ? [body] : [];
}

function pick(obj, keys, fallback = null) {
  for (const key of keys) {
    if (obj && obj[key] !== undefined && obj[key] !== null) {
      return obj[key];
    }
  }
  return fallback;
}

function toNumber(value, fallback = 0) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') {
    const cleaned = value.replace(/[.,](?=\d{3}(\D|$))/g, '').replace(',', '.');
    const parsed = Number(cleaned);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

function parseDirection(raw) {
  const val = String(raw || '').toLowerCase();
  if (
    val.includes('in') ||
    val.includes('income') ||
    val.includes('credit') ||
    val.includes('receive') ||
    val.includes('thu')
  ) {
    return 'income';
  }
  return 'expense';
}

function toDate(rawDate) {
  if (!rawDate) return new Date();
  const parsed = new Date(rawDate);
  if (Number.isNaN(parsed.getTime())) return new Date();
  return parsed;
}

async function sha256Base64Url(input) {
  const data = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest('SHA-256', data);
  const bytes = new Uint8Array(digest);
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function toFirestoreDocument(tx, env) {
  const transactionDate = toDate(tx.createdAt);

  return {
    fields: {
      provider: { stringValue: 'SEPAY' },
      source: { stringValue: 'sepay' },
      title: { stringValue: tx.title },
      description: { stringValue: tx.description },
      category: { stringValue: env.DEFAULT_CATEGORY || 'Khac' },
      type: { stringValue: tx.type },
      amount: { doubleValue: tx.amount },
      transactionTime: { timestampValue: transactionDate.toISOString() },
      providerTxId: { stringValue: tx.providerTxId },
      accountNumber: { stringValue: tx.accountNumber },
      bankCode: { stringValue: tx.bankCode },
      updatedAt: { timestampValue: new Date().toISOString() },
      createdAt: { timestampValue: new Date().toISOString() },
    },
  };
}

async function writeTransactionToFirestore(tx, env) {
  const projectId = env.FIREBASE_PROJECT_ID;
  const collection = env.FIRESTORE_COLLECTION || 'transactions';
  const apiKey = env.FIREBASE_WEB_API_KEY;
  const txId = tx.providerTxId || (await sha256Base64Url(`${tx.title}_${tx.amount}_${tx.createdAt}`));
  const docId = `sepay_${txId}`;

  const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/${collection}/${docId}?key=${encodeURIComponent(apiKey)}`;

  const docBody = toFirestoreDocument(tx, env);

  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
    },
    body: JSON.stringify(docBody),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`Firestore write failed (${response.status}): ${text}`);
  }

  return docId;
}

function normalizeSepayTransaction(raw) {
  const providerTxId = String(
    pick(raw, ['id', 'transaction_id', 'transfer_id', 'reference', 'tid'], '')
  );

  const amount = toNumber(
    pick(raw, ['amount', 'transfer_amount', 'transferAmount', 'value'], 0),
    0
  );

  const description = String(
    pick(raw, ['description', 'content', 'transaction_content', 'note', 'memo'], '')
  );

  const title = description && description.trim().length > 0 ? description : 'Giao dich SePay';

  return {
    providerTxId,
    amount,
    type: parseDirection(pick(raw, ['direction', 'type', 'transaction_type', 'flow'], '')),
    title,
    description,
    createdAt: pick(raw, ['created_at', 'transaction_date', 'time', 'createdAt']),
    accountNumber: String(
      pick(raw, ['account_number', 'bank_account', 'receiver_account', 'accountNo'], '')
    ),
    bankCode: String(pick(raw, ['bank_code', 'bank', 'bank_name', 'bankCode'], '')),
  };
}

function validateEnv(env) {
  const required = [
    'WEBHOOK_SECRET',
    'FIREBASE_PROJECT_ID',
    'FIREBASE_WEB_API_KEY',
  ];

  const missing = required.filter((key) => !env[key] || String(env[key]).trim() === '');
  return missing;
}

export default {
  async fetch(request, env) {
    if (request.method === 'GET') {
      return json({ ok: true, service: 'sepay-webhook-firestore', time: new Date().toISOString() });
    }

    if (request.method !== 'POST') {
      return json({ ok: false, error: 'Method not allowed' }, 405);
    }

    const missing = validateEnv(env);
    if (missing.length > 0) {
      return json({ ok: false, error: `Missing env: ${missing.join(', ')}` }, 500);
    }

    const url = new URL(request.url);
    const querySecret = url.searchParams.get('secret') || '';
    const headerSecret = request.headers.get('x-webhook-secret') || '';
    const providedSecret = querySecret || headerSecret;

    if (providedSecret !== env.WEBHOOK_SECRET) {
      return json({ ok: false, error: 'Unauthorized webhook secret' }, 401);
    }

    let body = null;
    try {
      body = await request.json();
    } catch {
      return json({ ok: false, error: 'Invalid JSON payload' }, 400);
    }

    const items = normalizeArrayPayload(body);
    if (items.length === 0) {
      return json({ ok: false, error: 'No transactions found in payload' }, 400);
    }

    try {
      const ids = [];

      for (const item of items) {
        const tx = normalizeSepayTransaction(item);
        const id = await writeTransactionToFirestore(tx, env);
        ids.push(id);
      }

      return json({ ok: true, saved: ids.length, ids });
    } catch (error) {
      return json({ ok: false, error: String(error.message || error) }, 500);
    }
  },
};
