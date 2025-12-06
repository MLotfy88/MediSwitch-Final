/**
 * MediSwitch Cloudflare Worker API - Service Worker Format
 * Complete implementation without ES modules
 */

// ==========================================
// Utility Functions
// ==========================================

function generateId() {
    return crypto.randomUUID();
}

async function hashPassword(password) {
    const encoder = new TextEncoder();
    const data = encoder.encode(password);
    const hash = await crypto.subtle.digest('SHA-256', data);
    return Array.from(new Uint8Array(hash))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
}

async function verifyPassword(password, hash) {
    const computed = await hashPassword(password);
    return computed === hash;
}

async function generateToken(payload, secret) {
    const header = { alg: 'HS256', typ: 'JWT' };
    const exp = Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60); // 7 days
    const body = { ...payload, exp, iat: Math.floor(Date.now() / 1000) };

    const base64Header = btoa(JSON.stringify(header));
    const base64Payload = btoa(JSON.stringify(body));
    const signature = await sign(`${base64Header}.${base64Payload}`, secret);

    return `${base64Header}.${base64Payload}.${signature}`;
}

async function verifyToken(token, secret) {
    try {
        const [header, payload, signature] = token.split('.');
        const expectedSignature = await sign(`${header}.${payload}`, secret);

        if (signature !== expectedSignature) {
            return null;
        }

        const decoded = JSON.parse(atob(payload));

        if (decoded.exp < Math.floor(Date.now() / 1000)) {
            return null; // Expired
        }

        return decoded;
    } catch {
        return null;
    }
}

async function sign(data, secret) {
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
        'raw',
        encoder.encode(secret),
        { name: 'HMAC', hash: 'SHA-256' },
        false,
        ['sign']
    );

    const signature = await crypto.subtle.sign(
        'HMAC',
        key,
        encoder.encode(data)
    );

    return btoa(String.fromCharCode(...new Uint8Array(signature)));
}

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

function jsonResponse(data, status = 200) {
    return new Response(JSON.stringify({
        success: true,
        ...data,
        timestamp: new Date().toISOString()
    }), {
        status,
        headers: {
            'Content-Type': 'application/json',
            ...corsHeaders
        }
    });
}

function errorResponse(message, status = 400, code = null) {
    return new Response(JSON.stringify({
        success: false,
        error: { message, code: code || `ERROR_${status}` },
        timestamp: new Date().toISOString()
    }), {
        status,
        headers: {
            'Content-Type': 'application/json',
            ...corsHeaders
        }
    });
}

async function requireAuth(request, env) {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Unauthorized');
    }

    const token = authHeader.substring(7);
    const payload = await verifyToken(token, env.JWT_SECRET || 'mediswitch-secret-2024');

    if (!payload) {
        throw new Error('Invalid or expired token');
    }

    return payload;
}

// ==========================================
// Event Listener
// ==========================================

addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request, event));
});

async function handleRequest(request, event) {
    const env = event.env || {};

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
        return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
        // ========== PUBLIC ROUTES ==========

        if (path === '/api/health') {
            return jsonResponse({ status: 'healthy', version: '2.0' });
        }

        if (path === '/api/stats' && request.method === 'GET') {
            return handleStats(request, env);
        }

        if (path === '/api/drugs' && request.method === 'GET') {
            return handleGetDrugs(request, env);
        }

        if (path.match(/^\/api\/drugs\/[^/]+$/) && request.method === 'GET') {
            return handleGetDrug(request, env);
        }

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

        // ========== ADMIN ROUTES ==========

        if (path === '/api/admin/login' && request.method === 'POST') {
            return handleAdminLogin(request, env);
        }

        if (path === '/api/admin/users' && request.method === 'GET') {
            return handleAdminGetUsers(request, env);
        }

        if (path === '/api/admin/subscriptions' && request.method === 'GET') {
            return handleAdminGetSubscriptions(request, env);
        }

        // ========== LEGACY ROUTES ==========

        if (path === '/api/sync' && request.method === 'GET') {
            return handleSync(request, env);
        }

        if (path === '/api/config' && request.method === 'GET') {
            return handleGetConfig(request, env);
        }

        if (path === '/api/interactions' && request.method === 'GET') {
            return handleGetInteractions(request, env);
        }

        // 404
        return errorResponse('Not found', 404);
    } catch (error) {
        console.error('Error:', error);
        return errorResponse(error.message, 500);
    }
}

// ... (سأكمل الـ handlers في التعليق التالي)
