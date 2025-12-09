/**
 * MediSwitch Monetization API Handlers - Part 3
 * Gamification, A/B Testing, Segmentation, Revenue Analytics
 */

// ============================================
// 5. GAMIFICATION API
// ============================================

async function handleGetAchievements(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const achievements = await DB.prepare(`
            SELECT * FROM achievements 
            WHERE enabled = 1 
            ORDER BY sort_order, points
        `).all();

        return jsonResponse({ achievements: achievements.results || [] });
    } catch (error) {
        console.error('Get achievements error:', error);
        return errorResponse('Failed to fetch achievements', 500);
    }
}

async function handleGetUserGamification(userId, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const [userPoints, userAchievements] = await Promise.all([
            DB.prepare('SELECT * FROM user_points WHERE user_id = ?').bind(userId).first(),
            DB.prepare(`
                SELECT ua.*, a.name, a.name_ar, a.description, a.description_ar, a.icon, a.points
                FROM user_achievements ua
                JOIN achievements a ON ua.achievement_id = a.id
                WHERE ua.user_id = ?
                ORDER BY ua.unlocked_at DESC
            `).bind(userId).all()
        ]);

        return jsonResponse({
            points: userPoints || {
                user_id: userId,
                total_points: 0,
                level: 1,
                current_streak: 0,
                best_streak: 0
            },
            achievements: userAchievements.results || [],
            unlocked_count: userAchievements.results?.filter(a => a.unlocked).length || 0
        });
    } catch (error) {
        console.error('Get user gamification error:', error);
        return errorResponse('Failed to fetch user gamification data', 500);
    }
}

async function handleGamificationAction(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const { user_id, action_type, details } = data;

        if (!user_id || !action_type) {
            return errorResponse('Missing required fields', 400);
        }

        // Points mapping
        const pointsMap = {
            'search': 1,
            'favorite': 2,
            'share': 5,
            'interaction': 3,
            'daily_login': 5
        };

        const pointsEarned = pointsMap[action_type] || 1;

        // Log activity
        await DB.prepare(`
            INSERT INTO user_activity_log (user_id, activity_type, points_earned, details)
            VALUES (?, ?, ?, ?)
        `).bind(user_id, action_type, pointsEarned, JSON.stringify(details || {})).run();

        // Update user points
        await DB.prepare(`
            INSERT INTO user_points (user_id, total_points, last_activity, updated_at)
            VALUES (?, ?, unixepoch('now'), unixepoch('now'))
            ON CONFLICT(user_id) DO UPDATE SET
                total_points = total_points + ?,
                last_activity = unixepoch('now'),
                updated_at = unixepoch('now')
        `).bind(user_id, pointsEarned, pointsEarned).run();

        // Check for achievements
        await checkAndUnlockAchievements(user_id, action_type, DB);

        return jsonResponse({
            points_earned: pointsEarned,
            message: 'Action tracked successfully'
        });
    } catch (error) {
        console.error('Track gamification action error:', error);
        return errorResponse('Failed to track action', 500);
    }
}

async function checkAndUnlockAchievements(userId, actionType, DB) {
    try {
        // Get relevant achievements
        const achievements = await DB.prepare(`
            SELECT * FROM achievements 
            WHERE type = ? AND enabled = 1
        `).bind(actionType).all();

        for (const achievement of achievements.results || []) {
            // Count user's actions of this type
            const count = await DB.prepare(`
                SELECT COUNT(*) as count 
                FROM user_activity_log 
                WHERE user_id = ? AND activity_type = ?
            `).bind(userId, actionType).first();

            if (count.count >= achievement.requirement) {
                // Check if already unlocked
                const existing = await DB.prepare(`
                    SELECT * FROM user_achievements 
                    WHERE user_id = ? AND achievement_id = ?
                `).bind(userId, achievement.id).first();

                if (!existing) {
                    // Unlock achievement
                    await DB.prepare(`
                        INSERT INTO user_achievements (user_id, achievement_id, progress, unlocked, unlocked_at)
                        VALUES (?, ?, ?, 1, unixepoch('now'))
                    `).bind(userId, achievement.id, achievement.requirement).run();

                    // Award points
                    await DB.prepare(`
                        UPDATE user_points 
                        SET total_points = total_points + ?
                        WHERE user_id = ?
                    `).bind(achievement.points, userId).run();
                } else if (!existing.unlocked) {
                    // Update to unlocked
                    await DB.prepare(`
                        UPDATE user_achievements 
                        SET unlocked = 1, unlocked_at = unixepoch('now'), progress = ?
                        WHERE user_id = ? AND achievement_id = ?
                    `).bind(achievement.requirement, userId, achievement.id).run();
                }
            }
        }
    } catch (error) {
        console.error('Check achievements error:', error);
    }
}

async function handleGetLeaderboard(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const limit = parseInt(url.searchParams.get('limit') || '100');

    try {
        const leaderboard = await DB.prepare(`
            SELECT user_id, total_points, level, current_streak, rank
            FROM user_points
            ORDER BY total_points DESC
            LIMIT ?
        `).bind(limit).all();

        return jsonResponse({ leaderboard: leaderboard.results || [] });
    } catch (error) {
        console.error('Get leaderboard error:', error);
        return errorResponse('Failed to fetch leaderboard', 500);
    }
}

