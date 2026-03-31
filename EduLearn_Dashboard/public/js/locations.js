const ARAB_LOCATIONS = {
    "مصر": {
        "القاهرة": ["إدارة شرق مدينة نصر", "إدارة غرب مدينة نصر", "إدارة المعادي", "إدارة مصر الجديدة", "إدارة النزهة"],
        "الجيزة": ["إدارة الدقي", "إدارة الهرم", "إدارة العجوزة", "إدارة 6 أكتوبر", "إدارة الشيخ زايد"],
        "الإسكندرية": ["إدارة شرق", "إدارة وسط", "إدارة العجمي", "إدارة المنتزه"]
    },
    "السعودية": {
        "الرياض": ["مكتب تعليم وسط الرياض", "مكتب تعليم شمال الرياض", "مكتب تعليم جنوب الرياض", "مكتب تعليم الروابي"],
        "جدة": ["مكتب تعليم وسط جدة", "مكتب تعليم شمال جدة", "مكتب تعليم جنوب جدة", "مكتب تعليم الصفا"],
        "مكة المكرمة": ["مكتب تعليم وسط مكة", "مكتب تعليم شمال مكة", "مكتب تعليم جنوب مكة"]
    },
    "الإمارات": {
        "أبوظبي": ["إدارة التفتيش المركزي", "إدارة العمليات المدرسية", "نطاق مدينة أبوظبي"],
        "دبي": ["منطقة دبي التعليمية", "ديرة", "بر دبي", "جميرا"],
        "الشارقة": ["منطقة الشارقة التعليمية", "الشارقة شرق", "الشارقة غرب"]
    },
    "اليمن": {
        "صنعاء": ["مديرية السبعين", "مديرية الوحدة", "مديرية التحرير", "مديرية معين", "مديرية شعوب", "مديرية آزال"],
        "عدن": ["مديرية صيرة", "مديرية خور مكسر", "مديرية المعلا", "مديرية التواهي", "مديرية المنصورة", "مديرية الشيخ عثمان", "مديرية دار سعد"],
        "تعز": ["مديرية المظفر", "مديرية القاهرة", "مديرية صالة"]
    },
    "الأردن": {
        "عمّان": ["قصبة عمّان", "لواء الجامعة", "لواء وادي السير", "لواء ماركا"],
        "إربد": ["قصبة إربد", "لواء بني كنانة", "لواء الرمثا"],
        "الزرقاء": ["قصبة الزرقاء", "لواء الرصيفة"]
    },
    "الكويت": {
        "العاصمة": ["منطقة العاصمة التعليمية"],
        "حولي": ["منطقة حولي التعليمية"],
        "الفروانية": ["منطقة الفروانية التعليمية"]
    },
    "عُمان": {
        "مسقط": ["المديرية العامة للتربية مسقط", "السيب", "مطرح", "بوشر"],
        "صلالة": ["المديرية العامة للتربية ظفار", "صلالة المركز"],
        "صحار": ["المديرية العامة للتربية شمال الباطنة", "صحار المركز"]
    }
};

function populateDropdown(selectElement, optionsKeyArray, currentValue = null, allowOther = true) {
    selectElement.innerHTML = '<option value="">' + selectElement.getAttribute("data-placeholder") + '</option>';
    let foundCurrent = false;

    if (optionsKeyArray && optionsKeyArray.length > 0) {
        optionsKeyArray.forEach(option => {
            let isSelected = (currentValue === option) ? "selected" : "";
            if (currentValue === option) foundCurrent = true;
            selectElement.innerHTML += `<option value="${option}" ${isSelected}>${option}</option>`;
        });
    }
    
    // Add "Other" if requested
    if (allowOther) {
        let otherSelected = (!foundCurrent && currentValue && currentValue !== 'other') ? "selected" : "";
        selectElement.innerHTML += `<option value="other" ${otherSelected}>أخرى / Other</option>`;
    }
}

