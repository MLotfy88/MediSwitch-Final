// ==========================================
// Auth & Utility Functions
// ==========================================

export function generateId() {
    return crypto.randomUUID();
}

export async function hashPassword(password) {
    const encoder = new TextEncoder();
    const data = encoder.encode(password);
    const hash = await crypto.subtle.digest('SHA-256', data);
    return Array.from(new Uint8Array(hash))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
}

export async function verifyPassword(password, hash) {
    const computed = await hashPassword(password);
    return computed === hash;
}

export async function generateToken(payload, secret) {
    const header = { alg: 'HS256', typ: 'JWT' };
    const exp = Math.floor(Date.now() / 1000) + (7 * 24 * 60 * 60); // 7 days
    const body = { ...payload, exp, iat: Math.floor(Date.now() / 1000) };

    const base64Header = btoa(JSON.stringify(header));
    const base64Payload = btoa(JSON.stringify(body));
    const signature = await sign(`${base64Header}.${base64Payload}`, secret);

    return `${base64Header}.${base64Payload}.${signature}`;
}

export async function verifyToken(token, secret) {
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

// Response helpers
export const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export function jsonResponse(data, status = 200) {
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

export function errorResponse(message, status = 400, code = null) {
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

// Auth Middleware
export async function requireAuth(request, env) {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        throw new Error('Unauthorized');
    }

    const token = authHeader.substring(7);
    const payload = await verifyToken(token, env.JWT_SECRET || 'default-secret-change-me');

    if (!payload) {
        throw new Error('Invalid or expired token');
    }

    return payload;
}

// Check subscription limits
export async function checkSubscriptionLimit(userId, feature, db) {
    // Get user's active subscription
    const { results } = await db.prepare(`
    SELECT sp.features
    FROM user_subscriptions us
    JOIN subscription_plans sp ON us.plan_id = sp.id
    WHERE us.user_id = ? AND us.status = 'active'
    ORDER BY us.created_at DESC
    LIMIT 1
  `).bind(userId).all();

    if (!results || results.length === 0) {
        // No active subscription, use free plan limits
        const freePlan = await db.prepare(`
      SELECT features FROM subscription_plans WHERE id = 'free'
    `).first();

        if (!freePlan) {
            throw new Error('No subscription plan found');
        }

        return JSON.parse(freePlan.features);
    }

    return JSON.parse(results[0].features);
}
