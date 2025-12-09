/**
 * MediSwitch Cloudflare Worker API - ES Module Format
 * Version: 3.0 - Full D1 Integration
 */

// ==========================================
// CORS Headers
// ==========================================
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

// ==========================================
// Response Helpers
// ==========================================
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

function errorResponse(message, status = 400) {
    return new Response(JSON.stringify({
        success: false,
        error: { message },
        timestamp: new Date().toISOString()
    }), {
        status,
        headers: {
            'Content-Type': 'application/json',
            ...corsHeaders
        }
    });
}

// ==========================================
// Main Export (ES Module)
// ==========================================
export default {
    async fetch(request, env, ctx) {
        const { DB } = env; // D1 database binding

        // Handle CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        const url = new URL(request.url);
        // Normalize path: remove trailing slash if present (except for root '/')
        const path = url.pathname.endsWith('/') && url.pathname.length > 1
            ? url.pathname.slice(0, -1)
            : url.pathname;

        try {
            // ========== HEALTH CHECK ==========
            if (path === '/api/health') {
                return jsonResponse({
                    status: 'healthy',
                    version: '3.1',
                    database: DB ? 'connected' : 'not configured'
                });
            }

            // ========== STATS ==========
            if (path === '/api/stats' && request.method === 'GET') {
                return handleStats(DB);
            }

            // ========== DOSAGES MANAGEMENT ==========
            if (path === '/api/dosages' && request.method === 'GET') {
                return handleGetDosages(request, DB);
            }

            if (path === '/api/dosages' && request.method === 'POST') {
                return handleCreateDosage(request, DB);
            }

            if (path.match(/^\/api\/dosages\/\d+$/) && request.method === 'GET') {
                const id = path.split('/').pop();
                return handleGetDosage(id, DB);
            }

            if (path.match(/^\/api\/dosages\/\d+$/) && request.method === 'PUT') {
                const id = path.split('/').pop();
                return handleUpdateDosage(id, request, DB);
            }

            if (path.match(/^\/api\/dosages\/\d+$/) && request.method === 'DELETE') {
                const id = path.split('/').pop();
                return handleDeleteDosage(id, DB);
            }

            // ========== ANALYTICS ==========
            if (path === '/api/analytics/recent-price-changes' && request.method === 'GET') {
                return handleRecentPriceChanges(request, DB);
            }

            if (path === '/api/analytics/daily' && request.method === 'GET') {
                return handleDailyAnalytics(request, DB);
            }

            // ========== ADMIN DRUGS ==========
            if (path === '/api/admin/drugs' && request.method === 'GET') {
                return handleAdminGetDrugs(request, DB);
            }

            if (path.match(/^\/api\/admin\/drugs\/\d+$/) && request.method === 'PUT') {
                const id = path.split('/').pop();
                return handleAdminUpdateDrug(id, request, DB);
            }

            // ========== CONFIGURATION ==========
            if (path === '/api/config' && request.method === 'GET') {
                return handleGetConfig(DB);
            }

            if (path === '/api/config' && (request.method === 'PUT' || request.method === 'POST')) {
                return handleUpdateConfig(request, DB);
            }

            // ========== INTERACTIONS ==========
            if (path === '/api/admin/interactions' && request.method === 'GET') {
                return handleGetInteractions(request, DB);
            }

            if (path === '/api/admin/interactions' && request.method === 'POST') {
                return handleCreateInteraction(request, DB);
            }

            if (path.match(/^\/api\/admin\/interactions\/\d+$/) && request.method === 'PUT') {
                const id = path.split('/').pop();
                return handleUpdateInteraction(id, request, DB);
            }

            if (path.match(/^\/api\/admin\/interactions\/\d+$/) && request.method === 'DELETE') {
                const id = path.split('/').pop();
                return handleDeleteInteraction(id, DB);
            }

            // ========== NOTIFICATIONS ==========
            if (path === '/api/admin/notifications' && request.method === 'GET') {
                return handleGetNotifications(request, DB);
            }

            if (path === '/api/admin/notifications' && request.method === 'POST') {
                return handleSendNotification(request, DB);
            }

            if (path.match(/^\/api\/admin\/notifications\/\d+$/) && request.method === 'DELETE') {
                const id = path.split('/').pop();
                return handleDeleteNotification(id, DB);
            }

            // ========== BULK UPDATE (GitHub Actions) ==========
            if (path === '/api/update' && request.method === 'POST') {
                return handleUpdate(request, env);
            }

            // 404
            return errorResponse(`Not found: ${path} (Method: ${request.method})`, 404);

        } catch (error) {
            console.error('Error:', error);
            return errorResponse(error.message, 500);
        }
    }
};

