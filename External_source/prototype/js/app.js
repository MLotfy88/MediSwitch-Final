document.addEventListener('DOMContentLoaded', function() {
    // ===== التنقل بين الشاشات =====
    function showScreen(screenId) {
        document.querySelectorAll('.screen').forEach(screen => {
            screen.classList.remove('active');
        });
        document.getElementById(screenId).classList.add('active');
        
        // تحديث القائمة السفلية
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        
        const activeNavItem = document.querySelector(`.nav-item[data-screen="${screenId}"]`);
        if (activeNavItem) {
            activeNavItem.classList.add('active');
        }
    }
    
    // ===== علامات التبويب =====
    document.querySelectorAll('.tab-button').forEach(button => {
        button.addEventListener('click', function() {
            const tabId = this.getAttribute('data-tab');
            
            // إزالة الصنف النشط من جميع الأزرار
            this.parentElement.querySelectorAll('.tab-button').forEach(btn => {
                btn.classList.remove('active');
            });
            
            // إضافة الصنف النشط للزر الحالي
            this.classList.add('active');
            
            // إلغاء تنشيط جميع محتويات التبويبات
            const tabContents = this.closest('.drug-info-tabs').querySelectorAll('.tab-content');
            tabContents.forEach(content => {
                content.classList.remove('active');
            });
            
            // تنشيط محتوى التبويب المحدد
            document.getElementById(tabId + '-tab').classList.add('active');
        });
    });
    
    // ===== شريط البحث =====
    const searchInput = document.getElementById('search-input');
    if (searchInput) {
        searchInput.addEventListener('focus', function() {
            showScreen('search-screen');
            document.getElementById('active-search-input').focus();
        });
    }
    
    const activeSearchInput = document.getElementById('active-search-input');
    if (activeSearchInput) {
        activeSearchInput.addEventListener('input', function() {
            // قم بتنفيذ البحث هنا
            const query = this.value.trim().toLowerCase();
            const searchResults = document.getElementById('search-results');
            
            // عرض كل العناصر إذا كان حقل البحث فارغًا
            if (query === '') {
                document.querySelectorAll('#search-results .search-result-item').forEach(item => {
                    item.style.display = 'flex';
                });
                return;
            }
            
            // إخفاء/إظهار العناصر بناءً على نص البحث
            document.querySelectorAll('#search-results .search-result-item').forEach(item => {
                const drugName = item.querySelector('.result-name').textContent.toLowerCase();
                if (drugName.includes(query)) {
                    item.style.display = 'flex';
                } else {
                    item.style.display = 'none';
                }
            });
        });
    }
    
    const clearSearchButton = document.getElementById('clear-search');
    if (clearSearchButton) {
        clearSearchButton.addEventListener('click', function() {
            const searchInput = document.getElementById('active-search-input');
            searchInput.value = '';
            
            // عرض كل نتائج البحث
            document.querySelectorAll('#search-results .search-result-item').forEach(item => {
                item.style.display = 'flex';
            });
        });
    }
    
    // ===== الفلترة =====
    const filterButton = document.querySelector('.filter-button');
    if (filterButton) {
        filterButton.addEventListener('click', function() {
            document.getElementById('filter-modal').classList.add('active');
        });
    }
    
    const closeFilterButton = document.querySelector('.close-filter');
    if (closeFilterButton) {
        closeFilterButton.addEventListener('click', function() {
            document.getElementById('filter-modal').classList.remove('active');
        });
    }
    
    // تحديث قيمة شريط السعر عند تحريكه
    const priceSlider = document.getElementById('price-slider');
    if (priceSlider) {
        priceSlider.addEventListener('input', function() {
            document.getElementById('price-value').textContent = this.value + ' جنيه';
        });
    }
    
    // اختيار رقائق التصفية
    document.querySelectorAll('.filter-chip').forEach(chip => {
        chip.addEventListener('click', function() {
            // إلغاء تنشيط جميع الرقائق في نفس المجموعة
            this.parentElement.querySelectorAll('.filter-chip').forEach(c => {
                c.classList.remove('active');
            });
            
            // تنشيط الرقاقة الحالية
            this.classList.add('active');
        });
    });
    
    // تطبيق الفلترة
    const applyFilterButton = document.querySelector('.apply-filter');
    if (applyFilterButton) {
        applyFilterButton.addEventListener('click', function() {
            // هنا يتم تطبيق معايير الفلترة على نتائج البحث
            
            // إغلاق نافذة الفلترة
            document.getElementById('filter-modal').classList.remove('active');
        });
    }
    
    // ===== عرض تفاصيل الدواء =====
    document.querySelectorAll('.drug-card, .search-result-item').forEach(card => {
        card.addEventListener('click', function() {
            showScreen('drug-details-screen');
            
            // يمكن هنا تعبئة بيانات الدواء بناءً على معرف البيانات
            const drugId = this.getAttribute('data-id');
            console.log(`عرض تفاصيل الدواء برقم: ${drugId}`);
        });
    });
    
    // ===== حساب الجرعات =====
    const calculateButton = document.querySelector('.calculate-button');
    if (calculateButton) {
        calculateButton.addEventListener('click', function() {
            const weight = document.getElementById('patient-weight').value;
            const age = document.getElementById('patient-age').value;
            
            // التحقق من إدخال الوزن والعمر
            if (!weight || !age) {
                alert('يرجى إدخال الوزن والعمر لحساب الجرعة');
                return;
            }
            
            // إظهار نتيجة الحساب
            document.getElementById('dosage-result').classList.add('active');
        });
    }
    
    // ===== زر فحص التفاعلات =====
    const interactionsCheckButton = document.querySelector('.interactions-check-button');
    if (interactionsCheckButton) {
        interactionsCheckButton.addEventListener('click', function() {
            showScreen('interactions-screen');
        });
    }
    
    // ===== أزرار الرجوع =====
    document.querySelectorAll('.back-button').forEach(button => {
        button.addEventListener('click', function() {
            showScreen('home-screen');
        });
    });
    
    // ===== إضافة/حذف الأدوية في شاشة التفاعلات =====
    // حذف دواء من قائمة الأدوية المختارة
    document.querySelectorAll('.remove-drug').forEach(button => {
        button.addEventListener('click', function(e) {
            e.stopPropagation(); // منع انتشار الحدث
            this.parentElement.remove();
        });
    });
    
    // ===== وضع اليل/النهار =====
    const darkModeToggle = document.getElementById('dark-mode-toggle');
    if (darkModeToggle) {
        darkModeToggle.addEventListener('change', function() {
            document.body.classList.toggle('dark-mode');
            
            // حفظ تفضيل المستخدم في التخزين المحلي
            if (document.body.classList.contains('dark-mode')) {
                localStorage.setItem('theme', 'dark');
            } else {
                localStorage.setItem('theme', 'light');
            }
        });
        
        // تعيين الوضع المحفوظ عند تحميل الصفحة
        if (localStorage.getItem('theme') === 'dark') {
            document.body.classList.add('dark-mode');
            darkModeToggle.checked = true;
        }
    }
    
    // ===== شريط التنقل السفلي =====
    document.querySelectorAll('.nav-item').forEach(item => {
        item.addEventListener('click', function() {
            const screenId = this.getAttribute('data-screen');
            showScreen(screenId);
        });
    });
    
    // ===== إضافة شريط التنقل السفلي ديناميكيًا إذا لم يكن موجودًا =====
    if (!document.querySelector('.bottom-nav')) {
        const bottomNav = document.createElement('div');
        bottomNav.className = 'bottom-nav';
        bottomNav.innerHTML = `
            <div class="nav-item active" data-screen="home-screen">
                <i class="fas fa-home"></i>
                <span>الرئيسية</span>
            </div>
            <div class="nav-item" data-screen="search-screen">
                <i class="fas fa-search"></i>
                <span>البحث</span>
            </div>
            <div class="nav-item" data-screen="calculator-screen">
                <i class="fas fa-calculator"></i>
                <span>حاسبة الجرعات</span>
            </div>
            <div class="nav-item" data-screen="interactions-screen">
                <i class="fas fa-exchange-alt"></i>
                <span>التفاعلات</span>
            </div>
            <div class="nav-item" data-screen="settings-screen">
                <i class="fas fa-cog"></i>
                <span>الإعدادات</span>
            </div>
        `;
        document.querySelector('.app-container').appendChild(bottomNav);
        
        // إضافة أحداث النقر للأزرار التي تم إنشاؤها حديثًا
        bottomNav.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', function() {
                const screenId = this.getAttribute('data-screen');
                showScreen(screenId);
            });
        });
    }
});
