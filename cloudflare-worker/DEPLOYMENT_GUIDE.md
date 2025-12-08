# MediSwitch Worker - Deployment & Testing Guide

## 🚀 Quick Start

### 1. Prerequisites
```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login
```

### 2. D1 Database Setup

#### Check existing D1 database:
```bash
wrangler d1 list
```

#### Get database ID (if exists):
Look for `mediswitch_db` and copy the ID, then update `wrangler.toml`:
```toml
database_id = "YOUR_ACTUAL_DATABASE_ID"
```

#### If database doesn't exist, create it:
```bash
wrangler d1 create mediswitch_db
```

### 3. Verify D1 Tables

```bash
# Execute SQL to check tables
wrangler d1 execute mediswitch_db --command "SELECT name FROM sqlite_master WHERE type='table'"
```

Expected tables:
- `medicines`
- `dosage_guidelines`
- `drug_interactions`
- `config`

### 4. Local Development

```bash
cd cloudflare-worker

# Start local dev server
npm run dev
# or
wrangler dev src/worker.js
```

Visit: `http://localhost:8787/api/health`

Expected response:
```json
{
  "success": true,
  "status": "healthy",
  "version": "3.0",
  "database": "connected",
  "timestamp": "2024-12-08T..."
}
```

### 5. Test Endpoints Locally

```bash
# Health check
curl http://localhost:8787/api/health

# Get stats
curl http://localhost:8787/api/stats

# Get dosages
curl "http://localhost:8787/api/dosages?page=1&limit=10"

# Create dosage (example)
curl -X POST http://localhost:8787/api/dosages \
  -H "Content-Type: application/json" \
  -d '{
    "active_ingredient": "Test Ingredient",
    "strength": "500mg",
    "standard_dose": "1-2 tablets",
    "max_dose": "8 tablets/day",
    "package_label": "Test label"
  }'

# Get recent price changes
curl http://localhost:8787/api/analytics/recent-price-changes

# Get daily analytics
curl http://localhost:8787/api/analytics/daily?days=7

# Admin: Get drugs
curl "http://localhost:8787/api/admin/drugs?page=1&limit=10"

# Get configuration
curl http://localhost:8787/api/config

# Get interactions
curl "http://localhost:8787/api/admin/interactions?page=1"
```

### 6. Deploy to Production

```bash
# Deploy Worker
wrangler deploy src/worker.js

# Your Worker URL will be:
# https://mediswitch-api.<your-subdomain>.workers.dev
```

### 7. Update Admin Dashboard API URL

Edit `/admin-dashboard/src/lib/api.ts`:
```typescript
export const API_BASE_URL = 
  import.meta.env.VITE_API_DIR || 
  'https://mediswitch-api.YOUR-SUBDOMAIN.workers.dev';
```

Or set environment variable in Cloudflare Pages:
```
VITE_API_DIR = https://mediswitch-api.YOUR-SUBDOMAIN.workers.dev
```

---

## 📊 API Endpoints Reference

### Public Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check |
| GET | `/api/stats` | General statistics |

### Dosages Management

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/dosages` | List dosages (paginated) |
| GET | `/api/dosages/:id` | Get single dosage |
| POST | `/api/dosages` | Create dosage |
| PUT | `/api/dosages/:id` | Update dosage |
| DELETE | `/api/dosages/:id` | Delete dosage |

**Query Parameters for GET /api/dosages:**
- `page` (default: 1)
- `limit` (default: 100)
- `search` (filters by ingredient/strength)
- `sort` (default: active_ingredient)

### Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/analytics/recent-price-changes` | Recent price changes |
| GET | `/api/analytics/daily` | Daily analytics |

**Query Parameters:**
- `limit` - for price changes (default: 10)
- `days` - for daily analytics (default: 7)

### Admin - Drugs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/drugs` | List drugs (paginated) |
| PUT | `/api/admin/drugs/:id` | Update drug |

### Admin - Interactions

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/interactions` | List interactions |
| POST | `/api/admin/interactions` | Create interaction |
| PUT | `/api/admin/interactions/:id` | Update interaction |
| DELETE | `/api/admin/interactions/:id` | Delete interaction |

### Configuration

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/config` | Get all config |
| PUT | `/api/config` | Update config |

---

## 🧪 Testing Checklist

### Basic Functionality
- [ ] Worker deploys successfully
- [ ] Health check returns 200
- [ ] Stats endpoint returns data
- [ ] CORS headers present

### Dosages CRUD
- [ ] GET /api/dosages returns list
- [ ] GET /api/dosages/:id returns single item
- [ ] POST /api/dosages creates new dosage
- [ ] PUT /api/dosages/:id updates dosage
- [ ] DELETE /api/dosages/:id deletes dosage
- [ ] Search filtering works
- [ ] Pagination works correctly

### Analytics
- [ ] Price changes return recent data
- [ ] Daily analytics return 7 days of data
- [ ] Data format matches frontend expectations

### Admin Features
- [ ] Drug list returns paginated results
- [ ] Drug update works
- [ ] Interactions CRUD operations work
- [ ] Configuration get/update works

### Error Handling
- [ ] 404 for non-existent resources
- [ ] 400 for invalid input
- [ ] 500 for server errors
- [ ] Proper error messages returned

---

## 🔧 Troubleshooting

### Worker не работает после деплоя
1. Check wrangler.toml has correct database_id
2. Verify D1 database exists: `wrangler d1 list`
3. Check Worker logs: `wrangler tail`

### "Database not configured" error
- D1 binding name must be `DB` in wrangler.toml
- Database must exist and be bound correctly

### CORS errors in dashboard
- Worker returns CORS headers on all responses
- Check browser developer console for details

### Empty data responses
- Verify D1 tables have data
- Run migrations if needed
- Check D1 in Cloudflare dashboard

---

## 📝 Next Steps

1. ✅ Deploy Worker
2. ✅ Test all endpoints
3. ✅ Update Dashboard API URL
4. ✅ Test Dashboard integration
5. ⏳ Monitor production logs
6. ⏳ Set up custom domain (optional)

---

## 🎯 Production Checklist

Before going live:
- [ ] Worker deployed and tested
- [ ] D1 database has production data
- [ ] Dashboard points to correct API URL
- [ ] All CRUD operations tested
- [ ] Error handling verified
- [ ] CORS working from dashboard domain
- [ ] Performance acceptable (< 200ms responses)

Done! Worker is now serving real data from D1! 🎉
