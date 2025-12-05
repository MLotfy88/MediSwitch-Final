# GitHub Secrets Configuration for Drug Interaction Sync

## Required Secrets

### 1. CLOUDFLARE_API_TOKEN ✅
**Status:** Already exists (used by drug sync workflow)
**Description:** Cloudflare API token with D1 database permissions
**How to get:**
1. Go to Cloudflare Dashboard
2. My Profile → API Tokens
3. Create Token → Edit Cloudflare Workers
4. Add permissions: D1 Database Edit

---

### 2. SLACK_WEBHOOK_URL (Optional) ⚠️
**Status:** Already configured
**Description:** For failure notifications
**How to configure:**
1. Go to Slack App Settings
2. Create Incoming Webhook
3. Copy webhook URL
4. Add as GitHub secret

---

## Current Configuration

From `wrangler.toml`:
```toml
account_id = "9f7fd7dfef294f26d47d62df34726367"
database_name = "mediswitch-db"
database_id = "77da23cd-a8cc-40bf-9c0f-f0effe7eeaa0"
```

These are **hardcoded** in workflow files, no secrets needed! ✅

---

## Workflow Configuration

The monthly interaction sync workflow is configured as:
- **Schedule:** `0 0 10 * *` (10th of every month, midnight UTC)
- **Manual trigger:** Available via GitHub Actions UI
- **Secrets used:**
  - `CLOUDFLARE_API_TOKEN` ✅
  - `SLACK_WEBHOOK_URL` (optional)

---

## Testing the Workflow

### Manual Trigger
1. Go to GitHub → Actions
2. Select "Monthly Drug Interaction Sync from OpenFDA"
3. Click "Run workflow"
4. Select branch: `main`
5. Files to process: `13` (default)

---

## Summary

✅ **All required secrets already exist!**
- CLOUDFLARE_API_TOKEN: Already configured
- Account ID & Database ID: Hardcoded in files

🎯 **Next Steps:**
1. Apply D1 schema (running now)
2. Test manual workflow trigger
3. Wait for 10th of next month for automatic run