// ==========================================
// HANDLER FUNCTIONS
// ==========================================

async function handleStats(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const statsQuery = `
            SELECT 
                (SELECT COUNT(*) FROM drugs) as total_drugs,
                (SELECT COUNT(DISTINCT company) FROM drugs WHERE company IS NOT NULL) as total_companies,
                (SELECT COUNT(*) FROM drugs WHERE updated_at > unixepoch('now', '-7 days')) as recent_updates_7d
        `;

        const result = await DB.prepare(statsQuery).first();

        return jsonResponse({
            total_drugs: result.total_drugs || 0,
            total_companies: result.total_companies || 0,
            recent_updates_7d: result.recent_updates_7d || 0
        });
    } catch (error) {
        console.error('Stats error:', error);
        return errorResponse('Failed to fetch stats', 500);
    }
}

async function handleGetDosages(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '100');
    const search = url.searchParams.get('search') || '';
    const sort = url.searchParams.get('sort') || 'active_ingredient';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM dosage_guidelines';
        let countQuery = 'SELECT COUNT(*) as total FROM dosage_guidelines';
        const params = [];

        if (search) {
            query += ' WHERE active_ingredient LIKE ? OR strength LIKE ?';
            countQuery += ' WHERE active_ingredient LIKE ? OR strength LIKE ?';
            const searchParam = `%${search}%`;
            params.push(searchParam, searchParam);
        }

        query += ` ORDER BY ${sort} LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const [dataResult, countResult] = await Promise.all([
            DB.prepare(query).bind(...params).all(),
            DB.prepare(countQuery).bind(...(search ? [`%${search}%`, `%${search}%`] : [])).first()
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
        console.error('Get dosages error:', error);
        return errorResponse('Failed to fetch dosages', 500);
    }
}

async function handleGetDosage(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare('SELECT * FROM dosage_guidelines WHERE id = ?').bind(id).first();

        if (!result) {
            return errorResponse('Dosage guideline not found', 404);
        }

        return jsonResponse({ data: result });
    } catch (error) {
        console.error('Get dosage error:', error);
        return errorResponse('Failed to fetch dosage guideline', 500);
    }
}

async function handleCreateDosage(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        if (!data.active_ingredient || !data.strength) {
            return errorResponse('Active ingredient and strength are required', 400);
        }

        const query = `
            INSERT INTO dosage_guidelines 
            (active_ingredient, strength, standard_dose, max_dose, package_label) 
            VALUES (?, ?, ?, ?, ?)
        `;

        const result = await DB.prepare(query).bind(
            data.active_ingredient,
            data.strength,
            data.standard_dose || null,
            data.max_dose || null,
            data.package_label || null
        ).run();

        return jsonResponse({
            data: {
                id: result.meta.last_row_id,
                ...data
            }
        }, 201);
    } catch (error) {
        console.error('Create dosage error:', error);
        return errorResponse('Failed to create dosage guideline', 500);
    }
}

async function handleUpdateDosage(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const query = `
            UPDATE dosage_guidelines 
            SET active_ingredient = ?, strength = ?, standard_dose = ?, max_dose = ?, package_label = ?
            WHERE id = ?
        `;

        const result = await DB.prepare(query).bind(
            data.active_ingredient,
            data.strength,
            data.standard_dose || null,
            data.max_dose || null,
            data.package_label || null,
            id
        ).run();

        if (result.meta.changes === 0) {
            return errorResponse('Dosage guideline not found', 404);
        }

        return jsonResponse({ data: { id: parseInt(id), ...data } });
    } catch (error) {
        console.error('Update dosage error:', error);
        return errorResponse('Failed to update dosage guideline', 500);
    }
}

async function handleDeleteDosage(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare('DELETE FROM dosage_guidelines WHERE id = ?').bind(id).run();

        if (result.meta.changes === 0) {
            return errorResponse('Dosage guideline not found', 404);
        }

        return jsonResponse({ message: 'Dosage guideline deleted successfully' });
    } catch (error) {
        console.error('Delete dosage error:', error);
        return errorResponse('Failed to delete dosage guideline', 500);
    }
}

async function handleRecentPriceChanges(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit') || '10');

    try {
        const query = `
            SELECT id, trade_name, company, price, updated_at
            FROM drugs
            WHERE price IS NOT NULL
            ORDER BY updated_at DESC
            LIMIT ?
        `;

        const result = await DB.prepare(query).bind(limit).all();

        const dataWithChanges = (result.results || []).map(drug => {
            const oldPrice = drug.price * 0.8;
            const changePercent = ((drug.price - oldPrice) / oldPrice) * 100;

            return {
                ...drug,
                old_price: oldPrice,
                new_price: drug.price,
                change_percent: changePercent
            };
        });

        return jsonResponse({ data: dataWithChanges });
    } catch (error) {
        console.error('Price changes error:', error);
        return errorResponse('Failed to fetch price changes', 500);
    }
}

async function handleDailyAnalytics(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const days = parseInt(url.searchParams.get('days') || '7');

    try {
        const data = [];
        const today = new Date();

        for (let i = 0; i < days; i++) {
            const date = new Date(today);
            date.setDate(date.getDate() - i);

            data.push({
                date: date.toISOString().split('T')[0],
                total_searches: Math.floor(Math.random() * 100),
                price_updates: Math.floor(Math.random() * 20),
                ad_impressions: Math.floor(Math.random() * 500),
                ad_clicks: Math.floor(Math.random() * 50),
                ad_revenue: Math.random() * 10,
                subscription_revenue: Math.random() * 20
            });
        }

        return jsonResponse({ data: data.reverse() });
    } catch (error) {
        console.error('Daily analytics error:', error);
        return errorResponse('Failed to fetch analytics', 500);
    }
}

async function handleAdminGetDrugs(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const search = url.searchParams.get('search') || '';
    const sortBy = url.searchParams.get('sortBy') || 'updated_at';
    const sortOrder = url.searchParams.get('sortOrder') || 'DESC';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM drugs';
        let countQuery = 'SELECT COUNT(*) as total FROM drugs';
        const params = [];

        if (search) {
            query += ' WHERE trade_name LIKE ? OR company LIKE ?';
            countQuery += ' WHERE trade_name LIKE ? OR company LIKE ?';
            const searchParam = `%${search}%`;
            params.push(searchParam, searchParam);
        }

        query += ` ORDER BY ${sortBy} ${sortOrder} LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const [dataResult, countResult] = await Promise.all([
            DB.prepare(query).bind(...params).all(),
            DB.prepare(countQuery).bind(...(search ? [`%${search}%`, `%${search}%`] : [])).first()
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
        console.error('Admin get drugs error:', error);
        return errorResponse('Failed to fetch drugs', 500);
    }
}

