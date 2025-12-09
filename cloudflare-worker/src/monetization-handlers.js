/**
 * MediSwitch Monetization API Handlers
 * All endpoints for subscriptions, IAP, sponsored listings, affiliate, gamification, etc.
 */

// ============================================
// 1. SUBSCRIPTIONS API
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

        // Check if transaction already exists
        const existing = await DB.prepare(
            'SELECT id FROM subscriptions WHERE transaction_id = ?'
        ).bind(transaction_id).first();

        if (existing) {
            return jsonResponse({ subscription: existing, message: 'Subscription already exists' });
        }

        // Create subscription
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

// ============================================
// 2. IN-APP PURCHASES (IAP) API
// ============================================

async function handleGetIAPProducts(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const products = await DB.prepare(
            'SELECT * FROM iap_products WHERE enabled = 1 ORDER BY sort_order, price'
        ).all();

        return jsonResponse({ products: products.results || [] });
    } catch (error) {
        console.error('Get IAP products error:', error);
        return errorResponse('Failed to fetch products', 500);
    }
}

async function handleVerifyIAPPurchase(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const { user_id, product_id, transaction_id, platform, purchase_token, price } = data;

        if (!user_id || !product_id || !transaction_id) {
            return errorResponse('Missing required fields', 400);
        }

        // Check if purchase already exists
        const existing = await DB.prepare(
            'SELECT id FROM iap_purchases WHERE transaction_id = ?'
        ).bind(transaction_id).first();

        if (existing) {
            return jsonResponse({ purchase: existing, message: 'Purchase already exists' });
        }

        // Record purchase
        const result = await DB.prepare(`
            INSERT INTO iap_purchases (
                user_id, product_id, transaction_id, purchase_token, platform, price, status
            ) VALUES (?, ?, ?, ?, ?, ?, 'completed')
        `).bind(user_id, product_id, transaction_id, purchase_token || '', platform, price || 0).run();

        const purchase = await DB.prepare('SELECT * FROM iap_purchases WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ purchase }, 201);
    } catch (error) {
        console.error('Verify IAP purchase error:', error);
        return errorResponse('Failed to verify purchase', 500);
    }
}

async function handleAdminGetIAPProducts(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const products = await DB.prepare('SELECT * FROM iap_products ORDER BY sort_order, created_at DESC').all();
        return jsonResponse({ products: products.results || [] });
    } catch (error) {
        console.error('Admin get IAP products error:', error);
        return errorResponse('Failed to fetch products', 500);
    }
}

async function handleAdminCreateIAPProduct(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const result = await DB.prepare(`
            INSERT INTO iap_products (
                product_id, name, name_ar, description, description_ar, price, currency, type, features, icon, enabled, sort_order
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
            data.product_id,
            data.name,
            data.name_ar || '',
            data.description || '',
            data.description_ar || '',
            data.price,
            data.currency || 'USD',
            data.type || 'non_consumable',
            data.features || '[]',
            data.icon || '',
            data.enabled !== undefined ? data.enabled : 1,
            data.sort_order || 0
        ).run();

        const product = await DB.prepare('SELECT * FROM iap_products WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ product }, 201);
    } catch (error) {
        console.error('Create IAP product error:', error);
        return errorResponse('Failed to create product', 500);
    }
}

async function handleAdminUpdateIAPProduct(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const updates = [];
        const params = [];

        if (data.name !== undefined) { updates.push('name = ?'); params.push(data.name); }
        if (data.name_ar !== undefined) { updates.push('name_ar = ?'); params.push(data.name_ar); }
        if (data.description !== undefined) { updates.push('description = ?'); params.push(data.description); }
        if (data.description_ar !== undefined) { updates.push('description_ar = ?'); params.push(data.description_ar); }
        if (data.price !== undefined) { updates.push('price = ?'); params.push(data.price); }
        if (data.currency !== undefined) { updates.push('currency = ?'); params.push(data.currency); }
        if (data.type !== undefined) { updates.push('type = ?'); params.push(data.type); }
        if (data.features !== undefined) { updates.push('features = ?'); params.push(data.features); }
        if (data.icon !== undefined) { updates.push('icon = ?'); params.push(data.icon); }
        if (data.enabled !== undefined) { updates.push('enabled = ?'); params.push(data.enabled); }
        if (data.sort_order !== undefined) { updates.push('sort_order = ?'); params.push(data.sort_order); }

        updates.push('updated_at = unixepoch(\'now\')');

        if (updates.length === 1) {
            return errorResponse('No fields to update', 400);
        }

        params.push(id);
        const query = `UPDATE iap_products SET ${updates.join(', ')} WHERE id = ?`;
        const result = await DB.prepare(query).bind(...params).run();

        if (result.meta.changes === 0) {
            return errorResponse('Product not found', 404);
        }

        const product = await DB.prepare('SELECT * FROM iap_products WHERE id = ?').bind(id).first();
        return jsonResponse({ product });
    } catch (error) {
        console.error('Update IAP product error:', error);
        return errorResponse('Failed to update product', 500);
    }
}

async function handleAdminDeleteIAPProduct(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare('DELETE FROM iap_products WHERE id = ?').bind(id).run();

        if (result.meta.changes === 0) {
            return errorResponse('Product not found', 404);
        }

        return jsonResponse({ message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Delete IAP product error:', error);
        return errorResponse('Failed to delete product', 500);
    }
}

async function handleAdminGetIAPPurchases(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const offset = (page - 1) * limit;

    try {
        const [dataResult, countResult] = await Promise.all([
            DB.prepare(`
                SELECT p.*, pr.name as product_name 
                FROM iap_purchases p
                LEFT JOIN iap_products pr ON p.product_id = pr.product_id
                ORDER BY p.purchased_at DESC
                LIMIT ? OFFSET ?
            `).bind(limit, offset).all(),
            DB.prepare('SELECT COUNT(*) as total FROM iap_purchases').first()
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
        console.error('Get IAP purchases error:', error);
        return errorResponse('Failed to fetch purchases', 500);
    }
}

// Continue in next message due to length...
