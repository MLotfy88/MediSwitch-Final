/**
 * MediSwitch Cloudflare Worker API v2.0
 * With Authentication & Subscriptions
 */

// CORS headers
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

// Utilities are imported from utils.js via concatenation

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

    // Admin: Get all users
    if (path === '/api/admin/users' && request.method === 'GET') {
      try {
        const { results } = await env.DB.prepare(`
          SELECT u.id, u.email, u.name, u.phone, u.status, u.created_at, u.last_login,
                 s.plan_id, s.status as subscription_status, s.expires_at
          FROM users u
          LEFT JOIN user_subscriptions s ON u.id = s.user_id AND s.status = 'active'
          ORDER BY u.created_at DESC
        `).all();
        return jsonResponse({ data: results || [] });
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
        const { trade_name, arabic_name, active, company, category, price, description, image_url } = await request.json();

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
          INSERT INTO drugs (id, trade_name, arabic_name, active, company, category, price, description, image_url, created_at, updated_at)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(drugId, trade_name, arabic_name || null, active, company, category, price || 0, description || null, image_url || null, now, now).run();

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
          if (['trade_name', 'arabic_name', 'active', 'company', 'category', 'price', 'description', 'image_url'].includes(key)) {
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
        const { id, trade_name, arabic_name, active, company, category, price, description, image_url, last_price_update } = await request.json();

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
          if (last_price_update !== undefined) { fields.push('last_price_update = ?'); params.push(last_price_update); }

          fields.push('updated_at = ?');
          params.push(now, id);

          await env.DB.prepare(`UPDATE drugs SET ${fields.join(', ')} WHERE id = ?`).bind(...params).run();
          return jsonResponse({ message: 'Drug updated successfully', data: { id, action: 'update' } });
        } else {
          // INSERT new drug
          await env.DB.prepare(`
            INSERT INTO drugs (id, trade_name, arabic_name, active, company, category, price, description, image_url, last_price_update, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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

        let query = 'SELECT * FROM drugs ORDER BY id';
        if (limit > 0) {
          query += ` LIMIT ${limit} OFFSET ${offset}`;
        }

        const { results } = await env.DB.prepare(query).all();
        const countResult = await env.DB.prepare('SELECT COUNT(*) as total FROM drugs').first();

        return jsonResponse({
          data: results,
          total: countResult.total,
          limit,
          offset,
          hasMore: limit > 0 && (offset + limit) < countResult.total
        });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    // Sync: Get all interactions for local database sync
    if (path === '/api/sync/interactions' && request.method === 'GET') {
      try {
        const limit = parseInt(url.searchParams.get('limit')) || 0;
        const offset = parseInt(url.searchParams.get('offset')) || 0;

        let query = 'SELECT * FROM drug_interactions ORDER BY id';
        if (limit > 0) {
          query += ` LIMIT ${limit} OFFSET ${offset}`;
        }

        const { results } = await env.DB.prepare(query).all();
        const countResult = await env.DB.prepare('SELECT COUNT(*) as total FROM drug_interactions').first();

        return jsonResponse({
          data: results,
          total: countResult.total,
          limit,
          offset,
          hasMore: limit > 0 && (offset + limit) < countResult.total
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

        const id = generateId(); // Or use auto-increment if INT? Using UUID logic but table might be INT. 
        // Debug output showed ID 221780 (INT). 
        // For new records, we should safe-guard. 
        // If table uses INT PK autoincrement, we shouldn't insert ID.
        // Let's assume we can INSERT without ID if it's autoincrement, OR generate ID if it's UUID. 
        // Given existing data is INT, better let DB handle ID or use MAX+1? D1 supports AUTOINCREMENT.
        // I will try to Insert WITHOUT ID, if it fails I'll generate one.
        // Actually, let's look at previous logic: it was inserting ID. 
        // I will try INSERT without ID first.

        const now = new Date().toISOString().replace('T', ' ').split('.')[0];
        // OpenFDA date format: "2025-12-05 20:19:43"

        await env.DB.prepare('INSERT INTO drug_interactions (ingredient1, ingredient2, severity, effect, created_at) VALUES (?, ?, ?, ?, ?)')
          .bind(ingredient1, ingredient2, severity, effect, now).run();

        // We can't easily get the last ID without returning * usually.
        // But let's assume success.
        return jsonResponse({ message: 'Interaction created' }, 201);
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    if (path.match(/^\/api\/admin\/interactions\/[^/]+$/) && request.method === 'PUT') {
      try {
        const id = path.split('/').pop();
        const { ingredient1, ingredient2, severity, effect } = await request.json();

        await env.DB.prepare('UPDATE drug_interactions SET ingredient1 = ?, ingredient2 = ?, severity = ?, effect = ? WHERE id = ?')
          .bind(ingredient1, ingredient2, severity, effect, id).run();

        return jsonResponse({ message: 'Interaction updated', data: { id } });
      } catch (e) {
        return jsonResponse({ error: e.message }, 500);
      }
    }

    if (path.match(/^\/api\/admin\/interactions\/[^/]+$/) && request.method === 'DELETE') {
      try {
        const id = path.split('/').pop();
        await env.DB.prepare('DELETE FROM drug_interactions WHERE id = ?').bind(id).run();
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
        const { results } = await env.DB.prepare('SELECT * FROM drug_interactions ORDER BY created_at DESC LIMIT ? OFFSET ?')
          .bind(limit, offset).all();
        const { count } = await env.DB.prepare('SELECT COUNT(*) as count FROM drug_interactions').first();

        return jsonResponse({
          data: results || [],
          pagination: { page, limit, total: count, pages: Math.ceil(count / limit) }
        });
      } catch (e) {
        return jsonResponse({ data: [], pagination: { page: 1, limit, total: 0, pages: 0 } });
      }
    }

    // 404
    return jsonResponse({ error: 'Not found' }, 404);

  } catch (error) {
    console.error('Error:', error);
    return jsonResponse({ error: error.message }, 500);
  }
}

// Event listener (Service Worker format)
export default {
  async fetch(request, env, ctx) {
    return handleRequest(request, env);
  }
};
