/**
 * MediSwitch Cloudflare Worker API - Complete Version
 * With Auth, Subscriptions, and Drug Management
 */

import {
    corsHeaders,
    errorResponse,
    generateId,
    generateToken,
    hashPassword,
    jsonResponse,
    requireAuth,
    verifyPassword
} from './utils.js';

/**
 * Main request handler
 */
export default {
    async fetch(request, env, ctx) {
        // Handle CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        const url = new URL(request.url);
        const path = url.pathname;

        try {
            // ========== PUBLIC ROUTES ==========

            // Health check
            if (path === '/api/health') {
                return jsonResponse({ status: 'healthy' });
            }

            // Stats
            if (path === '/api/stats' && request.method === 'GET') {
                return handleStats(request, env);
            }

            // Drugs - Public (with optional auth for limits)
            if (path === '/api/drugs' && request.method === 'GET') {
                return handleGetDrugs(request, env);
            }

            if (path.match(/^\/api\/drugs\/[^/]+$/) && request.method === 'GET') {
                return handleGetDrug(request, env);
            }

            // Subscription Plans
            if (path === '/api/plans' && request.method === 'GET') {
                return handleGetPlans(request, env);
            }

            // ========== AUTH ROUTES ==========

            if (path === '/api/auth/register' && request.method === 'POST') {
                return handleRegister(request, env);
            }

            if (path === '/api/auth/login' && request.method === 'POST') {
                return handleLogin(request, env);
            }

            // ========== PROTECTED ROUTES (User) ==========

            if (path === '/api/auth/me' && request.method === 'GET') {
                return handleGetMe(request, env);
            }

            if (path === '/api/subscriptions/my' && request.method === 'GET') {
                return handleGetMySubscription(request, env);
            }

            if (path === '/api/favorites' && request.method === 'GET') {
                return handleGetFavorites(request, env);
            }

            if (path === '/api/favorites' && request.method === 'POST') {
                return handleAddFavorite(request, env);
            }

            if (path.match(/^\/api\/favorites\/[^/]+$/) && request.method === 'DELETE') {
                return handleRemoveFavorite(request, env);
            }

            if (path === '/api/analytics/event' && request.method === 'POST') {
                return handleTrackEvent(request, env);
            }

            if (path === '/api/search/history' && request.method === 'GET') {
                return handleGetSearchHistory(request, env);
            }

            if (path === '/api/notifications' && request.method === 'GET') {
                return handleGetNotifications(request, env);
            }

            // ========== ADMIN ROUTES ==========

            if (path === '/api/admin/login' && request.method === 'POST') {
                return handleAdminLogin(request, env);
            }

            if (path === '/api/admin/users' && request.method === 'GET') {
                return handleAdminGetUsers(request, env);
            }

            if (path === '/api/admin/users' && request.method === 'POST') {
                return handleAdminCreateUser(request, env);
            }

            if (path.match(/^\/api\/admin\/users\/[^/]+$/) && request.method === 'GET') {
                return handleAdminGetUser(request, env);
            }

            if (path.match(/^\/api\/admin\/users\/[^/]+$/) && request.method === 'PUT') {
                return handleAdminUpdateUser(request, env);
            }

            if (path.match(/^\/api\/admin\/users\/[^/]+$/) && request.method === 'DELETE') {
                return handleAdminDeleteUser(request, env);
            }

            if (path === '/api/admin/subscriptions' && request.method === 'GET') {
                return handleAdminGetSubscriptions(request, env);
            }

            if (path === '/api/admin/subscriptions' && request.method === 'POST') {
                return handleAdminCreateSubscription(request, env);
            }

            if (path === '/api/admin/analytics' && request.method === 'GET') {
                return handleAdminAnalytics(request, env);
            }

            if (path === '/api/admin/drugs' && request.method === 'PUT') {
                return handleAdminUpdateDrug(request, env);
            }

            if (path.match(/^\/api\/admin\/drugs\/[^/]+$/) && request.method === 'DELETE') {
                return handleAdminDeleteDrug(request, env);
            }

            // ========== LEGACY ROUTES (keep for compatibility) ==========

            if (path === '/api/sync' && request.method === 'GET') {
                return handleSync(request, env);
            }

            if (path === '/api/update' && request.method === 'POST') {
                return handleUpdate(request, env);
            }

            if (path === '/api/config' && request.method === 'GET') {
                return handleGetConfig(request, env);
            }

            if (path === '/api/config' && request.method === 'POST') {
                return handleUpdateConfig(request, env);
            }

            if (path === '/api/interactions' && request.method === 'GET') {
                return handleGetInteractions(request, env);
            }

            if (path === '/api/searches/missed' && request.method === 'GET') {
                return handleGetMissedSearches(request, env);
            }

            if (path === '/api/searches/missed' && request.method === 'POST') {
                return handleLogMissedSearch(request, env);
            }

            // 404
            return errorResponse('Not found', 404);
        } catch (error) {
            console.error('Error:', error);
            return errorResponse(error.message, 500);
        }
    },
};

