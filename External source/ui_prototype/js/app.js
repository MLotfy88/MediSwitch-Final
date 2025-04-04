// تهيئة التطبيق عند تحميل الصفحة
document.addEventListener('DOMContentLoaded', function() {
    // تهيئة البيانات والعناصر
    initializeApp();
    
    // إضافة مستمعي الأحداث
    setupEventListeners();
});

// تهيئة التطبيق
function initializeApp() {
    // عرض الأدوية المحدثة مؤخرًا
    displayRecentlyUpdatedDrugs();
    
    // عرض الأدوية الأكثر بحثًا
    displayPopularDrugs();
    
    // تهيئة رقائق الفئات في نافذة الفلترة
    populateCategoryChips();
    
    // تهيئة رقائق أشكال الدواء في نافذة الفلترة
    populateDosageFormChips();
}

// إضافة مستمعي الأحداث
function setupEventListeners() {
    // التنقل بين الشاشات عبر شريط التنقل السفلي
    setupBottomNavigation();
    
    // مستمعي أحداث البحث
    setupSearchListeners();
    
    // مستمعي أحداث الفلترة
    setupFilterListeners();
    
    // مستمعي أحداث تفاصيل الدواء
    setupDrugDetailsListeners();
    
    // مستمعي أحداث علامات التبويب في تفاصيل الدواء
    setupTabsListeners();
    
    // مستمعي أحداث حاسبة الجرعات
    setupDoseCalculatorListeners();
    
    // مستمعي أحداث الفئات
    setupCategoryListeners();
}

// عرض الأدوية المحدثة مؤخرًا
function displayRecentlyUpdatedDrugs() {
    const drugsContainer = document.getElementById('recent-drugs-list');
    drugsContainer.innerHTML = '';
    
    // ترتيب الأدوية حسب تاريخ التحديث (الأحدث أولاً)
    const sortedDrugs = [...medicinesData].sort((a, b) => {
        const dateA = new Date(a.last_price_update.split('/').reverse().join('-'));
        const dateB = new Date(b.last_price_update.split('/').reverse().join('-'));
        return dateB - dateA;
    });
    
    // عرض أول 5 أدوية محدثة
    const recentDrugs = sortedDrugs.slice(0, 5);
    
    recentDrugs.forEach(drug => {
        drugsContainer.appendChild(createDrugCard(drug));
    });
}

// عرض الأدوية الأكثر بحثًا (محاكاة)
function displayPopularDrugs() {
    const drugsContainer = document.getElementById('popular-drugs-list');
    drugsContainer.innerHTML = '';
    
    // محاكاة الأدوية الأكثر بحثًا (في تطبيق حقيقي، ستكون هذه البيانات مستندة إلى إحصائيات البحث)
    const popularDrugIds = [1, 6, 4, 11, 8];
    const popularDrugs = popularDrugIds.map(id => medicinesData.find(drug => drug.id === id));
    
    popularDrugs.forEach(drug => {
        drugsContainer.appendChild(createDrugCard(drug));
    });
}

// إنشاء بطاقة دواء
function createDrugCard(drug) {
    const drugCard = document.createElement('div');
    drugCard.className = 'drug-card';
    drugCard.dataset.id = drug.id;
    
    drugCard.innerHTML = `
        <div class="drug-icon">
            <i class="fas fa-pills"></i>
        </div>
        <div class="drug-name">${drug.arabic_name}</div>
        <div class="drug-active">${drug.active}</div>
        <div class="drug-price">
            ${drug.price} <span class="currency">جنيه</span>
        </div>
    `;
    
    // إضافة مستمع حدث النقر لعرض تفاصيل الدواء
    drugCard.addEventListener('click', function() {
        showDrugDetails(drug.id);
    });
    
    return drugCard;
}

