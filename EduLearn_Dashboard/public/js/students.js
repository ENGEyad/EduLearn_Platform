document.addEventListener('DOMContentLoaded', () => {
  console.log('Students JS: Initializing...');
  const ROUTES = window.STUDENTS_ROUTES || {};
  const getListUrl = ROUTES.list || '/students/list';
  const getStoreUrl = ROUTES.store || '/students';
  const getUpdateUrl = ROUTES.update || ((id) => `/students/${id}`);
  const getDeleteUrl = ROUTES.destroy || ((id) => `/students/${id}`);
  const getImportUrl = ROUTES.import || '/students/import';

  const STORAGE_BASE_URL = window.STORAGE_BASE_URL || '/storage';

  const studentsTableBody = document.querySelector('#studentsTable tbody');
  const studentSearch = document.getElementById('studentSearch');
  const gradeFilter = document.getElementById('gradeFilter');

  const studentsListView = document.getElementById('studentsListView');
  const studentFormView = document.getElementById('studentFormView');
  const openStudentFormBtn = document.getElementById('openStudentFormBtn');
  const backToStudentsBtn = document.getElementById('backToStudentsBtn');
  const cancelStudentBtn = document.getElementById('cancelStudentBtn');
  const studentSavedAlert = document.getElementById('studentSavedAlert');
  const formTitle = document.getElementById('formTitle');

  const excelBtn = document.getElementById('importExcelBtn');
  const excelInput = document.getElementById('excelInput');
  const studentListActions = document.getElementById('studentListActions');
  const studentFormActions = document.getElementById('studentFormActions');

  const csrfMeta = document.querySelector('meta[name="csrf-token"]');
  const csrf = csrfMeta ? csrfMeta.content : '';

  // form fields
  const stDbId = document.getElementById('stDbId');
  const stFullName = document.getElementById('stFullName');
  const stGender = document.getElementById('stGender');
  const stBirthdate = document.getElementById('stBirthdate');
  const stStatus = document.getElementById('stStatus');
  const stEmail = document.getElementById('stEmail');
  const stGrade = document.getElementById('stGrade');
  const stClassSection = document.getElementById('stClassSection');
  const stNotes = document.getElementById('stNotes');
  const stGov = document.getElementById('stGov');
  const stCity = document.getElementById('stCity');
  const stStreet = document.getElementById('stStreet');
  const guardianName = document.getElementById('guardianName');
  const guardianRelation = document.getElementById('guardianRelation');
  const guardianPhone = document.getElementById('guardianPhone');
  const guardianRelationOtherWrap = document.getElementById('guardianRelationOtherWrap');
  const guardianRelationOther = document.getElementById('guardianRelationOther');
  const stPhoto = document.getElementById('stPhoto');

  // side panel (prof- prefixed)
  const spAvatar = document.getElementById('prof-avatar');
  const spName = document.getElementById('prof-name');
  const spId = document.getElementById('prof-id');
  const spDob = document.getElementById('prof-dob');
  const spEmail = document.getElementById('prof-email');
  const spAddress = document.getElementById('prof-address');
  const spGuardian = document.getElementById('prof-guardian');
  const spGuardianPhone = document.getElementById('prof-guardian-phone');
  const spGradeSection = document.getElementById('prof-grade-section');
  const spPerformance = document.getElementById('prof-performance');
  const spAttendance = document.getElementById('prof-attendance');

  // Sidebar Buttons
  const sidebarEditBtn = document.querySelector('.js-sidebar-edit');
  const sidebarReportBtn = document.querySelector('.js-sidebar-report');
  const sidebarDeleteBtn = document.querySelector('.js-sidebar-delete');

  // delete modal
  const deleteModalEl = document.getElementById('deleteStudentModal');
  const confirmDeleteStudentBtn = document.getElementById('confirmDeleteStudentBtn');
  const deleteModal =
    (deleteModalEl && window.bootstrap && bootstrap.Modal)
      ? new bootstrap.Modal(deleteModalEl)
      : null;
  let studentIdToDelete = null;

  let studentsData = [];
  let currentStudent = null;
  let currentMode = 'create';
  let isDirty = false;

  // Track Unsaved Changes (External Links / Tab Close)
  window.addEventListener('beforeunload', (e) => {
    if (isDirty) {
      e.preventDefault();
      e.returnValue = ''; // Required for some browsers
    }
  });

  if (studentFormView) {
    const inputs = studentFormView.querySelectorAll('input, select, textarea');
    inputs.forEach(input => {
      input.addEventListener('input', () => { isDirty = true; });
      input.addEventListener('change', () => { isDirty = true; });
    });
  }

  function handleCancelOrBack() {
    if (isDirty) {
      const msg = window.I18N?.confirmUnsaved || 'You have unsaved changes! Are you sure you want to discard them?';
      if (!confirm(msg)) return;
    }
    isDirty = false;
    showList();
  }

  function fullAddress(st) {
    const parts = [];
    if (st.address_governorate) parts.push(st.address_governorate);
    if (st.address_city) parts.push(st.address_city);
    if (st.address_street) parts.push(st.address_street);
    return parts.length ? parts.join(' – ') : '--';
  }

  function getInitials(name) {
    if (!name) return 'ST';
    return name
      .split(' ')
      .filter(Boolean)
      .map(p => p[0])
      .join('')
      .slice(0, 2)
      .toUpperCase();
  }

  function clearForm() {
    if (stDbId) stDbId.value = '';
    if (stFullName) stFullName.value = '';
    if (stGender) stGender.value = '';
    if (stBirthdate) stBirthdate.value = '';
    if (stStatus) stStatus.value = 'Active';
    if (stEmail) stEmail.value = '';
    if (stGrade) stGrade.value = '';
    if (stClassSection) stClassSection.value = '';
    if (stNotes) stNotes.value = '';
    if (stGov) stGov.value = '';
    if (stCity) stCity.value = '';
    if (stStreet) stStreet.value = '';
    if (guardianName) guardianName.value = '';
    if (guardianRelation) guardianRelation.value = '';
    if (guardianPhone) guardianPhone.value = '';
    if (guardianRelationOther) guardianRelationOther.value = '';
    if (guardianRelationOtherWrap) guardianRelationOtherWrap.classList.add('d-none');
    if (stPhoto) stPhoto.value = '';
    const formPhotoPreview = document.getElementById('formPhotoPreview');
    if (formPhotoPreview) {
        formPhotoPreview.style.backgroundImage = 'none';
        formPhotoPreview.style.display = 'none';
    }
    if (stClassSection) {
        stClassSection.innerHTML = `<option value="">${window.I18N?.select || 'Select'}</option>`;
    }
  }

  // Handle Photo Preview on File Select
  if (stPhoto) {
      stPhoto.addEventListener('change', (e) => {
          const file = e.target.files[0];
          const formPhotoPreview = document.getElementById('formPhotoPreview');
          if (file && formPhotoPreview) {
              const reader = new FileReader();
              reader.onload = (event) => {
                  formPhotoPreview.style.backgroundImage = `url('${event.target.result}')`;
                  formPhotoPreview.style.display = 'block';
              };
              reader.readAsDataURL(file);
          }
      });
  }

  function editStudent(st) {
    if (!st) return;

    try {
        console.log('Students JS: editStudent() called for student:', st.id);
        
        // Show form with a slight animation re-trigger
        showForm('edit');
        const formEl = document.getElementById('studentFormView');
        if (formEl) {
            formEl.classList.remove('animate__fadeIn');
            void formEl.offsetWidth; // Trigger reflow
            formEl.classList.add('animate__fadeIn');
        }

        if (stDbId) stDbId.value = st.id;
        if (stFullName) stFullName.value = st.full_name ?? '';
        if (stGender) stGender.value = st.gender ?? '';
        if (stBirthdate) stBirthdate.value = st.birthdate ? st.birthdate.split('T')[0] : '';
        if (stStatus) {
            let statusVal = st.status ?? 'Active';
            if (statusVal === 'Inactive') statusVal = 'Suspended';
            stStatus.value = statusVal;
        }
        if (stEmail) stEmail.value = st.email ?? '';
        
        // Handle Photo Preview
        const formPhotoPreview = document.getElementById('formPhotoPreview');
        if (formPhotoPreview) {
            if (st.photo_url) {
                formPhotoPreview.style.backgroundImage = `url('${st.photo_url}')`;
                formPhotoPreview.style.display = 'block';
            } else {
                formPhotoPreview.style.backgroundImage = 'none';
                formPhotoPreview.style.display = 'none';
            }
        }
        
        if (stGrade) {
          const gValue = st.grade ? st.grade.toString().replace(/[^0-9]/g, '') : '';
          stGrade.value = gValue;
          stGrade.dispatchEvent(new Event('change'));
        }
        
        if (stClassSection) {
            // We use a MutationObserver or a slightly longer, more robust check for options
            const checkAndSetSection = () => {
                const sectionMap = { 'أ': 'A', 'ب': 'B', 'ج': 'C', 'د': 'D', 'هـ': 'E', 'و': 'F', 'ز': 'G', 'ح': 'H' };
                const targetSection = sectionMap[st.class_section] || st.class_section;
                
                // Try to set by value
                stClassSection.value = targetSection;
                
                // If still empty, try to find by text
                if (!stClassSection.value && st.class_section) {
                    Array.from(stClassSection.options).forEach(opt => {
                        if (opt.textContent.trim() === st.class_section || opt.value === st.class_section) {
                            stClassSection.value = opt.value;
                        }
                    });
                }
            };

            // Initial attempt
            checkAndSetSection();
            // Backup attempt after DOM update
            setTimeout(checkAndSetSection, 100);
            setTimeout(checkAndSetSection, 300);
        }
        
        if (stGov) stGov.value = st.address_governorate ?? '';
        if (stCity) stCity.value = st.address_city ?? '';
        if (stStreet) stStreet.value = st.address_street ?? '';
        if (guardianName) guardianName.value = st.guardian_name ?? '';
        if (guardianRelation) guardianRelation.value = st.guardian_relation ?? '';
        if (guardianPhone) guardianPhone.value = st.guardian_phone ?? '';
        if (stNotes) stNotes.value = st.notes ?? '';
        
        if (guardianRelationOtherWrap) {
          if (st.guardian_relation === 'other') {
            guardianRelationOtherWrap.classList.remove('d-none');
            if (guardianRelationOther) guardianRelationOther.value = st.guardian_relation_other ?? '';
          } else {
            guardianRelationOtherWrap.classList.add('d-none');
          }
        }
        
        // if (stPhoto) stPhoto.value = '';
        // console.log('Students JS: editStudent() completed successfully');
    } catch (err) {
        console.error('CRITICAL: Error in editStudent:', err);
    }
  }

  // Handle Grade Change to update Sections
  if (stGrade && stClassSection) {
    stGrade.addEventListener('change', () => {
      const selectedGrade = stGrade.value; // e.g. "1" or "Grade 1"
      const allSections = window.ALL_SECTIONS || [];

      // Clear current options except the first one
      stClassSection.innerHTML = `<option value="">${window.I18N?.select || 'Select'}</option>`;

      if (selectedGrade) {
        const gradeLevel = selectedGrade.toString().replace(/[^0-9]/g, '');
        const currentLang = document.documentElement.lang || 'en';
        
        // تصفية الشعب بناءً على الصف المختار
        const filtered = allSections.filter(s => s.grade == gradeLevel);
        
        filtered.forEach(s => {
          const opt = document.createElement('option');
          opt.value = s.section; // القيمة البرمجية (مثل 'A' أو 'أ')
          
          // عرض الاسم بناءً على اللغة
          let displayName = s.section;
          if (currentLang === 'ar') {
              // إذا كانت اللغة عربية، نستخدم الاسم العربي (أو نحول الرموز)
              const arMap = {'A': 'أ', 'B': 'ب', 'C': 'ج', 'D': 'د', 'E': 'هـ', 'F': 'و', 'G': 'ز', 'H': 'ح'};
              displayName = s.name_ar || arMap[s.section] || s.section;
          } else {
              // إذا كانت اللغة إنجليزية
              const enMap = {'أ': 'A', 'ب': 'B', 'ج': 'C', 'د': 'D', 'هـ': 'E', 'و': 'F', 'ز': 'G', 'ح': 'H'};
              displayName = s.name_en || enMap[s.section] || s.section;
          }
          
          opt.textContent = displayName;
          stClassSection.appendChild(opt);
        });
      }
    });
  }

  function showForm(mode = 'create') {
    console.log('Students JS: showForm called with mode:', mode);
    isDirty = false;
    currentMode = mode;
    
    // Fetch fresh elements to avoid null references
    const listEl = document.getElementById('studentsListView');
    const formEl = document.getElementById('studentFormView');
    const titleEl = document.getElementById('formTitle');

    if (titleEl) {
        if (mode === 'create') {
            titleEl.textContent = window.I18N?.addNewStudent || 'Add New Student';
            clearForm();
        } else {
            titleEl.textContent = window.I18N?.editStudent || 'Edit Student';
        }
    }

    if (listEl) {
        listEl.style.display = 'none';
        console.log('Students JS: Hidden list view');
    }
    
    if (formEl) {
        formEl.style.display = 'block';
        console.log('Students JS: Shown form view');
    } else {
        console.error('Students JS: studentFormView NOT FOUND in DOM!');
    }

    // Toggle header actions
    if (studentListActions) studentListActions.classList.add('d-none');
    if (studentFormActions) studentFormActions.classList.remove('d-none');
    
    // Reset to first tab
    const firstTab = document.querySelector('#studentTabs a[href="#tab-basic"]');
    if (firstTab && window.bootstrap && bootstrap.Tab) {
        const tab = new bootstrap.Tab(firstTab);
        tab.show();
    }
  }

  function showList() {
    const listEl = document.getElementById('studentsListView');
    const formEl = document.getElementById('studentFormView');
    
    if (formEl) formEl.style.display = 'none';
    if (listEl) listEl.style.display = 'block';
    if (studentSavedAlert) studentSavedAlert.classList.add('d-none');

    // Toggle header actions
    if (studentListActions) studentListActions.classList.remove('d-none');
    if (studentFormActions) studentFormActions.classList.add('d-none');
  }

  function fillSidePanel(st) {
    currentStudent = st; // Store current selection
    const spAvatar = document.getElementById('prof-avatar');
    const spName = document.getElementById('prof-name');
    const spId = document.getElementById('prof-id');
    const spDob = document.getElementById('prof-dob');
    const spEmail = document.getElementById('prof-email');
    const spAddress = document.getElementById('prof-address');
    const spGuardian = document.getElementById('prof-guardian');
    const spGuardianPhone = document.getElementById('prof-guardian-phone');
    const spGradeSection = document.getElementById('prof-grade-section');
    const spPerformance = document.getElementById('prof-performance');
    const spAttendance = document.getElementById('prof-attendance');

    if (!spName) return;

    spName.textContent = st.full_name || '--';
    if (spId) spId.textContent = (window.I18N?.academicIdPrefix || 'Academic ID: ') + (st.academic_id || '--');
    if (spDob) spDob.textContent = st.birthdate || '--';
    if (spEmail) spEmail.textContent = st.email || '--';
    if (spAddress) spAddress.textContent = fullAddress(st);
    if (spGuardian) {
        spGuardian.textContent = st.guardian_name
            ? `${st.guardian_name} (${st.guardian_relation || st.guardian_relation_other || (window.I18N?.guardian || 'Guardian')})`
            : '--';
    }
    if (spGuardianPhone) spGuardianPhone.textContent = st.guardian_phone || '--';
    
    // Localize Section for Sidebar
    let dispSection = st.class_section || '--';
    if (document.documentElement.lang === 'en') {
        const map = {'أ': 'A', 'ب': 'B', 'ج': 'C', 'د': 'D', 'هـ': 'E', 'و': 'F', 'ز': 'G', 'ح': 'H'};
        dispSection = map[st.class_section] ?? st.class_section;
    }
    if (spGradeSection) spGradeSection.textContent = (st.grade || '--') + ' / ' + dispSection;
    if (spPerformance) spPerformance.textContent = st.performance_avg ? st.performance_avg + '%' : '--';
    if (spAttendance) spAttendance.textContent = st.attendance_rate ? st.attendance_rate + '%' : '--';

    if (spAvatar) {
      if (st.photo_url) {
        spAvatar.style.backgroundImage = `url('${st.photo_url}')`;
        spAvatar.style.backgroundSize = 'cover';
        spAvatar.style.backgroundPosition = 'center';
        spAvatar.textContent = '';
      } else {
        spAvatar.style.backgroundImage = 'none';
        spAvatar.textContent = getInitials(st.full_name);
      }
    }

    const perfVal = parseFloat(st.performance_avg || 0);
    const perfBar = document.getElementById('prof-perf-bar');
    if (perfBar) perfBar.style.width = perfVal + '%';

    const attVal = parseFloat(st.attendance_rate || 0);
    const attBar = document.getElementById('prof-att-bar');
    if (attBar) attBar.style.width = attVal + '%';

    // Show sidebar, hide empty state
    const studentProfile = document.getElementById('studentProfile');
    const sidebarEmptyState = document.getElementById('sidebarEmptyState');
    
    if (studentProfile) studentProfile.classList.remove('d-none');
    if (sidebarEmptyState) sidebarEmptyState.classList.add('d-none');

    // Sidebar Action Buttons - use addEventListener or ensure we don't double up
    // We already have global listeners at the bottom of the script

    // Trigger animation
    // Reveal Profile
    if (sidebarEmptyState) sidebarEmptyState.style.display = 'none';
    if (studentProfile) {
      studentProfile.style.display = 'block';
      studentProfile.classList.remove('animate-update');
      void studentProfile.offsetWidth; // Trigger reflow
      studentProfile.classList.add('animate-update');
    }

    /* Sidebar performance button removed by request */
  }

  function renderStudents(filterText = '', grade = '') {
    console.log('Students JS: Rendering students...', { filterText, grade });
    if (!studentsTableBody) {
        console.warn('Students JS: Cannot render, table body missing');
        return;
    }
    studentsTableBody.innerHTML = '';

    const txtLower = filterText.toLowerCase();

    const filterGender = document.getElementById('genderFilter')?.value;
    const filterStatus = document.getElementById('statusFilter')?.value;

    const filteredStudents = studentsData.filter(st => {
      const matchText =
        (st.full_name && st.full_name.toLowerCase().includes(txtLower)) ||
        (st.academic_id && st.academic_id.toLowerCase().includes(txtLower));
      
      const stGender = (st.gender || '').toLowerCase();
      const selGender = (filterGender || '').toLowerCase();
      const matchGender = filterGender ? (stGender === selGender) : true;

      // Map 'Inactive' to 'Suspended' logic for filter
      let stStatus = (st.status || 'Active').toLowerCase();
      if (stStatus === 'inactive') stStatus = 'suspended';
      const selStatus = (filterStatus || '').toLowerCase();
      const matchStatus = filterStatus ? (stStatus === selStatus) : true;

      const matchGrade = grade ? st.grade === grade : true;

      return matchText && matchGrade && matchGender && matchStatus;
    });

    if (filteredStudents.length === 0) {
      studentsTableBody.innerHTML = `<tr><td colspan="5" class="text-center py-5">
        <div class="empty-state anim-fade-up">
           <i class="bi bi-people text-muted" style="font-size: 3.5rem; opacity: 0.3;"></i>
           <h5 class="mt-3 text-dark fw-bold">${window.I18N?.noStudentsRegistered || 'لم يتم تسجيل أي طالب بعد'}</h5>
           <p class="text-muted small">${window.I18N?.startByAddingStudent || 'ابدأ بإضافة أول طالب للمدرسة من خلال زر الإضافة'}</p>
        </div>
      </td></tr>`;
      return;
    }

    filteredStudents.forEach(st => {
        const genderIcon = st.gender === 'Female' ? '<i class="bi bi-gender-female text-danger"></i>' : '<i class="bi bi-gender-male text-primary"></i>';
        const tr = document.createElement('tr');
        tr.className = 'cursor-pointer';
        tr.innerHTML = `
          <td class="ps-4">
            <div class="d-flex align-items-center gap-3">
               <div style="font-size: 1.2rem;">${genderIcon}</div>
               <div class="fw-bold text-navy">${st.full_name ?? ''}</div>
            </div>
          </td>
          <td class="text-muted small">${st.academic_id ?? ''}</td>
          <td>
            <span class="badge bg-soft-primary text-primary px-3 rounded-pill">
              ${(st.grade ?? '')} / 
              ${(document.documentElement.lang === 'en') 
                  ? (({'أ': 'A', 'ب': 'B', 'ج': 'C', 'د': 'D', 'هـ': 'E', 'و': 'F', 'ز': 'G', 'ح': 'H'})[st.class_section] ?? st.class_section)
                  : st.class_section
              }
            </span>
          </td>
          <td>
            <span class="status-pill ${(st.status === 'Active') ? 'status-active' : 'status-suspended'}">
              ${(st.status === 'Active') ? (window.I18N?.active || 'Active') : (window.I18N?.suspended || 'Suspended')}
            </span>
          </td>
          <td class="text-end pe-4">
            <div class="btn-group shadow-sm rounded-pill overflow-hidden">
                <button class="btn btn-sm btn-white border-end" data-action="edit" data-id="${st.id}" title="Edit"><i class="bi bi-pencil text-primary"></i></button>
                <button class="btn btn-sm btn-white border-end" data-action="report" data-id="${st.id}" title="Report"><i class="bi bi-bar-chart text-info"></i></button>
                <button class="btn btn-sm btn-white" data-action="delete" data-id="${st.id}" title="Delete"><i class="bi bi-trash text-danger"></i></button>
            </div>
          </td>
        `;

        tr.addEventListener('click', (e) => {
          if (e.target.closest('button')) return;
          
          // Clear previous selection
          document.querySelectorAll('#studentsTable tr.selected-row').forEach(row => row.classList.remove('selected-row'));
          // Highlight current row
          tr.classList.add('selected-row');

          fillSidePanel(st);
        });

        const reportBtn = tr.querySelector('button[data-action="report"]');
        const editBtn = tr.querySelector('button[data-action="edit"]');
        const deleteBtn = tr.querySelector('button[data-action="delete"]');

        reportBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          window.location.href = `/reports?student_id=${st.id}`;
        });

        editBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          editStudent(st);
        });

        deleteBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          studentIdToDelete = st.id;
          if (deleteModal) deleteModal.show();
        });

        studentsTableBody.appendChild(tr);
      });
  }

  function fetchStudents() {
    console.log('Students JS: Fetching students from', getListUrl);
    const url = typeof getListUrl === 'function' ? getListUrl() : getListUrl;
    if (studentsTableBody) {
        studentsTableBody.innerHTML = '<tr><td colspan="5" class="text-center py-4"><div class="spinner-border text-primary"></div></td></tr>';
    } else {
        console.warn('Students JS: studentsTableBody not found!');
    }
    fetch(url)
      .then(res => {
        if (!res.ok) throw new Error('Fetch failed with status ' + res.status);
        return res.json();
      })
      .then(data => {
        console.log('Students JS: Received', data.length, 'students');
        studentsData = data;
        renderStudents(studentSearch ? studentSearch.value : '', gradeFilter ? gradeFilter.value : '');
        
        // Auto-select first student if list is not empty and not in form view
        if (studentsData.length && studentFormView.style.display === 'none') {
            fillSidePanel(studentsData[0]);
            const firstRow = document.querySelector('#studentsTable tbody tr');
            if (firstRow) firstRow.classList.add('selected-row');
        } else if (!studentsData.length) {
            console.log('Students JS: No students to show in side panel');
        }
      })
      .catch(err => {
          console.error('Students JS: Fetch Error:', err);
          if (studentsTableBody) {
              studentsTableBody.innerHTML = `<tr><td colspan="5" class="text-center py-4 text-danger">Error loading students: ${err.message}</td></tr>`;
          }
      });
  }
  fetchStudents();

  if (studentSearch) {
    studentSearch.addEventListener('input', e => {
      renderStudents(e.target.value, gradeFilter ? gradeFilter.value : '');
    });
  }

  if (gradeFilter) {
    gradeFilter.addEventListener('change', () => {
      renderStudents(studentSearch ? studentSearch.value : '', gradeFilter.value);
    });
  }

  const genderFilter = document.getElementById('genderFilter');
  if (genderFilter) {
      genderFilter.addEventListener('change', () => {
          renderStudents(studentSearch ? studentSearch.value : '', gradeFilter ? gradeFilter.value : '');
      });
  }

  const statusFilter = document.getElementById('statusFilter');
  if (statusFilter) {
      statusFilter.addEventListener('change', () => {
          renderStudents(studentSearch ? studentSearch.value : '', gradeFilter ? gradeFilter.value : '');
      });
  }

  if (openStudentFormBtn) openStudentFormBtn.addEventListener('click', () => showForm('create'));
  if (backToStudentsBtn) backToStudentsBtn.addEventListener('click', handleCancelOrBack);
  if (cancelStudentBtn) cancelStudentBtn.addEventListener('click', handleCancelOrBack);

  if (guardianRelation) {
    guardianRelation.addEventListener('change', () => {
      if (guardianRelation.value === 'other') {
        guardianRelationOtherWrap.classList.remove('d-none');
      } else {
        guardianRelationOtherWrap.classList.add('d-none');
      }
    });
  }

  const saveStudentBtn = document.getElementById('saveStudentBtn');
  if (saveStudentBtn) {
    saveStudentBtn.addEventListener('click', () => {
      // 1. Validation Logic
      const requiredFields = [
        { el: stFullName, label: window.I18N?.fullName || 'Full Name' },
        { el: stGender, label: window.I18N?.gender || 'Gender' },
        { el: stBirthdate, label: window.I18N?.birthdate || 'Birthdate' },
        { el: stGrade, label: window.I18N?.grade || 'Grade' },
        { el: stClassSection, label: window.I18N?.classSection || 'Class Section' },
        { el: guardianName, label: window.I18N?.guardianName || 'Guardian Name' },
        { el: guardianPhone, label: window.I18N?.guardianPhone || 'Guardian Phone' }
      ];

      let missing = [];
      requiredFields.forEach(field => {
        if (!field.el.value || field.el.value.trim() === '') {
          missing.push(field.label);
          field.el.classList.add('is-invalid'); // Add visual feedback
        } else {
          field.el.classList.remove('is-invalid');
        }
      });

      if (missing.length > 0) {
        Swal.fire({
          title: window.I18N?.requiredFieldsMissing || 'Required Fields Missing',
          html: (window.I18N?.pleaseFill || 'Please fill in the following fields:') + '<br><b>' + missing.join(', ') + '</b>',
          icon: 'warning',
          confirmButtonText: window.I18N?.ok || 'OK'
        });
        return;
      }

      // 2. Age Validation (3 - 22 years)
      const bday = new Date(stBirthdate.value);
      const today = new Date();
      let age = today.getFullYear() - bday.getFullYear();
      const m = today.getMonth() - bday.getMonth();
      if (m < 0 || (m === 0 && today.getDate() < bday.getDate())) age--;

      if (age < 3 || age > 22) {
        Swal.fire({
          title: window.I18N?.error || 'Error',
          text: window.I18N?.invalidStudentAge || 'Student age must be between 3 and 22 years.',
          icon: 'error',
          confirmButtonText: window.I18N?.ok || 'OK'
        });
        stBirthdate.classList.add('is-invalid');
        return;
      }

      const formData = new FormData();
      formData.append('full_name', stFullName.value);
      formData.append('gender', stGender.value);
      formData.append('birthdate', stBirthdate.value);
      formData.append('status', stStatus.value);
      formData.append('email', stEmail.value);
      formData.append('grade', stGrade.value);
      formData.append('class_section', stClassSection.value);
      formData.append('address_governorate', stGov.value);
      formData.append('address_city', stCity.value);
      formData.append('address_street', stStreet.value);
      formData.append('guardian_name', guardianName.value);
      formData.append('guardian_relation', guardianRelation.value);
      formData.append('guardian_relation_other', guardianRelationOther ? guardianRelationOther.value : '');
      formData.append('guardian_phone', guardianPhone.value);
      formData.append('notes', stNotes ? stNotes.value : '');

      if (stPhoto && stPhoto.files[0]) {
        formData.append('photo', stPhoto.files[0]);
      }

      let url = getStoreUrl;
      let method = 'POST';

      if (currentMode === 'edit' && stDbId.value) {
        url = typeof getUpdateUrl === 'function' ? getUpdateUrl(stDbId.value) : `/students/${stDbId.value}`;
        method = 'POST';
        formData.append('_method', 'PUT');
      }

      fetch(url, {
        method: method,
        headers: {
          'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: formData
      })
      .then(async (res) => {
        if (!res.ok) {
          const text = await res.text();
          console.error('Server error:', text);
          alert((window.I18N?.savingFailed || 'Saving failed') + '. Status: ' + res.status);
          throw new Error('Request failed');
        }
        return res.json();
      })
      .then(saved => {
        Swal.fire({
          title: window.I18N?.success || 'Success',
          text: window.I18N?.studentSaved || 'Student saved successfully.',
          icon: 'success',
          confirmButtonText: window.I18N?.ok || 'OK'
        }).then(() => {
          isDirty = false;
          fetchStudents();
          showList();
          clearForm();
        });
      })
      .catch(err => console.error(err));
    });
  }

  if (confirmDeleteStudentBtn) {
    confirmDeleteStudentBtn.addEventListener('click', () => {
      if (!studentIdToDelete) return;
      const url = typeof getDeleteUrl === 'function' ? getDeleteUrl(studentIdToDelete) : `/students/${studentIdToDelete}`;
      fetch(url, {
        method: 'DELETE',
        headers: {
          'X-CSRF-TOKEN': csrf
        }
      })
      .then(res => res.json())
      .then(() => {
        if (deleteModal) deleteModal.hide();
        studentIdToDelete = null;
        fetchStudents();
      })
      .catch(err => console.error(err));
    });
  }

  if (excelBtn) {
    excelBtn.addEventListener('click', () => {
      if (!excelInput) {
        alert('File input for import not found (excelInput).');
        return;
      }
      excelInput.click();
    });
  }

  if (excelInput) {
    excelInput.addEventListener('change', () => {
      const file = excelInput.files[0];
      if (!file) return;

      const formData = new FormData();
      formData.append('file', file);

      const url = typeof getImportUrl === 'function' ? getImportUrl() : getImportUrl;

      if (window.loadingManager) window.loadingManager.start();

      fetch(url, {
        method: 'POST',
        headers: {
          'X-CSRF-TOKEN': csrf,
          'Accept': 'application/json'
        },
        body: formData
      })
      .then(async (res) => {
        if (!res.ok) {
          const text = await res.text();
          console.error('Import error:', text);
          if (window.loadingManager) window.loadingManager.stop();
          Swal.fire('Error', 'Import failed', 'error');
          throw new Error('Import failed');
        }
        try {
          const data = await res.json();
          if (window.loadingManager) {
            window.loadingManager.stop({
                success: data.success,
                failed: data.failed
            });
          } else {
             Swal.fire('Success', data.message || 'Imported!', 'success');
          }
          fetchStudents();
        } catch(e) { 
           if (window.loadingManager) window.loadingManager.stop();
           Swal.fire('Success', 'Imported!', 'success');
           fetchStudents(); 
        }
      })
      .catch(err => {
        console.error(err);
        Swal.fire('خطأ', 'حدث خطأ غير متوقع أثناء المعالجة', 'error');
      });
    });
  }

  // Sidebar Actions Activation
  sidebarEditBtn?.addEventListener('click', () => currentStudent && editStudent(currentStudent));
  sidebarReportBtn?.addEventListener('click', () => currentStudent && (window.location.href = `/reports?student_id=${currentStudent.id}`));
  sidebarDeleteBtn?.addEventListener('click', () => {
      if (currentStudent) {
          studentIdToDelete = currentStudent.id;
          if (deleteModal) deleteModal.show();
      }
  });

});