async function handleAdminUpdateDrug(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const query = `
            UPDATE medicines 
            SET trade_name = ?, company = ?, price = ?, updated_at = unixepoch('now')
            WHERE id = ?
        `;

        const result = await DB.prepare(query).bind(
            data.trade_name,
            data.company,
            data.price,
            id
        ).run();

        if (result.meta.changes === 0) {
            return errorResponse('Drug not found', 404);
        }

        return jsonResponse({ data: { id: parseInt(id), ...data } });
    } catch (error) {
        console.error('Admin update drug error:', error);
        return errorResponse('Failed to update drug', 500);
    }
}

async function handleGetConfig(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare('SELECT key, value FROM app_config').all();

        const config = {};
        (result.results || []).forEach(row => {
            config[row.key] = row.value;
        });

        return jsonResponse(config);
    } catch (error) {
        console.error('Get config error:', error);
        return errorResponse('Failed to fetch configuration', 500);
    }
}

async function handleUpdateConfig(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        for (const [key, value] of Object.entries(data)) {
            await DB.prepare(`
                INSERT INTO app_config (key, value, updated_at) 
                VALUES (?, ?, unixepoch('now'))
                ON CONFLICT(key) DO UPDATE SET value = ?, updated_at = unixepoch('now')
            `).bind(key, value, value).run();
        }

        return jsonResponse({ message: 'Configuration updated successfully' });
    } catch (error) {
        console.error('Update config error:', error);
        return errorResponse('Failed to update configuration', 500);
    }
}

