/**
 * MediSwitch Cloudflare Worker API
 * Serverless backend for drug database sync
 */

// CORS headers
const CORS_HEADERS = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
	'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

/**
 * Main request handler
 */
export default {
	async fetch(request, env, ctx) {
		// Handle CORS preflight
		if (request.method === 'OPTIONS') {
			return new Response(null, { headers: CORS_HEADERS });
		}

		const url = new URL(request.url);
		const path = url.pathname;

		try {
			// Route handling
			if (path === '/api/drugs' && request.method === 'GET') {
				return handleGetDrugs(request, env);
			}

			if (path.startsWith('/api/drugs/') && request.method === 'GET') {
				return handleGetDrug(request, env);
			}

			if (path === '/api/sync' && request.method === 'GET') {
				return handleSync(request, env);
			}

			if (path === '/api/update' && request.method === 'POST') {
				return handleUpdate(request, env);
			}

			if (path === '/api/stats' && request.method === 'GET') {
				return handleStats(request, env);
			}

			// Config Routes
			if (path === '/api/config' && request.method === 'GET') {
				return handleGetConfig(request, env);
			}

			if (path === '/api/config' && request.method === 'POST') {
				return handleUpdateConfig(request, env);
			}

			// Analytics Routes
			if (path === '/api/searches/missed' && request.method === 'GET') {
				return handleGetMissedSearches(request, env);
			}

			if (path === '/api/searches/missed' && request.method === 'POST') {
				return handleLogMissedSearch(request, env);
			}

			// Interactions Routes
			if (path === '/api/interactions' && request.method === 'GET') {
				return handleGetInteractions(request, env);
			}

			if (path === '/api/interactions/sync' && request.method === 'GET') {
				return handleSyncInteractions(request, env);
			}

			// 404
			return jsonResponse({ error: 'Not found' }, 404);
		} catch (error) {
			console.error('Error:', error);
			return jsonResponse({ error: error.message }, 500);
		}
	},
};

/**
 * GET /api/drugs
 * List all drugs with pagination
 */
async function handleGetDrugs(request, env) {
	const url = new URL(request.url);
	const page = parseInt(url.searchParams.get('page') || '1');
	const limit = parseInt(url.searchParams.get('limit') || '100');
	const search = url.searchParams.get('search') || '';
	const offset = (page - 1) * limit;

	if (search) {
		const searchPattern = `%${search}%`;
		const { results } = await env.DB.prepare(
			`SELECT * FROM drugs 
			 WHERE trade_name LIKE ? OR arabic_name LIKE ? 
			 ORDER BY updated_at DESC LIMIT ? OFFSET ?`
		).bind(searchPattern, searchPattern, limit, offset).all();

		const { count } = await env.DB.prepare(
			`SELECT COUNT(*) as count FROM drugs 
			 WHERE trade_name LIKE ? OR arabic_name LIKE ?`
		).bind(searchPattern, searchPattern).first();

		return jsonResponse({
			data: results,
			pagination: {
				page,
				limit,
				total: count,
				pages: Math.ceil(count / limit),
			},
		});
	}

	const { results } = await env.DB.prepare(
		'SELECT * FROM drugs ORDER BY updated_at DESC LIMIT ? OFFSET ?'
	).bind(limit, offset).all();

	const { count } = await env.DB.prepare(
		'SELECT COUNT(*) as count FROM drugs'
	).first();

	return jsonResponse({
		data: results,
		pagination: {
			page,
			limit,
			total: count,
			pages: Math.ceil(count / limit),
		},
	});
}

/**
 * GET /api/drugs/:id
 * Get single drug by ID
 */
async function handleGetDrug(request, env) {
	const url = new URL(request.url);
	const id = url.pathname.split('/').pop();

	const drug = await env.DB.prepare(
		'SELECT * FROM drugs WHERE id = ?'
	).bind(id).first();

	if (!drug) {
		return jsonResponse({ error: 'Drug not found' }, 404);
	}

	return jsonResponse({ data: drug });
}

/**
 * GET /api/sync?since=2025-12-01
 * Get drugs updated since a specific date (incremental sync)
 */
