-- Dosage Guidelines for Concentration-Specific Dosage
CREATE TABLE IF NOT EXISTS dosage_guidelines (
    id INTEGER PRIMARY KEY,
    active_ingredient TEXT,
    strength TEXT,
    standard_dose TEXT,
    max_dose TEXT,
    package_label TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_dosage_active ON dosage_guidelines(active_ingredient);
