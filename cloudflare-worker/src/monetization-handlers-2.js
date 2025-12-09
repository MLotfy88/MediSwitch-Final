/**
 * MediSwitch Monetization API Handlers - Part 2
 * Sponsored listings, Affiliate, Gamification, A/B Testing, etc.
 */

// ============================================
// 3. SPONSORED LISTINGS API
// ============================================

async function handleGetActiveSponsoredDrugs(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const now = Math.floor(Date.now() / 1000);
        const sponsored = await DB.prepare(`
            SELECT s.*, d.trade_name, d.company as drug_company
            FROM sponsored_drugs s
            LEFT JOIN drugs d ON s.drug_id = d.id
            WHERE s.status = 'active' 
            AND s.start_date <= ? 
            AND s.end_date >= ?
            ORDER BY s.position ASC
            LIMIT 5
        `).bind(now, now).all();

        return jsonResponse({ sponsored: sponsored.results || [] });
    } catch (error) {
        console.error('Get sponsored drugs error:', error);
        return errorResponse('Failed to fetch sponsored drugs', 500);
    }
}

async function handleTrackSponsoredImpression(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        // Record impression
        await DB.prepare(`
            INSERT INTO sponsored_impressions (sponsored_id, user_id, search_query)
            VALUES (?, ?, ?)
        `).bind(id, data.user_id || '', data.search_query || '').run();

        // Update count
        await DB.prepare(`
            UPDATE sponsored_drugs 
            SET impressions = impressions + 1 
            WHERE id = ?
        `).bind(id).run();

        return jsonResponse({ message: 'Impression tracked' });
    } catch (error) {
        console.error('Track impression error:', error);
        return errorResponse('Failed to track impression', 500);
    }
}

async function handleTrackSponsoredClick(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        // Record click
        await DB.prepare(`
            INSERT INTO sponsored_clicks (sponsored_id, user_id, search_query)
            VALUES (?, ?, ?)
        `).bind(id, data.user_id || '', data.search_query || '').run();

        // Update count
        await DB.prepare(`
            UPDATE sponsored_drugs 
            SET clicks = clicks + 1 
            WHERE id = ?
        `).bind(id).run();

        return jsonResponse({ message: 'Click tracked' });
    } catch (error) {
        console.error('Track click error:', error);
        return errorResponse('Failed to track click', 500);
    }
}

async function handleAdminGetSponsoredListings(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = parseInt(url.searchParams.get('limit') || '50');
    const status = url.searchParams.get('status') || '';
    const offset = (page - 1) * limit;

    try {
        let query = `
            SELECT s.*, d.trade_name 
            FROM sponsored_drugs s
            LEFT JOIN drugs d ON s.drug_id = d.id
        `;
        let countQuery = 'SELECT COUNT(*) as total FROM sponsored_drugs';
        const params = [];

        if (status) {
            query += ' WHERE s.status = ?';
            countQuery += ' WHERE status = ?';
            params.push(status);
        }

        query += ' ORDER BY s.created_at DESC LIMIT ? OFFSET ?';
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
        console.error('Admin get sponsored error:', error);
        return errorResponse('Failed to fetch sponsored listings', 500);
    }
}