// تهيئة رقائق الفئات في نافذة الفلترة
function populateCategoryChips() {
    const categoryChipsContainer = document.getElementById('main-category-chips');
    categoryChipsContainer.innerHTML = '';
    
    // إضافة رقاقة "الكل"
    const allChip = document.createElement('div');
    allChip.className = 'filter-chip active';
    allChip.dataset.category = 'all';
    allChip.textContent = 'الكل';
    categoryChipsContainer.appendChild(allChip);
    
    // إضافة رقائق الفئات الرئيسية
    uniqueMainCategories.forEach(category => {
        const chip = document.createElement('div');
        chip.className = 'filter-chip';
        chip.dataset.category = category;
        
        // الحصول على الاسم العربي للفئة
        const arabicName = medicinesData.find(med => med.main_category === category)?.main_category_ar || category;
        chip.textContent = arabicName;
        
        categoryChipsContainer.appendChild(chip);
    });
    
    // إضافة مستمعي أحداث النقر على الرقائق
    const filterChips = categoryChipsContainer.querySelectorAll('.filter-chip');
    filterChips.forEach(chip => {
        chip.addEventListener('click', function() {
            // إزالة الفئة النشطة من جميع الرقائق
            filterChips.forEach(c => c.classList.remove('active'));
            // تعيين الرقاقة الحالية كنشطة
            this.classList.add('active');
        });
    });
}

// تهيئة رقائق أشكال الدواء في نافذة الفلترة
function populateDosageFormChips() {
    const dosageFormChipsContainer = document.getElementById('dosage-form-chips');
    dosageFormChipsContainer.innerHTML = '';
    
    // إضافة رقاقة "الكل"
    const allChip = document.createElement('div');
    allChip.className = 'filter-chip active';
    allChip.dataset.form = 'all';
    allChip.textContent = 'الكل';
    dosageFormChipsContainer.appendChild(allChip);
    
    // إضافة رقائق أشكال الدواء
    uniqueDosageForms.forEach(form => {
        const chip = document.createElement('div');
        chip.className = 'filter-chip';
        chip.dataset.form = form;
        
        // الحصول على الاسم العربي لشكل الدواء
        const arabicName = medicinesData.find(med => med.dosage_form === form)?.dosage_form_ar || form;
        chip.textContent = arabicName;
        
        dosageFormChipsContainer.appendChild(chip);
    });
    
    // إضافة مستمعي أحداث النقر على الرقائق
    const filterChips = dosageFormChipsContainer.querySelectorAll('.filter-chip');
    filterChips.forEach(chip => {
        chip.addEventListener('click', function() {
            // إزالة الفئة النشطة من جميع الرقائق
            filterChips.forEach(c => c.classList.remove('active'));
            // تعيين الرقاقة الحالية كنشطة
            this.classList.add('active');
        });
    });
}

// إعداد التنقل بين الشاشات عبر شريط التنقل السفلي
function setupBottomNavigation() {
    const navItems = document.querySelectorAll('.nav-item');
    const screens = document.querySelectorAll('.screen');
    
    navItems.forEach(item => {
        item.addEventListener('click', function() {
            const targetScreenId = this.dataset.screen;
            
            // إخفاء جميع الشاشات
            screens.forEach(screen => {
                screen.classList.remove('active');
            });
            
            // عرض الشاشة المستهدفة
            document.getElementById(targetScreenId).classList.add('active');
            
            // تحديث حالة عناصر التنقل
            navItems.forEach(navItem => {
                navItem.classList.remove('active');
            });
            this.classList.add('active');
        });
    });
}

// إعداد مستمعي أحداث البحث
function setupSearchListeners() {
    // مربع البحث في الشاشة الرئيسية
    const searchInput = document.getElementById('search-input');
    searchInput.addEventListener('click', function() {
        // الانتقال إلى شاشة البحث
        document.getElementById('home-screen').classList.remove('active');
        document.getElementById('search-screen').classList.add('active');
        
        // تحديث حالة عناصر التنقل
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector('.nav-item[data-screen="search-screen"]').classList.add('active');
        
        // تركيز مربع البحث النشط
        document.getElementById('active-search-input').focus();
    });
    
    // زر الرجوع في شاشة البحث
    const backButton = document.querySelector('#search-screen .back-button');
    backButton.addEventListener('click', function() {
        // الرجوع إلى الشاشة الرئيسية
        document.getElementById('search-screen').classList.remove('active');
        document.getElementById('home-screen').classList.add('active');
        
        // تحديث حالة عناصر التنقل
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector('.nav-item[data-screen="home-screen"]').classList.add('active');
    });
    
    // مربع البحث النشط في شاشة البحث
    const activeSearchInput = document.getElementById('active-search-input');
    activeSearchInput.addEventListener('input', function() {
        const query = this.value.trim().toLowerCase();
        searchDrugs(query);
    });
    
    // زر مسح البحث
    const clearSearchButton = document.getElementById('clear-search');
    clearSearchButton.addEventListener('click', function() {
        activeSearchInput.value = '';
        searchDrugs('');
    });
}

