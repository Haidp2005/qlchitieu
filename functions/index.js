const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

const DEFAULT_REGION = 'asia-southeast1';
const DEFAULT_TZ = process.env.APP_TIMEZONE || 'Asia/Ho_Chi_Minh';

const SEPAY_API_TOKEN = defineSecret('SEPAY_API_TOKEN');
const SEPAY_API_URL = defineSecret('SEPAY_API_URL');
const SEPAY_WEBHOOK_SECRET = defineSecret('SEPAY_WEBHOOK_SECRET');
const SYNC_API_KEY = defineSecret('SYNC_API_KEY');

function getConfig() {
  return {
    sepayApiToken: SEPAY_API_TOKEN.value() || '',
    sepayApiUrl:
      SEPAY_API_URL.value() ||
      'https://my.sepay.vn/userapi/transactions/list',
    webhookSecret: SEPAY_WEBHOOK_SECRET.value() || '',
    syncApiKey: SYNC_API_KEY.value() || '',
  };
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
    const normalized = value.replace(/[.,](?=\d{3}(\D|$))/g, '').replace(',', '.');
    const parsed = Number(normalized);
    return Number.isNaN(parsed) ? fallback : parsed;
  }
  return fallback;
}

function normalizeSepayTransaction(raw) {
  const txId = String(
    pick(raw, ['id', 'transaction_id', 'transfer_id', 'reference', 'tid'], '')
  );

  const amount = toNumber(
    pick(raw, ['amount', 'transfer_amount', 'transferAmount', 'value'], 0),
    0
  );

  const directionRaw = String(
    pick(raw, ['direction', 'type', 'transaction_type', 'flow'], '')
  ).toLowerCase();

  const incomingKeywords = ['in', 'credit', 'receive', 'income', 'thu'];
  const direction = incomingKeywords.some((k) => directionRaw.includes(k))
    ? 'IN'
    : 'OUT';

  const createdAtRaw = pick(raw, ['created_at', 'transaction_date', 'time', 'createdAt']);

  let createdAt = new Date();
  if (createdAtRaw) {
    const parsed = new Date(createdAtRaw);
    if (!Number.isNaN(parsed.getTime())) {
      createdAt = parsed;
    }
  }

  const accountNumber = String(
    pick(raw, ['account_number', 'bank_account', 'receiver_account', 'accountNo'], '')
  );

  const bankCode = String(pick(raw, ['bank_code', 'bank', 'bank_name', 'bankCode'], ''));
  const description = String(
    pick(raw, ['description', 'content', 'transaction_content', 'note', 'memo'], '')
  );

  const status = String(pick(raw, ['status', 'state'], 'SUCCESS')).toUpperCase();

  const source = String(pick(raw, ['source', 'provider'], 'SEPAY')).toUpperCase();

  return {
    txId,
    amount,
    direction,
    accountNumber,
    bankCode,
    description,
    status,
    source,
    createdAt,
    raw,
  };
}

function buildDocId(normalized) {
  if (normalized.txId) return `sepay_${normalized.txId}`;

  const fallback = [
    normalized.direction,
    normalized.amount,
    normalized.accountNumber,
    normalized.createdAt.toISOString(),
  ].join('_');

  return `sepay_${Buffer.from(fallback).toString('base64url').slice(0, 40)}`;
}

