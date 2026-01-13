/**
 * MediSwitch Cloudflare Worker API v2.0
 * With Authentication & Subscriptions
 */

import {
  corsHeaders,
  generateId,
  hashPassword,
  jsonResponse,
  verifyPassword
} from './utils.js';

// Use exported corsHeaders as CORS_HEADERS for compatibility
const CORS_HEADERS = corsHeaders;

// Main request handler function

// Main request handler function
async function handleRequest(request, env) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS });
  }

  const url = new URL(request.url);
  const path = url.pathname;

  try {
    // Health check
    if (path === '/api/health') {
      return jsonResponse({ status: 'healthy', version: '2.0' });
    }

    // Stats
    if (path === '/api/stats' && request.method === 'GET') {
      const drugs = await env.DB.prepare('SELECT COUNT(*) as count FROM drugs').first();
      const companies = await env.DB.prepare('SELECT COUNT(DISTINCT company) as count FROM drugs').first();
      const recent = await env.DB.prepare('SELECT COUNT(*) as count FROM drugs WHERE DATE(updated_at) >= DATE("now", "-7 days")').first();

      let users = 0, subs = 0;
      try {
        const u = await env.DB.prepare('SELECT COUNT(*) as count FROM users').first();
        users = u?.count || 0;
        const s = await env.DB.prepare('SELECT COUNT(*) as count FROM user_subscriptions WHERE status = "active"').first();
        subs = s?.count || 0;
      } catch (e) { }

      return jsonResponse({
        total_drugs: drugs.count,
        total_companies: companies.count,
        recent_updates_7d: recent.count,
        total_users: users,
        active_subscriptions: subs
      });
    }

    // Get subscription plans
    if (path === '/api/plans' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare('SELECT * FROM subscription_plans WHERE is_active = 1 ORDER BY sort_order').all();
        return jsonResponse({ data: results || [] });
      } catch (e) {
        return jsonResponse({ data: [] });
      }
    }

    // Drugs - listing with enhanced features
    if (path === '/api/drugs' && request.method === 'GET') {
      const page = parseInt(url.searchParams.get('page') || '1');
      const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);
      const search = url.searchParams.get('search') || '';
      const category = url.searchParams.get('category') || '';
      const sortBy = url.searchParams.get('sortBy') || 'updated_at';
      const sortOrder = url.searchParams.get('sortOrder') || 'DESC';
      const offset = (page - 1) * limit;

      let query = 'SELECT * FROM drugs WHERE 1=1';
      const params = [];

      if (search) {
        query += ' AND (trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ?)';
        const pattern = `%${search}%`;
        params.push(pattern, pattern, pattern);
      }

      if (category) {
        query += ' AND category = ?';
        params.push(category);
      }

      const validSorts = ['trade_name', 'price', 'updated_at', 'category', 'company'];
      const sort = validSorts.includes(sortBy) ? sortBy : 'updated_at';
      const order = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

      query += ` ORDER BY ${sort} ${order} LIMIT ? OFFSET ?`;
      params.push(limit, offset);

      const { results } = await env.DB.prepare(query).bind(...params).all();

      let countQuery = 'SELECT COUNT(*) as total FROM drugs WHERE 1=1';
      const countParams = [];
      if (search) {
        countQuery += ' AND (trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ?)';
        const pattern = `%${search}%`;
        countParams.push(pattern, pattern, pattern);
      }
      if (category) {
        countQuery += ' AND category = ?';
        countParams.push(category);
      }

      const { total } = await env.DB.prepare(countQuery).bind(...countParams).first();

      return jsonResponse({
        data: results,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
          hasMore: (page * limit) < total
        }
      });
    }

    // Get single drug
    if (path.match(/^\/api\/drugs\/[^/]+$/) && request.method === 'GET') {
      const id = path.split('/').pop();
      const drug = await env.DB.prepare('SELECT * FROM drugs WHERE id = ?').bind(id).first();
      if (!drug) return jsonResponse({ error: 'Not found' }, 404);
      return jsonResponse({ data: drug });
    }

    // Register
    if (path === '/api/auth/register' && request.method === 'POST') {
      const { email, password, name } = await request.json();
      if (!email || !password) return jsonResponse({ error: 'Email and password required' }, 400);

      const exists = await env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(email).first();
      if (exists) return jsonResponse({ error: 'Email already registered' }, 409);

      const userId = generateId();
      const hash = await hashPassword(password);
      const now = Math.floor(Date.now() / 1000);

      await env.DB.prepare('INSERT INTO users (id, email, password_hash, name, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)')
        .bind(userId, email, hash, name || null, now, now).run();

      const subId = generateId();
      const expires = now + (100 * 365 * 24 * 60 * 60);
      await env.DB.prepare('INSERT INTO user_subscriptions (id, user_id, plan_id, status, started_at, expires_at, created_at, updated_at) VALUES (?, ?, "free", "active", ?, ?, ?, ?)')
        .bind(subId, userId, now, expires, now, now).run();

      return jsonResponse({ message: 'Registration successful', data: { userId, email, name } }, 201);
    }

    // Login
    if (path === '/api/auth/login' && request.method === 'POST') {
      const { email, password } = await request.json();
      const user = await env.DB.prepare('SELECT * FROM users WHERE email = ? AND status = "active"').bind(email).first();
      if (!user) return jsonResponse({ error: 'Invalid credentials' }, 401);

      const valid = await verifyPassword(password, user.password_hash);
      if (!valid) return jsonResponse({ error: 'Invalid credentials' }, 401);

      return jsonResponse({ message: 'Login successful', data: { userId: user.id, email: user.email, name: user.name } });
    }

    // Admin: Get all users with Real Intelligence
    if (path === '/api/admin/users' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare(`
          SELECT u.id, u.email, u.name, u.phone, u.status, u.created_at, u.last_login,
                 s.plan_id, s.status as subscription_status, s.expires_at,
                 (SELECT COUNT(*) FROM user_searches WHERE user_id = u.id) as search_count
          FROM users u
          LEFT JOIN user_subscriptions s ON u.id = s.user_id AND s.status = 'active'
          ORDER BY u.created_at DESC
        `).all();

        const now = Math.floor(Date.now() / 1000);

        // Enhance with computed intelligence
        const enriched = results.map(u => {
          // 1. Calculate Last Login Days
          const lastLogin = u.last_login || u.created_at;
          const daysSinceLogin = Math.floor((now - lastLogin) / 86400);

          // 2. Engagement Score (0-100)
          // Base: 100
          // Penalty: -2 per day since login
          // Bonus: +1 per search (capped at 20)
          let score = 100 - (daysSinceLogin * 2);
          score += Math.min(u.search_count || 0, 20);
          score = Math.max(0, Math.min(100, score));

          // 3. Churn Risk
          let churn = 'low';
          if (daysSinceLogin > 30) churn = 'high';
          else if (daysSinceLogin > 14) churn = 'medium';

          // 4. Persona Inference
          let persona = 'patient';
          const email = (u.email || '').toLowerCase();
          const name = (u.name || '').toLowerCase();

          if (email.includes('dr') || name.startsWith('dr') || email.includes('clinic') || email.includes('hospital')) persona = 'doctor';
          else if (email.includes('pharma') || name.includes('pharm')) persona = 'pharmacist';
          else if (email.includes('admin')) persona = 'admin';

          return {
            ...u,
            engagement_score: score,
            churn_risk: churn,
            persona: persona,
            days_inactive: daysSinceLogin
          };
        });

        return jsonResponse({ data: enriched });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Get all subscriptions
    if (path === '/api/admin/subscriptions' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare(`
          SELECT s.*, u.email, u.name, p.name_en, p.price
          FROM user_subscriptions s
          JOIN users u ON s.user_id = u.id
          JOIN subscription_plans p ON s.plan_id = p.id
          ORDER BY s.created_at DESC
        `).all();
        return jsonResponse({ data: results || [] });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Update User Status
    if (path.match(/^\/api\/admin\/users\/[^/]+$/) && request.method === 'PUT') {
      try {
        const id = path.split('/').pop();
        const { status } = await request.json();

        if (!['active', 'suspended', 'deleted'].includes(status)) {
          return jsonResponse({ error: 'Invalid status' }, 400);
        }

        const now = Math.floor(Date.now() / 1000);
        await env.DB.prepare('UPDATE users SET status = ?, updated_at = ? WHERE id = ?')
          .bind(status, now, id).run();

        return jsonResponse({ message: 'User status updated', data: { id, status } });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Update Subscription Status
    if (path.match(/^\/api\/admin\/subscriptions\/[^/]+$/) && request.method === 'PUT') {
      try {
        const id = path.split('/').pop();
        const { status } = await request.json();

        if (!['active', 'canceled', 'expired', 'trial'].includes(status)) {
          return jsonResponse({ error: 'Invalid status' }, 400);
        }

        const now = Math.floor(Date.now() / 1000);
        await env.DB.prepare('UPDATE user_subscriptions SET status = ?, updated_at = ? WHERE id = ?')
          .bind(status, now, id).run();

        return jsonResponse({ message: 'Subscription status updated', data: { id, status } });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Drug Management (CRUD)

    // Admin: Get all drugs (with pagination/search for admin)
    if (path === '/api/admin/drugs' && request.method === 'GET') {
      try {
        const page = parseInt(url.searchParams.get('page') || '1');
        const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);
        const search = url.searchParams.get('search') || '';
        const sortBy = url.searchParams.get('sortBy') || 'updated_at';
        const sortOrder = url.searchParams.get('sortOrder') || 'DESC';
        const offset = (page - 1) * limit;

        let query = 'SELECT * FROM drugs WHERE 1=1';
        const params = [];

        if (search) {
          query += ' AND (trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ? OR company LIKE ? OR category LIKE ?)';
          const pattern = `%${search}%`;
          params.push(pattern, pattern, pattern, pattern, pattern);
        }

        const validSorts = ['id', 'trade_name', 'arabic_name', 'active', 'company', 'category', 'price', 'created_at', 'updated_at'];
        const sort = validSorts.includes(sortBy) ? sortBy : 'updated_at';
        const order = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

        query += ` ORDER BY ${sort} ${order} LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const { results } = await env.DB.prepare(query).bind(...params).all();

        let countQuery = 'SELECT COUNT(*) as total FROM drugs WHERE 1=1';
        const countParams = [];
        if (search) {
          countQuery += ' AND (trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ? OR company LIKE ? OR category LIKE ?)';
          const pattern = `%${search}%`;
          countParams.push(pattern, pattern, pattern, pattern, pattern);
        }

        const { total } = await env.DB.prepare(countQuery).bind(...countParams).first();

        return jsonResponse({
          data: results,
          pagination: {
            page,
            limit,
            total,
            totalPages: Math.ceil(total / limit),
            hasMore: (page * limit) < total
          }
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Get single drug by ID
    if (path.match(/^\/api\/admin\/drugs\/[^/]+$/) && request.method === 'GET') {
      try {
        const id = path.split('/').pop();
        const drug = await env.DB.prepare('SELECT * FROM drugs WHERE id = ?').bind(id).first();
        if (!drug) return jsonResponse({ error: 'Drug not found' }, 404);
        return jsonResponse({ data: drug });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Create new drug
    if (path === '/api/admin/drugs' && request.method === 'POST') {
      try {
        const { trade_name, arabic_name, active, company, category, price, description, image_url, atc_codes, external_links } = await request.json();

        // Enhanced validation
        if (!trade_name || !active || !company || !category) {
          return jsonResponse({ error: 'Missing required fields: trade_name, active, company, category' }, 400);
        }

        if (trade_name.trim().length === 0) {
          return jsonResponse({ error: 'Trade name cannot be empty' }, 400);
        }

        if (price !== undefined && (isNaN(price) || price < 0)) {
          return jsonResponse({ error: 'Price must be a positive number' }, 400);
        }

        const drugId = generateId();
        const now = Math.floor(Date.now() / 1000);

        await env.DB.prepare(`
          INSERT INTO drugs (id, trade_name, arabic_name, active, company, category, price, description, image_url, atc_codes, external_links, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(drugId, trade_name, arabic_name || null, active, company, category, price || 0, description || null, image_url || null, atc_codes || null, external_links || null, now, now).run();

        return jsonResponse({ message: 'Drug created successfully', data: { id: drugId, trade_name } }, 201);
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Update existing drug
    if (path.match(/^\/api\/admin\/drugs\/[^/]+$/) && request.method === 'PUT') {
      try {
        const id = path.split('/').pop();
        const updates = await request.json();
        const now = Math.floor(Date.now() / 1000);

        const fields = [];
        const params = [];

        for (const key in updates) {
          if (['trade_name', 'arabic_name', 'active', 'company', 'category', 'price', 'description', 'image_url', 'atc_codes', 'external_links'].includes(key)) {
            fields.push(`${key} = ?`);
            params.push(updates[key]);
          }
        }

        if (fields.length === 0) {
          return jsonResponse({ error: 'No valid fields provided for update' }, 400);
        }

        fields.push('updated_at = ?');
        params.push(now, id); // Add updated_at and id for WHERE clause

        const stmt = await env.DB.prepare(`UPDATE drugs SET ${fields.join(', ')} WHERE id = ?`).bind(...params);
        const { changes } = await stmt.run();

        if (changes === 0) {
          return jsonResponse({ error: 'Drug not found or no changes made' }, 404);
        }

        return jsonResponse({ message: 'Drug updated successfully', data: { id } });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Delete drug
    if (path.match(/^\/api\/admin\/drugs\/[^/]+$/) && request.method === 'DELETE') {
      try {
        const id = path.split('/').pop();
        const { changes } = await env.DB.prepare('DELETE FROM drugs WHERE id = ?').bind(id).run();

        if (changes === 0) {
          return jsonResponse({ error: 'Drug not found' }, 404);
        }

        return jsonResponse({ message: 'Drug deleted successfully', data: { id } });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: UPSERT drug (Insert or Update based on ID)
    if (path === '/api/admin/drugs/upsert' && request.method === 'POST') {
      try {
        const { id, trade_name, arabic_name, active, company, category, price, description, image_url, atc_codes, external_links, last_price_update } = await request.json();

        // Validation
        if (!id || !trade_name || !active || !company || !category) {
          return jsonResponse({ error: 'Missing required fields: id, trade_name, active, company, category' }, 400);
        }

        if (price !== undefined && (isNaN(price) || price < 0)) {
          return jsonResponse({ error: 'Price must be a positive number' }, 400);
        }

        if (trade_name.trim().length === 0) {
          return jsonResponse({ error: 'Trade name cannot be empty' }, 400);
        }

        const now = Math.floor(Date.now() / 1000);

        // Check if drug exists
        const exists = await env.DB.prepare('SELECT id FROM drugs WHERE id = ?').bind(id).first();

        if (exists) {
          // UPDATE existing drug
          const fields = [];
          const params = [];

          if (trade_name !== undefined) { fields.push('trade_name = ?'); params.push(trade_name); }
          if (arabic_name !== undefined) { fields.push('arabic_name = ?'); params.push(arabic_name); }
          if (active !== undefined) { fields.push('active = ?'); params.push(active); }
          if (company !== undefined) { fields.push('company = ?'); params.push(company); }
          if (category !== undefined) { fields.push('category = ?'); params.push(category); }
          if (price !== undefined) { fields.push('price = ?'); params.push(price); }
          if (description !== undefined) { fields.push('description = ?'); params.push(description); }
          if (image_url !== undefined) { fields.push('image_url = ?'); params.push(image_url); }
          if (atc_codes !== undefined) { fields.push('atc_codes = ?'); params.push(atc_codes); }
          if (external_links !== undefined) { fields.push('external_links = ?'); params.push(external_links); }
          if (last_price_update !== undefined) { fields.push('last_price_update = ?'); params.push(last_price_update); }

          fields.push('updated_at = ?');
          params.push(now, id);

          await env.DB.prepare(`UPDATE drugs SET ${fields.join(', ')} WHERE id = ?`).bind(...params).run();
          return jsonResponse({ message: 'Drug updated successfully', data: { id, action: 'update' } });
        } else {
          // INSERT new drug
          await env.DB.prepare(`
            INSERT INTO drugs (id, trade_name, arabic_name, active, company, category, price, description, image_url, atc_codes, external_links, last_price_update, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `).bind(
            id,
            trade_name,
            arabic_name || null,
            active,
            company,
            category,
            price || 0,
            description || null,
            image_url || null,
            atc_codes || null,
            external_links || null,
            last_price_update || new Date().toISOString().split('T')[0],
            now,
            now
          ).run();

          return jsonResponse({ message: 'Drug created successfully', data: { id, action: 'insert' } }, 201);
        }
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Bulk UPSERT drugs (for daily-update workflow)
    if (path === '/api/admin/drugs/bulk-upsert' && request.method === 'POST') {
      try {
        const { drugs } = await request.json();

        if (!drugs || !Array.isArray(drugs) || drugs.length === 0) {
          return jsonResponse({ error: 'drugs array required' }, 400);
        }

        if (drugs.length > 1000) {
          return jsonResponse({ error: 'Maximum 1000 drugs per batch' }, 400);
        }

        const now = Math.floor(Date.now() / 1000);
        let inserted = 0;
        let updated = 0;
        let errors = 0;

        for (const drug of drugs) {
          try {
            const { id, trade_name, arabic_name, active, company, category, price, description, image_url, last_price_update } = drug;

            if (!id || !trade_name) continue;

            const exists = await env.DB.prepare('SELECT id FROM drugs WHERE id = ?').bind(id).first();

            if (exists) {
              // UPDATE
              const fields = [];
              const params = [];

              if (trade_name) { fields.push('trade_name = ?'); params.push(trade_name); }
              if (arabic_name !== undefined) { fields.push('arabic_name = ?'); params.push(arabic_name); }
              if (active) { fields.push('active = ?'); params.push(active); }
              if (company) { fields.push('company = ?'); params.push(company); }
              if (category) { fields.push('category = ?'); params.push(category); }
              if (price !== undefined) { fields.push('price = ?'); params.push(price); }
              if (description !== undefined) { fields.push('description = ?'); params.push(description); }
              if (image_url !== undefined) { fields.push('image_url = ?'); params.push(image_url); }
              if (last_price_update) { fields.push('last_price_update = ?'); params.push(last_price_update); }

              fields.push('updated_at = ?');
              params.push(now, id);

              await env.DB.prepare(`UPDATE drugs SET ${fields.join(', ')} WHERE id = ?`).bind(...params).run();
              updated++;
            } else {
              // INSERT
              await env.DB.prepare(`
                INSERT INTO drugs (id, trade_name, arabic_name, active, company, category, price, description, image_url, last_price_update, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              `).bind(
                id, trade_name, arabic_name || null, active, company, category,
                price || 0, description || null, image_url || null,
                last_price_update || new Date().toISOString().split('T')[0],
                now, now
              ).run();
              inserted++;
            }
          } catch (e) {
            errors++;
          }
        }

        return jsonResponse({
          message: 'Bulk upsert completed',
          data: { inserted, updated, errors, total: drugs.length }
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Sync: Get all drugs for local database sync
    if (path === '/api/sync/drugs' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;
        const since = parseInt(url.searchParams.get('since')) || 0;

        let query = 'SELECT * FROM drugs';
        let conditions = [];
        let params = [];

        if (since > 0) {
          conditions.push('updated_at > ?');
          params.push(since);
        }

        if (conditions.length > 0) {
          query += ' WHERE ' + conditions.join(' AND ');
        }

        query += ' ORDER BY id';

        if (limit > 0) {
          query += ` LIMIT ${limit} OFFSET ${offset}`;
        }

        const { results } = await env.DB.prepare(query).bind(...params).all();
        const countResult = await env.DB.prepare(
          `SELECT COUNT(*) as total FROM drugs ${conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : ''}`
        ).bind(...params).first();

        return jsonResponse({
          data: results,
          total: countResult.total,
          limit,
          offset,
          hasMore: limit > 0 && (offset + limit) < countResult.total,
          currentTimestamp: Math.floor(Date.now() / 1000)
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Sync: Get all interactions for local database sync (Rule-based)
    if (path === '/api/sync/interactions' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;
        const since = parseInt(url.searchParams.get('since')) || 0;

        let query = 'SELECT * FROM drug_interactions';
        let conditions = [];
        let params = [];

        if (since > 0) {
          conditions.push('updated_at > ?');
          params.push(since); // Interactions don't always have updated_at, but checks created_at if only that exists? 
          // Our V16 schema HAS created_at, but updated_at? V16 schema usually has updated_at?
          // SQLite schema has created_at only for interactions usually?
          // Let's assume we use created_at if updated_at is missing, or query * and let caller filter.
          // Correct V16 schema has `created_at`.
        }

        // Actually, interactions table usually DOES NOT have `updated_at` in simple schemas.
        // Let's check schema. `d1_migration_sql/01_schema.sql` says: `created_at TEXT DEFAULT CURRENT_TIMESTAMP`. No `updated_at`.
        // So `updated_at > ?` will fail if column missing.
        // I will change logic to use `created_at` matching standard sync.
      } catch (e) { }
    }

    // Rewrite Sync Interactions correctly
    if (path === '/api/sync/interactions' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;
        // Interactions are static mostly, so 'since' might just track new insertions

        let query = 'SELECT * FROM drug_interactions';
        let conditions = [];
        let params = [];

        // Simple Pagination
        query += ' ORDER BY id';
        if (limit > 0) query += ` LIMIT ${limit} OFFSET ${offset}`;

        const { results } = await env.DB.prepare(query).bind().all();
        const { count } = await env.DB.prepare('SELECT COUNT(*) as count FROM drug_interactions').first();

        return jsonResponse({
          data: results,
          total: count,
          limit,
          offset,
          hasMore: limit > 0 && (offset + limit) < count,
          currentTimestamp: Math.floor(Date.now() / 1000)
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Sync: Food Interactions
    if (path === '/api/sync/interactions/food' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;

        let query = 'SELECT * FROM food_interactions ORDER BY id';
        if (limit > 0) query += ` LIMIT ${limit} OFFSET ${offset}`;

        const { results } = await env.DB.prepare(query).all();
        const { count } = await env.DB.prepare('SELECT COUNT(*) as count FROM food_interactions').first();

        return jsonResponse({
          data: results || [],
          total: count,
          limit, offset,
          hasMore: limit > 0 && (offset + limit) < count
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Sync: Disease Interactions
    if (path === '/api/sync/interactions/disease' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;

        let query = 'SELECT * FROM disease_interactions ORDER BY id';
        if (limit > 0) query += ` LIMIT ${limit} OFFSET ${offset}`;

        const { results } = await env.DB.prepare(query).all();
        const { count } = await env.DB.prepare('SELECT COUNT(*) as count FROM disease_interactions').first();

        return jsonResponse({
          data: results || [],
          total: count,
          limit, offset,
          hasMore: limit > 0 && (offset + limit) < count
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Sync: Get med-ingredients map for local database sync
    if (path === '/api/sync/med-ingredients' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;
        const since = parseInt(url.searchParams.get('since')) || 0;

        let query = 'SELECT * FROM med_ingredients';
        let conditions = [];
        let params = [];

        if (since > 0) {
          conditions.push('updated_at > ?');
          params.push(since);
        }

        if (conditions.length > 0) {
          query += ' WHERE ' + conditions.join(' AND ');
        }

        query += ' ORDER BY med_id, ingredient';

        if (limit > 0) {
          query += ` LIMIT ${limit} OFFSET ${offset}`;
        }

        const { results } = await env.DB.prepare(query).bind(...params).all();
        const countResult = await env.DB.prepare(
          `SELECT COUNT(*) as total FROM med_ingredients ${conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : ''}`
        ).bind(...params).first();

        return jsonResponse({
          data: results,
          total: countResult.total,
          limit,
          offset,
          hasMore: limit > 0 && (offset + limit) < countResult.total,
          currentTimestamp: Math.floor(Date.now() / 1000)
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Sync: Get all dosages for local database sync
    if (path === '/api/sync/dosages' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;
        const since = parseInt(url.searchParams.get('since')) || 0;

        let query = 'SELECT * FROM dosage_guidelines';
        let conditions = [];
        let params = [];

        if (since > 0) {
          conditions.push('updated_at > ?');
          params.push(since);
        }

        if (conditions.length > 0) {
          query += ' WHERE ' + conditions.join(' AND ');
        }

        query += ' ORDER BY id';

        if (limit > 0) {
          query += ` LIMIT ${limit} OFFSET ${offset}`;
        }

        const { results } = await env.DB.prepare(query).bind(...params).all();
        const countResult = await env.DB.prepare(
          `SELECT COUNT(*) as total FROM dosage_guidelines ${conditions.length > 0 ? 'WHERE ' + conditions.join(' AND ') : ''}`
        ).bind(...params).first();

        return jsonResponse({
          data: results,
          total: countResult.total,
          limit,
          offset,
          hasMore: limit > 0 && (offset + limit) < countResult.total,
          currentTimestamp: Math.floor(Date.now() / 1000)
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Dosage Guidelines - Admin Listing
    if (path === '/api/dosages' && request.method === 'GET') {
      try {
        const page = parseInt(url.searchParams.get('page') || '1');
        const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);
        const search = url.searchParams.get('search') || '';
        const sortBy = url.searchParams.get('sortBy') || 'id';
        const sortOrder = url.searchParams.get('sortOrder') || 'ASC';
        const offset = (page - 1) * limit;

        let query = 'SELECT * FROM dosage_guidelines WHERE 1=1';
        const params = [];

        if (search) {
          query += ' AND (instructions LIKE ? OR condition LIKE ? OR source LIKE ?)';
          const pattern = `%${search}%`;
          params.push(pattern, pattern, pattern);
        }

        const validSorts = ['id', 'med_id', 'min_dose', 'max_dose', 'frequency', 'duration', 'source'];
        const sort = validSorts.includes(sortBy) ? sortBy : 'id';
        const order = sortOrder.toUpperCase() === 'DESC' ? 'DESC' : 'ASC';

        query += ` ORDER BY ${sort} ${order} LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const { results } = await env.DB.prepare(query).bind(...params).all();
        const { total } = await env.DB.prepare('SELECT COUNT(*) as total FROM dosage_guidelines').first();

        return jsonResponse({
          data: results,
          pagination: { page, limit, total }
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Dosage Guidelines - Single CRUD
    if (path.match(/^\/api\/dosages\/[^/]+$/)) {
      const id = path.split('/').pop();

      if (request.method === 'GET') {
        const result = await env.DB.prepare('SELECT * FROM dosage_guidelines WHERE id = ?').bind(id).first();
        if (!result) return jsonResponse({ error: 'Not found' }, 404);
        return jsonResponse({ data: result });
      }

      if (request.method === 'DELETE') {
        await env.DB.prepare('DELETE FROM dosage_guidelines WHERE id = ?').bind(id).run();
        return jsonResponse({ message: 'Deleted successfully' });
      }

      if (request.method === 'PUT') {
        const updates = await request.json();
        const fields = [];
        const params = [];
        const allowed = ['min_dose', 'max_dose', 'frequency', 'duration', 'instructions', 'condition', 'is_pediatric'];

        for (const key of allowed) {
          if (updates[key] !== undefined) {
            fields.push(`${key} = ?`);
            params.push(updates[key]);
          }
        }

        if (fields.length > 0) {
          params.push(id);
          await env.DB.prepare(`UPDATE dosage_guidelines SET ${fields.join(', ')} WHERE id = ?`).bind(...params).run();
        }
        return jsonResponse({ message: 'Updated successfully' });
      }
    }

    if (path === '/api/dosages' && request.method === 'POST') {
      const data = await request.json();
      const { med_id, instructions, source } = data;
      if (!med_id || !instructions) return jsonResponse({ error: 'med_id and instructions required' }, 400);

      await env.DB.prepare(`
        INSERT INTO dosage_guidelines (med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).bind(
        med_id, data.dailymed_setid || null, data.min_dose || 0, data.max_dose || null,
        data.frequency || 0, data.duration || 0, instructions, data.condition || '',
        source || 'Admin', data.is_pediatric ? 1 : 0
      ).run();

      return jsonResponse({ message: 'Created successfully' }, 201);
    }

    // Delta Sync Alias (Backward Compatibility)
    if (path.startsWith('/api/drugs/delta/') && request.method === 'GET') {
      const parts = path.split('/');
      const timestamp = parseInt(parts[parts.length - 1]) || 0;
      // Redirect or rewrite to /api/sync/drugs?since=
      const sinceParam = timestamp > 1000000000 ? timestamp : 0; // Check if valid timestamp

      // We can just call the same logic as sync/drugs
      url.searchParams.set('since', sinceParam.toString());
      // Re-trigger the sync/drugs logic by falling through or just copying logic.
      // Easiest is to fall through if we restructure, but here let's just use JSON response manually or use a helper.
      // But path matched sync/drugs won't trigger if we are here.
      // Let's just implement a simple wrapper.
      try {
        const { results } = await env.DB.prepare('SELECT * FROM drugs WHERE updated_at > ? ORDER BY updated_at DESC').bind(sinceParam).all();
        return jsonResponse({
          count: results.length,
          drugs: results,
          currentTimestamp: Math.floor(Date.now() / 1000)
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Notifications Management
    if (path === '/api/admin/notifications' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare('SELECT * FROM notifications ORDER BY created_at DESC LIMIT 50').all();
        return jsonResponse({ data: results || [] });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    if (path === '/api/admin/notifications' && request.method === 'POST') {
      try {
        const { title, message, type, user_id } = await request.json();
        if (!title || !message) return jsonResponse({ error: 'Title and message required' }, 400);

        const id = generateId();
        const now = Math.floor(Date.now() / 1000);

        await env.DB.prepare('INSERT INTO notifications (id, user_id, title_en, title_ar, message_en, message_ar, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)')
          .bind(id, user_id || null, title, title, message, message, type || 'system', now).run();

        return jsonResponse({ message: 'Notification sent', data: { id } }, 201);
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Interactions Management
    if (path === '/api/admin/interactions' && request.method === 'POST') {
      try {
        const { ingredient1, ingredient2, severity, effect } = await request.json();

        // Basic validation
        if (!ingredient1 || !ingredient2 || !effect) {
          return jsonResponse({ error: 'Components and effect required' }, 400);
        }

        const now = new Date().toISOString().replace('T', ' ').split('.')[0];

        await env.INTERACTIONS_DB.prepare('INSERT INTO drug_interactions (ingredient1, ingredient2, severity, effect, created_at) VALUES (?, ?, ?, ?, ?)')
          .bind(ingredient1, ingredient2, severity, effect, now).run();

        return jsonResponse({ message: 'Interaction created' }, 201);
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    if (path.match(/^\/api\/admin\/interactions\/[^/]+$/) && request.method === 'PUT') {
      try {
        const id = path.split('/').pop();
        const { ingredient1, ingredient2, severity, effect } = await request.json();

        await env.INTERACTIONS_DB.prepare('UPDATE drug_interactions SET ingredient1 = ?, ingredient2 = ?, severity = ?, effect = ? WHERE id = ?')
          .bind(ingredient1, ingredient2, severity, effect, id).run();

        return jsonResponse({ message: 'Interaction updated', data: { id } });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    if (path.match(/^\/api\/admin\/interactions\/[^/]+$/) && request.method === 'DELETE') {
      try {
        const id = path.split('/').pop();
        await env.INTERACTIONS_DB.prepare('DELETE FROM drug_interactions WHERE id = ?').bind(id).run();
        return jsonResponse({ message: 'Interaction deleted', data: { id } });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Analytics: Missed Searches
    if (path === '/api/searches/missed' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare('SELECT * FROM missed_searches ORDER BY count DESC LIMIT 50').all();
        return jsonResponse({ data: results || [] });
      } catch (e) {
        // Table might not exist yet if schema_config wasn't applied or failed
        return jsonResponse({ data: [] });
      }
    }

    // Analytics: Daily Stats
    if (path === '/api/analytics/daily' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare('SELECT * FROM analytics_daily ORDER BY date DESC LIMIT 30').all();
        return jsonResponse({ data: (results || []).reverse() });
      } catch (e) {
        return jsonResponse({ data: [] });
      }
    }

    if (path === '/api/config' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare('SELECT * FROM app_config').all();
        const config = {};
        if (results) results.forEach(r => config[r.key] = r.value);
        return jsonResponse(config);
      } catch (e) {
        return jsonResponse({});
      }
    }

    if (path === '/api/interactions' && request.method === 'GET') {
      const page = parseInt(url.searchParams.get('page') || '1');
      const limit = parseInt(url.searchParams.get('limit') || '100');
      const offset = (page - 1) * limit;

      try {
        const { results } = await env.INTERACTIONS_DB.prepare('SELECT * FROM drug_interactions ORDER BY created_at DESC LIMIT ? OFFSET ?')
          .bind(limit, offset).all();
        const { count } = await env.INTERACTIONS_DB.prepare('SELECT COUNT(*) as count FROM drug_interactions').first();

        return jsonResponse({
          data: results || [],
          pagination: { page, limit, total: count, pages: Math.ceil(count / limit) }
        });
      } catch (e) {
        return jsonResponse({ data: [], pagination: { page: 1, limit, total: 0, pages: 0 } });
      }
    }

    // Admin: Generic DB Manager - List Tables
    if (path === '/api/admin/db/tables' && request.method === 'GET') {
      try {
        // Fetch all tables excluding sqlite internal ones
        const { results } = await env.DB.prepare("SELECT name FROM sqlite_schema WHERE type ='table' AND name NOT LIKE 'sqlite_%'").all();
        const tables = results.map(r => r.name);
        return jsonResponse({ data: tables });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: Generic DB Manager - Execute Query
    if (path === '/api/admin/db/query' && request.method === 'POST') {
      try {
        const { query, params = [], target = 'main' } = await request.json();

        // Basic security check (though it is admin only)
        if (!query) return jsonResponse({ error: 'Query required' }, 400);

        // Select Database Binding
        let selectedDB = env.DB;
        if (target === 'interactions') {
          selectedDB = env.INTERACTIONS_DB;
        }

        const stmt = selectedDB.prepare(query).bind(...params);

        // Check if it's a SELECT or modifying query
        const isSelect = query.trim().toUpperCase().startsWith('SELECT') || query.trim().toUpperCase().startsWith('PRAGMA');

        if (isSelect) {
          const { results } = await stmt.all();
          return jsonResponse({ data: results || [] });
        } else {
          const { meta } = await stmt.run();
          return jsonResponse({ message: 'Query executed', meta });
        }
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }


    // Admin: Sponsored Drugs
    if (path === '/api/admin/sponsored' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare(`
          SELECT s.*, d.trade_name as drug_name 
          FROM sponsored_drugs s
          LEFT JOIN drugs d ON s.drug_id = d.id
          ORDER BY s.priority DESC
        `).all();
        return jsonResponse({ data: results || [] });
      } catch (e) {
        return jsonResponse({ data: [] }); // Start with empty if table missing
      }
    }

    if (path === '/api/admin/sponsored' && request.method === 'POST') {
      try {
        const { drug_id, priority, expires_at } = await request.json();
        const id = generateId();
        await env.DB.prepare('INSERT INTO sponsored_drugs (id, drug_id, priority, active, expires_at) VALUES (?, ?, ?, ?, ?)')
          .bind(id, drug_id, priority || 1, 1, expires_at).run();
        return jsonResponse({ message: 'Sponsored drug added', data: { id } }, 201);
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Admin: IAP Products
    if (path === '/api/admin/iap' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare('SELECT * FROM iap_products ORDER BY price').all();
        return jsonResponse({ data: results || [] });
      } catch (e) {
        return jsonResponse({ data: [] });
      }
    }

    // Update Config
    if (path === '/api/config' && request.method === 'PUT') {
      try {
        const updates = await request.json();
        // Upsert config keys
        for (const [key, value] of Object.entries(updates)) {
          const exists = await env.DB.prepare('SELECT 1 FROM app_config WHERE key = ?').bind(key).first();
          if (exists) {
            await env.DB.prepare('UPDATE app_config SET value = ?, updated_at = CURRENT_TIMESTAMP WHERE key = ?').bind(String(value), key).run();
          } else {
            await env.DB.prepare('INSERT INTO app_config (key, value) VALUES (?, ?)').bind(key, String(value)).run();
          }
        }
        return jsonResponse({ message: 'Config updated' });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // 404
    return jsonResponse({ error: 'Not found' }, 404);
  } catch (e) {
    return jsonResponse({ error: e.message || 'Server Error' }, 500);
  }
}

// Event listener (Service Worker format)
export default {
  async fetch(request, env, ctx) {
    return handleRequest(request, env);
  }
};
