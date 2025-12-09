// ============================================
// SUBSCRIPTION HANDLERS (Essential Only)
// ============================================

async function handleGetUserSubscription(userId, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const subscription = await DB.prepare(`
            SELECT * FROM subscriptions 
            WHERE user_id = ? AND status = 'active'
            ORDER BY created_at DESC LIMIT 1
        `).bind(userId).first();

        return jsonResponse({ subscription });
    } catch (error) {
        console.error('Get subscription error:', error);
        return errorResponse('Failed to fetch subscription', 500);
    }
}

async function handleVerifySubscription(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const { user_id, transaction_id, platform, tier, purchase_token, starts_at, expires_at, price } = data;

        if (!user_id || !transaction_id || !platform || !tier) {
            return errorResponse('Missing required fields', 400);
        }

        const existing = await DB.prepare(
            'SELECT id FROM subscriptions WHERE transaction_id = ?'
        ).bind(transaction_id).first();

        if (existing) {
            return jsonResponse({ subscription: existing, message: 'Subscription already exists' });
        }

        const result = await DB.prepare(`
            INSERT INTO subscriptions (
                user_id, tier, platform, transaction_id, purchase_token,
                starts_at, expires_at, status, price, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'active', ?, unixepoch('now'), unixepoch('now'))
        `).bind(
            user_id, tier, platform, transaction_id, purchase_token || '',
            starts_at, expires_at, price || 0
        ).run();

        const subscription = await DB.prepare('SELECT * FROM subscriptions WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ subscription }, 201);
    } catch (error) {
        console.error('Verify subscription error:', error);
        return errorResponse('Failed to verify subscription', 500);
    }
}

async function handleCancelSubscription(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare(`
            UPDATE subscriptions 
            SET status = 'canceled', auto_renew = 0, updated_at = unixepoch('now')
            WHERE id = ?
        `).bind(id).run();

        if (result.meta.changes === 0) {
            return errorResponse('Subscription not found', 404);
        }

        return jsonResponse({ message: 'Subscription canceled successfully' });
    } catch (error) {
        console.error('Cancel subscription error:', error);
        return errorResponse('Failed to cancel subscription', 500);
    }
}

async function handleAdminGetSubscriptions(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const status = url.searchParams.get('status') || '';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM subscriptions';
        let countQuery = 'SELECT COUNT(*) as total FROM subscriptions';
        const params = [];

        if (status) {
            query += ' WHERE status = ?';
            countQuery += ' WHERE status = ?';
            params.push(status);
        }

        query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
        params.push(limit, offset);

        const [dataResult, countResult] = await Promise.all([
            DB.prepare(query).bind(...params).all(),
            DB.prepare(countQuery).bind(...(status ? [status] : [])).first()
        ]);

        return jsonResponse({
            data: dataResult.results || [],
            pagination: {
                page,
                limit,
                total: countResult.total || 0,
                totalPages: Math.ceil((countResult.total || 0) / limit)
            }
        });
    } catch (error) {
        console.error('Admin get subscriptions error:', error);
        return errorResponse('Failed to fetch subscriptions', 500);
    }
}

async function handleAdminGrantPremium(userId, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const expiresAt = data.expires_at || Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60);

        const result = await DB.prepare(`
            INSERT INTO subscriptions (
                user_id, tier, platform, starts_at, expires_at, status, created_at, updated_at
            ) VALUES (?, 'premium', 'admin', unixepoch('now'), ?, 'active', unixepoch('now'), unixepoch('now'))
        `).bind(userId, expiresAt).run();

        const subscription = await DB.prepare('SELECT * FROM subscriptions WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ subscription }, 201);
    } catch (error) {
        console.error('Grant premium error:', error);
        return errorResponse('Failed to grant premium', 500);
    }
}