async function upsertTransaction(normalized, channel) {
  const docId = buildDocId(normalized);
  const ref = db.collection('sepay_transactions').doc(docId);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const payload = {
      provider: 'SEPAY',
      providerTxId: normalized.txId || null,
      amount: normalized.amount,
      direction: normalized.direction,
      accountNumber: normalized.accountNumber || null,
      bankCode: normalized.bankCode || null,
      description: normalized.description || null,
      status: normalized.status,
      source: normalized.source,
      channel,
      transactionTime: admin.firestore.Timestamp.fromDate(normalized.createdAt),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      raw: normalized.raw,
    };

    if (!snap.exists) {
      tx.set(ref, {
        ...payload,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    tx.set(ref, payload, { merge: true });
  });

  return docId;
}

function parseIncomingPayload(body) {
  if (Array.isArray(body)) return body;

  if (body && Array.isArray(body.transactions)) return body.transactions;
  if (body && body.data && Array.isArray(body.data.transactions)) {
    return body.data.transactions;
  }
  if (body && Array.isArray(body.data)) return body.data;

  return body ? [body] : [];
}

exports.sepayWebhook = onRequest(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 60,
    memory: '256MiB',
    secrets: [SEPAY_WEBHOOK_SECRET],
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ ok: false, error: 'Method not allowed' });
      return;
    }

    const cfg = getConfig();
    if (cfg.webhookSecret) {
      const secret = String(req.query.secret || '');
      if (secret !== cfg.webhookSecret) {
        res.status(401).json({ ok: false, error: 'Invalid webhook secret' });
        return;
      }
    }

    try {
      const rawItems = parseIncomingPayload(req.body || {});
      if (rawItems.length === 0) {
        res.status(400).json({ ok: false, error: 'No transaction payload found' });
        return;
      }

      const results = [];
      for (const raw of rawItems) {
        const normalized = normalizeSepayTransaction(raw);
        const docId = await upsertTransaction(normalized, 'WEBHOOK');
        results.push(docId);
      }

      res.status(200).json({ ok: true, saved: results.length, ids: results });
    } catch (error) {
      logger.error('sepayWebhook failed', error);
      res.status(500).json({ ok: false, error: 'Internal error' });
    }
  }
);

async function fetchSepayTransactions() {
  const cfg = getConfig();
  if (!cfg.sepayApiToken) {
    throw new Error('Missing SEPAY_API_TOKEN');
  }

  const response = await fetch(cfg.sepayApiUrl, {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${cfg.sepayApiToken}`,
      'Content-Type': 'application/json',
    },
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`SePay API failed (${response.status}): ${text}`);
  }

  const body = await response.json();
  return parseIncomingPayload(body);
}

async function runSyncJob(triggerType) {
  const rawItems = await fetchSepayTransactions();

  let saved = 0;
  for (const raw of rawItems) {
    const normalized = normalizeSepayTransaction(raw);
    await upsertTransaction(normalized, triggerType);
    saved += 1;
  }

  await db.collection('sepay_sync_state').doc('main').set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      lastRunTimezone: DEFAULT_TZ,
      totalFetched: rawItems.length,
      totalSaved: saved,
      triggerType,
    },
    { merge: true }
  );

  return { fetched: rawItems.length, saved };
}

exports.syncSepayTransactions = onRequest(
  {
    region: DEFAULT_REGION,
    timeoutSeconds: 120,
    memory: '256MiB',
    secrets: [SEPAY_API_TOKEN, SEPAY_API_URL, SYNC_API_KEY],
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ ok: false, error: 'Method not allowed' });
      return;
    }

    const cfg = getConfig();
    if (!cfg.syncApiKey) {
      res.status(500).json({ ok: false, error: 'SYNC_API_KEY is not configured' });
      return;
    }

    const key = req.get('x-sync-api-key') || '';
    if (key !== cfg.syncApiKey) {
      res.status(401).json({ ok: false, error: 'Unauthorized' });
      return;
    }

    try {
      const result = await runSyncJob('MANUAL_SYNC');
      res.status(200).json({ ok: true, ...result });
    } catch (error) {
      logger.error('syncSepayTransactions failed', error);
      res.status(500).json({ ok: false, error: String(error.message || error) });
    }
  }
);

exports.syncSepayTransactionsScheduled = onSchedule(
  {
    schedule: 'every 5 minutes',
    region: DEFAULT_REGION,
    timeZone: DEFAULT_TZ,
    timeoutSeconds: 120,
    memory: '256MiB',
    secrets: [SEPAY_API_TOKEN, SEPAY_API_URL],
  },
  async () => {
    try {
      const result = await runSyncJob('SCHEDULED_SYNC');
      logger.info('Scheduled SePay sync completed', result);
    } catch (error) {
      logger.error('Scheduled SePay sync failed', error);
    }
  }
);