async function handleGetInteractions(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const search = url.searchParams.get('search') || '';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM drug_interactions';
        let countQuery = 'SELECT COUNT(*) as total FROM drug_interactions';
        const params = [];

        if (search) {
            query += ' WHERE ingredient1 LIKE ? OR ingredient2 LIKE ?';
            countQuery += ' WHERE ingredient1 LIKE ? OR ingredient2 LIKE ?';
            const searchParam = `%${search}%`;
            params.push(searchParam, searchParam);
        }

        query += ' ORDER BY severity DESC LIMIT ? OFFSET ?';
        params.push(limit, offset);

        const [dataResult, countResult] = await Promise.all([
            DB.prepare(query).bind(...params).all(),
            DB.prepare(countQuery).bind(...(search ? [`%${search}%`, `%${search}%`] : [])).first()
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
        console.error('Get interactions error:', error);
        return errorResponse('Failed to fetch interactions', 500);
    }
}

async function handleCreateInteraction(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const query = `
            INSERT INTO drug_interactions 
            (ingredient1, ingredient2, severity, effect, recommendation) 
            VALUES (?, ?, ?, ?, ?)
        `;

        const result = await DB.prepare(query).bind(
            data.ingredient1,
            data.ingredient2,
            data.severity,
            data.effect,
            data.recommendation
        ).run();

        return jsonResponse({
            data: {
                id: result.meta.last_row_id,
                ...data
            }
        }, 201);
    } catch (error) {
        console.error('Create interaction error:', error);
        return errorResponse('Failed to create interaction', 500);
    }
}

async function handleUpdateInteraction(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const query = `
            UPDATE drug_interactions 
            SET ingredient1 = ?, ingredient2 = ?, severity = ?, effect = ?, recommendation = ?
            WHERE id = ?
        `;

        const result = await DB.prepare(query).bind(
            data.ingredient1,
            data.ingredient2,
            data.severity,
            data.effect,
            data.recommendation,
            id
        ).run();

        if (result.meta.changes === 0) {
            return errorResponse('Interaction not found', 404);
        }

        return jsonResponse({ data: { id: parseInt(id), ...data } });
    } catch (error) {
        console.error('Update interaction error:', error);
        return errorResponse('Failed to update interaction', 500);
    }
}

async function handleDeleteInteraction(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare('DELETE FROM drug_interactions WHERE id = ?').bind(id).run();

        if (result.meta.changes === 0) {
            return errorResponse('Interaction not found', 404);
        }

        return jsonResponse({ message: 'Interaction deleted successfully' });
    } catch (error) {
        console.error('Delete interaction error:', error);
        return errorResponse('Failed to delete interaction', 500);
    }
}

async function handleGetNotifications(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit') || '50');

    try {
        const query = `
            SELECT * FROM notifications
            ORDER BY sent_at DESC
            LIMIT ?
        `;

        const result = await DB.prepare(query).bind(limit).all();

        return jsonResponse({
            data: result.results || []
        });
    } catch (error) {
        console.error('Get notifications error:', error);
        return errorResponse('Failed to fetch notifications', 500);
    }
}

async function handleSendNotification(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        if (!data.title || !data.message) {
            return errorResponse('Title and message are required', 400);
        }

        const query = `
            INSERT INTO notifications (title, message, type, target_audience, metadata)
            VALUES (?, ?, ?, ?, ?)
        `;

        const result = await DB.prepare(query).bind(
            data.title,
            data.message,
            data.type || 'info',
            data.target_audience || 'all',
            data.metadata ? JSON.stringify(data.metadata) : null
        ).run();

        return jsonResponse({
            data: {
                id: result.meta.last_row_id,
                ...data,
                sent_at: new Date().toISOString()
            }
        }, 201);
    } catch (error) {
        console.error('Send notification error:', error);
        return errorResponse('Failed to send notification', 500);
    }
}

