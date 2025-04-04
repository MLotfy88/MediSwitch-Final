// بيانات الأدوية مستوحاة من ملف meds.csv
const medicinesData = [
    {
        id: 1,
        trade_name: "ابيمول 500مجم",
        arabic_name: "ابيمول 500مجم 20 قرص",
        price: 24,
        old_price: 13,
        active: "paracetamol(acetaminophen)",
        main_category: "anti_inflammatory",
        main_category_ar: "مضادات الالتهاب",
        category: "antipyretic.analgesic",
        category_ar: "خافض للحرارة ومسكن",
        company: "glaxo smithkline",
        dosage_form: "tablet",
        dosage_form_ar: "أقراص",
        description: "خافض للحرارة ومسكن للألم، يستخدم لعلاج الصداع والآلام الخفيفة إلى المتوسطة وخفض الحرارة.",
        last_price_update: "30/10/2024"
    },
    {
        id: 2,
        trade_name: "ابيمول اكسترا",
        arabic_name: "ابيمول اكسترا 500مجم 20 قرص",
        price: 28,
        old_price: 16,
        active: "caffeine+paracetamol",
        main_category: "anti_inflammatory",
        main_category_ar: "مضادات الالتهاب",
        category: "analgesic.antipyretic.headache",
        category_ar: "مسكن للألم وخافض للحرارة",
        company: "glaxo smithkline",
        dosage_form: "tablet",
        dosage_form_ar: "أقراص",
        description: "مسكن قوي للألم يحتوي على الباراسيتامول والكافيين، فعال في علاج الصداع والصداع النصفي والآلام المتوسطة.",
        last_price_update: "30/10/2024"
    },
    {
        id: 3,
        trade_name: "ابيمول 150مجم/5مل",
        arabic_name: "ابيمول 150مجم/5مل 125 مل شراب",
        price: 23,
        old_price: 20,
        active: "paracetamol(acetaminophen)",
        main_category: "anti_inflammatory",
        main_category_ar: "مضادات الالتهاب",
        category: "antipyretic.analgesic",
        category_ar: "خافض للحرارة ومسكن",
        company: "glaxo smithkline",
        dosage_form: "syrup",
        dosage_form_ar: "شراب",
        description: "شراب خافض للحرارة ومسكن للألم، مناسب للأطفال والرضع.",
        last_price_update: "28/10/2024"
    },
    {
        id: 4,
        trade_name: "كونجستال",
        arabic_name: "كونجستال 20 قرص",
        price: 40,
        old_price: 24,
        active: "pseudoephedrine+paracetamol+chlorpheniramine",
        main_category: "cold_respiratory",
        main_category_ar: "نزلات البرد والجهاز التنفسي",
        category: "cold drugs",
        category_ar: "أدوية البرد",
        company: "hikma",
        dosage_form: "tablet",
        dosage_form_ar: "أقراص",
        description: "يستخدم لعلاج أعراض نزلات البرد والإنفلونزا مثل سيلان الأنف، انسداد الأنف، العطس، الحمى، والصداع.",
        last_price_update: "18/09/2024"
    },
    {
        id: 5,
        trade_name: "كونجستال سيروب",
        arabic_name: "كونجستال شراب 120 مل",
        price: 32,
        old_price: 19.5,
        active: "pseudoephedrine+paracetamol+chlorpheniramine",
        main_category: "cold_respiratory",
        main_category_ar: "نزلات البرد والجهاز التنفسي",
        category: "cold drugs",
        category_ar: "أدوية البرد",
        company: "hikma",
        dosage_form: "syrup",
        dosage_form_ar: "شراب",
        description: "شراب لعلاج أعراض نزلات البرد والإنفلونزا، مناسب للأطفال والبالغين.",
        last_price_update: "04/07/2024"
    },
    {
        id: 6,
        trade_name: "بروفين 400مجم",
        arabic_name: "بروفين 400مجم 20 قرص",
        price: 35,
        old_price: 22,
        active: "ibuprofen",
        main_category: "anti_inflammatory",
        main_category_ar: "مضادات الالتهاب",
        category: "nsaid",
        category_ar: "مضاد التهاب غير ستيرويدي",
        company: "abbott",
        dosage_form: "tablet",
        dosage_form_ar: "أقراص",
        description: "مضاد للالتهاب ومسكن للألم وخافض للحرارة، يستخدم لعلاج آلام العضلات والمفاصل والصداع وآلام الدورة الشهرية.",
        last_price_update: "15/10/2024"
    },
    {
        id: 7,
        trade_name: "بروفين 600مجم",
        arabic_name: "بروفين 600مجم 20 قرص",
        price: 45,
        old_price: 30,
        active: "ibuprofen",
        main_category: "anti_inflammatory",
        main_category_ar: "مضادات الالتهاب",
        category: "nsaid",
        category_ar: "مضاد التهاب غير ستيرويدي",
        company: "abbott",
        dosage_form: "tablet",
        dosage_form_ar: "أقراص",
        description: "مضاد للالتهاب ومسكن قوي للألم، يستخدم لعلاج الآلام المتوسطة إلى الشديدة.",
        last_price_update: "15/10/2024"
    },
    {
        id: 8,
        trade_name: "فولتارين إيمولجيل",
        arabic_name: "فولتارين إيمولجيل 1% 50 جم",
        price: 75,
        old_price: 50,
        active: "diclofenac diethylamine",
        main_category: "pain_management",
        main_category_ar: "علاج الألم",
        category: "topical nsaid",
        category_ar: "مضاد التهاب موضعي",
        company: "novartis",
        dosage_form: "gel",
        dosage_form_ar: "جل",
        description: "جل موضعي لتخفيف الألم والالتهاب في العضلات والمفاصل، يستخدم لعلاج آلام الظهر والرقبة والتواء المفاصل.",
        last_price_update: "20/09/2024"
    },
    {
        id: 9,
        trade_name: "ديرموفيت",
        arabic_name: "ديرموفيت كريم 15 جم",
        price: 60,
        old_price: 40,
        active: "clobetasol propionate",
        main_category: "skin_care",
        main_category_ar: "العناية بالبشرة",
        category: "corticosteroid",
        category_ar: "كورتيكوستيرويد",
        company: "gsk",
        dosage_form: "cream",
        dosage_form_ar: "كريم",
        description: "كريم موضعي يحتوي على كورتيكوستيرويد قوي، يستخدم لعلاج الالتهابات الجلدية والأكزيما والصدفية.",
        last_price_update: "10/08/2024"
    },
    {
        id: 10,
        trade_name: "بيتاديرم",
        arabic_name: "بيتاديرم كريم 15 جم",
        price: 45,
        old_price: 30,
        active: "betamethasone",
        main_category: "skin_care",
        main_category_ar: "العناية بالبشرة",
        category: "corticosteroid",
        category_ar: "كورتيكوستيرويد",
        company: "minapharm",
        dosage_form: "cream",
        dosage_form_ar: "كريم",
        description: "كريم موضعي يحتوي على كورتيكوستيرويد، يستخدم لعلاج الالتهابات الجلدية والحكة والاحمرار.",
        last_price_update: "05/09/2024"
    },
    {
        id: 11,
        trade_name: "أوميز 20مجم",
        arabic_name: "أوميز 20مجم 14 كبسولة",
        price: 85,
        old_price: 60,
        active: "omeprazole",
        main_category: "digestive_system",
        main_category_ar: "الجهاز الهضمي",
        category: "proton pump inhibitor",
        category_ar: "مثبط مضخة البروتون",
        company: "astrazeneca",
        dosage_form: "capsule",
        dosage_form_ar: "كبسولة",
        description: "يستخدم لعلاج قرحة المعدة والاثني عشر وارتجاع المريء وحرقة المعدة.",
        last_price_update: "25/10/2024"
    },
    {
        id: 12,
        trade_name: "كلاريتين",
        arabic_name: "كلاريتين 10مجم 10 أقراص",
        price: 50,
        old_price: 35,
        active: "loratadine",
        main_category: "allergy",
        main_category_ar: "الحساسية",
        category: "antihistamine",
        category_ar: "مضاد للهيستامين",
        company: "schering-plough",
        dosage_form: "tablet",
        dosage_form_ar: "أقراص",
        description: "مضاد للهيستامين يستخدم لعلاج أعراض الحساسية مثل العطس وسيلان الأنف والحكة والطفح الجلدي.",
        last_price_update: "12/09/2024"
    }
];