async function handleSync(request, env) {
	const url = new URL(request.url);
	const since = url.searchParams.get('since');

	if (!since) {
		return jsonResponse({ error: 'Missing "since" parameter (format: YYYY-MM-DD or dd/mm/yyyy)' }, 400);
	}

	// Convert dd/mm/yyyy to YYYY-MM-DD for comparison
	const dateStr = convertDateFormat(since);

	const { results } = await env.DB.prepare(
		`SELECT * FROM drugs 
		 WHERE DATE(updated_at) >= DATE(?) 
		 ORDER BY updated_at DESC`
	).bind(dateStr).all();

	/**
	 * GET /api/interactions/sync?since=2025-12-01
	 * Get interactions created/updated since a specific date
	 */
	async function handleSyncInteractions(request, env) {
		const url = new URL(request.url);
		const since = url.searchParams.get('since');

		if (!since) {
			return jsonResponse({ error: 'Missing "since" parameter' }, 400);
		}

		// Support both YYYY-MM-DD and full timestamp
		const dateStr = convertDateFormat(since);

		const { results } = await env.DB.prepare(
			`SELECT * FROM drug_interactions 
		 WHERE DATE(created_at) >= DATE(?) 
		 ORDER BY created_at DESC`
		).bind(dateStr).all();

		return jsonResponse({
			data: results,
			count: results.length,
			since: since,
		});
	}

	/**
	 * POST /api/update
	 * Update database with new data (from GitHub Action)
	 */
	async function handleUpdate(request, env) {
		// Verify API key
		const apiKey = request.headers.get('Authorization')?.replace('Bearer ', '');
		if (!apiKey || apiKey !== env.API_KEY) {
			return jsonResponse({ error: 'Unauthorized' }, 401);
		}

		const data = await request.json();

		if (!Array.isArray(data)) {
			return jsonResponse({ error: 'Data must be an array' }, 400);
		}

		let inserted = 0;
		let updated = 0;

		// Batch insert/update
		const batch = [];
		for (const drug of data) {
			batch.push(
				env.DB.prepare(
					`INSERT INTO drugs (
					id, trade_name, arabic_name, old_price, price, active,
					main_category, main_category_ar, category, category_ar,
					company, dosage_form, dosage_form_ar, unit, usage, usage_ar,
					description, last_price_update, concentration, visits,
					updated_at
				) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
				ON CONFLICT(id) DO UPDATE SET
					trade_name = excluded.trade_name,
					arabic_name = excluded.arabic_name,
					old_price = excluded.old_price,
					price = excluded.price,
					active = excluded.active,
					main_category = excluded.main_category,
					main_category_ar = excluded.main_category_ar,
					category = excluded.category,
					category_ar = excluded.category_ar,
					company = excluded.company,
					dosage_form = excluded.dosage_form,
					dosage_form_ar = excluded.dosage_form_ar,
					unit = excluded.unit,
					usage = excluded.usage,
					usage_ar = excluded.usage_ar,
					description = excluded.description,
					last_price_update = excluded.last_price_update,
					concentration = excluded.concentration,
					visits = excluded.visits,
					updated_at = CURRENT_TIMESTAMP
			`).bind(
						drug.id || null,
						drug.trade_name,
						drug.arabic_name || '',
						drug.old_price || 0,
						drug.price || 0,
						drug.active || '',
						drug.main_category || '',
						drug.main_category_ar || '',
						drug.category || '',
						drug.category_ar || '',
						drug.company || '',
						drug.dosage_form || '',
						drug.dosage_form_ar || '',
						drug.unit || '1',
						drug.usage || '',
						drug.usage_ar || '',
						drug.description || '',
						drug.last_price_update || '',
						drug.concentration || '',
						drug.visits || 0
					)
			);

			// Execute in batches of 100
			if (batch.length >= 100) {
				await env.DB.batch(batch);
				updated += batch.length;
				batch.length = 0;
			}
		}

		// Execute remaining
		if (batch.length > 0) {
			await env.DB.batch(batch);
			updated += batch.length;
		}

		return jsonResponse({
			success: true,
			updated: data.length,
			message: `Successfully updated ${data.length} drugs`,
		});
	}

	/**
	 * GET /api/stats
	 * Get database statistics
	 */
	async function handleStats(request, env) {
		const totalDrugs = await env.DB.prepare('SELECT COUNT(*) as count FROM drugs').first();
		const totalCompanies = await env.DB.prepare('SELECT COUNT(DISTINCT company) as count FROM drugs').first();
		const recentUpdates = await env.DB.prepare(
			'SELECT COUNT(*) as count FROM drugs WHERE DATE(updated_at) >= DATE("now", "-7 days")'
		).first();

		return jsonResponse({
			total_drugs: totalDrugs.count,
			total_companies: totalCompanies.count,
			recent_updates_7d: recentUpdates.count,
		});
	}

	/**
	 * Helper: JSON response with CORS
	 */
	function jsonResponse(data, status = 200) {
		return new Response(JSON.stringify(data), {
			status,
			headers: {
				'Content-Type': 'application/json',
				...CORS_HEADERS,
			},
		});
	}

	/**
	 * Helper: Convert date from dd/mm/yyyy to YYYY-MM-DD
	 */
	function convertDateFormat(dateStr) {
		// If already in YYYY-MM-DD format
		if (/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) {
			return dateStr;
		}

		// Convert dd/mm/yyyy to YYYY-MM-DD
		const parts = dateStr.split('/');
		if (parts.length === 3) {
			return `${parts[2]}-${parts[1]}-${parts[0]}`;
		}

		return dateStr;
	}

	/**
	 * GET /api/interactions
	 * List all interactions with pagination
	 */
	async function handleGetInteractions(request, env) {
		const url = new URL(request.url);
		const page = parseInt(url.searchParams.get('page') || '1');
		const limit = parseInt(url.searchParams.get('limit') || '100');
		const offset = (page - 1) * limit;

		const { results } = await env.DB.prepare(
			'SELECT * FROM drug_interactions ORDER BY created_at DESC LIMIT ? OFFSET ?'
		).bind(limit, offset).all();

		const { count } = await env.DB.prepare(
			'SELECT COUNT(*) as count FROM drug_interactions'
		).first();

		return jsonResponse({
			data: results,
			pagination: {
				page,
				limit,
				total: count,
				pages: Math.ceil(count / limit),
			},
		});
	}

	return jsonResponse({
		data: results,
		count: results.length,
		since: since,
	});
}