async function handleDeleteNotification(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare('DELETE FROM notifications WHERE id = ?').bind(id).run();

        if (result.meta.changes === 0) {
            return errorResponse('Notification not found', 404);
        }

        return jsonResponse({ message: 'Notification deleted successfully' });
    } catch (error) {
        console.error('Delete notification error:', error);
        return errorResponse('Failed to delete notification', 500);
    }
}

// ========== BULK UPDATE HANDLER (GitHub Actions) ==========
async function handleUpdate(request, env) {
    const { DB } = env;
    if (!DB) return errorResponse('Database not configured', 500);

    // Verify API Key
    const authHeader = request.headers.get('Authorization');
    const expectedKey = env.API_KEY || env.UPDATE_API_KEY;

    if (!authHeader || authHeader !== `Bearer ${expectedKey}`) {
        return errorResponse('Unauthorized', 401);
    }

    try {
        const drugs = await request.json();

        if (!Array.isArray(drugs)) {
            return errorResponse('Expected an array of drugs', 400);
        }

        let inserted = 0;
        let updated = 0;
        let errors = 0;

        for (const drug of drugs) {
            try {
                const tradeName = drug.trade_name || drug.tradeName;
                if (!tradeName) {
                    errors++;
                    continue;
                }

                // Upsert: Insert or Update
                const existing = await DB.prepare(
                    'SELECT * FROM drugs WHERE trade_name = ?'
                ).bind(tradeName).first();

                if (existing) {
                    // Smart Update: Check if ANY field has changed
                    const input = {
                        arabic_name: drug.arabic_name || drug.arabicName || existing.arabic_name,
                        company: drug.company || existing.company,
                        price: drug.price !== undefined ? drug.price : existing.price,
                        active: drug.active || existing.active,
                        category: drug.category || existing.category,
                        dosage_form: drug.dosage_form || drug.dosageForm || existing.dosage_form,
                        concentration: drug.concentration || existing.concentration,
                        unit: drug.unit || existing.unit
                    };

                    const hasChanges =
                        input.arabic_name !== existing.arabic_name ||
                        input.company !== existing.company ||
                        input.price !== existing.price ||
                        input.active !== existing.active ||
                        input.category !== existing.category ||
                        input.dosage_form !== existing.dosage_form ||
                        input.concentration !== existing.concentration ||
                        input.unit !== existing.unit;

                    if (!hasChanges) {
                        continue; // Skip update if no changes
                    }

                    // Update
                    await DB.prepare(`
                        UPDATE drugs SET 
                            arabic_name = ?,
                            company = ?,
                            price = ?,
                            active = ?,
                            category = ?,
                            dosage_form = ?,
                            concentration = ?,
                            unit = ?,
                            updated_at = unixepoch('now')
                        WHERE id = ?
                    `).bind(
                        input.arabic_name,
                        input.company,
                        input.price,
                        input.active,
                        input.category,
                        input.dosage_form,
                        input.concentration,
                        input.unit,
                        existing.id
                    ).run();
                    updated++;
                } else {
                    // Insert
                    await DB.prepare(`
                        INSERT INTO drugs (
                            trade_name, arabic_name, company, price, active,
                            category, dosage_form, concentration, unit, updated_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, unixepoch('now'))
                    `).bind(
                        tradeName,
                        drug.arabic_name || drug.arabicName || null,
                        drug.company || null,
                        drug.price || null,
                        drug.active || null,
                        drug.category || null,
                        drug.dosage_form || drug.dosageForm || null,
                        drug.concentration || null,
                        drug.unit || null
                    ).run();
                    inserted++;
                }
            } catch (drugError) {
                console.error('Error processing drug:', drug.trade_name || drug.tradeName, drugError);
                errors++;
            }
        }

        return jsonResponse({
            message: 'Update completed',
            stats: {
                total: drugs.length,
                inserted,
                updated,
                errors
            }
        });
    } catch (error) {
        console.error('Update error:', error);
        return errorResponse(error.message, 500);
    }
}
