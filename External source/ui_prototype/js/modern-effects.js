/**
 * ملف التأثيرات الحركية والتحسينات العصرية
 * يضيف تأثيرات حركية خفيفة وتحسينات بصرية للواجهة
 */

document.addEventListener('DOMContentLoaded', function() {
    // تهيئة التأثيرات الحركية
    initializeAnimations();
    
    // إضافة مستمعي الأحداث للتأثيرات التفاعلية
    setupInteractiveEffects();
    
    // تهيئة وضع الليل/النهار
    setupThemeToggle();
    
    // تحسين تجربة التمرير
    enhanceScrollExperience();
});

/**
 * تهيئة التأثيرات الحركية الأساسية
 */
function initializeAnimations() {
    // إضافة تأثير ظهور تدريجي للعناصر عند تحميل الصفحة
    const elementsToAnimate = [
        '.category-card',
        '.drug-card',
        '.section-header',
        '.user-profile',
        '.search-bar',
        '.interaction-card'
    ];
    
    elementsToAnimate.forEach((selector, index) => {
        const elements = document.querySelectorAll(selector);
        elements.forEach((el, i) => {
            el.style.opacity = '0';
            el.style.transform = 'translateY(20px)';
            setTimeout(() => {
                el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
                el.style.opacity = '1';
                el.style.transform = 'translateY(0)';
            }, 100 + (index * 50) + (i * 50));
        });
    });
    
    // إضافة تأثير نبض خفيف لبعض العناصر
    const pulsateElements = document.querySelectorAll('.category-icon, .drug-icon, .interaction-icon');
    pulsateElements.forEach(el => {
        el.classList.add('pulse');
    });
}

/**
 * إضافة مستمعي الأحداث للتأثيرات التفاعلية
 */
function setupInteractiveEffects() {
    // تأثير تحويم على بطاقات الأدوية
    const drugCards = document.querySelectorAll('.drug-card');
    drugCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
            this.style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.1), 0 4px 8px rgba(0, 0, 0, 0.04)';
            
            // تأثير على أيقونة الدواء
            const icon = this.querySelector('.drug-icon');
            if (icon) {
                icon.style.transform = 'scale(1.1)';
            }
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.08), 0 2px 4px rgba(0, 0, 0, 0.04)';
            
            // إعادة الأيقونة لحجمها الطبيعي
            const icon = this.querySelector('.drug-icon');
            if (icon) {
                icon.style.transform = 'scale(1)';
            }
        });
    });
    
    // تأثير تحويم على بطاقات الفئات
    const categoryCards = document.querySelectorAll('.category-card');
    categoryCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
            this.style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.1), 0 4px 8px rgba(0, 0, 0, 0.04)';
            
            // تأثير على أيقونة الفئة
            const icon = this.querySelector('.category-icon');
            if (icon) {
                icon.style.transform = 'scale(1.1)';
            }
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.08), 0 2px 4px rgba(0, 0, 0, 0.04)';
            
            // إعادة الأيقونة لحجمها الطبيعي
            const icon = this.querySelector('.category-icon');
            if (icon) {
                icon.style.transform = 'scale(1)';
            }
        });
    });
    
    // تأثير تحويم على أزرار التنقل السفلية
    const navItems = document.querySelectorAll('.nav-item');
    navItems.forEach(item => {
        item.addEventListener('mouseenter', function() {
            const icon = this.querySelector('i');
            if (icon) {
                icon.style.transform = 'translateY(-3px)';
            }
        });
        
        item.addEventListener('mouseleave', function() {
            const icon = this.querySelector('i');
            if (icon) {
                icon.style.transform = 'translateY(0)';
            }
        });
    });
    
    // تأثير تحويم على شريط البحث
    const searchBar = document.querySelector('.search-bar');
    if (searchBar) {
        searchBar.addEventListener('focus', function() {
            this.style.transform = 'translateY(-2px)';
            this.style.boxShadow = '0 6px 20px rgba(0, 0, 0, 0.15)';
        }, true);
        
        searchBar.addEventListener('blur', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = '0 4px 15px rgba(0, 0, 0, 0.1)';
        }, true);
    }
    
    // تأثير تحويم على بطاقات التفاعلات
    const interactionCards = document.querySelectorAll('.interaction-card');
    interactionCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px)';
            this.style.boxShadow = '0 8px 24px rgba(0, 0, 0, 0.1), 0 4px 8px rgba(0, 0, 0, 0.04)';
            
            // تأثير على أيقونة التفاعل
            const icon = this.querySelector('.interaction-icon');
            if (icon) {
                icon.style.transform = 'scale(1.1)';
            }
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0)';
            this.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.08), 0 2px 4px rgba(0, 0, 0, 0.04)';
            
            // إعادة الأيقونة لحجمها الطبيعي
            const icon = this.querySelector('.interaction-icon');
            if (icon) {
                icon.style.transform = 'scale(1)';
            }
        });
    });
}