// البحث عن الأدوية
function searchDrugs(query) {
    const searchResults = document.getElementById('search-results');
    searchResults.innerHTML = '';
    
    if (query === '') {
        searchResults.innerHTML = '<div class="empty-results">ابدأ البحث عن دواء...</div>';
        return;
    }
    
    // البحث في الأدوية
    const results = medicinesData.filter(drug => 
        drug.trade_name.toLowerCase().includes(query) ||
        drug.arabic_name.toLowerCase().includes(query) ||
        drug.active.toLowerCase().includes(query)
    );
    
    if (results.length === 0) {
        searchResults.innerHTML = '<div class="empty-results">لا توجد نتائج مطابقة للبحث</div>';
        return;
    }
    
    // عرض نتائج البحث
    results.forEach(drug => {
        const resultItem = document.createElement('div');
        resultItem.className = 'search-result-item';
        resultItem.dataset.id = drug.id;
        
        resultItem.innerHTML = `
            <div class="result-icon">
                <i class="fas fa-pills"></i>
            </div>
            <div class="result-info">
                <div class="result-name">${drug.arabic_name}</div>
                <div class="result-details">
                    <span class="result-category">${drug.main_category_ar}</span>
                    <span class="result-form">${drug.dosage_form_ar}</span>
                </div>
            </div>
            <div class="result-price">${drug.price} جنيه</div>
        `;
        
        // إضافة مستمع حدث النقر لعرض تفاصيل الدواء
        resultItem.addEventListener('click', function() {
            showDrugDetails(drug.id);
        });
        
        searchResults.appendChild(resultItem);
    });
}

// إعداد مستمعي أحداث الفلترة
function setupFilterListeners() {
    // زر الفلترة
    const filterButton = document.querySelector('.filter-button');
    const filterModal = document.getElementById('filter-modal');
    
    filterButton.addEventListener('click', function() {
        filterModal.classList.add('active');
    });
    
    // زر إغلاق نافذة الفلترة
    const closeFilterButton = document.querySelector('.close-filter');
    closeFilterButton.addEventListener('click', function() {
        filterModal.classList.remove('active');
    });
    
    // شريط تمرير السعر
    const priceSlider = document.getElementById('price-slider');
    const priceValue = document.getElementById('price-value');
    
    priceSlider.addEventListener('input', function() {
        priceValue.textContent = `${this.value} جنيه`;
    });
    
    // زر إعادة ضبط الفلترة
    const resetFilterButton = document.querySelector('.reset-filter');
    resetFilterButton.addEventListener('click', function() {
        // إعادة تعيين رقائق الفئات
        document.querySelectorAll('#main-category-chips .filter-chip').forEach((chip, index) => {
            chip.classList.toggle('active', index === 0);
        });
        
        // إعادة تعيين رقائق أشكال الدواء
        document.querySelectorAll('#dosage-form-chips .filter-chip').forEach((chip, index) => {
            chip.classList.toggle('active', index === 0);
        });
        
        // إعادة تعيين شريط تمرير السعر
        priceSlider.value = 500;
        priceValue.textContent = '500 جنيه';
    });
    
    // زر تطبيق الفلترة
    const applyFilterButton = document.querySelector('.apply-filter');
    applyFilterButton.addEventListener('click', function() {
        // الحصول على الفئة المحددة
        const selectedCategory = document.querySelector('#main-category-chips .filter-chip.active').dataset.category;
        
        // الحصول على شكل الدواء المحدد
        const selectedForm = document.querySelector('#dosage-form-chips .filter-chip.active').dataset.form;
        
        // الحصول على السعر الأقصى
        const maxPrice = parseInt(priceSlider.value);
        
        // تطبيق الفلترة
        applyFilters(selectedCategory, selectedForm, maxPrice);
        
        // إغلاق نافذة الفلترة
        filterModal.classList.remove('active');
    });
}