function initDynamicLocations(countrySelector, citySelector, dirSelector, initialCountry = '', initialCity = '', initialDir = '') {
    const defaultCountries = Object.keys(ARAB_LOCATIONS);
    
    // 1. Setup countries
    populateDropdown(countrySelector, defaultCountries, initialCountry);

    const updateCities = () => {
        let selectedCountry = countrySelector.value;
        if (selectedCountry === 'other' || !selectedCountry || !ARAB_LOCATIONS[selectedCountry]) {
            populateDropdown(citySelector, [], initialCity);
        } else {
            let cities = Object.keys(ARAB_LOCATIONS[selectedCountry]);
            populateDropdown(citySelector, cities, initialCity);
        }
        updateDirectorates();
    };

    const updateDirectorates = () => {
        let selectedCountry = countrySelector.value;
        let selectedCity = citySelector.value;
        
        if (selectedCity === 'other' || !selectedCountry || !selectedCity || !ARAB_LOCATIONS[selectedCountry] || !ARAB_LOCATIONS[selectedCountry][selectedCity]) {
            populateDropdown(dirSelector, [], initialDir);
        } else {
            let dirs = ARAB_LOCATIONS[selectedCountry][selectedCity];
            populateDropdown(dirSelector, dirs, initialDir);
        }
        
        // After populating, trigger 'change' manually so the "Other" dynamic input logic (if any) re-assesses visibility.
        if (typeof Event !== 'undefined') {
            citySelector.dispatchEvent(new Event('change'));
            dirSelector.dispatchEvent(new Event('change'));
        }
    };

    async function askForValue(titleMsg) {
        if (typeof Swal !== 'undefined') {
            const { value: newVal } = await Swal.fire({
                title: titleMsg,
                input: 'text',
                background: '#1e293b',
                color: '#fff',
                confirmButtonColor: '#6366f1',
                inputPlaceholder: 'اكتب هنا...',
                showCancelButton: true,
                confirmButtonText: 'تأكيد',
                cancelButtonText: 'إلغاء',
                customClass: {
                    popup: 'border border-primary'
                }
            });
            return newVal;
        } else {
            return prompt(titleMsg);
        }
    }

    countrySelector.addEventListener('change', async () => {
        let val = countrySelector.value;
        if (val === 'other') {
            let newVal = await askForValue("الرجاء إدخال اسم الدولة الجديد");
            if (newVal && newVal.trim() !== "") {
                newVal = newVal.trim();
                if (!ARAB_LOCATIONS[newVal]) {
                    ARAB_LOCATIONS[newVal] = {}; // Register new country
                }
                // Append and select
                let opt = document.createElement('option');
                opt.value = newVal;
                opt.text = newVal;
                countrySelector.add(opt, countrySelector.options[countrySelector.selectedIndex]);
                countrySelector.value = newVal;
                countrySelector.style.backgroundColor = '#e0f2fe'; // change color
                countrySelector.style.color = '#0369a1';
            } else {
                countrySelector.value = ''; // cancel
                countrySelector.style.backgroundColor = '';
                countrySelector.style.color = '';
            }
        } else {
            countrySelector.style.backgroundColor = '';
            countrySelector.style.color = '';
        }

        initialCity = ''; // Reset on change
        initialDir = '';  // Reset on change
        updateCities();
    });

    citySelector.addEventListener('change', async () => {
        let val = citySelector.value;
        let cVal = countrySelector.value;
        if (val === 'other') {
            let newVal = await askForValue("الرجاء إدخال اسم المدينة الجديد");
            if (newVal && newVal.trim() !== "" && cVal && cVal !== 'other') {
                newVal = newVal.trim();
                if (!ARAB_LOCATIONS[cVal][newVal]) {
                    ARAB_LOCATIONS[cVal][newVal] = []; // Register new city
                }
                let opt = document.createElement('option');
                opt.value = newVal;
                opt.text = newVal;
                citySelector.add(opt, citySelector.options[citySelector.selectedIndex]);
                citySelector.value = newVal;
                citySelector.style.backgroundColor = '#e0f2fe';
                citySelector.style.color = '#0369a1';
            } else {
                citySelector.value = '';
                citySelector.style.backgroundColor = '';
                citySelector.style.color = '';
            }
        } else {
            citySelector.style.backgroundColor = '';
            citySelector.style.color = '';
        }

        initialDir = ''; // Reset on change
        updateDirectorates();
    });

    dirSelector.addEventListener('change', async () => {
        let val = dirSelector.value;
        let cVal = countrySelector.value;
        let ciVal = citySelector.value;
        if (val === 'other') {
            let newVal = await askForValue("الرجاء إدخال اسم المديرية الجديد");
            if (newVal && newVal.trim() !== "" && cVal && ciVal && cVal !== 'other' && ciVal !== 'other') {
                newVal = newVal.trim();
                let dirs = ARAB_LOCATIONS[cVal][ciVal];
                if (!dirs.includes(newVal)) {
                    dirs.push(newVal); // Register new directorate
                }
                let opt = document.createElement('option');
                opt.value = newVal;
                opt.text = newVal;
                dirSelector.add(opt, dirSelector.options[dirSelector.selectedIndex]);
                dirSelector.value = newVal;
                dirSelector.style.backgroundColor = '#e0f2fe';
                dirSelector.style.color = '#0369a1';
            } else {
                dirSelector.value = '';
                dirSelector.style.backgroundColor = '';
                dirSelector.style.color = '';
            }
        } else {
            dirSelector.style.backgroundColor = '';
            dirSelector.style.color = '';
        }
    });

    // Run initial population
    updateCities();
}