/**
 * تهيئة زر تبديل وضع الليل/النهار
 */
function setupThemeToggle() {
    const themeToggle = document.querySelector('.theme-toggle');
    if (themeToggle) {
        themeToggle.addEventListener('click', function() {
            document.body.classList.toggle('dark-mode');
            
            // تغيير أيقونة الزر
            const icon = this.querySelector('i');
            if (icon) {
                if (document.body.classList.contains('dark-mode')) {
                    icon.className = 'fas fa-sun';
                    this.style.background = 'var(--dark-gradient-accent)';
                } else {
                    icon.className = 'fas fa-moon';
                    this.style.background = 'var(--gradient-primary)';
                }
            }
            
            // تأثير نبض عند النقر
            this.classList.add('pulse');
            setTimeout(() => {
                this.classList.remove('pulse');
            }, 1000);
            
            // حفظ الإعداد في التخزين المحلي
            localStorage.setItem('darkMode', document.body.classList.contains('dark-mode'));
        });
        
        // تحقق من الإعداد المحفوظ
        const savedDarkMode = localStorage.getItem('darkMode');
        if (savedDarkMode === 'true') {
            document.body.classList.add('dark-mode');
            const icon = themeToggle.querySelector('i');
            if (icon) {
                icon.className = 'fas fa-sun';
                themeToggle.style.background = 'var(--dark-gradient-accent)';
            }
        }
    }
}

/**
 * تحسين تجربة التمرير
 */
function enhanceScrollExperience() {
    // تمرير سلس للقوائم الأفقية
    const horizontalLists = document.querySelectorAll('.drugs-horizontal-list');
    horizontalLists.forEach(list => {
        // إضافة أزرار تمرير للقوائم الأفقية
        const container = list.parentElement;
        
        // إنشاء زر التمرير لليسار
        const scrollLeftBtn = document.createElement('button');
        scrollLeftBtn.className = 'scroll-btn scroll-left';
        scrollLeftBtn.innerHTML = '<i class="fas fa-chevron-right"></i>';
        scrollLeftBtn.style.display = 'none'; // إخفاء في البداية
        
        // إنشاء زر التمرير لليمين
        const scrollRightBtn = document.createElement('button');
        scrollRightBtn.className = 'scroll-btn scroll-right';
        scrollRightBtn.innerHTML = '<i class="fas fa-chevron-left"></i>';
        
        // إضافة الأزرار للحاوية
        container.style.position = 'relative';
        container.appendChild(scrollLeftBtn);
        container.appendChild(scrollRightBtn);
        
        // تنسيق الأزرار
        const btnStyle = {
            position: 'absolute',
            top: '50%',
            transform: 'translateY(-50%)',
            width: '30px',
            height: '30px',
            borderRadius: '50%',
            background: 'var(--primary-color)',
            color: 'white',
            border: 'none',
            boxShadow: '0 2px 5px rgba(0,0,0,0.2)',
            cursor: 'pointer',
            zIndex: '10',
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            transition: 'all 0.3s ease'
        };
        
        Object.assign(scrollLeftBtn.style, btnStyle);
        Object.assign(scrollRightBtn.style, btnStyle);
        
        scrollLeftBtn.style.left = '0';
        scrollRightBtn.style.right = '0';
        
        // إضافة مستمعي الأحداث للأزرار
        scrollLeftBtn.addEventListener('click', () => {
            list.scrollBy({ left: -200, behavior: 'smooth' });
        });
        
        scrollRightBtn.addEventListener('click', () => {
            list.scrollBy({ left: 200, behavior: 'smooth' });
        });
        
        // تحديث ظهور الأزرار عند التمرير
        list.addEventListener('scroll', () => {
            scrollLeftBtn.style.display = list.scrollLeft > 0 ? 'flex' : 'none';
            scrollRightBtn.style.display = 
                list.scrollLeft < (list.scrollWidth - list.clientWidth - 10) ? 'flex' : 'none';
        });
        
        // تحقق أولي من حالة التمرير
        setTimeout(() => {
            scrollLeftBtn.style.display = list.scrollLeft > 0 ? 'flex' : 'none';
            scrollRightBtn.style.display = 
                list.scrollWidth > list.clientWidth ? 'flex' : 'none';
        }, 500);
    });
    
    // تأثير ظهور تدريجي للعناصر عند التمرير إليها
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.1
    };
    
    const appearOnScroll = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (!entry.isIntersecting) return;
            
            entry.target.classList.add('fade-in');
            observer.unobserve(entry.target);
        });
    }, observerOptions);
    
    // العناصر التي ستظهر عند التمرير إليها
    const scrollElements = document.querySelectorAll('.category-card, .drug-card, .section-header, .interaction-card');
    scrollElements.forEach(el => {
        el.classList.add('initially-hidden');
        appearOnScroll.observe(el);
    });
}

