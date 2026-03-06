document.addEventListener('DOMContentLoaded', () => {
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

  // side panel
  const spAvatar = document.getElementById('studentAvatar');
  const spName = document.getElementById('studentName');
  const spId = document.getElementById('studentId');
  const spDob = document.getElementById('studentDob');
  const spEmail = document.getElementById('studentEmail');
  const spAddress = document.getElementById('studentAddress');
  const spGuardian = document.getElementById('studentGuardian');
  const spGuardianPhone = document.getElementById('studentGuardianPhone');
  const spGradeSection = document.getElementById('studentGradeSection');
  const spPerformance = document.getElementById('studentPerformance');
  const spAttendance = document.getElementById('studentAttendance');

  // delete modal
  const deleteModalEl = document.getElementById('deleteStudentModal');
  const confirmDeleteStudentBtn = document.getElementById('confirmDeleteStudentBtn');
  const deleteModal =
    (deleteModalEl && window.bootstrap && bootstrap.Modal)
      ? new bootstrap.Modal(deleteModalEl)
      : null;
  let studentIdToDelete = null;

  let studentsData = [];
  let currentMode = 'create';

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
  }

  function showForm(mode = 'create') {
    currentMode = mode;
    if (mode === 'create') {
      formTitle.textContent = 'Add New Student';
      clearForm();
    } else {
      formTitle.textContent = 'Edit Student';
    }
    if (studentsListView) studentsListView.style.display = 'none';
    if (studentFormView) studentFormView.style.display = 'block';
  }

  function showList() {
    if (studentFormView) studentFormView.style.display = 'none';
    if (studentsListView) studentsListView.style.display = 'block';
    if (studentSavedAlert) studentSavedAlert.classList.add('d-none');
  }

  function fillSidePanel(st) {
    if (!spName) return;

    spName.textContent = st.full_name || '--';
    spId.textContent = 'Academic ID: ' + (st.academic_id || '--');
    spDob.textContent = st.birthdate || '--';
    spEmail.textContent = st.email || '--';
    spAddress.textContent = fullAddress(st);
    spGuardian.textContent = st.guardian_name
      ? `${st.guardian_name} (${st.guardian_relation || st.guardian_relation_other || 'Guardian'})`
      : '--';
    spGuardianPhone.textContent = st.guardian_phone || '--';
    spGradeSection.textContent = (st.grade || '--') + (st.class_section ? ' / ' + st.class_section : '');
    spPerformance.textContent = st.performance_avg ? st.performance_avg + '%' : '--';
    spAttendance.textContent = st.attendance_rate ? st.attendance_rate + '%' : '--';

    if (spAvatar) {
      if (st.photo_path) {
        const url = `${STORAGE_BASE_URL}/${st.photo_path}`;
        spAvatar.style.backgroundImage = `url('${url}')`;
        spAvatar.style.backgroundSize = 'cover';
        spAvatar.style.backgroundPosition = 'center';
        spAvatar.textContent = '';
      } else {
        spAvatar.style.backgroundImage = 'none';
        spAvatar.textContent = getInitials(st.full_name);
      }
    }
  }

  function renderStudents(filterText = '', grade = '') {
    if (!studentsTableBody) return;
    studentsTableBody.innerHTML = '';

    const txtLower = filterText.toLowerCase();

    studentsData
      .filter(st => {
        const matchText =
          (st.full_name && st.full_name.toLowerCase().includes(txtLower)) ||
          (st.academic_id && st.academic_id.toLowerCase().includes(txtLower));
        const matchGrade = grade ? st.grade === grade : true;
        return matchText && matchGrade;
      })
      .forEach(st => {
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${st.full_name ?? ''}</td>
          <td>${st.academic_id ?? ''}</td>
          <td>${(st.grade ?? '')}${st.class_section ? ' / ' + st.class_section : ''}</td>
          <td>
            <span class="status-pill ${st.status === 'Active' ? 'status-active' : 'status-suspended'}">
              ${st.status ?? ''}
            </span>
          </td>
          <td class="text-end">
            <button class="btn btn-sm btn-outline-primary me-1" data-action="edit" data-id="${st.id}">
              <i class="bi bi-pencil"></i>
            </button>
            <button class="btn btn-sm btn-outline-danger" data-action="delete" data-id="${st.id}">
              <i class="bi bi-trash"></i>
            </button>
          </td>
        `;

        tr.addEventListener('click', (e) => {
          if (e.target.closest('button')) return;
          fillSidePanel(st);
        });

        const editBtn = tr.querySelector('button[data-action="edit"]');
        const deleteBtn = tr.querySelector('button[data-action="delete"]');

        editBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          showForm('edit');
          if (stDbId) stDbId.value = st.id;
          if (stFullName) stFullName.value = st.full_name ?? '';
          if (stGender) stGender.value = st.gender ?? '';
          if (stBirthdate) stBirthdate.value = st.birthdate ?? '';
          if (stStatus) stStatus.value = st.status ?? 'Active';
          if (stEmail) stEmail.value = st.email ?? '';
          if (stGrade) stGrade.value = st.grade ?? '';
          if (stClassSection) stClassSection.value = st.class_section ?? '';
          if (stGov) stGov.value = st.address_governorate ?? '';
          if (stCity) stCity.value = st.address_city ?? '';
          if (stStreet) stStreet.value = st.address_street ?? '';
          if (guardianName) guardianName.value = st.guardian_name ?? '';
          if (guardianRelation) guardianRelation.value = st.guardian_relation ?? '';
          if (guardianPhone) guardianPhone.value = st.guardian_phone ?? '';
          if (stNotes) stNotes.value = st.notes ?? '';
          if (st.guardian_relation === 'other' && guardianRelationOtherWrap) {
            guardianRelationOtherWrap.classList.remove('d-none');
            if (guardianRelationOther) guardianRelationOther.value = st.guardian_relation_other ?? '';
          } else if (guardianRelationOtherWrap) {
            guardianRelationOtherWrap.classList.add('d-none');
          }
          if (stPhoto) stPhoto.value = ''; // لا يمكن تعبئة ملف مسبقاً
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
    const url = typeof getListUrl === 'function' ? getListUrl() : getListUrl;
    fetch(url)
      .then(res => res.json())
      .then(data => {
        studentsData = data;
        renderStudents(studentSearch ? studentSearch.value : '', gradeFilter ? gradeFilter.value : '');
        if (studentsData.length) fillSidePanel(studentsData[0]);
      })
      .catch(err => console.error(err));
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

  if (openStudentFormBtn) openStudentFormBtn.addEventListener('click', () => showForm('create'));
  if (backToStudentsBtn) backToStudentsBtn.addEventListener('click', showList);
  if (cancelStudentBtn) cancelStudentBtn.addEventListener('click', showList);

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
          'X-CSRF-TOKEN': csrf
        },
        body: formData
      })
      .then(async (res) => {
        if (!res.ok) {
          const text = await res.text();
          console.error('Server error:', text);
          alert('Saving failed. Status: ' + res.status);
          throw new Error('Request failed');
        }
        return res.json();
      })
      .then(saved => {
        fetchStudents();
        showList();
        clearForm();
        if (studentSavedAlert) {
          studentSavedAlert.textContent = 'Student saved successfully.';
          studentSavedAlert.classList.remove('d-none');
        }
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
          alert('Import failed. Status: ' + res.status);
          throw new Error('Import failed');
        }
        try {
          return await res.json();
        } catch (e) {
          return {};
        }
      })
      .then((data) => {
        if (data && data.message) {
          alert(data.message);
        } else {
          alert('Students imported successfully.');
        }
        excelInput.value = '';
        fetchStudents();
      })
      .catch(err => {
        console.error(err);
        alert('Unexpected error during import.');
      });
    });
  }

});
