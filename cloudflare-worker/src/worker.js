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
        const { DB, INTERACTIONS_DB } = env; // D1 database bindings

        // Handle CORS preflight
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }

        const url = new URL(request.url);
        const method = request.method;
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
            if (path === '/api/stats' && method === 'GET') {
                return handleStats(DB);
            }

            // ========== DOSAGES MANAGEMENT ==========
            if (path === '/api/dosages' && method === 'GET') {
                return handleGetDosages(request, DB);
            }
            if (path === '/api/dosages' && method === 'POST') {
                return handleCreateDosage(request, DB);
            }
            if (path.match(/^\/api\/dosages\/\d+$/)) {
                const id = path.split('/').pop();
                if (method === 'GET') return handleGetDosage(id, DB);
                if (method === 'PUT') return handleUpdateDosage(id, request, DB);
                if (method === 'DELETE') return handleDeleteDosage(id, DB);
            }

            // ========== ANALYTICS ==========
            if (path === '/api/analytics/recent-price-changes' && method === 'GET') {
                return handleRecentPriceChanges(request, DB);
            }
            if (path === '/api/analytics/daily' && method === 'GET') {
                return handleDailyAnalytics(request, DB);
            }

            // ========== ADMIN API (STRATEGY COMMAND CENTER) ==========

            // Drugs
            if (path === '/api/admin/drugs' && method === 'GET') return handleAdminGetDrugs(request, DB);
            if (path === '/api/admin/drugs' && method === 'POST') return handleAdminCreateDrug(request, DB);
            if (path.startsWith('/api/admin/drugs/')) {
                const id = path.split('/').pop();
                if (method === 'GET') return handleAdminGetDrug(id, DB);
                if (method === 'PUT') return handleAdminUpdateDrug(id, request, DB);
                if (method === 'DELETE') return handleAdminDeleteDrug(id, DB);
            }

            // Users
            if (path === '/api/admin/users' && method === 'GET') return handleAdminGetUsers(request, DB);
            if (path.startsWith('/api/admin/users/')) {
                const id = path.split('/').pop();
                if (method === 'PUT') return handleAdminUpdateUser(id, request, DB);
            }

            // Subscriptions
            if (path === '/api/admin/subscriptions' && method === 'GET') return handleAdminGetSubscriptions(request, DB);
            if (path.startsWith('/api/admin/subscriptions/')) {
                const parts = path.split('/');
                const id = parts[4];
                if (parts[5] === 'grant' && method === 'POST') return handleAdminGrantPremium(id, request, DB);
                if (method === 'PUT') return handleAdminUpdateSubscription(id, request, DB);
            }

            // Sponsored Drugs
            if (path === '/api/admin/sponsored' && method === 'GET') return handleGetSponsoredDrugs(DB);
            if (path === '/api/admin/sponsored' && method === 'POST') return handleCreateSponsoredDrug(request, DB);
            if (path.startsWith('/api/admin/sponsored/')) {
                const id = path.split('/').pop();
                if (method === 'PUT') return handleUpdateSponsoredDrug(id, request, DB);
                if (method === 'DELETE') return handleDeleteSponsoredDrug(id, DB);
            }

            // IAP Products
            if (path === '/api/admin/iap' && method === 'GET') return handleGetIapProducts(DB);
            if (path === '/api/admin/iap' && method === 'POST') return handleCreateIapProduct(request, DB);
            if (path.startsWith('/api/admin/iap/')) {
                const id = path.split('/').pop();
                if (method === 'PUT') return handleUpdateIapProduct(id, request, DB);
                if (method === 'DELETE') return handleDeleteIapProduct(id, DB);
            }

            // Notifications
            if (path === '/api/admin/notifications' && method === 'GET') return handleGetNotifications(request, DB);
            if (path === '/api/admin/notifications' && method === 'POST') return handleSendNotification(request, DB);
            if (path.startsWith('/api/admin/notifications/') && method === 'DELETE') {
                return handleDeleteNotification(path.split('/').pop(), DB);
            }

            // Interactions (Hybrid Split - Routed to INTERACTIONS_DB)
            if (path === '/api/admin/interactions' && method === 'GET') return handleAdminGetInteractions(request, INTERACTIONS_DB || DB);
            if (path === '/api/admin/interactions' && method === 'POST') return handleCreateInteraction(request, INTERACTIONS_DB || DB);
            if (path.startsWith('/api/admin/interactions/')) {
                const id = path.split('/').pop();
                if (method === 'PUT') return handleAdminUpdateInteraction(id, request, INTERACTIONS_DB || DB);
                if (method === 'DELETE') return handleDeleteInteraction(id, INTERACTIONS_DB || DB);
            }

            // Feedback (Main DB)
            if (path === '/api/admin/feedback' && method === 'GET') return handleGetFeedback(request, DB);
            if (path.startsWith('/api/admin/feedback/')) {
                const id = path.split('/').pop();
                if (method === 'PUT') return handleUpdateFeedback(id, request, DB);
            }

            // Disease Interactions (Hybrid Split - Routed to INTERACTIONS_DB)
            if (path === '/api/admin/disease-interactions' && method === 'GET') return handleGetDiseaseInteractions(request, INTERACTIONS_DB || DB);
            if (path === '/api/admin/disease-interactions' && method === 'POST') return handleCreateDiseaseInteraction(request, INTERACTIONS_DB || DB);
            if (path.startsWith('/api/admin/disease-interactions/')) {
                const id = path.split('/').pop();
                if (method === 'PUT') return handleUpdateDiseaseInteraction(id, request, INTERACTIONS_DB || DB);
                if (method === 'DELETE') return handleDeleteDiseaseInteraction(id, INTERACTIONS_DB || DB);
            }

            // Food Interactions (Hybrid Split - Routed to INTERACTIONS_DB)
            if (path === '/api/admin/food-interactions' && method === 'GET') return handleGetFoodInteractions(request, INTERACTIONS_DB || DB);
            if (path === '/api/admin/food-interactions' && method === 'POST') return handleCreateFoodInteraction(request, INTERACTIONS_DB || DB);
            if (path.startsWith('/api/admin/food-interactions/')) {
                const id = path.split('/').pop();
                if (method === 'PUT') return handleUpdateFoodInteraction(id, request, INTERACTIONS_DB || DB);
                if (method === 'DELETE') return handleDeleteFoodInteraction(id, INTERACTIONS_DB || DB);
            }

            // Missed Searches
            if (path === '/api/admin/missed-searches' && method === 'GET') return handleGetMissedSearches(DB);
            if (path === '/api/searches/missed' && method === 'GET') return handleGetMissedSearches(DB);

            // Configuration
            if (path === '/api/config') {
                if (method === 'GET') return handleGetConfig(DB);
                if (method === 'POST' || method === 'PUT') return handleUpdateConfig(request, DB);
            }

            // Generic Interaction Lookup (Public - Hybrid Split)
            if (path === '/api/interactions' && method === 'GET') return handleGetInteractions(request, INTERACTIONS_DB || DB);
            if (path === '/api/notifications' && method === 'GET') return handleGetUserNotifications(request, DB);

            // Sync (Internal/Admin)
            if (path.startsWith('/api/sync/')) {
                if (path === '/api/sync/version') return handleSyncVersion(DB);
                if (path === '/api/sync/drugs') return handleSyncDrugs(request, DB);
                if (path === '/api/sync/med-ingredients') return handleSyncMedIngredients(request, DB);
                if (path === '/api/sync/interactions') return handleSyncInteractions(request, INTERACTIONS_DB || DB);
                if (path === '/api/sync/dosages') return handleSyncDosages(request, DB);
            }

            // Public Sync Aliases (for backward compatibility)
            if (path === '/api/interactions/sync' && method === 'GET') return handleSyncInteractions(request, INTERACTIONS_DB || DB);

            // Bulk Update (GitHub Actions)
            if (path === '/api/update' && method === 'POST') {
                return handleUpdate(request, env);
            }

            // Admin: Generic DB Manager
            if (path === '/api/admin/db/tables' && method === 'GET') {
                try {
                    const { results } = await DB.prepare("SELECT name FROM sqlite_schema WHERE type ='table' AND name NOT LIKE 'sqlite_%'").all();
                    const tables = results.map(r => r.name);
                    return jsonResponse({ data: tables });
                } catch (e) {
                    return errorResponse(e.message, 500);
                }
            }

            if (path === '/api/admin/db/query' && method === 'POST') {
                try {
                    const { query, params = [] } = await request.json();
                    if (!query) return errorResponse('Query required', 400);

                    const stmt = DB.prepare(query).bind(...params);
                    const isSelect = query.trim().toUpperCase().startsWith('SELECT') || query.trim().toUpperCase().startsWith('PRAGMA');

                    if (isSelect) {
                        const { results } = await stmt.all();
                        return jsonResponse({ data: results || [] });
                    } else {
                        const { meta } = await stmt.run();
                        return jsonResponse({ message: 'Query executed', meta });
                    }
                } catch (e) {
                    return errorResponse(e.message, 500);
                }
            }

            // 404
            return errorResponse(`Not found: ${path} (Method: ${method})`, 404);

        } catch (error) {
            console.error('Fetch error:', error);
            return errorResponse(error.message, 500);
        }
    }
};