async function handleAdminGetAchievements(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const achievements = await DB.prepare(`
            SELECT a.*, 
                   COUNT(ua.id) as unlock_count
            FROM achievements a
            LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.unlocked = 1
            GROUP BY a.id
            ORDER BY a.sort_order, a.created_at DESC
        `).all();

        return jsonResponse({ achievements: achievements.results || [] });
    } catch (error) {
        console.error('Admin get achievements error:', error);
        return errorResponse('Failed to fetch achievements', 500);
    }
}

async function handleAdminCreateAchievement(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const result = await DB.prepare(`
            INSERT INTO achievements (
                name, name_ar, description, description_ar, icon, points, type, requirement, requirement_type, enabled, sort_order
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `).bind(
            data.name,
            data.name_ar || '',
            data.description || '',
            data.description_ar || '',
            data.icon || '',
            data.points || 10,
            data.type,
            data.requirement || 1,
            data.requirement_type || 'count',
            data.enabled !== undefined ? data.enabled : 1,
            data.sort_order || 0
        ).run();

        const achievement = await DB.prepare('SELECT * FROM achievements WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ achievement }, 201);
    } catch (error) {
        console.error('Create achievement error:', error);
        return errorResponse('Failed to create achievement', 500);
    }
}

// ============================================
// 6. A/B TESTING API
// ============================================

async function handleGetABAssignment(userId, request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const url = new URL(request.url);
        const testId = url.searchParams.get('test_id');

        if (!testId) {
            return errorResponse('test_id required', 400);
        }

        // Check existing assignment
        let assignment = await DB.prepare(`
            SELECT * FROM ab_test_assignments 
            WHERE user_id = ? AND test_id = ?
        `).bind(userId, testId).first();

        if (!assignment) {
            // Assign random variant
            const variant = Math.random() < 0.5 ? 'A' : 'B';

            await DB.prepare(`
                INSERT INTO ab_test_assignments (user_id, test_id, variant)
                VALUES (?, ?, ?)
            `).bind(userId, testId, variant).run();

            // Update user count
            await DB.prepare(`
                UPDATE ab_test_variants 
                SET user_count = user_count + 1
                WHERE test_id = ? AND variant = ?
            `).bind(testId, variant).run();

            assignment = { user_id: userId, test_id: testId, variant };
        }

        // Get variant config
        const variantData = await DB.prepare(`
            SELECT config FROM ab_test_variants 
            WHERE test_id = ? AND variant = ?
        `).bind(testId, assignment.variant).first();

        return jsonResponse({
            variant: assignment.variant,
            config: variantData ? JSON.parse(variantData.config) : {}
        });
    } catch (error) {
        console.error('Get AB assignment error:', error);
        return errorResponse('Failed to get assignment', 500);
    }
}

async function handleTrackABEvent(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();
        const { test_id, user_id, variant, event_type, event_value } = data;

        if (!test_id || !user_id || !variant || !event_type) {
            return errorResponse('Missing required fields', 400);
        }

        // Record event
        await DB.prepare(`
            INSERT INTO ab_test_events (test_id, user_id, variant, event_type, event_value)
            VALUES (?, ?, ?, ?, ?)
        `).bind(test_id, user_id, variant, event_type, event_value || 0).run();

        // Update variant metrics
        if (event_type === 'conversion') {
            await DB.prepare(`
                UPDATE ab_test_variants 
                SET conversions = conversions + 1, revenue = revenue + ?
                WHERE test_id = ? AND variant = ?
            `).bind(event_value || 0, test_id, variant).run();
        }

        return jsonResponse({ message: 'Event tracked successfully' });
    } catch (error) {
        console.error('Track AB event error:', error);
        return errorResponse('Failed to track event', 500);
    }
}

async function handleAdminGetABTests(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const status = url.searchParams.get('status') || '';

    try {
        let query = 'SELECT * FROM ab_tests';
        const params = [];

        if (status) {
            query += ' WHERE status = ?';
            params.push(status);
        }

        query += ' ORDER BY created_at DESC';

        const tests = await DB.prepare(query).bind(...params).all();

        return jsonResponse({ tests: tests.results || [] });
    } catch (error) {
        console.error('Admin get AB tests error:', error);
        return errorResponse('Failed to fetch tests', 500);
    }
}

async function handleAdminCreateABTest(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const result = await DB.prepare(`
            INSERT INTO ab_tests (name, description, metric, start_date, end_date, status)
            VALUES (?, ?, ?, ?, ?, ?)
        `).bind(
            data.name,
            data.description || '',
            data.metric || 'conversion',
            data.start_date,
            data.end_date || null,
            data.status || 'draft'
        ).run();

        const testId = result.meta.last_row_id;

        // Create variants
        await DB.prepare(`
            INSERT INTO ab_test_variants (test_id, variant, config)
            VALUES (?, 'A', ?), (?, 'B', ?)
        `).bind(testId, data.config_a || '{}', testId, data.config_b || '{}').run();

        const test = await DB.prepare('SELECT * FROM ab_tests WHERE id = ?').bind(testId).first();

        return jsonResponse({ test }, 201);
    } catch (error) {
        console.error('Create AB test error:', error);
        return errorResponse('Failed to create test', 500);
    }
}

