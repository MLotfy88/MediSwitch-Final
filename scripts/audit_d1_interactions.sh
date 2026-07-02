#!/bin/bash

export CLOUDFLARE_API_TOKEN=yy-vk8KC4yth3Cn2lpva1AgrP2kGMJrQQrGIUM1-

echo "==================================="
echo "D1 Interactions Database Audit"
echo "==================================="
echo ""

echo "📊 DRUG INTERACTIONS TABLE"
echo "-----------------------------------"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as total FROM drug_interactions;" --remote 2>/dev/null | grep -A1 '"total"' | tail -1
echo ""
echo "Column: ingredient1"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE ingredient1 IS NOT NULL AND ingredient1 != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: ingredient2"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE ingredient2 IS NOT NULL AND ingredient2 != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: severity"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE severity IS NOT NULL AND severity != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: effect"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE effect IS NOT NULL AND effect != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: management_text"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE management_text IS NOT NULL AND management_text != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: mechanism_text"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE mechanism_text IS NOT NULL AND mechanism_text != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: recommendation"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE recommendation IS NOT NULL AND recommendation != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: risk_level"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE risk_level IS NOT NULL AND risk_level != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: alternatives_a"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE alternatives_a IS NOT NULL AND alternatives_a != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: alternatives_b"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM drug_interactions WHERE alternatives_b IS NOT NULL AND alternatives_b != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""

echo ""
echo "📊 FOOD INTERACTIONS TABLE"
echo "-----------------------------------"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as total FROM food_interactions;" --remote 2>/dev/null | grep -A1 '"total"' | tail -1
echo ""
echo "Column: med_id"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM food_interactions WHERE med_id IS NOT NULL;" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: interaction"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM food_interactions WHERE interaction IS NOT NULL AND interaction != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: ingredient"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM food_interactions WHERE ingredient IS NOT NULL AND ingredient != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: severity"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM food_interactions WHERE severity IS NOT NULL AND severity != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: management_text"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM food_interactions WHERE management_text IS NOT NULL AND management_text != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""

echo ""
echo "📊 DISEASE INTERACTIONS TABLE"
echo "-----------------------------------"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as total FROM disease_interactions;" --remote 2>/dev/null | grep -A1 '"total"' | tail -1
echo ""
echo "Column: med_id"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM disease_interactions WHERE med_id IS NOT NULL;" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: disease_name"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM disease_interactions WHERE disease_name IS NOT NULL AND disease_name != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: interaction_text"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM disease_interactions WHERE interaction_text IS NOT NULL AND interaction_text != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: severity"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM disease_interactions WHERE severity IS NOT NULL AND severity != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""
echo "Column: reference_text"
npx wrangler d1 execute mediswitch-interactions --command "SELECT COUNT(*) as filled FROM disease_interactions WHERE reference_text IS NOT NULL AND reference_text != '';" --remote 2>/dev/null | grep -A1 '"filled"' | tail -1
echo ""

echo "==================================="
echo "Audit Complete!"
echo "==================================="
