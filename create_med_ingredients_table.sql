-- Create med_ingredients table in mediswitch-interactions database
CREATE TABLE IF NOT EXISTS med_ingredients (
  med_id INTEGER NOT NULL,
  ingredient TEXT NOT NULL,
  updated_at INTEGER DEFAULT 0,
  PRIMARY KEY (med_id, ingredient)
);

CREATE INDEX IF NOT EXISTS idx_med_ingredients_med ON med_ingredients(med_id);
CREATE INDEX IF NOT EXISTS idx_med_ingredients_ing ON med_ingredients(ingredient);
