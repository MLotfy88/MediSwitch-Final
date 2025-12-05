# Apply D1 Schema - Quick Guide

## Option 1: Using Environment Variable (Recommended)

```bash
export CLOUDFLARE_API_TOKEN="your_token_here"
python3 scripts/apply_d1_schema.py
```

## Option 2: Using Command Line Argument

```bash
python3 scripts/apply_d1_schema.py --api-token "your_token_here"
```

## Option 3: Via GitHub Actions (Automatic)

The workflow will apply schema automatically if it doesn't exist.

---

## Getting Your Token

1. Go to Cloudflare Dashboard
2. My Profile → API Tokens
3. Use existing token or create new one
4. Copy token value

---

## After Schema Applied

Upload interactions:
```bash
export CLOUDFLARE_API_TOKEN="your_token_here"
python3 scripts/upload_interactions_d1.py \
  --json-file assets/data/drug_interactions.json \
  --account-id 9f7fd7dfef294f26d47d62df34726367 \
  --database-id 77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0 \
  --api-token "$CLOUDFLARE_API_TOKEN" \
  --clear-first
```
