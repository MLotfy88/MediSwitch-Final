#!/bin/bash
# دليل سريع لدفع الكود لجميع المستودعات

echo "🚀 دفع MediSwitch لجميع المستودعات"
echo "========================================"

# 1. إضافة جميع الملفات
echo ""
echo "📦 إضافة جميع الملفات..."
git add .

# 2. عرض الملفات المتغيرة
echo ""
echo "📋 الملفات المتغيرة:"
git status --short

# 3. Commit
echo ""
echo "💾 إنشاء commit..."
git commit -m "Complete Cloudflare Workers integration with auto-sync

✨ Features:
- Cloudflare Worker API with D1 Database (free 100%)
- GitHub Actions daily scraper (automated updates)
- Flutter SyncService for incremental sync
- 25,500 drugs with full enriched data (20 columns)

🔧 Technical Updates:
- Fixed priceLabel localization
- Added csv_to_json.py converter
- Updated sync_service.dart for Worker API
- Complete deployment documentation

📚 Documentation:
- COMPLETE_SETUP_GUIDE.md (comprehensive)
- CLOUDFLARE_DEPLOYMENT_GUIDE.md
- update_local_database.py script

🎯 Ready for production deployment!"

# 4. عرض المستودعات المرتبطة
echo ""
echo "🔗 المستودعات المرتبطة:"
git remote -v

# 5. السؤال عن الدفع
echo ""
read -p "هل تريد الدفع لجميع المستودعات؟ (y/n): " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    echo ""
    echo "⬆️  جاري الدفع..."
    
    # الدفع لكل remote
    for remote in $(git remote); do
        echo ""
        echo "📤 دفع إلى: $remote"
        git push $remote main || git push $remote master
    done
    
    echo ""
    echo "✅ تم الدفع بنجاح لجميع المستودعات!"
else
    echo ""
    echo "❌ تم الإلغاء"
fi

echo ""
echo "🎉 تم!"