/**
 * تحسين أيقونات التطبيق
 * استبدال الأيقونات الافتراضية بأيقونات أكثر حداثة
 */
function enhanceIcons() {
    // تحديث أيقونات الفئات
    const categoryIconMap = {
        'anti_inflammatory': 'fa-capsules',
        'pain_management': 'fa-head-side-virus',
        'cold_respiratory': 'fa-lungs',
        'skin_care': 'fa-hand-sparkles'
    };
    
    // تطبيق الأيقونات المحسنة على الفئات
    const categoryCards = document.querySelectorAll('.category-card');
    categoryCards.forEach(card => {
        const category = card.dataset.category;
        const iconElement = card.querySelector('.category-icon i');
        
        if (iconElement && categoryIconMap[category]) {
            iconElement.className = `fas ${categoryIconMap[category]}`;
        }
    });
    
    // تحسين أيقونات الأدوية حسب الفئة
    const drugCards = document.querySelectorAll('.drug-card');
    drugCards.forEach(card => {
        const drugId = card.dataset.id;
        const drug = medicinesData.find(d => d.id == drugId);
        
        if (drug) {
            const iconElement = card.querySelector('.drug-icon i');
            if (iconElement) {
                // تعيين أيقونة مناسبة حسب فئة الدواء
                switch(drug.main_category) {
                    case 'anti_inflammatory':
                        iconElement.className = 'fas fa-capsules';
                        break;
                    case 'pain_management':
                        iconElement.className = 'fas fa-head-side-virus';
                        break;
                    case 'cold_respiratory':
                        iconElement.className = 'fas fa-lungs';
                        break;
                    case 'skin_care':
                        iconElement.className = 'fas fa-hand-sparkles';
                        break;
                    default:
                        iconElement.className = 'fas fa-pills';
                }
            }
        }
    });
    
    // تحسين أيقونات شريط التنقل
    const navIcons = {
        'home-nav': 'fa-home',
        'search-nav': 'fa-search',
        'interactions-nav': 'fa-exchange-alt',
        'profile-nav': 'fa-user'
    };
    
    for (const [id, icon] of Object.entries(navIcons)) {
        const navItem = document.getElementById(id);
        if (navItem) {
            const iconElement = navItem.querySelector('i');
            if (iconElement) {
                iconElement.className = `fas ${icon}`;
            }
        }
    }
}

// استدعاء وظيفة تحسين الأيقونات عند تحميل البيانات
document.addEventListener('dataLoaded', enhanceIcons);

// إضافة أنماط CSS ديناميكية
function addDynamicStyles() {
    const styleElement = document.createElement('style');
    styleElement.textContent = `
        .initially-hidden {
            opacity: 0;
            transform: translateY(20px);
        }
        
        .fade-in {
            animation: fadeIn 0.5s ease forwards;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .scroll-btn:hover {
            background: var(--primary-dark) !important;
            transform: translateY(-50%) scale(1.1) !important;
        }
        
        .scroll-btn:active {
            transform: translateY(-50%) scale(0.95) !important;
        }
    `;
    
    document.head.appendChild(styleElement);
}

// استدعاء وظيفة إضافة الأنماط الديناميكية
document.addEventListener('DOMContentLoaded', addDynamicStyles);