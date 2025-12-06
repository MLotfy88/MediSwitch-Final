-- ==========================================
-- MediSwitch Users & Subscriptions Schema
-- For Cloudflare D1 Database
-- ==========================================

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,              -- UUID
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT,
  phone TEXT,
  created_at INTEGER NOT NULL,      -- Unix timestamp
  updated_at INTEGER NOT NULL,
  status TEXT DEFAULT 'active',     -- active, suspended, deleted
  email_verified INTEGER DEFAULT 0, -- 0 or 1
  last_login INTEGER,
  fcm_token TEXT                    -- Firebase Cloud Messaging token
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_users_created ON users(created_at);

-- Subscription Plans
CREATE TABLE IF NOT EXISTS subscription_plans (
  id TEXT PRIMARY KEY,              -- free, premium_monthly, premium_yearly, professional
  name_en TEXT NOT NULL,
  name_ar TEXT NOT NULL,
  description_en TEXT,
  description_ar TEXT,
  price REAL NOT NULL,              -- 0 for free
  currency TEXT DEFAULT 'EGP',
  duration_months INTEGER NOT NULL, -- 1 for monthly, 12 for yearly
  features TEXT NOT NULL,           -- JSON string
  is_active INTEGER DEFAULT 1,
  sort_order INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_plans_active ON subscription_plans(is_active);

-- User Subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  plan_id TEXT NOT NULL,
  status TEXT DEFAULT 'active',     -- active, canceled, expired, trial
  started_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  auto_renew INTEGER DEFAULT 1,
  payment_method TEXT,              -- fawry, paymob, card, etc
  trial_ends_at INTEGER,
  canceled_at INTEGER,
  cancellation_reason TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (plan_id) REFERENCES subscription_plans(id)
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON user_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_expires ON user_subscriptions(expires_at);
CREATE INDEX IF NOT EXISTS idx_subscriptions_plan ON user_subscriptions(plan_id);

-- Payments
CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  subscription_id TEXT,
  amount REAL NOT NULL,
  currency TEXT DEFAULT 'EGP',
  payment_method TEXT,
  transaction_id TEXT,
  gateway_response TEXT,            -- JSON string
  status TEXT DEFAULT 'pending',    -- pending, completed, failed, refunded
  metadata TEXT,                     -- JSON: additional info
  created_at INTEGER NOT NULL,
  completed_at INTEGER,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (subscription_id) REFERENCES user_subscriptions(id)
);

CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_transaction ON payments(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payments_created ON payments(created_at);

-- User Activity/Analytics
CREATE TABLE IF NOT EXISTS user_activity (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  event_type TEXT NOT NULL,         -- search, view_drug, add_favorite, etc
  drug_id TEXT,
  metadata TEXT,                     -- JSON
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_activity_user ON user_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_type ON user_activity(event_type);
CREATE INDEX IF NOT EXISTS idx_activity_date ON user_activity(created_at);

-- User Favorites
CREATE TABLE IF NOT EXISTS user_favorites (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  drug_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  UNIQUE(user_id, drug_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON user_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_drug ON user_favorites(drug_id);

-- User Search History
CREATE TABLE IF NOT EXISTS user_search_history (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  query TEXT NOT NULL,
  results_count INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_search_history_user ON user_search_history(user_id);
CREATE INDEX IF NOT EXISTS idx_search_history_date ON user_search_history(created_at);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  user_id TEXT,                      -- NULL for broadcast
  title_en TEXT NOT NULL,
  title_ar TEXT NOT NULL,
  message_en TEXT NOT NULL,
  message_ar TEXT NOT NULL,
  type TEXT NOT NULL,                -- price_change, new_drug, interaction_alert, system, subscription
  drug_id TEXT,
  metadata TEXT,                     -- JSON
  is_read INTEGER DEFAULT 0,
  sent_at INTEGER,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at);

-- Admin Users (for dashboard access)
CREATE TABLE IF NOT EXISTS admin_users (
  id TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  email TEXT,
  role TEXT DEFAULT 'admin',        -- admin, super_admin
  permissions TEXT,                  -- JSON array of permissions
  is_active INTEGER DEFAULT 1,
  last_login INTEGER,
  created_at INTEGER NOT NULL,
  created_by TEXT
);

CREATE INDEX IF NOT EXISTS idx_admin_username ON admin_users(username);
CREATE INDEX IF NOT EXISTS idx_admin_active ON admin_users(is_active);

-- Add default subscription plans
INSERT OR IGNORE INTO subscription_plans (id, name_en, name_ar, description_en, description_ar, price, duration_months, features, sort_order, created_at, updated_at) VALUES
('free', 'Free Plan', 'الخطة المجانية', 'Basic features with limits', 'ميزات أساسية مع حدود', 0.00, 999, 
'{"searches_per_day":10,"max_favorites":10,"history_days":7,"max_alternatives":3,"interactions":"major_only","export":false,"offline":false,"price_history":false,"advanced_filters":false}',
0, strftime('%s', 'now'), strftime('%s', 'now')),

('premium_monthly', 'Premium Monthly', 'بريميوم شهري', 'All features, monthly billing', 'جميع الميزات، فوترة شهرية', 49.99, 1,
'{"searches_per_day":999999,"max_favorites":999999,"history_days":999999,"max_alternatives":999999,"interactions":"all","export":true,"offline":true,"price_history":true,"advanced_filters":true,"priority_support":true}',
1, strftime('%s', 'now'), strftime('%s', 'now')),

('premium_yearly', 'Premium Yearly', 'بريميوم سنوي', 'All features, yearly billing (save 17%)', 'جميع الميزات، فوترة سنوية (وفر 17%)', 499.99, 12,
'{"searches_per_day":999999,"max_favorites":999999,"history_days":999999,"max_alternatives":999999,"interactions":"all","export":true,"offline":true,"price_history":true,"advanced_filters":true,"priority_support":true}',
2, strftime('%s', 'now'), strftime('%s', 'now')),

('professional', 'Professional', 'احترافي', 'For healthcare professionals', 'للمحترفين في المجال الطبي', 99.99, 1,
'{"searches_per_day":999999,"max_favorites":999999,"history_days":999999,"max_alternatives":999999,"interactions":"extended","export":true,"offline":true,"price_history":true,"advanced_filters":true,"priority_support":true,"api_access":true,"patient_management":true,"dosage_calculator":true}',
3, strftime('%s', 'now'), strftime('%s', 'now'));

-- Add default admin user (username: admin, password: admin123)
-- Password hash for "admin123" using simple SHA-256 (replace with proper bcrypt in production)
INSERT OR IGNORE INTO admin_users (id, username, password_hash, email, role, permissions, created_at) VALUES
('admin-1', 'admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'admin@mediswitch.com', 'super_admin', '["all"]', strftime('%s', 'now'));