// استخراج الفئات الرئيسية الفريدة
const uniqueMainCategories = [...new Set(medicinesData.map(med => med.main_category))];

// استخراج أشكال الدواء الفريدة
const uniqueDosageForms = [...new Set(medicinesData.map(med => med.dosage_form))];

// دالة للحصول على البدائل لدواء معين
function getAlternatives(drugId) {
    const drug = medicinesData.find(med => med.id === drugId);
    if (!drug) return [];
    
    // البحث عن الأدوية التي تحتوي على نفس المادة الفعالة
    return medicinesData.filter(med => 
        med.id !== drugId && 
        med.active === drug.active
    );
}

// دالة لحساب الجرعة بناءً على الوزن والعمر
function calculateDosage(drugId, weight, age) {
    const drug = medicinesData.find(med => med.id === drugId);
    if (!drug) return null;
    
    let dosage = "";
    
    // حساب الجرعة بناءً على المادة الفعالة ونوع الدواء
    if (drug.active.includes("paracetamol")) {
        // جرعة الباراسيتامول: 10-15 مجم/كجم كل 4-6 ساعات
        const minDose = Math.round(weight * 10);
        const maxDose = Math.round(weight * 15);
        
        if (drug.dosage_form === "tablet") {
            dosage = `للبالغين والأطفال فوق 12 سنة: قرص واحد (500 مجم) كل 4-6 ساعات حسب الحاجة، بحد أقصى 4 أقراص في اليوم.`;
            
            if (age < 12) {
                dosage = `للأطفال ${age} سنوات (${weight} كجم): ${minDose}-${maxDose} مجم كل 4-6 ساعات حسب الحاجة.`;
            }
        } else if (drug.dosage_form === "syrup") {
            // افتراض أن تركيز الشراب 120 مجم/5 مل
            const minMl = Math.round((minDose / 120) * 5);
            const maxMl = Math.round((maxDose / 120) * 5);
            dosage = `للأطفال ${age} سنوات (${weight} كجم): ${minMl}-${maxMl} مل كل 4-6 ساعات حسب الحاجة.`;
        }
    } else if (drug.active.includes("ibuprofen")) {
        // جرعة الإيبوبروفين: 5-10 مجم/كجم كل 6-8 ساعات
        const minDose = Math.round(weight * 5);
        const maxDose = Math.round(weight * 10);
        
        if (age >= 12) {
            dosage = `للبالغين والأطفال فوق 12 سنة: قرص واحد (${drug.trade_name.includes("600") ? "600" : "400"} مجم) كل 6-8 ساعات حسب الحاجة.`;
        } else {
            dosage = `للأطفال ${age} سنوات (${weight} كجم): ${minDose}-${maxDose} مجم كل 6-8 ساعات حسب الحاجة.`;
        }
    } else {
        dosage = "يرجى استشارة الطبيب أو الصيدلي لتحديد الجرعة المناسبة.";
    }
    
    return {
        drug: drug,
        dosage: dosage,
        warning: age < 2 ? "تحذير: يجب استشارة الطبيب قبل إعطاء أي دواء للأطفال أقل من سنتين." : ""
    };
}