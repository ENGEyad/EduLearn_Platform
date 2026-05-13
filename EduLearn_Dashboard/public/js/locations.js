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

function populateDropdown(selectElement, optionsKeyArray, currentValue = null, allowOther = true, choicesInstance = null) {
    const placeholder = selectElement.getAttribute("data-placeholder") || "Choose...";
    
    if (choicesInstance) {
        choicesInstance.clearChoices();
        let choices = [{
            value: '',
            label: placeholder,
            selected: !currentValue,
            disabled: true,
            placeholder: true
        }];

        let foundCurrent = false;
        if (optionsKeyArray && optionsKeyArray.length > 0) {
            optionsKeyArray.forEach(option => {
                let isSelected = (currentValue === option);
                if (isSelected) foundCurrent = true;
                choices.push({ value: option, label: option, selected: isSelected });
            });
        }

        if (allowOther) {
            let otherSelected = (!foundCurrent && currentValue && currentValue !== 'other');
            choices.push({ value: 'other', label: 'أخرى / Other', selected: otherSelected });
        }
        
        choicesInstance.setChoices(choices, 'value', 'label', true);
    } else {
        selectElement.innerHTML = `<option value="">${placeholder}</option>`;
        let foundCurrent = false;

        if (optionsKeyArray && optionsKeyArray.length > 0) {
            optionsKeyArray.forEach(option => {
                let isSelected = (currentValue === option) ? "selected" : "";
                if (currentValue === option) foundCurrent = true;
                selectElement.innerHTML += `<option value="${option}" ${isSelected}>${option}</option>`;
            });
        }
        
        if (allowOther) {
            let otherSelected = (!foundCurrent && currentValue && currentValue !== 'other') ? "selected" : "";
            selectElement.innerHTML += `<option value="other" ${otherSelected}>أخرى / Other</option>`;
        }
    }
}

function initDynamicLocations(countrySelector, citySelector, dirSelector, initialCountry = '', initialCity = '', initialDir = '') {
    if (typeof Choices === 'undefined') {
        console.error('Choices.js is not loaded. Please check the script inclusion.');
        return;
    }
    const defaultCountries = Object.keys(ARAB_LOCATIONS);
    
    // Initialize Choices instances
    const cChoices = new Choices(countrySelector, { searchEnabled: true, itemSelectText: '', position: 'bottom', shouldSort: false });
    const ciChoices = new Choices(citySelector, { searchEnabled: true, itemSelectText: '', position: 'bottom', shouldSort: false });
    const dChoices = new Choices(dirSelector, { searchEnabled: true, itemSelectText: '', position: 'bottom', shouldSort: false });

    const updateCities = () => {
        let selectedCountry = countrySelector.value;
        if (selectedCountry === 'other' || !selectedCountry || !ARAB_LOCATIONS[selectedCountry]) {
            populateDropdown(citySelector, [], initialCity, true, ciChoices);
        } else {
            let cities = Object.keys(ARAB_LOCATIONS[selectedCountry]);
            populateDropdown(citySelector, cities, initialCity, true, ciChoices);
        }
        updateDirectorates();
    };

    const updateDirectorates = () => {
        let selectedCountry = countrySelector.value;
        let selectedCity = citySelector.value;
        
        if (selectedCity === 'other' || !selectedCountry || !selectedCity || !ARAB_LOCATIONS[selectedCountry] || !ARAB_LOCATIONS[selectedCountry][selectedCity]) {
            populateDropdown(dirSelector, [], initialDir, true, dChoices);
        } else {
            let dirs = ARAB_LOCATIONS[selectedCountry][selectedCity];
            populateDropdown(dirSelector, dirs, initialDir, true, dChoices);
        }
    };

    async function askForValue(titleMsg) {
        if (typeof Swal !== 'undefined') {
            const { value: newVal } = await Swal.fire({
                title: titleMsg,
                input: 'text',
                background: '#1e293b',
                color: '#fff',
                confirmButtonColor: '#FF6600',
                inputPlaceholder: 'اكتب هنا...',
                showCancelButton: true,
                confirmButtonText: 'تأكيد',
                cancelButtonText: 'إلغاء',
                customClass: { popup: 'border border-primary rounded-4' }
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
                if (!ARAB_LOCATIONS[newVal]) ARAB_LOCATIONS[newVal] = {};
                cChoices.setChoices([{ value: newVal, label: newVal, selected: true }], 'value', 'label', false);
            } else {
                cChoices.setChoiceByValue('');
            }
        }
        initialCity = '';
        initialDir = '';
        updateCities();
    });

    citySelector.addEventListener('change', async () => {
        let val = citySelector.value;
        let cVal = countrySelector.value;
        if (val === 'other') {
            let newVal = await askForValue("الرجاء إدخال اسم المدينة الجديد");
            if (newVal && newVal.trim() !== "" && cVal && cVal !== 'other') {
                newVal = newVal.trim();
                if (!ARAB_LOCATIONS[cVal][newVal]) ARAB_LOCATIONS[cVal][newVal] = [];
                ciChoices.setChoices([{ value: newVal, label: newVal, selected: true }], 'value', 'label', false);
            } else {
                ciChoices.setChoiceByValue('');
            }
        }
        initialDir = '';
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
                if (!dirs.includes(newVal)) dirs.push(newVal);
                dChoices.setChoices([{ value: newVal, label: newVal, selected: true }], 'value', 'label', false);
            } else {
                dChoices.setChoiceByValue('');
            }
        }
    });

    populateDropdown(countrySelector, defaultCountries, initialCountry, true, cChoices);
    updateCities();
}