// تطبيق الفلترة على نتائج البحث
function applyFilters(category, form, maxPrice) {
    const searchResults = document.getElementById('search-results');
    searchResults.innerHTML = '';
    
    // فلترة الأدوية
    let filteredDrugs = [...medicinesData];
    
    // فلترة حسب الفئة
    if (category !== 'all') {
        filteredDrugs = filteredDrugs.filter(drug => drug.main_category === category);
    }
    
    // فلترة حسب شكل الدواء
    if (form !== 'all') {
        filteredDrugs = filteredDrugs.filter(drug => drug.dosage_form === form);
    }
    
    // فلترة حسب السعر
    filteredDrugs = filteredDrugs.filter(drug => drug.price <= maxPrice);
    
    if (filteredDrugs.length === 0) {
        searchResults.innerHTML = '<div class="empty-results">لا توجد نتائج مطابقة للفلترة</div>';
        return;
    }
    
    // عرض نتائج الفلترة
    filteredDrugs.forEach(drug => {
        const resultItem = document.createElement('div');
        resultItem.className = 'search-result-item';
        resultItem.dataset.id = drug.id;
        
        resultItem.innerHTML = `
            <div class="result-icon">
                <i class="fas fa-pills"></i>
            </div>
            <div class="result-info">
                <div class="result-name">${drug.arabic_name}</div>
                <div class="result-details">
                    <span class="result-category">${drug.main_category_ar}</span>
                    <span class="result-form">${drug.dosage_form_ar}</span>
                </div>
            </div>
            <div class="result-price">${drug.price} جنيه</div>
        `;
        
        // إضافة مستمع حدث النقر لعرض تفاصيل الدواء
        resultItem.addEventListener('click', function() {
            showDrugDetails(drug.id);
        });
        
        searchResults.appendChild(resultItem);
    });
}

// إعداد مستمعي أحداث تفاصيل الدواء
function setupDrugDetailsListeners() {
    // زر الرجوع في شاشة تفاصيل الدواء
    const backButton = document.querySelector('#drug-details-screen .back-button');
    backButton.addEventListener('click', function() {
        // الرجوع إلى الشاشة السابقة
        document.getElementById('drug-details-screen').classList.remove('active');
        
        // التحقق من الشاشة النشطة قبل عرض تفاصيل الدواء
        if (document.getElementById('search-screen').classList.contains('was-active')) {
            document.getElementById('search-screen').classList.add('active');
            document.getElementById('search-screen').classList.remove('was-active');
        } else {
            document.getElementById('home-screen').classList.add('active');
        }
    });
    
    // زر المفضلة
    const favoriteButton = document.querySelector('.favorite-button');
    favoriteButton.addEventListener('click', function() {
        this.querySelector('i').classList.toggle('far');
        this.querySelector('i').classList.toggle('fas');
    });
}

// إعداد مستمعي أحداث علامات التبويب في تفاصيل الدواء
function setupTabsListeners() {
    const tabButtons = document.querySelectorAll('.tab-button');
    const tabContents = document.querySelectorAll('.tab-content');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', function() {
            const tabId = this.dataset.tab;
            
            // إزالة الفئة النشطة من جميع الأزرار والمحتويات
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));
            
            // تعيين الزر والمحتوى الحاليين كنشطين
            this.classList.add('active');
            document.getElementById(`${tabId}-tab`).classList.add('active');
        });
    });
}

// إعداد مستمعي أحداث حاسبة الجرعات
function setupDoseCalculatorListeners() {
    const calculateButton = document.querySelector('.calculate-button');
    calculateButton.addEventListener('click', function() {
        const weight = parseFloat(document.getElementById('patient-weight').value);
        const age = parseInt(document.getElementById('patient-age').value);
        
        if (isNaN(weight) || isNaN(age)) {
            alert('يرجى إدخال الوزن والعمر بشكل صحيح');
            return;
        }
        
        // الحصول على معرف الدواء الحالي
        const drugId = parseInt(document.querySelector('#drug-details-screen').dataset.drugId);
        
        // حساب الجرعة
        const result = calculateDosage(drugId, weight, age);
        
        if (result) {
            const resultElement = document.getElementById('dosage-result');
            resultElement.innerHTML = `
                <h4>الجرعة الموصى بها:</h4>
                <p>${result.dosage}</p>
                ${result.warning ? `<p class="warning">${result.warning}</p>` : ''}
            `;
            resultElement.classList.add('active');
        }
    });
}

