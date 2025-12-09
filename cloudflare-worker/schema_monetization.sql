-- ============================================
-- MediSwitch Monetization System - D1 Schema
-- ============================================

-- ============================================
-- 1. SUBSCRIPTIONS SYSTEM
-- ============================================

CREATE TABLE IF NOT EXISTS subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  tier TEXT NOT NULL CHECK(tier IN ('free', 'premium', 'premium_plus')),
  platform TEXT NOT NULL CHECK(platform IN ('android', 'ios', 'web')),
  transaction_id TEXT UNIQUE,
  purchase_token TEXT,
  starts_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  auto_renew BOOLEAN DEFAULT 1,
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'canceled', 'expired', 'trial', 'paused')),
  price REAL,
  currency TEXT DEFAULT 'USD',
  trial_used BOOLEAN DEFAULT 0,
  cancellation_reason TEXT,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires ON subscriptions(expires_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tier ON subscriptions(tier);

-- ============================================
-- 2. IN-APP PURCHASES (IAP)
-- ============================================

CREATE TABLE IF NOT EXISTS iap_products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  price REAL NOT NULL,
  currency TEXT DEFAULT 'USD',
  type TEXT CHECK(type IN ('consumable', 'non_consumable', 'subscription')),
  features TEXT, -- JSON array of features
  icon TEXT,
  enabled BOOLEAN DEFAULT 1,
  sort_order INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS iap_purchases (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  transaction_id TEXT UNIQUE NOT NULL,
  purchase_token TEXT,
  platform TEXT CHECK(platform IN ('android', 'ios')),
  price REAL,
  currency TEXT,
  status TEXT DEFAULT 'completed' CHECK(status IN ('completed', 'pending', 'refunded', 'canceled')),
  purchased_at INTEGER DEFAULT (unixepoch('now')),
  refunded_at INTEGER,
  FOREIGN KEY (product_id) REFERENCES iap_products(product_id)
);

CREATE INDEX IF NOT EXISTS idx_iap_user ON iap_purchases(user_id);
CREATE INDEX IF NOT EXISTS idx_iap_product ON iap_purchases(product_id);
CREATE INDEX IF NOT EXISTS idx_iap_status ON iap_purchases(status);

-- ============================================
-- 3. SPONSORED LISTINGS
-- ============================================

CREATE TABLE IF NOT EXISTS sponsored_drugs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  drug_id INTEGER NOT NULL,
  company TEXT NOT NULL,
  contact_email TEXT,
  contact_phone TEXT,
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  position INTEGER DEFAULT 1, -- 1=top, 2=second, etc.
  cost_per_month REAL NOT NULL,
  total_cost REAL,
  impressions INTEGER DEFAULT 0,
  clicks INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'paused', 'ended', 'pending')),
  notes TEXT,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now')),
  FOREIGN KEY (drug_id) REFERENCES drugs(id)
);

CREATE TABLE IF NOT EXISTS sponsored_impressions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sponsored_id INTEGER NOT NULL,
  user_id TEXT,
  search_query TEXT,
  viewed_at INTEGER DEFAULT (unixepoch('now')),
  FOREIGN KEY (sponsored_id) REFERENCES sponsored_drugs(id)
);

CREATE TABLE IF NOT EXISTS sponsored_clicks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sponsored_id INTEGER NOT NULL,
  user_id TEXT,
  search_query TEXT,
  clicked_at INTEGER DEFAULT (unixepoch('now')),
  FOREIGN KEY (sponsored_id) REFERENCES sponsored_drugs(id)
);