// ==========================================
// HANDLER FUNCTIONS
// ==========================================

/**
 * POST /api/auth/register
 */
async function handleRegister(request, env) {
    try {
        const { email, password, name, phone } = await request.json();

        if (!email || !password) {
            return errorResponse('Email and password required', 400);
        }

        // Check if user exists
        const existing = await env.DB.prepare('SELECT id FROM users WHERE email = ?').bind(email).first();
        if (existing) {
            return errorResponse('Email already registered', 409);
        }

        // Create user
        const userId = generateId();
        const passwordHash = await hashPassword(password);
        const now = Math.floor(Date.now() / 1000);

        await env.DB.prepare(`
      INSERT INTO users (id, email, password_hash, name, phone, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).bind(userId, email, passwordHash, name || null, phone || null, now, now).run();

        // Create free subscription
        const subId = generateId();
        const expiresAt = now + (100 * 365 * 24 * 60 * 60); // 100 years for free

        await env.DB.prepare(`
      INSERT INTO user_subscriptions (id, user_id, plan_id, status, started_at, expires_at, created_at, updated_at)
      VALUES (?, ?, 'free', 'active', ?, ?, ?, ?)
    `).bind(subId, userId, now, expiresAt, now, now).run();

        // Generate token
        const token = await generateToken(
            { userId, email, type: 'user' },
            env.JWT_SECRET || 'default-secret'
        );

        return jsonResponse({
            message: 'Registration successful',
            data: { userId, email, name, token }
        }, 201);
    } catch (error) {
        return errorResponse(error.message, 500);
    }
}

/**
 * POST /api/auth/login
 */
async function handleLogin(request, env) {
    try {
        const { email, password } = await request.json();

        const user = await env.DB.prepare(
            'SELECT * FROM users WHERE email = ? AND status = "active"'
        ).bind(email).first();

        if (!user) {
            return errorResponse('Invalid credentials', 401);
        }

        const valid = await verifyPassword(password, user.password_hash);
        if (!valid) {
            return errorResponse('Invalid credentials', 401);
        }

        // Update last login
        const now = Math.floor(Date.now() / 1000);
        await env.DB.prepare('UPDATE users SET last_login = ? WHERE id = ?')
            .bind(now, user.id).run();

        // Generate token
        const token = await generateToken(
            { userId: user.id, email: user.email, type: 'user' },
            env.JWT_SECRET || 'default-secret'
        );

        return jsonResponse({
            message: 'Login successful',
            data: {
                userId: user.id,
                email: user.email,
                name: user.name,
                token
            }
        });
    } catch (error) {
        return errorResponse(error.message, 500);
    }
}

/**
 * GET /api/auth/me
 */
async function handleGetMe(request, env) {
    try {
        const payload = await requireAuth(request, env);

        const user = await env.DB.prepare(`
      SELECT u.id, u.email, u.name, u.phone, u.created_at, u.email_verified,
             s.plan_id, s.status as subscription_status, s.expires_at
      FROM users u
      LEFT JOIN user_subscriptions s ON u.id = s.user_id AND s.status = 'active'
      WHERE u.id = ?
    `).bind(payload.userId).first();

        if (!user) {
            return errorResponse('User not found', 404);
        }

        return jsonResponse({ data: user });
    } catch (error) {
        return errorResponse(error.message, 401);
    }
}

/**
 * GET /api/subscriptions/my
 */
async function handleGetMySubscription(request, env) {
    try {
        const payload = await requireAuth(request, env);

        const sub = await env.DB.prepare(`
      SELECT s.*, p.name_en, p.name_ar, p.price, p.features, p.duration_months
      FROM user_subscriptions s
      JOIN subscription_plans p ON s.plan_id = p.id
      WHERE s.user_id = ? AND s.status = 'active'
      ORDER BY s.created_at DESC
      LIMIT 1
    `).bind(payload.userId).first();

        return jsonResponse({ data: sub || null });
    } catch (error) {
        return errorResponse(error.message, 401);
    }
}

/**
 * GET /api/plans
 */
async function handleGetPlans(request, env) {
    const { results } = await env.DB.prepare(
        'SELECT * FROM subscription_plans WHERE is_active = 1 ORDER BY sort_order'
    ).all();

    return jsonResponse({ data: results });
}

/**
 * GET /api/drugs
 */
async function handleGetDrugs(request, env) {
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = Math.min(parseInt(url.searchParams.get('limit') || '50'), 100);
    const search = url.searchParams.get('search') || '';
    const category = url.searchParams.get('category') || '';
    const sortBy = url.searchParams.get('sortBy') || 'updated_at';
    const sortOrder = url.searchParams.get('sortOrder') || 'DESC';
    const offset = (page - 1) * limit;

    // Build query
    let query = 'SELECT * FROM drugs WHERE 1=1';
    const params = [];

    if (search) {
        query += ' AND (trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ?)';
        const searchPattern = `%${search}%`;
        params.push(searchPattern, searchPattern, searchPattern);
    }

    if (category) {
        query += ' AND category = ?';
        params.push(category);
    }

    // Validate sortBy to prevent SQL injection
    const allowedSorts = ['trade_name', 'price', 'updated_at', 'category', 'company'];
    const validSort = allowedSorts.includes(sortBy) ? sortBy : 'updated_at';
    const validOrder = sortOrder.toUpperCase() === 'ASC' ? 'ASC' : 'DESC';

    query += ` ORDER BY ${validSort} ${validOrder} LIMIT ? OFFSET ?`;
    params.push(limit, offset);

    const { results } = await env.DB.prepare(query).bind(...params).all();

    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM drugs WHERE 1=1';
    const countParams = [];

    if (search) {
        countQuery += ' AND (trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ?)';
        const searchPattern = `%${search}%`;
        countParams.push(searchPattern, searchPattern, searchPattern);
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

/**
 * GET /api/drugs/:id
 */
async function handleGetDrug(request, env) {
    const url = new URL(request.url);
    const id = url.pathname.split('/').pop();

    const drug = await env.DB.prepare('SELECT * FROM drugs WHERE id = ?').bind(id).first();

    if (!drug) {
        return errorResponse('Drug not found', 404);
    }

    return jsonResponse({ data: drug });
}

/**
 * GET /api/stats
 */
async function handleStats(request, env) {
    const totalDrugs = await env.DB.prepare('SELECT COUNT(*) as count FROM drugs').first();
    const totalCompanies = await env.DB.prepare('SELECT COUNT(DISTINCT company) as count FROM drugs').first();
    const recentUpdates = await env.DB.prepare(
        'SELECT COUNT(*) as count FROM drugs WHERE DATE(updated_at) >= DATE("now", "-7 days")'
    ).first();

    // User stats (if users table exists)
    let totalUsers = 0;
    let activeSubscriptions = 0;

    try {
        const users = await env.DB.prepare('SELECT COUNT(*) as count FROM users').first();
        totalUsers = users?.count || 0;

        const subs = await env.DB.prepare(
            'SELECT COUNT(*) as count FROM user_subscriptions WHERE status = "active"'
        ).first();
        activeSubscriptions = subs?.count || 0;
    } catch (e) {
        // Tables might not exist yet
    }

    return jsonResponse({
        total_drugs: totalDrugs.count,
        total_companies: totalCompanies.count,
        recent_updates_7d: recentUpdates.count,
        total_users: totalUsers,
        active_subscriptions: activeSubscriptions
    });
}

// ... (باقي الـ handlers في الملف التالي للاختصار)

// Legacy handlers (keep existing ones from old index.js)
// نسخهم كما هم من الملف القديم
