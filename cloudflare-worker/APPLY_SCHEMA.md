# Apply Cloudflare D1 Schema for Drug Interactions

## Instructions

### 1. Apply Schema via Wrangler CLI

```bash
cd cloudflare-worker
npx wrangler d1 execute MediSwitch --file=schema_interactions.sql
```

### 2. Verify Tables Created

```bash
npx wrangler d1 execute MediSwitch --command="SELECT name FROM sqlite_master WHERE type='table'"
```

Expected output:
- `drug_interactions`
- `interaction_sync_log`

### 3. Test Insert

```bash
npx wrangler d1 execute MediSwitch --command="
INSERT INTO drug_interactions 
(ingredient1, ingredient2, severity, type, effect) 
VALUES ('test_drug1', 'test_drug2', 'minor', 'pharmacodynamic', 'Test interaction')
"
```

### 4. Verify Insert

```bash
npx wrangler d1 execute MediSwitch --command="SELECT * FROM drug_interactions LIMIT 1"
```

### 5. Clean Test Data

```bash
npx wrangler d1 execute MediSwitch --command="DELETE FROM drug_interactions WHERE ingredient1='test_drug1'"
```

---

## Alternative: Apply via Dashboard

1. Go to Cloudflare Dashboard
2. Workers & Pages → D1
3. Select "MediSwitch" database
4. Click "Console"
5. Copy contents of `schema_interactions.sql`
6. Paste and execute

---

## Next: Upload Real Data

After schema is applied:

```bash
python3 scripts/upload_interactions_d1.py \
  --json-file assets/data/drug_interactions.json \
  --account-id YOUR_ACCOUNT_ID \
  --database-id YOUR_DB_ID \
  --api-token YOUR_TOKEN \
  --clear-first
```
