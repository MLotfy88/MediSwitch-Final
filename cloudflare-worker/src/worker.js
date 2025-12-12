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

            // ========== PUBLIC NOTIFICATIONS (Mobile App) ==========
            if (path === '/api/notifications' && request.method === 'GET') {
                return handleGetUserNotifications(request, DB);
            }

            // ========== MAINTENANCE ==========
            if (path === '/api/admin/fix-dates' && request.method === 'POST') {
                return handleFixDates(request, DB);
            }

            if (path === '/api/admin/fix-null-dates' && request.method === 'POST') {
                return handleFixNullDates(request, DB);
            }

            // ========== DELTA SYNC ==========
            if (path.match(/^\/api\/drugs\/delta\/\d+$/) && request.method === 'GET') {
                const timestamp = path.split('/').pop();
                return handleDeltaSync(timestamp, DB);
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

            // Use real old_price if available, otherwise fallback (though fallback shouldn't be needed for accurate data)
            const oldPrice = drug.old_price || (drug.price * 0.8);
            const changePercent = oldPrice > 0
                ? ((drug.price - oldPrice) / oldPrice) * 100
                : 0;

            return {
                ...drug,
                old_price: oldPrice,
                new_price: drug.price,
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

async function handleDeltaSync(timestamp, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const timestampNum = parseInt(timestamp);

        // Transform D1 snake_case to Flutter camelCase
        const transformDrug = (drug) => ({
            id: drug.id,
            tradeName: drug.trade_name,
            arabicName: drug.arabic_name,
            oldPrice: drug.old_price,
            price: drug.price,
            active: drug.active,
            mainCategory: drug.main_category,
            mainCategory_ar: drug.main_category_ar,
            company: drug.company,
            dosageForm: drug.dosage_form,
            dosageForm_ar: drug.dosage_form_ar,
            unit: drug.unit,
            usage: drug.usage,
            usage_ar: drug.usage_ar,
            description: drug.description || '',
            lastPriceUpdate: drug.last_price_update,
            concentration: drug.concentration,
            imageUrl: drug.image_url || null,
            category: drug.category,
            category_ar: drug.category_ar,
            visits: drug.visits || 0,
            createdAt: drug.created_at,
            updatedAt: drug.updated_at
        });

        // If timestamp is 0, return last 1000 drugs (full sync)
        if (timestampNum === 0) {
            const query = `
                SELECT * FROM drugs
                ORDER BY updated_at DESC
                LIMIT 1000
            `;
            const result = await DB.prepare(query).all();
            const transformedDrugs = (result.results || []).map(transformDrug);

            return jsonResponse({
                drugs: transformedDrugs,
                count: transformedDrugs.length,
                sync_type: 'full'
            });
        }

        // Delta sync: return drugs updated after timestamp
        const query = `
            SELECT * FROM drugs
            WHERE updated_at > ?
            ORDER BY updated_at ASC
        `;

        const result = await DB.prepare(query).bind(timestampNum).all();
        const transformedDrugs = (result.results || []).map(transformDrug);

        return jsonResponse({
            drugs: transformedDrugs,
            count: transformedDrugs.length,
            sync_type: 'delta',
            timestamp: timestampNum,
            server_time: Math.floor(Date.now() / 1000)
        });

    } catch (error) {
        console.error('Delta sync error:', error);
        return errorResponse('Delta sync failed: ' + error.message, 500);
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
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const search = url.searchParams.get('search') || '';
    const sortBy = url.searchParams.get('sortBy') || 'updated_at';
    const sortOrder = url.searchParams.get('sortOrder') || 'DESC';
    const offset = (page - 1) * limit;

    try {
        // Select logic with defaults handled in JS
        let query = 'SELECT * FROM drugs';
        let countQuery = 'SELECT COUNT(*) as total FROM drugs';
        const params = [];

        if (search) {
            query += ' WHERE trade_name LIKE ? OR company LIKE ?';
            countQuery += ' WHERE trade_name LIKE ? OR company LIKE ?';
            const searchParam = `%${search}%`;
            params.push(searchParam, searchParam);
        }

        const allowedSortColumns = ['id', 'trade_name', 'company', 'price', 'old_price', 'updated_at', 'last_price_update', 'created_at'];
        if (!allowedSortColumns.includes(sortBy)) {
            // Fallback to default if invalid column
            // But valid columns should pass through
        }

        // If sorting by last_price_update, ensure we handle NULLs if necessary (SQLite defaults NULLs first for ASC, last for DESC usually, but good to be safe)
        // For formatted strings YYYY-MM-DD, standard sorting works.

        const safeSortBy = allowedSortColumns.includes(sortBy) ? sortBy : 'updated_at';
        const safeSortOrder = (sortOrder === 'ASC' || sortOrder === 'DESC') ? sortOrder : 'DESC';

        // Add NULLS LAST to ensure empty values don't clutter the top of the list
        query += ` ORDER BY ${safeSortBy} ${safeSortOrder} NULLS LAST LIMIT ? OFFSET ?`;
        params.push(limit, offset);

        const [dataResult, countResult] = await Promise.all([
            DB.prepare(query).bind(...params).all(),
            DB.prepare(countQuery).bind(...(search ? [`%${search}%`, `%${search}%`] : [])).first()
        ]);

        // Process results to inject default date
        const processedResults = (dataResult.results || []).map(drug => {
            let lastPriceUpdate = drug.last_price_update;
            // Check for null, undefined, or empty/whitespace/N/A string
            if (!lastPriceUpdate ||
                (typeof lastPriceUpdate === 'string' && (lastPriceUpdate.trim() === '' || lastPriceUpdate.trim().toUpperCase() === 'N/A' || lastPriceUpdate.trim().toLowerCase() === 'null'))) {
                // Use a PAST DATE so real updates appear first when sorting DESC
                lastPriceUpdate = '2000-01-01';
            } else if (typeof lastPriceUpdate === 'string' && /^\d{1,2}\/\d{1,2}\/\d{4}$/.test(lastPriceUpdate)) {
                // Handle DD/MM/YYYY format found in DB
                const parts = lastPriceUpdate.split('/');
                if (parts.length === 3) {
                    // Convert to YYYY-MM-DD
                    const day = parts[0].padStart(2, '0');
                    const month = parts[1].padStart(2, '0');
                    const year = parts[2];
                    lastPriceUpdate = `${year}-${month}-${day}`;
                }
            }
            return {
                ...drug,
                last_price_update: lastPriceUpdate
            };
        });

        return jsonResponse({
            data: processedResults,
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