CREATE INDEX IF NOT EXISTS idx_sponsored_drug ON sponsored_drugs(drug_id);
CREATE INDEX IF NOT EXISTS idx_sponsored_status ON sponsored_drugs(status);
CREATE INDEX IF NOT EXISTS idx_sponsored_dates ON sponsored_drugs(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_sponsored_impressions_id ON sponsored_impressions(sponsored_id);
CREATE INDEX IF NOT EXISTS idx_sponsored_clicks_id ON sponsored_clicks(sponsored_id);

-- ============================================
-- 4. AFFILIATE MARKETING
-- ============================================

CREATE TABLE IF NOT EXISTS affiliate_partners (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  name_ar TEXT,
  logo_url TEXT,
  url_template TEXT NOT NULL, -- e.g., https://pharmacy.com?ref={ref_id}&drug={drug_id}
  commission_rate REAL DEFAULT 10.0, -- percentage
  payment_terms TEXT, -- e.g., "Net 30"
  contact_email TEXT,
  enabled BOOLEAN DEFAULT 1,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS affiliate_clicks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  partner_id INTEGER NOT NULL,
  drug_id INTEGER,
  user_id TEXT,
  ref_id TEXT NOT NULL,
  clicked_at INTEGER DEFAULT (unixepoch('now')),
  converted BOOLEAN DEFAULT 0,
  converted_at INTEGER,
  conversion_value REAL,
  commission_earned REAL,
  ip_address TEXT,
  user_agent TEXT,
  FOREIGN KEY (partner_id) REFERENCES affiliate_partners(id)
);

CREATE INDEX IF NOT EXISTS idx_affiliate_partner ON affiliate_clicks(partner_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_ref ON affiliate_clicks(ref_id);
CREATE INDEX IF NOT EXISTS idx_affiliate_converted ON affiliate_clicks(converted);

-- ============================================
-- 5. GAMIFICATION SYSTEM
-- ============================================

CREATE TABLE IF NOT EXISTS achievements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  name_ar TEXT,
  description TEXT,
  description_ar TEXT,
  icon TEXT,
  points INTEGER DEFAULT 10,
  type TEXT CHECK(type IN ('search', 'favorite', 'streak', 'interaction', 'share', 'premium', 'referral')),
  requirement INTEGER, -- e.g., 10 searches to unlock
  requirement_type TEXT, -- 'count', 'streak', 'cumulative'
  enabled BOOLEAN DEFAULT 1,
  sort_order INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS user_achievements (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  achievement_id INTEGER NOT NULL,
  progress INTEGER DEFAULT 0,
  unlocked BOOLEAN DEFAULT 0,
  unlocked_at INTEGER,
  FOREIGN KEY (achievement_id) REFERENCES achievements(id),
  UNIQUE(user_id, achievement_id)
);

CREATE TABLE IF NOT EXISTS user_points (
  user_id TEXT PRIMARY KEY,
  total_points INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  current_streak INTEGER DEFAULT 0,
  best_streak INTEGER DEFAULT 0,
  last_activity INTEGER,
  rank INTEGER,
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS user_activity_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  activity_type TEXT NOT NULL, -- 'search', 'favorite', 'share', etc.
  points_earned INTEGER DEFAULT 0,
  details TEXT, -- JSON with activity details
  created_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_user_achievements ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_type ON achievements(type);
CREATE INDEX IF NOT EXISTS idx_points_rank ON user_points(total_points DESC);
CREATE INDEX IF NOT EXISTS idx_activity_user ON user_activity_log(user_id);

-- ============================================
-- 6. A/B TESTING PLATFORM
-- ============================================

CREATE TABLE IF NOT EXISTS ab_tests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  metric TEXT CHECK(metric IN ('revenue', 'retention', 'engagement', 'conversion', 'ctr')),
  start_date INTEGER NOT NULL,
  end_date INTEGER,
  status TEXT DEFAULT 'draft' CHECK(status IN ('draft', 'running', 'completed', 'archived')),
  winner TEXT, -- 'A' or 'B'
  confidence_level REAL,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS ab_test_variants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  test_id INTEGER NOT NULL,
  variant TEXT CHECK(variant IN ('A', 'B')),
  config TEXT NOT NULL, -- JSON config
  user_count INTEGER DEFAULT 0,
  conversions INTEGER DEFAULT 0,
  revenue REAL DEFAULT 0,
  engagement_score REAL DEFAULT 0,
  FOREIGN KEY (test_id) REFERENCES ab_tests(id)
);

CREATE TABLE IF NOT EXISTS ab_test_assignments (
  user_id TEXT NOT NULL,
  test_id INTEGER NOT NULL,
  variant TEXT CHECK(variant IN ('A', 'B')),
  assigned_at INTEGER DEFAULT (unixepoch('now')),
  PRIMARY KEY (user_id, test_id),
  FOREIGN KEY (test_id) REFERENCES ab_tests(id)
);

CREATE TABLE IF NOT EXISTS ab_test_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  test_id INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  variant TEXT CHECK(variant IN ('A', 'B')),
  event_type TEXT NOT NULL, -- 'view', 'click', 'conversion', etc.
  event_value REAL,
  created_at INTEGER DEFAULT (unixepoch('now')),
  FOREIGN KEY (test_id) REFERENCES ab_tests(id)
);

CREATE INDEX IF NOT EXISTS idx_ab_tests_status ON ab_tests(status);
CREATE INDEX IF NOT EXISTS idx_ab_assignments_user ON ab_test_assignments(user_id);
CREATE INDEX IF NOT EXISTS idx_ab_events_test ON ab_test_events(test_id);

-- ============================================
-- 7. USER SEGMENTATION
-- ============================================

CREATE TABLE IF NOT EXISTS user_segments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT,
  criteria TEXT NOT NULL, -- JSON criteria
  auto_refresh BOOLEAN DEFAULT 1,
  last_refreshed INTEGER,
  user_count INTEGER DEFAULT 0,
  enabled BOOLEAN DEFAULT 1,
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS segment_users (
  segment_id INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  added_at INTEGER DEFAULT (unixepoch('now')),
  PRIMARY KEY (segment_id, user_id),
  FOREIGN KEY (segment_id) REFERENCES user_segments(id)
);

CREATE INDEX IF NOT EXISTS idx_segment_users_user ON segment_users(user_id);

-- ============================================
-- 8. REVENUE ANALYTICS
-- ============================================

CREATE TABLE IF NOT EXISTS revenue_daily (
  date TEXT PRIMARY KEY, -- YYYY-MM-DD
  ads_revenue REAL DEFAULT 0,
  ads_impressions INTEGER DEFAULT 0,
  ads_clicks INTEGER DEFAULT 0,
  subscriptions_revenue REAL DEFAULT 0,
  subscriptions_new INTEGER DEFAULT 0,
  subscriptions_canceled INTEGER DEFAULT 0,
  iap_revenue REAL DEFAULT 0,
  iap_transactions INTEGER DEFAULT 0,
  sponsored_revenue REAL DEFAULT 0,
  sponsored_impressions INTEGER DEFAULT 0,
  sponsored_clicks INTEGER DEFAULT 0,
  affiliate_revenue REAL DEFAULT 0,
  affiliate_conversions INTEGER DEFAULT 0,
  total_revenue REAL DEFAULT 0,
  active_users INTEGER DEFAULT 0,
  new_users INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE TABLE IF NOT EXISTS revenue_monthly (
  month TEXT PRIMARY KEY, -- YYYY-MM
  ads_revenue REAL DEFAULT 0,
  subscriptions_revenue REAL DEFAULT 0,
  iap_revenue REAL DEFAULT 0,
  sponsored_revenue REAL DEFAULT 0,
  affiliate_revenue REAL DEFAULT 0,
  total_revenue REAL DEFAULT 0,
  mrr REAL DEFAULT 0, -- Monthly Recurring Revenue
  arpu REAL DEFAULT 0, -- Average Revenue Per User
  active_users INTEGER DEFAULT 0,
  paying_users INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch('now'))
);

-- ============================================
-- 9. PRICING EXPERIMENTS
-- ============================================

CREATE TABLE IF NOT EXISTS pricing_experiments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_type TEXT CHECK(product_type IN ('subscription', 'iap')),
  product_id TEXT,
  region TEXT,
  price_variant REAL NOT NULL,
  currency TEXT DEFAULT 'USD',
  start_date INTEGER NOT NULL,
  end_date INTEGER,
  conversions INTEGER DEFAULT 0,
  revenue REAL DEFAULT 0,
  impressions INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'completed', 'archived')),
  created_at INTEGER DEFAULT (unixepoch('now')),
  updated_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_pricing_status ON pricing_experiments(status);
