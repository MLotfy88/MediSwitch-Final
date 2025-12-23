-- User Feedback Table
CREATE TABLE IF NOT EXISTS user_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT,
    name TEXT,
    email TEXT,
    subject TEXT,
    message TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, reviewed, resolved, ignored
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