/**
 * GET /api/config
 * Get all app configuration
 */
async function handleGetConfig(request, env) {
	try {
		const { results } = await env.DB.prepare('SELECT * FROM app_config').all();

		// Convert to key-value object
		const config = {};
		if (results) {
			results.forEach(row => {
				config[row.key] = row.value;
			});
		}

		return jsonResponse(config);
	} catch (e) {
		// Table might not exist yet
		return jsonResponse({ error: 'Config not available', details: e.message }, 500);
	}
}

/**
 * POST /api/config
 * Update app configuration
 */
async function handleUpdateConfig(request, env) {
	// Basic Auth Check (Weak but better than nothing for now)
	const apiKey = request.headers.get('Authorization')?.replace('Bearer ', '');
	if (!apiKey || apiKey !== env.API_KEY) {
		return jsonResponse({ error: 'Unauthorized' }, 401);
	}

	const data = await request.json();
	const batch = [];

	for (const [key, value] of Object.entries(data)) {
		batch.push(
			env.DB.prepare(
				`INSERT INTO app_config (key, value, updated_at) 
                 VALUES (?, ?, CURRENT_TIMESTAMP)
                 ON CONFLICT(key) DO UPDATE SET 
                 value = excluded.value, 
                 updated_at = excluded.updated_at`
			).bind(key, String(value))
		);
	}

	if (batch.length > 0) {
		await env.DB.batch(batch);
	}

	return jsonResponse({ success: true, updated: batch.length });
}

/**
 * GET /api/searches/missed
 * Get missed search terms
 */
async function handleGetMissedSearches(request, env) {
	try {
		const { results } = await env.DB.prepare(
			'SELECT * FROM missed_searches ORDER BY last_seen DESC LIMIT 50'
		).all();
		return jsonResponse(results || []);
	} catch (e) {
		return jsonResponse([], 200); // Return empty if table doesn't exist
	}
}

/**
 * POST /api/searches/missed
 * Log a missed search
 */
async function handleLogMissedSearch(request, env) {
	const { term } = await request.json();
	if (!term) return jsonResponse({ error: 'Term required' }, 400);

	try {
		await env.DB.prepare(
			`INSERT INTO missed_searches (term, count, last_seen) 
             VALUES (?, 1, CURRENT_TIMESTAMP)
             ON CONFLICT(term) DO UPDATE SET 
             count = count + 1, 
             last_seen = CURRENT_TIMESTAMP`
		).bind(term).run();

		return jsonResponse({ success: true });
	} catch (e) {
		return jsonResponse({ error: e.message }, 500);
	}
}