// ==========================================
// HANDLER FUNCTIONS
// ==========================================

async function handleSyncVersion(DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const result = await DB.prepare('SELECT MAX(updated_at) as last_update FROM drugs').first();
        const lastUpdate = result.last_update || '2024-06-01 00:00:00';
        const timestamp = Math.floor(new Date(lastUpdate).getTime() / 1000);

        return jsonResponse({
            version: timestamp, // Flutter expects this as the version/timestamp
            lastUpdate: lastUpdate,
            timestamp: Math.floor(Date.now() / 1000)
        });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleStats(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const statsQuery = `
            SELECT 
                (SELECT COUNT(*) FROM drugs) as total_drugs,
                (SELECT COUNT(DISTINCT company) FROM drugs WHERE company IS NOT NULL) as total_companies,
                (SELECT COUNT(*) FROM drugs WHERE updated_at > datetime('now', '-7 days')) as recent_updates_7d,
                (SELECT COUNT(*) FROM users) as total_users,
                (SELECT COUNT(*) FROM subscriptions WHERE status = 'active' AND expires_at > unixepoch('now')) as active_subscriptions,
                (SELECT COUNT(*) FROM sponsored_drugs WHERE active = 1) as sponsored_count,
                (SELECT COUNT(*) FROM drugs WHERE price > 0) as drugs_with_price,
                (SELECT COUNT(*) FROM drugs WHERE qr_code IS NOT NULL) as drugs_with_barcode
        `;

        const result = await DB.prepare(statsQuery).first();

        return jsonResponse({
            total_drugs: result.total_drugs || 0,
            total_companies: result.total_companies || 0,
            recent_updates_7d: result.recent_updates_7d || 0,
            total_users: result.total_users || 0,
            active_subscriptions: result.active_subscriptions || 0,
            sponsored_count: result.sponsored_count || 0,
            drugs_with_price: result.drugs_with_price || 0,
            drugs_with_barcode: result.drugs_with_barcode || 0
        });
    } catch (error) {
        console.error('Stats error:', error);
        // Fallback to basic stats if some tables still fail
        try {
            const basicResult = await DB.prepare('SELECT COUNT(*) as count FROM drugs').first();
            return jsonResponse({
                total_drugs: basicResult.count || 0,
                total_companies: 0,
                recent_updates_7d: 0,
                total_users: 0,
                active_subscriptions: 0,
                sponsored_count: 0,
                drugs_with_price: 0,
                drugs_with_barcode: 0
            });
        } catch (e) {
            return errorResponse('Failed to fetch stats', 500);
        }
    }
}