CREATE INDEX IF NOT EXISTS idx_pricing_product ON pricing_experiments(product_type, product_id);

-- ============================================
-- 10. REFERRAL SYSTEM (Bonus)
-- ============================================

CREATE TABLE IF NOT EXISTS user_referrals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  referrer_id TEXT NOT NULL,
  referred_id TEXT NOT NULL,
  referral_code TEXT UNIQUE NOT NULL,
  reward_type TEXT, -- 'points', 'premium_days', 'discount'
  reward_value INTEGER,
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'completed', 'expired')),
  completed_at INTEGER,
  created_at INTEGER DEFAULT (unixepoch('now'))
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON user_referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON user_referrals(referral_code);

-- ============================================
-- INITIAL DATA
-- ============================================

-- Sample IAP Products
INSERT OR IGNORE INTO iap_products (product_id, name, name_ar, description, description_ar, price, type, features) VALUES
('offline_database', 'Offline Database', 'قاعدة بيانات غير متصلة', 'Download full drug database for offline use', 'تحميل قاعدة البيانات الكاملة للاستخدام بدون إنترنت', 4.99, 'non_consumable', '["offline_access", "25500_drugs", "instant_search"]'),
('advanced_analytics', 'Advanced Analytics', 'تحليلات متقدمة', 'Track medication history and get detailed reports', 'تتبع تاريخ الأدوية والحصول على تقارير مفصلة', 1.99, 'non_consumable', '["history_tracking", "pdf_export", "charts"]'),
('professional_tools', 'Professional Tools Pack', 'حزمة الأدوات الاحترافية', 'Advanced dosage calculator and interaction checker', 'حاسبة جرعات متقدمة وفاحص تفاعلات محسّن', 9.99, 'non_consumable', '["advanced_calculator", "interaction_tree", "medical_cards"]');