// إعداد مستمعي أحداث الفئات
function setupCategoryListeners() {
    const categoryCards = document.querySelectorAll('.category-card');
    
    categoryCards.forEach(card => {
        card.addEventListener('click', function() {
            const category = this.dataset.category;
            
            // الانتقال إلى شاشة البحث
            document.getElementById('home-screen').classList.remove('active');
            document.getElementById('search-screen').classList.add('active');
            
            // تحديث حالة عناصر التنقل
            document.querySelectorAll('.nav-item').forEach(item => {
                item.classList.remove('active');
            });
            document.querySelector('.nav-item[data-screen="search-screen"]').classList.add('active');
            
            // تطبيق الفلترة حسب الفئة
            applyFilters(category, 'all', 1000);
        });
    });
}

// عرض تفاصيل الدواء
function showDrugDetails(drugId) {
    const drug = medicinesData.find(med => med.id === parseInt(drugId));
    if (!drug) return;
    
    // تخزين معرف الدواء في شاشة التفاصيل
    document.querySelector('#drug-details-screen').dataset.drugId = drugId;
    
    // تعيين معلومات الدواء
    document.getElementById('drug-name').textContent = drug.arabic_name;
    document.getElementById('drug-active').textContent = drug.active;
    document.getElementById('drug-price').textContent = drug.price;
    document.getElementById('drug-old-price').textContent = drug.old_price;
    document.getElementById('drug-company').textContent = drug.company;
    document.getElementById('drug-category').textContent = drug.category_ar || drug.category;
    document.getElementById('drug-form').textContent = drug.dosage_form_ar;
    document.getElementById('drug-description').textContent = drug.description;
    
    // حساب نسبة التغير في السعر
    const priceChange = Math.round(((drug.price - drug.old_price) / drug.old_price) * 100);
    const priceChangeElement = document.getElementById('price-change-percentage');
    priceChangeElement.textContent = `${priceChange > 0 ? '+' : ''}${priceChange}%`;
    priceChangeElement.parentElement.classList.toggle('decrease', priceChange < 0);
    
    // عرض البدائل
    displayAlternatives(drugId);
    
    // تحديد الشاشة النشطة قبل عرض تفاصيل الدواء
    if (document.getElementById('search-screen').classList.contains('active')) {
        document.getElementById('search-screen').classList.remove('active');
        document.getElementById('search-screen').classList.add('was-active');
    } else {
        document.getElementById('home-screen').classList.remove('active');
    }
    
    // عرض شاشة تفاصيل الدواء
    document.getElementById('drug-details-screen').classList.add('active');
    
    // إعادة تعيين علامات التبويب
    document.querySelectorAll('.tab-button').forEach((button, index) => {
        button.classList.toggle('active', index === 0);
    });
    document.querySelectorAll('.tab-content').forEach((content, index) => {
        content.classList.toggle('active', index === 0);
    });
    
    // إعادة تعيين حاسبة الجرعات
    document.getElementById('patient-weight').value = '';
    document.getElementById('patient-age').value = '';
    document.getElementById('dosage-result').classList.remove('active');
}

// عرض البدائل
function displayAlternatives(drugId) {
    const alternativesList = document.getElementById('alternatives-list');
    alternativesList.innerHTML = '';
    
    const alternatives = getAlternatives(parseInt(drugId));
    
    if (alternatives.length === 0) {
        alternativesList.innerHTML = '<div class="empty-results">لا توجد بدائل متاحة</div>';
        return;
    }
    
    alternatives.forEach(drug => {
        const alternativeItem = document.createElement('div');
        alternativeItem.className = 'alternative-item';
        alternativeItem.dataset.id = drug.id;
        
        alternativeItem.innerHTML = `
            <div class="alternative-icon">
                <i class="fas fa-pills"></i>
            </div>
            <div class="alternative-info">
                <div class="alternative-name">${drug.arabic_name}</div>
                <div class="alternative-active">${drug.active}</div>
            </div>
            <div class="alternative-price">${drug.price} جنيه</div>
        `;
        
        // إضافة مستمع حدث النقر لعرض تفاصيل البديل
        alternativeItem.addEventListener('click', function() {
            showDrugDetails(drug.id);
        });
        
        alternativesList.appendChild(alternativeItem);
    });
}