async function handleGetDosages(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '100');
    const search = url.searchParams.get('search') || '';
    // Map UI column names to DB column names if they differ
    let sortBy = url.searchParams.get('sortBy') || 'id';
    if (sortBy === 'active_ingredient') sortBy = 'med_id';
    if (sortBy === 'strength') sortBy = 'med_id'; // Placeholder if strength not in DB

    const sortOrder = url.searchParams.get('sortOrder') === 'DESC' ? 'DESC' : 'ASC';
    const offset = (page - 1) * limit;

    try {
        // Table existence check
        const tableCheck = await DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='dosage_guidelines'").first();
        if (!tableCheck) {
            return jsonResponse({ data: [], pagination: { page, limit, total: 0, totalPages: 0 } });
        }

        let query = 'SELECT * FROM dosage_guidelines';
        let countQuery = 'SELECT COUNT(*) as total FROM dosage_guidelines';
        const params = [];

        if (search) {
            query += ' WHERE instructions LIKE ? OR condition LIKE ?';
            countQuery += ' WHERE instructions LIKE ? OR condition LIKE ?';
            const searchParam = `%${search}%`;
            params.push(searchParam, searchParam);
        }

        query += ` ORDER BY ${sortBy} ${sortOrder} LIMIT ? OFFSET ?`;
        const countParams = search ? [`%${search}%`, `%${search}%`] : [];
        params.push(limit, offset);

        const [dataResult, countResult] = await Promise.all([
            DB.prepare(query).bind(...params).all(),
            DB.prepare(countQuery).bind(...countParams).first()
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

        if (!data.med_id) {
            return errorResponse('med_id is required', 400);
        }

        const query = `
            INSERT INTO dosage_guidelines 
            (med_id, dailymed_setid, min_dose, max_dose, frequency, duration, instructions, condition, source, is_pediatric) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        const result = await DB.prepare(query).bind(
            data.med_id,
            data.dailymed_setid || null,
            data.min_dose || 0,
            data.max_dose || null,
            data.frequency || null,
            data.duration || null,
            data.instructions || '',
            data.condition || '',
            data.source || 'DailyMed',
            data.is_pediatric ? 1 : 0
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
            SET med_id = ?, dailymed_setid = ?, min_dose = ?, max_dose = ?, 
                frequency = ?, duration = ?, instructions = ?, condition = ?, 
                source = ?, is_pediatric = ?
            WHERE id = ?
        `;

        const result = await DB.prepare(query).bind(
            data.med_id,
            data.dailymed_setid || null,
            data.min_dose || 0,
            data.max_dose || null,
            data.frequency || null,
            data.duration || null,
            data.instructions || '',
            data.condition || '',
            data.source || 'DailyMed',
            data.is_pediatric ? 1 : 0,
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
        // Use last_price_update for sorting, and fetch old_price
        // Default empty dates to 2025-01-01 as requested
        // Query drugs with valid last_price_update, sorted by that field
        const query = `
            SELECT id, trade_name, company, price, old_price, last_price_update, updated_at
            FROM drugs
            WHERE last_price_update IS NOT NULL 
              AND last_price_update != '' 
              AND last_price_update != 'N/A'
              AND last_price_update != '2000-01-01'
            ORDER BY last_price_update DESC
            LIMIT ?
        `;

        const result = await DB.prepare(query).bind(limit).all();

        let validDrugs = (result.results || []).map(drug => {
            // STRICT FILTERING: Exclude empty/N/A dates completely
            let lastPriceUpdate = drug.last_price_update;
            if (!lastPriceUpdate ||
                (typeof lastPriceUpdate === 'string' && (lastPriceUpdate.trim() === '' || lastPriceUpdate.trim().toUpperCase() === 'N/A' || lastPriceUpdate.trim().toLowerCase() === 'null'))) {
                return null;
            }

            let sortableDate = lastPriceUpdate;
            // Normalize DD/MM/YYYY if present
            if (typeof lastPriceUpdate === 'string' && /^\d{1,2}\/\d{1,2}\/\d{4}$/.test(lastPriceUpdate)) {
                // Handle DD/MM/YYYY format found in DB
                const parts = lastPriceUpdate.split('/');
                if (parts.length === 3) {
                    // Convert to YYYY-MM-DD
                    const day = parts[0].padStart(2, '0');
                    const month = parts[1].padStart(2, '0');
                    const year = parts[2];
                    sortableDate = `${year}-${month}-${day}`;
                    lastPriceUpdate = sortableDate; // Update lastPriceUpdate to the normalized format
                }
            }

            // Ensure prices are numbers
            const currentPrice = Number(drug.price) || 0;
            const oldPrice = drug.old_price !== null ? Number(drug.old_price) : (currentPrice * 0.8);

            const changePercent = oldPrice > 0
                ? ((currentPrice - oldPrice) / oldPrice) * 100
                : 0;

            return {
                ...drug,
                price: currentPrice,
                old_price: oldPrice,
                new_price: currentPrice,
                change_percent: changePercent,
                // Ensure updated_at reflects the price update date for the UI
                updated_at: lastPriceUpdate,
                last_price_update: lastPriceUpdate,
                _sortKey: new Date(sortableDate).getTime() // helper for JS sort
            };
        })
            .filter(item => item !== null && !isNaN(item._sortKey))
            .sort((a, b) => b._sortKey - a._sortKey) // JS Sort DESC
            .slice(0, limit); // Take top N

        // cleanup sortKey
        const finalData = validDrugs.map(({ _sortKey, ...item }) => item);

        return jsonResponse({ data: finalData });
    } catch (error) {
        console.error('Price changes error:', error);
        return errorResponse('Failed to fetch price changes', 500);
    }
}

async function handleAdminGetInteractions(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page')) || 1;
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const search = url.searchParams.get('search') || '';
    const sortBy = url.searchParams.get('sortBy') || 'id';
    const sortOrder = url.searchParams.get('sortOrder') === 'DESC' ? 'DESC' : 'ASC';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM drug_interactions';
        const params = [];

        if (search) {
            query += ' WHERE ingredient1 LIKE ? OR ingredient2 LIKE ?';
            params.push(`%${search}%`, `%${search}%`);
        }

        query += ` ORDER BY ${sortBy} ${sortOrder} LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const { results } = await DB.prepare(query).bind(...params).all();
        const countQuery = 'SELECT COUNT(*) as count FROM drug_interactions' + (search ? ' WHERE ingredient1 LIKE ? OR ingredient2 LIKE ?' : '');
        const { count } = await DB.prepare(countQuery).bind(...(search ? [`%${search}%`, `%${search}%`] : [])).first();

        return jsonResponse({
            data: results,
            pagination: { page, limit, total: count }
        });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}
async function handleGetFoodInteractions(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page')) || 1;
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const search = url.searchParams.get('search') || '';
    const sortBy = url.searchParams.get('sortBy') || 'trade_name';
    const sortOrder = url.searchParams.get('sortOrder') === 'DESC' ? 'DESC' : 'ASC';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM food_interactions';
        const params = [];

        if (search) {
            query += ' WHERE trade_name LIKE ? OR interaction LIKE ?';
            params.push(`%${search}%`, `%${search}%`);
        }

        query += ` ORDER BY ${sortBy} ${sortOrder} LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const { results } = await DB.prepare(query).bind(...params).all();
        const countQuery = 'SELECT COUNT(*) as count FROM food_interactions' + (search ? ' WHERE trade_name LIKE ? OR interaction LIKE ?' : '');
        const { count } = await DB.prepare(countQuery).bind(...(search ? [`%${search}%`, `%${search}%`] : [])).first();

        return jsonResponse({
            data: results,
            pagination: { page, limit, total: count }
        });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleCreateFoodInteraction(request, DB) {
    try {
        const data = await request.json();
        const { med_id, trade_name, interaction, source } = data;

        await DB.prepare(`
            INSERT INTO food_interactions 
            (med_id, trade_name, interaction, source)
            VALUES (?, ?, ?, ?)
        `).bind(med_id, trade_name, interaction, source || 'DrugBank').run();

        return jsonResponse({ message: 'Food interaction created' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleUpdateFoodInteraction(id, request, DB) {
    try {
        const data = await request.json();
        const { med_id, trade_name, interaction, source } = data;

        await DB.prepare(`
            UPDATE food_interactions SET
            med_id = ?, trade_name = ?, interaction = ?, source = ?
            WHERE id = ?
        `).bind(med_id, trade_name, interaction, source || 'DrugBank', id).run();

        return jsonResponse({ message: 'Food interaction updated' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleDeleteFoodInteraction(id, DB) {
    try {
        await DB.prepare('DELETE FROM food_interactions WHERE id = ?').bind(id).run();
        return jsonResponse({ message: 'Food interaction deleted' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleGetDiseaseInteractions(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page')) || 1;
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const search = url.searchParams.get('search') || '';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM disease_interactions';
        const params = [];

        if (search) {
            query += ' WHERE disease_name LIKE ? OR trade_name LIKE ?';
            params.push(`%${search}%`, `%${search}%`);
        }

        query += ' ORDER BY id DESC LIMIT ? OFFSET ?';
        params.push(limit, offset);

        const { results } = await DB.prepare(query).bind(...params).all();
        const countQuery = 'SELECT COUNT(*) as count FROM disease_interactions' + (search ? ' WHERE disease_name LIKE ? OR trade_name LIKE ?' : '');
        const { count } = await DB.prepare(countQuery).bind(...(search ? [`%${search}%`, `%${search}%`] : [])).first();

        return jsonResponse({
            data: results || [],
            pagination: { page, limit, total: count || 0 }
        });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleCreateDiseaseInteraction(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        const result = await DB.prepare(`
            INSERT INTO disease_interactions (med_id, trade_name, disease_name, interaction_text, source)
            VALUES (?, ?, ?, ?, ?)
        `).bind(
            data.med_id, data.trade_name, data.disease_name,
            data.interaction_text, data.source || 'DDInter'
        ).run();

        return jsonResponse({ data: { id: result.meta.last_row_id, ...data } }, 201);
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleUpdateDiseaseInteraction(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        await DB.prepare(`
            UPDATE disease_interactions SET 
                med_id = ?, trade_name = ?, disease_name = ?, 
                interaction_text = ?, source = ?
            WHERE id = ?
        `).bind(
            data.med_id, data.trade_name, data.disease_name,
            data.interaction_text, data.source || 'DDInter', id
        ).run();
        return jsonResponse({ data: { id: parseInt(id), ...data } });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleDeleteDiseaseInteraction(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        await DB.prepare('DELETE FROM disease_interactions WHERE id = ?').bind(id).run();
        return jsonResponse({ message: 'Disease interaction deleted' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleSyncDrugs(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    const url = new URL(request.url);
    const since = parseInt(url.searchParams.get('since')) || 0;
    const limit = parseInt(url.searchParams.get('limit')) || 0;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    try {
        let query = 'SELECT * FROM drugs';
        const params = [];
        if (since > 0) {
            // Compare using unix epoch to match App's integer timestamp
            query += " WHERE CAST(strftime('%s', updated_at) AS INTEGER) > ?";
            params.push(since);
        }
        query += ' ORDER BY id';
        if (limit > 0) {
            query += ' LIMIT ? OFFSET ?';
            params.push(limit, offset);
        }

        const { results } = await DB.prepare(query).bind(...params).all();

        let countQuery = 'SELECT COUNT(*) as total FROM drugs';
        const countParams = [];
        if (since > 0) {
            countQuery += " WHERE CAST(strftime('%s', updated_at) AS INTEGER) > ?";
            countParams.push(since);
        }
        const countResult = await DB.prepare(countQuery).bind(...countParams).first();

        return jsonResponse({
            data: results || [],
            total: countResult.total || 0,
            currentTimestamp: Math.floor(Date.now() / 1000)
        });

    } catch (e) {
        console.error('Sync drugs error:', e);
        return errorResponse(e.message, 500);
    }
}

async function handleSyncInteractions(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    const url = new URL(request.url);
    const since = parseInt(url.searchParams.get('since')) || 0;
    const limit = parseInt(url.searchParams.get('limit')) || 0;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    try {
        let query = 'SELECT * FROM drug_interactions';
        const params = [];
        if (since > 0) {
            query += " WHERE CAST(strftime('%s', updated_at) AS INTEGER) > ?";
            params.push(since);
        }
        query += ' ORDER BY id';
        if (limit > 0) {
            query += ' LIMIT ? OFFSET ?';
            params.push(limit, offset);
        }

        const { results } = await DB.prepare(query).bind(...params).all();

        let countQuery = 'SELECT COUNT(*) as total FROM drug_interactions';
        const countParams = [];
        if (since > 0) {
            countQuery += " WHERE CAST(strftime('%s', updated_at) AS INTEGER) > ?";
            countParams.push(since);
        }
        const countResult = await DB.prepare(countQuery).bind(...countParams).first();

        return jsonResponse({
            data: results || [],
            total: countResult.total || 0,
            currentTimestamp: Math.floor(Date.now() / 1000)
        });

    } catch (e) {
        console.error('Sync interactions error:', e);
        return errorResponse(e.message, 500);
    }
}

async function handleSyncDosages(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    const url = new URL(request.url);
    const since = parseInt(url.searchParams.get('since')) || 0;
    const limit = parseInt(url.searchParams.get('limit')) || 0;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    try {
        let query = 'SELECT * FROM dosage_guidelines';
        const params = [];
        if (since > 0) {
            query += " WHERE CAST(strftime('%s', created_at) AS INTEGER) > ?";
            params.push(since);
        }
        query += ' ORDER BY id';
        if (limit > 0) {
            query += ' LIMIT ? OFFSET ?';
            params.push(limit, offset);
        }

        const { results } = await DB.prepare(query).bind(...params).all();

        let countQuery = 'SELECT COUNT(*) as total FROM dosage_guidelines';
        const countParams = [];
        if (since > 0) {
            countQuery += " WHERE CAST(strftime('%s', created_at) AS INTEGER) > ?";
            countParams.push(since);
        }
        const countResult = await DB.prepare(countQuery).bind(...countParams).first();

        return jsonResponse({
            data: results || [],
            total: countResult.total || 0,
            currentTimestamp: Math.floor(Date.now() / 1000)
        });

    } catch (e) {
        console.error('Sync dosages error:', e);
        return errorResponse(e.message, 500);
    }
}

async function handleSyncMedIngredients(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    const url = new URL(request.url);
    const since = parseInt(url.searchParams.get('since')) || 0;
    const limit = parseInt(url.searchParams.get('limit')) || 0;
    const offset = parseInt(url.searchParams.get('offset')) || 0;

    try {
        let query = 'SELECT * FROM med_ingredients';
        const params = [];
        if (since > 0) {
            // med_ingredients might not have updated_at in all schemas, 
            // but we add the check for consistency if it exists.
            query += " WHERE CAST(strftime('%s', updated_at) AS INTEGER) > ?";
            params.push(since);
        }
        query += ' ORDER BY med_id';
        if (limit > 0) {
            query += ' LIMIT ? OFFSET ?';
            params.push(limit, offset);
        }

        const { results } = await DB.prepare(query).bind(...params).all();

        let countQuery = 'SELECT COUNT(*) as total FROM med_ingredients';
        const countParams = [];
        if (since > 0) {
            countQuery += " WHERE CAST(strftime('%s', updated_at) AS INTEGER) > ?";
            countParams.push(since);
        }
        const countResult = await DB.prepare(countQuery).bind(...countParams).first();

        return jsonResponse({
            data: results || [],
            total: countResult.total || 0,
            currentTimestamp: Math.floor(Date.now() / 1000)
        });

    } catch (e) {
        console.error('Sync med_ingredients error:', e);
        return errorResponse(e.message, 500);
    }
}

async function handleFixDates(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        // 1. Fetch all drugs with slashes in last_price_update (increased to 5000)
        const query = `SELECT id, last_price_update FROM drugs WHERE last_price_update LIKE '%/%' LIMIT 5000`;
        const result = await DB.prepare(query).all();
        const drugsToFix = result.results || [];

        let fixedCount = 0;
        const stmt = DB.prepare(`UPDATE drugs SET last_price_update = ? WHERE id = ?`);
        const batch = [];

        for (const drug of drugsToFix) {
            const parts = drug.last_price_update.split('/');
            if (parts.length === 3) {
                // Assume DD/MM/YYYY -> YYYY-MM-DD
                // Pad with 0 just in case
                const day = parts[0].padStart(2, '0');
                const month = parts[1].padStart(2, '0');
                const year = parts[2];
                const isoDate = `${year}-${month}-${day}`;

                batch.push(stmt.bind(isoDate, drug.id));
                fixedCount++;
            }
        }

        // Execute in chunks of 50 to avoid limits
        for (let i = 0; i < batch.length; i += 50) {
            await DB.batch(batch.slice(i, i + 50));
        }

        return jsonResponse({
            success: true,
            message: `Fixed ${fixedCount} dates`,
            total_found: drugsToFix.length
        });

    } catch (e) {
        return errorResponse('Migration failed: ' + e.message, 500);
    }
}

async function handleFixNullDates(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        // Fix NULL, empty, or 'N/A' dates to 2000-01-01
        const query = `
            SELECT id, last_price_update FROM drugs 
            WHERE last_price_update IS NULL 
               OR last_price_update = '' 
               OR last_price_update = 'N/A' 
               OR last_price_update = 'null'
            LIMIT 5000
        `;
        const result = await DB.prepare(query).all();
        const drugsToFix = result.results || [];

        const stmt = DB.prepare(`UPDATE drugs SET last_price_update = '2000-01-01' WHERE id = ?`);
        const batch = drugsToFix.map(drug => stmt.bind(drug.id));

        // Execute in chunks of 50
        for (let i = 0; i < batch.length; i += 50) {
            await DB.batch(batch.slice(i, i + 50));
        }

        return jsonResponse({
            success: true,
            message: `Fixed ${drugsToFix.length} null/empty dates`,
            total_found: drugsToFix.length
        });

    } catch (e) {
        return errorResponse('Null fix failed: ' + e.message, 500);
    }
}

async function handleDailyAnalytics(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const days = parseInt(url.searchParams.get('days') || '7');

    try {
        // Fetch Real Price Updates per day from drugs table
        const priceUpdatesQuery = `
            SELECT COALESCE(NULLIF(last_price_update, ''), '2025-01-01') as date, COUNT(*) as count
            FROM drugs 
            WHERE last_price_update >= date('now', '-' || ? || ' days') OR last_price_update IS NULL OR last_price_update = ''
            GROUP BY date
            ORDER BY date ASC
        `;

        // Fetch Analytics Daily stats (searches, etc.)
        const analyticsQuery = `
            SELECT * FROM analytics_daily
            WHERE date >= date('now', '-' || ? || ' days')
            ORDER BY date ASC
        `;

        const [priceUpdatesResult, analyticsResult] = await Promise.all([
            DB.prepare(priceUpdatesQuery).bind(days.toString()).all(),
            DB.prepare(analyticsQuery).bind(days.toString()).all()
        ]);

        const priceUpdatesMap = new Map();
        (priceUpdatesResult.results || []).forEach(row => {
            if (row.date) priceUpdatesMap.set(row.date, row.count);
        });

        const analyticsMap = new Map();
        (analyticsResult.results || []).forEach(row => {
            if (row.date) analyticsMap.set(row.date, row);
        });

        // Fill in the last 'days' days
        const data = [];
        const today = new Date();

        for (let i = 0; i < days; i++) {
            const dateObj = new Date();
            dateObj.setDate(today.getDate() - i);
            const dateStr = dateObj.toISOString().split('T')[0];

            const analytics = analyticsMap.get(dateStr) || {};

            data.push({
                date: dateStr,
                total_searches: analytics.total_searches || 0,
                price_updates: priceUpdatesMap.get(dateStr) || 0,
                ad_impressions: analytics.ad_impressions || 0,
                ad_clicks: analytics.ad_clicks || 0,
                ad_revenue: analytics.ad_revenue || 0,
                subscription_revenue: analytics.subscription_revenue || 0
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
    const page = parseInt(url.searchParams.get('page')) || 1;
    const limit = parseInt(url.searchParams.get('limit')) || 20;
    const search = url.searchParams.get('search') || '';
    const sortBy = url.searchParams.get('sortBy') || 'updated_at';
    const sortOrder = url.searchParams.get('sortOrder') === 'ASC' ? 'ASC' : 'DESC';
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT * FROM drugs';
        const params = [];

        if (search) {
            query += ' WHERE trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ? OR company LIKE ? OR category LIKE ?';
            const pattern = `%${search}%`;
            params.push(pattern, pattern, pattern, pattern, pattern);
        }

        const allowedColumns = ['id', 'trade_name', 'arabic_name', 'price', 'updated_at', 'company', 'category'];
        const safeSortBy = allowedColumns.includes(sortBy) ? sortBy : 'updated_at';
        query += ` ORDER BY ${safeSortBy} ${sortOrder} LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const { results } = await DB.prepare(query).bind(...params).all();

        let countQuery = 'SELECT COUNT(*) as count FROM drugs';
        const countParams = [];
        if (search) {
            countQuery += ' WHERE trade_name LIKE ? OR arabic_name LIKE ? OR active LIKE ? OR company LIKE ? OR category LIKE ?';
            const pattern = `%${search}%`;
            countParams.push(pattern, pattern, pattern, pattern, pattern);
        }

        const countResult = await DB.prepare(countQuery).bind(...countParams).first();

        return jsonResponse({
            data: results,
            pagination: { page, limit, total: countResult.count }
        });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleAdminGetDrug(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const drug = await DB.prepare('SELECT * FROM drugs WHERE id = ?').bind(id).first();
        if (!drug) return errorResponse('Drug not found', 404);
        return jsonResponse({ data: drug });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleAdminDeleteDrug(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const result = await DB.prepare('DELETE FROM drugs WHERE id = ?').bind(id).run();
        if (result.meta.changes === 0) return errorResponse('Drug not found', 404);
        return jsonResponse({ message: 'Drug deleted successfully' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleAdminCreateDrug(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();

        // Basic validation
        if (!data.trade_name) return errorResponse('trade_name is required', 400);

        const query = `
            INSERT INTO drugs (
                id, trade_name, arabic_name, price, old_price, category, active, company, 
                dosage_form, dosage_form_ar, concentration, unit, usage, pharmacology, 
                barcode, qr_code, visits, last_price_update, updated_at, indication, 
                mechanism_of_action, pharmacodynamics, data_source_pharmacology, 
                has_drug_interaction, has_food_interaction, has_disease_interaction
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, unixepoch('now'), ?, ?, ?, ?, ?, ?, ?)
        `;

        const result = await DB.prepare(query).bind(
            data.id || null, // Auto-increment if null
            data.trade_name,
            data.arabic_name || null,
            data.price || null,
            data.old_price || null,
            data.category || null,
            data.active || null,
            data.company || null,
            data.dosage_form || null,
            data.dosage_form_ar || null,
            data.concentration || null,
            data.unit || null,
            data.usage || null,
            data.pharmacology || null,
            data.barcode || null,
            data.qr_code || null,
            data.visits || 0,
            data.last_price_update || new Date().toISOString().split('T')[0],
            data.indication || null,
            data.mechanism_of_action || null,
            data.pharmacodynamics || null,
            data.data_source_pharmacology || null,
            data.has_drug_interaction ? 1 : 0,
            data.has_food_interaction ? 1 : 0,
            data.has_disease_interaction ? 1 : 0
        ).run();

        return jsonResponse({
            message: 'Drug created successfully',
            data: { id: result.meta.last_row_id, trade_name: data.trade_name }
        }, 201);
    } catch (e) {
        console.error('Admin create drug error:', e);
        return errorResponse(e.message, 500);
    }
}

async function handleAdminUpdateDrug(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        const query = `
            UPDATE drugs SET 
                trade_name = ?, arabic_name = ?, price = ?, old_price = ?, category = ?, 
                active = ?, company = ?, dosage_form = ?, dosage_form_ar = ?, 
                concentration = ?, unit = ?, usage = ?, pharmacology = ?, 
                barcode = ?, qr_code = ?, visits = ?, last_price_update = ?, 
                updated_at = unixepoch('now'), indication = ?, mechanism_of_action = ?, 
                pharmacodynamics = ?, data_source_pharmacology = ?, 
                has_drug_interaction = ?, has_food_interaction = ?, has_disease_interaction = ?
            WHERE id = ?
        `;

        const result = await DB.prepare(query).bind(
            data.trade_name,
            data.arabic_name || null,
            data.price || null,
            data.old_price || null,
            data.category || null,
            data.active || null,
            data.company || null,
            data.dosage_form || null,
            data.dosage_form_ar || null,
            data.concentration || null,
            data.unit || null,
            data.usage || null,
            data.pharmacology || null,
            data.barcode || null,
            data.qr_code || null,
            data.visits || 0,
            data.last_price_update || null,
            data.indication || null,
            data.mechanism_of_action || null,
            data.pharmacodynamics || null,
            data.data_source_pharmacology || null,
            data.has_drug_interaction ? 1 : 0,
            data.has_food_interaction ? 1 : 0,
            data.has_disease_interaction ? 1 : 0,
            id
        ).run();

        if (result.meta.changes === 0) return errorResponse('Drug not found', 404);
        return jsonResponse({ data: { id: parseInt(id), ...data } });
    } catch (error) {
        console.error('Admin update drug error:', error);
        return errorResponse(error.message, 500);
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
    const medId = url.searchParams.get('med_id'); // Support precise relational lookup
    const offset = (page - 1) * limit;

    try {
        let query = 'SELECT di.* FROM drug_interactions di';
        let countQuery = 'SELECT COUNT(DISTINCT di.id) as total FROM drug_interactions di';
        const params = [];
        const conditions = [];

        if (medId) {
            // Join with med_ingredients to link med_id to ingredients
            query += ' JOIN med_ingredients mi ON (di.ingredient1 = mi.ingredient OR di.ingredient2 = mi.ingredient)';
            countQuery += ' JOIN med_ingredients mi ON (di.ingredient1 = mi.ingredient OR di.ingredient2 = mi.ingredient)';

            conditions.push('mi.med_id = ?');
            params.push(medId);
        }

        if (search) {
            conditions.push('(di.ingredient1 LIKE ? OR di.ingredient2 LIKE ?)'); // Removed interaction_drug_name if not exist
            const searchParam = `%${search}%`;
            params.push(searchParam, searchParam);
        }

        if (conditions.length > 0) {
            const whereClause = ' WHERE ' + conditions.join(' AND ');
            query += whereClause;
            countQuery += whereClause;
        }

        query += ' ORDER BY di.severity DESC LIMIT ? OFFSET ?';
        // params for countQuery are the same as query (minus limit/offset)
        const countParams = [...params];

        params.push(limit, offset);

        const [dataResult, countResult] = await Promise.all([
            DB.prepare(query).bind(...params).all(),
            DB.prepare(countQuery).bind(...countParams).first()
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
            (ingredient1, ingredient2, severity, effect, recommendation, 
             arabic_effect, arabic_recommendation, management_text, mechanism_text, 
             risk_level, source, type) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;

        const result = await DB.prepare(query).bind(
            data.ingredient1,
            data.ingredient2,
            data.severity,
            data.effect,
            data.recommendation,
            data.arabic_effect || null,
            data.arabic_recommendation || null,
            data.management_text || null,
            data.mechanism_text || null,
            data.risk_level || null,
            data.source || 'Manual',
            data.type || 'pharmacodynamic'
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
            SET ingredient1 = ?, ingredient2 = ?, severity = ?, effect = ?, recommendation = ?,
                arabic_effect = ?, arabic_recommendation = ?, management_text = ?, 
                mechanism_text = ?, risk_level = ?, source = ?, type = ?
            WHERE id = ?
        `;

        const result = await DB.prepare(query).bind(
            data.ingredient1,
            data.ingredient2,
            data.severity,
            data.effect,
            data.recommendation,
            data.arabic_effect || null,
            data.arabic_recommendation || null,
            data.management_text || null,
            data.mechanism_text || null,
            data.risk_level || null,
            data.source || 'Manual',
            data.type || 'pharmacodynamic',
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
                        old_price: drug.old_price || existing.old_price,
                        active: drug.active || existing.active,
                        category: drug.category || existing.category,
                        dosage_form: drug.dosage_form || drug.dosageForm || existing.dosage_form,
                        concentration: drug.concentration || existing.concentration,
                        unit: drug.unit || existing.unit,
                        last_price_update: drug.last_price_update || existing.last_price_update
                    };

                    const priceChanged = input.price !== existing.price;
                    const hasChanges =
                        input.arabic_name !== existing.arabic_name ||
                        input.company !== existing.company ||
                        priceChanged ||
                        input.active !== existing.active ||
                        input.category !== existing.category ||
                        input.dosage_form !== existing.dosage_form ||
                        input.concentration !== existing.concentration ||
                        input.unit !== existing.unit;

                    // If price changed, update last_price_update to today
                    if (priceChanged) {
                        const today = new Date().toISOString().split('T')[0];
                        input.last_price_update = today;
                    }

                    if (!hasChanges) {
                        continue; // Skip update if no changes
                    }

                    // Update
                    await DB.prepare(`
                        UPDATE drugs SET 
                            arabic_name = ?,
                            company = ?,
                            price = ?,
                            old_price = ?,
                            active = ?,
                            category = ?,
                            dosage_form = ?,
                            concentration = ?,
                            unit = ?,
                            last_price_update = ?,
                            updated_at = unixepoch('now')
                        WHERE id = ?
                    `).bind(
                        input.arabic_name,
                        input.company,
                        input.price,
                        input.old_price,
                        input.active,
                        input.category,
                        input.dosage_form,
                        input.concentration,
                        input.unit,
                        input.last_price_update,
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

async function handleGetUserNotifications(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit') || '20');
    // Optional: Filter by 'since' timestamp to get only new ones
    const since = url.searchParams.get('since');

    try {
        let query = `
            SELECT * FROM notifications
            WHERE target_audience IN ('all', 'public')
        `;
        const params = [];

        if (since) {
            query += ' AND sent_at > ?';
            params.push(since);
        }

        query += ' ORDER BY sent_at DESC LIMIT ?';
        params.push(limit);

        const result = await DB.prepare(query).bind(...params).all();

        return jsonResponse({
            data: result.results || []
        });
    } catch (error) {
        console.error('Get user notifications error:', error);
        return errorResponse('Failed to fetch notifications', 500);
    }
}

// ============================================
// MONETIZATION HANDLERS (Sponsored & IAP)
// ============================================

async function handleGetSponsoredDrugs(DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const { results } = await DB.prepare('SELECT * FROM sponsored_drugs ORDER BY priority DESC').all();
        return jsonResponse({ data: results || [] });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleCreateSponsoredDrug(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        const result = await DB.prepare(`
            INSERT INTO sponsored_drugs (drug_id, company, banner_url, campaign_type, priority, status, starts_at, ends_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
            data.drug_id, data.company, data.banner_url || null,
            data.campaign_type || 'search_top', data.priority || 0,
            data.status || 'active', data.starts_at || null, data.ends_at || null
        ).run();
        return jsonResponse({ data: { id: result.meta.last_row_id, ...data } }, 201);
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleUpdateSponsoredDrug(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        await DB.prepare(`
            UPDATE sponsored_drugs SET 
                drug_id = ?, company = ?, banner_url = ?, campaign_type = ?, 
                priority = ?, status = ?, starts_at = ?, ends_at = ?
            WHERE id = ?
        `).bind(
            data.drug_id, data.company, data.banner_url, data.campaign_type,
            data.priority, data.status, data.starts_at, data.ends_at, id
        ).run();
        return jsonResponse({ data: { id: parseInt(id), ...data } });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleDeleteSponsoredDrug(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        await DB.prepare('DELETE FROM sponsored_drugs WHERE id = ?').bind(id).run();
        return jsonResponse({ message: 'Sponsored drug deleted' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleGetIapProducts(DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const { results } = await DB.prepare('SELECT * FROM iap_products ORDER BY price ASC').all();
        return jsonResponse({ data: results || [] });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleCreateIapProduct(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        const result = await DB.prepare(`
            INSERT INTO iap_products (product_id, tier, name, description, price, currency, duration_days, status, permissions)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
            data.product_id, data.tier, data.name, data.description,
            data.price, data.currency || 'EGP', data.duration_days, data.status || 'active',
            data.permissions ? JSON.stringify(data.permissions) : '{}'
        ).run();
        return jsonResponse({ data: { id: result.meta.last_row_id, ...data } }, 201);
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleUpdateIapProduct(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        await DB.prepare(`
            UPDATE iap_products SET 
                product_id = ?, tier = ?, name = ?, description = ?, 
                price = ?, currency = ?, duration_days = ?, status = ?, permissions = ?
            WHERE id = ?
        `).bind(
            data.product_id, data.tier, data.name, data.description,
            data.price, data.currency, data.duration_days, data.status,
            data.permissions ? JSON.stringify(data.permissions) : '{}', id
        ).run();
        return jsonResponse({ data: { id: parseInt(id), ...data } });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleDeleteIapProduct(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        await DB.prepare('DELETE FROM iap_products WHERE id = ?').bind(id).run();
        return jsonResponse({ message: 'IAP product deleted' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

// ============================================
// USER & SUBSCRIPTION ADMIN HANDLERS
// ============================================

async function handleAdminGetUsers(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        // Mocking user data until users table is fully implemented if missing
        // Checking if users table exists
        const tableCheck = await DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='users'").first();
        if (!tableCheck) {
            // Return dummy data to keep UI functional
            return jsonResponse({
                data: [
                    { id: '1', name: 'Dr. Ahmed Lotfy', email: 'lotfy@mediswitch.com', status: 'active', tier: 'premium', created_at: Date.now() - 86400000 * 30 },
                    { id: '2', name: 'Pharmacist Sarah', email: 'sarah@mediswitch.com', status: 'active', tier: 'free', created_at: Date.now() - 86400000 * 15 }
                ]
            });
        }
        const { results } = await DB.prepare('SELECT * FROM users ORDER BY created_at DESC LIMIT 100').all();
        return jsonResponse({ data: results || [] });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleAdminUpdateUser(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        await DB.prepare('UPDATE users SET status = ? WHERE id = ?').bind(data.status, id).run();
        return jsonResponse({ message: 'User updated' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleAdminUpdateSubscription(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);
    try {
        const data = await request.json();
        await DB.prepare('UPDATE subscriptions SET status = ? WHERE id = ?').bind(data.status, id).run();
        return jsonResponse({ message: 'Subscription updated' });
    } catch (e) {
        return errorResponse(e.message, 500);
    }
}

async function handleGetMissedSearches(DB) {
    if (!DB) return jsonResponse({ data: [] });
    try {
        const tableCheck = await DB.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='missed_searches'").first();
        if (!tableCheck) {
            return jsonResponse({ data: [] });
        }
        const { results } = await DB.prepare('SELECT * FROM missed_searches ORDER BY hit_count DESC LIMIT 100').all();
        return jsonResponse({ data: results || [] });
    } catch (e) {
        console.error('Missed searches error:', e);
        return jsonResponse({ data: [] }); // Return empty instead of 500 for non-critical analytics
    }
}