-- Sample Achievements
INSERT OR IGNORE INTO achievements (name, name_ar, description, description_ar, icon, points, type, requirement, requirement_type) VALUES
('First Search', 'أول بحث', 'Completed your first drug search', 'أكملت أول بحث عن دواء', '🔍', 5, 'search', 1, 'count'),
('Search Master', 'محترف البحث', 'Searched for 100 different drugs', 'بحثت عن 100 دواء مختلف', '🎯', 50, 'search', 100, 'count'),
('Week Streak', 'أسبوع متواصل', 'Used the app for 7 days in a row', 'استخدمت التطبيق لمدة 7 أيام متتالية', '🔥', 25, 'streak', 7, 'streak'),
('Favorite Collector', 'جامع المفضلات', 'Added 10 drugs to favorites', 'أضفت 10 أدوية إلى المفضلة', '⭐', 15, 'favorite', 10, 'count'),
('Interaction Expert', 'خبير التفاعلات', 'Checked 50 drug interactions', 'فحصت 50 تفاعل دوائي', '💊', 30, 'interaction', 50, 'count'),
('Premium Member', 'عضو مميز', 'Subscribed to Premium', 'اشتركت في الخطة المميزة', '💎', 100, 'premium', 1, 'count');

-- Sample Affiliate Partners
INSERT OR IGNORE INTO affiliate_partners (name, name_ar, url_template, commission_rate, enabled) VALUES
('Sample Pharmacy', 'صيدلية تجريبية', 'https://example-pharmacy.com?ref={ref_id}&drug={drug_id}', 10.0, 0);
