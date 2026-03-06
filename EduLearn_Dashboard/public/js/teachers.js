document.addEventListener('DOMContentLoaded', () => {
  const ROUTES = window.TEACHERS_ROUTES || {};
  const getListUrl   = ROUTES.list || '/teachers/list';
  const getStoreUrl  = ROUTES.store || '/teachers';
  const getUpdateUrl = ROUTES.update || ((id) => `/teachers/${id}`);
  const getDeleteUrl = ROUTES.destroy || ((id) => `/teachers/${id}`);
  const getImportUrl = ROUTES.import || '/teachers/import';

  const STORAGE_BASE_URL = window.STORAGE_BASE_URL || '/storage';

  const csrfMeta = document.querySelector('meta[name="csrf-token"]');
  const csrf = csrfMeta ? csrfMeta.content : '';

  const teachersTableBody = document.querySelector('#teachersTable tbody');
  const teacherSearch = document.getElementById('teacherSearch');
  const teacherSubjectFilter = document.getElementById('teacherSubjectFilter');
  const teacherStatusFilter = document.getElementById('teacherStatusFilter');

  const teachersListView = document.getElementById('teachersListView');
  const teacherFormView = document.getElementById('teacherFormView');
  const openTeacherFormBtn = document.getElementById('openTeacherFormBtn');
  const backToTeachersBtn = document.getElementById('backToTeachersBtn');
  const cancelTeacherBtn = document.getElementById('cancelTeacherBtn');
  const teacherSavedAlert = document.getElementById('teacherSavedAlert');
  const teacherFormTitle = document.getElementById('teacherFormTitle');

  const importTeachersBtn = document.getElementById('importTeachersBtn');
  const importTeachersInput = document.getElementById('importTeachersInput');

  // form fields
  const tcDbId = document.getElementById('tcDbId');
  const tcFullName = document.getElementById('tcFullName');
  const tcBirthdate = document.getElementById('tcBirthdate');
  const tcAge = document.getElementById('tcAge');
  const calcAgeBtn = document.getElementById('calcAgeBtn');
  const tcShift = document.getElementById('tcShift');
  const tcPhone = document.getElementById('tcPhone');
  const tcEmail = document.getElementById('tcEmail');
  const tcDistrict = document.getElementById('tcDistrict');
  const tcNeighborhood = document.getElementById('tcNeighborhood');
  const tcStreet = document.getElementById('tcStreet');
  const tcPhoto = document.getElementById('tcPhoto');
  const tcAssignedClasses = document.getElementById('tcAssignedClasses');
  const saveTeacherBtn = document.getElementById('saveTeacherBtn');

  // side panel
  const teacherName = document.getElementById('teacherName');
  const teacherId = document.getElementById('teacherId');
  const teacherAvatar = document.getElementById('teacherAvatar');

  const spTcBirthdate = document.getElementById('spTcBirthdate');
  const spTcEmail = document.getElementById('spTcEmail');
  const spTcAddress = document.getElementById('spTcAddress');
  const spTcPhone = document.getElementById('spTcPhone');
  const spTcClassSection = document.getElementById('spTcClassSection');
  const spTcSubjects = document.getElementById('spTcSubjects');
  const spTcPerformance = document.getElementById('spTcPerformance');
  const spTcAttendance = document.getElementById('spTcAttendance');

  let teachersData = [];
  let currentMode = 'create';

  function getInitials(name) {
    if (!name) return 'TC';
    return name
      .split(' ')
      .filter(Boolean)
      .map(p => p[0])
      .join('')
      .slice(0, 2)
      .toUpperCase();
  }

  function clearForm() {
    if (tcDbId) tcDbId.value = '';
    if (tcFullName) tcFullName.value = '';
    if (tcBirthdate) tcBirthdate.value = '';
    if (tcAge) tcAge.value = '';
    if (tcPhone) tcPhone.value = '';
    if (tcEmail) tcEmail.value = '';
    if (tcShift) tcShift.value = '';
    if (tcDistrict) tcDistrict.value = '';
    if (tcNeighborhood) tcNeighborhood.value = '';
    if (tcStreet) tcStreet.value = '';
    if (tcPhoto) tcPhoto.value = '';
    if (tcAssignedClasses) tcAssignedClasses.value = '';
  }

  function showForm(mode = 'create') {
    currentMode = mode;
    if (mode === 'create') {
      teacherFormTitle.textContent = 'Add New Teacher';
      clearForm();
    } else {
      teacherFormTitle.textContent = 'Edit Teacher';
    }
    teachersListView.style.display = 'none';
    teacherFormView.style.display = 'block';
  }

  function showList() {
    teacherFormView.style.display = 'none';
    teachersListView.style.display = 'block';
    if (teacherSavedAlert) teacherSavedAlert.classList.add('d-none');
  }

  function buildAddress(tc) {
    const parts = [tc.district, tc.neighborhood, tc.street].filter(Boolean);
    return parts.length ? parts.join(' - ') : '--';
  }

  function fillSidePanel(tc) {
    if (!tc) return;

    if (teacherName) teacherName.textContent = tc.full_name || '--';
    if (teacherId) teacherId.textContent = tc.teacher_code
      ? `Teacher Code: ${tc.teacher_code}`
      : `Teacher Code: T-${tc.id}`;

    if (teacherAvatar) {
      if (tc.photo_path) {
        const url = `${STORAGE_BASE_URL}/${tc.photo_path}`;
        teacherAvatar.style.backgroundImage = `url('${url}')`;
        teacherAvatar.style.backgroundSize = 'cover';
        teacherAvatar.style.backgroundPosition = 'center';
        teacherAvatar.textContent = '';
      } else {
        teacherAvatar.style.backgroundImage = 'none';
        teacherAvatar.textContent = getInitials(tc.full_name);
      }
    }

    if (spTcBirthdate) spTcBirthdate.textContent = tc.birthdate || '--';
    if (spTcEmail) spTcEmail.textContent = tc.email || '--';
    if (spTcAddress) spTcAddress.textContent = buildAddress(tc);
    if (spTcPhone) spTcPhone.textContent = tc.phone || '--';

    const subjectsArr = Array.isArray(tc.assigned_subjects)
      ? tc.assigned_subjects
      : (Array.isArray(tc.subjects) ? tc.subjects : []);

    if (spTcSubjects) {
      spTcSubjects.textContent = subjectsArr && subjectsArr.length
        ? subjectsArr.join(', ')
        : '--';
    }

    const classSections = Array.isArray(tc.assigned_class_sections)
      ? tc.assigned_class_sections
      : [];

    if (spTcClassSection) {
      spTcClassSection.textContent = classSections.length
        ? classSections.join(', ')
        : '--';
    }

    if (spTcPerformance) {
      spTcPerformance.textContent =
        tc.avg_student_score !== null && tc.avg_student_score !== undefined
          ? tc.avg_student_score + '%'
          : '--';
    }

    if (spTcAttendance) {
      spTcAttendance.textContent =
        tc.attendance_rate !== null && tc.attendance_rate !== undefined
          ? tc.attendance_rate + '%'
          : '--';
    }
  }

  function renderTeachers() {
    if (!teachersTableBody) return;
    teachersTableBody.innerHTML = '';

    const search = teacherSearch ? teacherSearch.value.toLowerCase() : '';
    const subjectFilter = teacherSubjectFilter ? teacherSubjectFilter.value.toLowerCase() : '';
    const statusFilter = teacherStatusFilter ? teacherStatusFilter.value : '';

    teachersData
      .filter(tc => {
        const nameMatch = (tc.full_name || '').toLowerCase().includes(search);
        const idMatch = (tc.teacher_code || '').toLowerCase().includes(search);
        return nameMatch || idMatch;
      })
      .filter(tc => {
        if (!subjectFilter) return true;

        const subjectsArr = Array.isArray(tc.assigned_subjects)
          ? tc.assigned_subjects
          : (Array.isArray(tc.subjects) ? tc.subjects : []);

        if (!subjectsArr || !subjectsArr.length) return false;

        return subjectsArr.some(s => (s || '').toLowerCase().includes(subjectFilter));
      })
      .filter(tc => {
        if (!statusFilter) return true;
        return (tc.status || '') === statusFilter;
      })
      .forEach(tc => {
        const subjectsText = Array.isArray(tc.assigned_subjects)
          ? tc.assigned_subjects.join(', ')
          : (Array.isArray(tc.subjects)
              ? tc.subjects.join(', ')
              : (tc.subjects ?? '')
            );

        const totalStudents = tc.total_assigned_students ?? tc.students_count ?? 0;

        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>
            <div class="d-flex align-items-center gap-2">
              <div class="rounded-circle bg-light d-flex align-items-center justify-content-center" style="width:32px;height:32px;">
                ${getInitials(tc.full_name)}
              </div>
              <div>
                <div>${tc.full_name ?? ''}</div>
                <small class="text-muted">${tc.email ?? ''}</small>
              </div>
            </div>
          </td>
          <td>${tc.teacher_code ?? ''}</td>
          <td>${subjectsText}</td>
          <td>${totalStudents}</td>
          <td>
            <span class="status-pill ${tc.status === 'Active' ? 'status-active' : 'status-inactive'}">
              ${tc.status ?? ''}
            </span>
          </td>
          <td class="text-end">
            <button class="btn btn-sm btn-outline-primary me-1" data-action="edit" data-id="${tc.id}">
              <i class="bi bi-pencil"></i>
            </button>
            <button class="btn btn-sm btn-outline-danger" data-action="delete" data-id="${tc.id}">
              <i class="bi bi-trash"></i>
            </button>
          </td>
        `;

        tr.addEventListener('click', (e) => {
          if (e.target.closest('button')) return;
          fillSidePanel(tc);
          // تعبئة حقل الصف/الشعبة للقراءة فقط في الفورم لو فتحه بعدين
          if (tcAssignedClasses) {
            const classSections = Array.isArray(tc.assigned_class_sections)
              ? tc.assigned_class_sections
              : [];
            tcAssignedClasses.value = classSections.length ? classSections.join(', ') : '';
          }
        });

        const editBtn = tr.querySelector('button[data-action="edit"]');
        const delBtn = tr.querySelector('button[data-action="delete"]');

        editBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          showForm('edit');

          if (tcDbId) tcDbId.value = tc.id;
          if (tcFullName) tcFullName.value = tc.full_name ?? '';
          if (tcBirthdate) tcBirthdate.value = tc.birthdate ?? '';
          if (tcAge) tcAge.value = tc.age ?? '';
          if (tcPhone) tcPhone.value = tc.phone ?? '';
          if (tcEmail) tcEmail.value = tc.email ?? '';
          if (tcShift) tcShift.value = tc.shift ?? '';
          if (tcDistrict) tcDistrict.value = tc.district ?? '';
          if (tcNeighborhood) tcNeighborhood.value = tc.neighborhood ?? '';
          if (tcStreet) tcStreet.value = tc.street ?? '';
          if (tcAssignedClasses) {
            const classSections = Array.isArray(tc.assigned_class_sections)
              ? tc.assigned_class_sections
              : [];
            tcAssignedClasses.value = classSections.length ? classSections.join(', ') : '';
          }
          if (tcPhoto) tcPhoto.value = '';
        });

        delBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          if (!confirm('Delete this teacher?')) return;
          const url = typeof getDeleteUrl === 'function' ? getDeleteUrl(tc.id) : `/teachers/${tc.id}`;
          fetch(url, {
            method: 'DELETE',
            headers: {
              'X-CSRF-TOKEN': csrf
            }
          })
          .then(res => res.json())
          .then(() => fetchTeachers())
          .catch(console.error);
        });

        teachersTableBody.appendChild(tr);
      });
  }

  function fetchTeachers() {
    const url = typeof getListUrl === 'function' ? getListUrl() : getListUrl;
    fetch(url)
      .then(res => res.json())
      .then(data => {
        teachersData = data;
        renderTeachers();
        if (teachersData.length) fillSidePanel(teachersData[0]);
      })
      .catch(console.error);
  }
  fetchTeachers();

  if (teacherSearch) teacherSearch.addEventListener('input', renderTeachers);
  if (teacherSubjectFilter) teacherSubjectFilter.addEventListener('change', renderTeachers);
  if (teacherStatusFilter) teacherStatusFilter.addEventListener('change', renderTeachers);

  // calc age
  if (calcAgeBtn) {
    calcAgeBtn.addEventListener('click', () => {
      if (!tcBirthdate || !tcBirthdate.value || !tcAge) return;
      const dob = new Date(tcBirthdate.value);
      const today = new Date();
      let age = today.getFullYear() - dob.getFullYear();
      const m = today.getMonth() - dob.getMonth();
      if (m < 0 || (m === 0 && today.getDate() < dob.getDate())) {
        age--;
      }
      tcAge.value = age;
    });
  }

  // حفظ أستاذ (نفس منطق الطلاب: FormData + صورة)
  if (saveTeacherBtn) {
    saveTeacherBtn.addEventListener('click', () => {
      const formData = new FormData();
      formData.append('full_name', tcFullName.value);
      formData.append('birthdate', tcBirthdate ? tcBirthdate.value : '');
      formData.append('age', tcAge ? tcAge.value : '');
      formData.append('phone', tcPhone ? tcPhone.value : '');
      formData.append('email', tcEmail ? tcEmail.value : '');
      formData.append('shift', tcShift ? tcShift.value : '');
      formData.append('district', tcDistrict ? tcDistrict.value : '');
      formData.append('neighborhood', tcNeighborhood ? tcNeighborhood.value : '');
      formData.append('street', tcStreet ? tcStreet.value : '');
      formData.append('status', 'Active');

      if (tcPhoto && tcPhoto.files[0]) {
        formData.append('photo', tcPhoto.files[0]);
      }

      let url = getStoreUrl;
      let method = 'POST';

      if (currentMode === 'edit' && tcDbId && tcDbId.value) {
        if (typeof getUpdateUrl === 'string' && getUpdateUrl.includes('__ID__')) {
          url = getUpdateUrl.replace('__ID__', tcDbId.value);
        } else if (typeof getUpdateUrl === 'function') {
          url = getUpdateUrl(tcDbId.value);
        } else {
          url = `/teachers/${tcDbId.value}`;
        }
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
        fetchTeachers();
        showList();
        clearForm();
        if (teacherSavedAlert) {
          teacherSavedAlert.textContent = 'Teacher saved successfully.';
          teacherSavedAlert.classList.remove('d-none');
        }
      })
      .catch(console.error);
    });
  }

  // import CSV/Excel (نفس منطق الطلاب)
  if (importTeachersBtn && importTeachersInput) {
    importTeachersBtn.addEventListener('click', () => importTeachersInput.click());
    importTeachersInput.addEventListener('change', () => {
      const file = importTeachersInput.files[0];
      if (!file) return;

      const fd = new FormData();
      fd.append('file', file);

      const url = typeof getImportUrl === 'function' ? getImportUrl() : getImportUrl;

      fetch(url, {
        method: 'POST',
        headers: {
          'X-CSRF-TOKEN': csrf,
          'Accept': 'application/json'
        },
        body: fd
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
      .then(() => {
        importTeachersInput.value = '';
        fetchTeachers();
      })
      .catch(console.error);
    });
  }

  if (openTeacherFormBtn) openTeacherFormBtn.addEventListener('click', () => showForm('create'));
  if (backToTeachersBtn) backToTeachersBtn.addEventListener('click', showList);
  if (cancelTeacherBtn) cancelTeacherBtn.addEventListener('click', showList);

  window.__pageCleanup = function () {
    // لو حاب تنظف لسيناريو SPA مستقبلاً
  };
});