async function handleAdminGetABTestResults(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const test = await DB.prepare('SELECT * FROM ab_tests WHERE id = ?').bind(id).first();

        if (!test) {
            return errorResponse('Test not found', 404);
        }

        const variants = await DB.prepare(`
            SELECT * FROM ab_test_variants WHERE test_id = ?
        `).bind(id).all();

        return jsonResponse({
            test,
            variants: variants.results || [],
            winner: test.winner
        });
    } catch (error) {
        console.error('Get AB test results error:', error);
        return errorResponse('Failed to fetch results', 500);
    }
}

// ============================================
// 7. USER SEGMENTATION API
// ============================================

async function handleAdminGetSegments(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const segments = await DB.prepare(`
            SELECT * FROM user_segments 
            ORDER BY created_at DESC
        `).all();

        return jsonResponse({ segments: segments.results || [] });
    } catch (error) {
        console.error('Get segments error:', error);
        return errorResponse('Failed to fetch segments', 500);
    }
}

async function handleAdminCreateSegment(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const data = await request.json();

        const result = await DB.prepare(`
            INSERT INTO user_segments (name, description, criteria, auto_refresh, enabled)
            VALUES (?, ?, ?, ?, ?)
        `).bind(
            data.name,
            data.description || '',
            JSON.stringify(data.criteria || {}),
            data.auto_refresh !== undefined ? data.auto_refresh : 1,
            data.enabled !== undefined ? data.enabled : 1
        ).run();

        const segment = await DB.prepare('SELECT * FROM user_segments WHERE id = ?')
            .bind(result.meta.last_row_id).first();

        return jsonResponse({ segment }, 201);
    } catch (error) {
        console.error('Create segment error:', error);
        return errorResponse('Failed to create segment', 500);
    }
}

async function handleAdminGetSegmentUsers(id, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const users = await DB.prepare(`
            SELECT user_id, added_at 
            FROM segment_users 
            WHERE segment_id = ?
            ORDER BY added_at DESC
        `).bind(id).all();

        return jsonResponse({ users: users.results || [] });
    } catch (error) {
        console.error('Get segment users error:', error);
        return errorResponse('Failed to fetch segment users', 500);
    }
}

// ============================================
// 8. REVENUE ANALYTICS API
// ============================================

async function handleAdminGetRevenueDashboard(DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    try {
        const today = new Date().toISOString().split('T')[0];
        const thisMonth = today.substring(0, 7);

        const [todayRevenue, monthRevenue, activeSubscriptions, totalRevenue] = await Promise.all([
            DB.prepare('SELECT * FROM revenue_daily WHERE date = ?').bind(today).first(),
            DB.prepare('SELECT * FROM revenue_monthly WHERE month = ?').bind(thisMonth).first(),
            DB.prepare('SELECT COUNT(*) as count FROM subscriptions WHERE status = \'active\'').first(),
            DB.prepare('SELECT SUM(total_revenue) as total FROM revenue_daily').first()
        ]);

        return jsonResponse({
            today: todayRevenue || { total_revenue: 0 },
            this_month: monthRevenue || { total_revenue: 0, mrr: 0 },
            active_subscriptions: activeSubscriptions?.count || 0,
            total_revenue: totalRevenue?.total || 0
        });
    } catch (error) {
        console.error('Get revenue dashboard error:', error);
        return errorResponse('Failed to fetch revenue data', 500);
    }
}

async function handleAdminGetDailyRevenue(request, DB) {
    if (!DB) return errorResponse('Database not configured', 500);

    const url = new URL(request.url);
    const start = url.searchParams.get('start') || '';
    const end = url.searchParams.get('end') || '';

    try {
        let query = 'SELECT * FROM revenue_daily';
        const params = [];

        if (start && end) {
            query += ' WHERE date BETWEEN ? AND ?';
            params.push(start, end);
        }

        query += ' ORDER BY date DESC LIMIT 90';

        const revenue = await DB.prepare(query).bind(...params).all();

        return jsonResponse({ revenue: revenue.results || [] });
    } catch (error) {
        console.error('Get daily revenue error:', error);
        return errorResponse('Failed to fetch revenue data', 500);
    }
}

// Export all functions
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        // Gamification
        handleGetAchievements,
        handleGetUserGamification,
        handleGamificationAction,
        handleGetLeaderboard,
        handleAdminGetAchievements,
        handleAdminCreateAchievement,
        // A/B Testing
        handleGetABAssignment,
        handleTrackABEvent,
        handleAdminGetABTests,
        handleAdminCreateABTest,
        handleAdminGetABTestResults,
        // Segmentation
        handleAdminGetSegments,
        handleAdminCreateSegment,
        handleAdminGetSegmentUsers,
        // Revenue
        handleAdminGetRevenueDashboard,
        handleAdminGetDailyRevenue
    };
}