async function handleAdminCreateSponsored(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const result = await DB.prepare(`
            INSERT INTO sponsored_drugs (
                drug_id, company, contact_email, contact_phone, start_date, end_date,
                position, cost_per_month, total_cost, status, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
            data.drug_id,
            data.company,
            data.contact_email || '',
            data.contact_phone || '',
            data.start_date,
            data.end_date,
            data.position || 1,
            data.cost_per_month,
            data.total_cost || data.cost_per_month,
            data.status || 'pending',
            data.notes || ''
        ).run();

        const sponsored = await DB.prepare('SELECT * FROM sponsored_drugs WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ sponsored }, 201);
    } catch (error) {
        console.error('Create sponsored error:', error);
        return errorResponse('Failed to create sponsored listing', 500);
    }
}

async function handleAdminUpdateSponsored(id, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const updates = [];
        const params = [];

        if (data.drug_id !== undefined) { updates.push('drug_id = ?'); params.push(data.drug_id); }
        if (data.company !== undefined) { updates.push('company = ?'); params.push(data.company); }
        if (data.contact_email !== undefined) { updates.push('contact_email = ?'); params.push(data.contact_email); }
        if (data.contact_phone !== undefined) { updates.push('contact_phone = ?'); params.push(data.contact_phone); }
        if (data.start_date !== undefined) { updates.push('start_date = ?'); params.push(data.start_date); }
        if (data.end_date !== undefined) { updates.push('end_date = ?'); params.push(data.end_date); }
        if (data.position !== undefined) { updates.push('position = ?'); params.push(data.position); }
        if (data.cost_per_month !== undefined) { updates.push('cost_per_month = ?'); params.push(data.cost_per_month); }
        if (data.total_cost !== undefined) { updates.push('total_cost = ?'); params.push(data.total_cost); }
        if (data.status !== undefined) { updates.push('status = ?'); params.push(data.status); }
        if (data.notes !== undefined) { updates.push('notes = ?'); params.push(data.notes); }

        updates.push('updated_at = unixepoch(\'now\')');

        if (updates.length === 1) {
            return errorResponse('No fields to update', 400);
        }

        params.push(id);
        const query = `UPDATE sponsored_drugs SET ${updates.join(', ')} WHERE id = ?`;
        const result = await DB.prepare(query).bind(...params).run();

        if (result.meta.changes === 0) {
            return errorResponse('Sponsored listing not found', 404);
        }

        const sponsored = await DB.prepare('SELECT * FROM sponsored_drugs WHERE id = ?').bind(id).first();
        return jsonResponse({ sponsored });
    } catch (error) {
        console.error('Update sponsored error:', error);
        return errorResponse('Failed to update sponsored listing', 500);
    }
}

async function handleAdminDeleteSponsored(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const result = await DB.prepare('DELETE FROM sponsored_drugs WHERE id = ?').bind(id).run();

        if (result.meta.changes === 0) {
            return errorResponse('Sponsored listing not found', 404);
        }

        return jsonResponse({ message: 'Sponsored listing deleted successfully' });
    } catch (error) {
        console.error('Delete sponsored error:', error);
        return errorResponse('Failed to delete sponsored listing', 500);
    }
}

async function handleAdminGetSponsoredAnalytics(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const sponsored = await DB.prepare('SELECT * FROM sponsored_drugs WHERE id = ?').bind(id).first();

        if (!sponsored) {
            return errorResponse('Sponsored listing not found', 404);
        }

        // Calculate CTR
        const ctr = sponsored.impressions > 0 ? (sponsored.clicks / sponsored.impressions * 100).toFixed(2) : 0;

        // Get daily breakdown (last 30 days)
        const dailyStats = await DB.prepare(`
            SELECT 
                DATE(clicked_at, 'unixepoch') as date,
                COUNT(*) as clicks
            FROM sponsored_clicks
            WHERE sponsored_id = ?
            GROUP BY date
            ORDER BY date DESC
            LIMIT 30
        `).bind(id).all();

        return jsonResponse({
            sponsored,
            analytics: {
                ctr: parseFloat(ctr),
                cost_per_click: sponsored.clicks > 0 ? (sponsored.total_cost / sponsored.clicks).toFixed(2) : 0,
                daily_stats: dailyStats.results || []
            }
        });
    } catch (error) {
        console.error('Get sponsored analytics error:', error);
        return errorResponse('Failed to fetch analytics', 500);
    }
}

// ============================================
// 4. AFFILIATE API
// ============================================

async function handleGetAffiliateLink(drugId, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const url = new URL(request.url);
        const userId = url.searchParams.get('user_id') || '';

        // Get random active partner or specific one
        const partner = await DB.prepare(`
            SELECT * FROM affiliate_partners 
            WHERE enabled = 1 
            ORDER BY RANDOM() 
            LIMIT 1
        `).first();

        if (!partner) {
            return errorResponse('No affiliate partners available', 404);
        }

        // Generate unique ref ID
        const refId = `${userId}-${drugId}-${Date.now()}`;

        // Generate URL
        const affiliateUrl = partner.url_template
            .replace('{ref_id}', refId)
            .replace('{drug_id}', drugId)
            .replace('{user_id}', userId);

        return jsonResponse({
            partner: {
                id: partner.id,
                name: partner.name
            },
            url: affiliateUrl,
            ref_id: refId
        });
    } catch (error) {
        console.error('Get affiliate link error:', error);
        return errorResponse('Failed to generate affiliate link', 500);
    }
}

async function handleTrackAffiliateClick(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const { partner_id, drug_id, user_id, ref_id } = data;

        if (!partner_id || !ref_id) {
            return errorResponse('Missing required fields', 400);
        }

        await DB.prepare(`
            INSERT INTO affiliate_clicks (
                partner_id, drug_id, user_id, ref_id, ip_address, user_agent
            ) VALUES (?, ?, ?, ?, ?, ?)
        `).bind(
            partner_id,
            drug_id || null,
            user_id || '',
            ref_id,
            data.ip_address || '',
            data.user_agent || ''
        ).run();

        return jsonResponse({ message: 'Click tracked successfully' });
    } catch (error) {
        console.error('Track affiliate click error:', error);
        return errorResponse('Failed to track click', 500);
    }
}

async function handleAdminGetAffiliatePartners(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const partners = await DB.prepare(`
            SELECT p.*, 
                   COUNT(c.id) as total_clicks,
                   SUM(CASE WHEN c.converted = 1 THEN 1 ELSE 0 END) as conversions,
                   SUM(c.commission_earned) as total_commission
            FROM affiliate_partners p
            LEFT JOIN affiliate_clicks c ON p.id = c.partner_id
            GROUP BY p.id
            ORDER BY p.created_at DESC
        `).all();

        return jsonResponse({ partners: partners.results || [] });
    } catch (error) {
        console.error('Get affiliate partners error:', error);
        return errorResponse('Failed to fetch partners', 500);
    }
}

async function handleAdminCreateAffiliatePartner(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const result = await DB.prepare(`
            INSERT INTO affiliate_partners (
                name, name_ar, logo_url, url_template, commission_rate, payment_terms, contact_email, enabled
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
            data.name,
            data.name_ar || '',
            data.logo_url || '',
            data.url_template,
            data.commission_rate || 10.0,
            data.payment_terms || 'Net 30',
            data.contact_email || '',
            data.enabled !== undefined ? data.enabled : 1
        ).run();

        const partner = await DB.prepare('SELECT * FROM affiliate_partners WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ partner }, 201);
    } catch (error) {
        console.error('Create affiliate partner error:', error);
        return errorResponse('Failed to create partner', 500);
    }
}

// Continued in Part 3...
