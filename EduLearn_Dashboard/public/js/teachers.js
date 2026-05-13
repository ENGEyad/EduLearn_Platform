document.addEventListener('DOMContentLoaded', () => {
    console.log('Teachers JS: Initializing...');
    const ROUTES = window.TEACHERS_ROUTES || {};
    const STORAGE_BASE_URL = window.STORAGE_BASE_URL || '/storage';
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content || '';

    // UI Elements
    const teachersTableBody = document.querySelector('#teachersTable tbody');
    const teacherSearch = document.getElementById('teacherSearch');
    const teacherSubjectFilter = document.getElementById('teacherSubjectFilter');
    const teacherStatusFilter = document.getElementById('teacherStatusFilter');
    const teachersListView = document.getElementById('teachersListView');
    const teacherFormView = document.getElementById('teacherFormView');
    const teacherProfile = document.getElementById('teacherProfile');
    const sidebarEmptyState = document.getElementById('sidebarEmptyState');
    const importTeachersBtn = document.getElementById('importTeachersBtn');
    const teacherExcelInput = document.getElementById('teacherExcelInput');
    const teacherListActions = document.getElementById('teacherListActions');
    const teacherFormActions = document.getElementById('teacherFormActions');
    
    // Sidebar Elements (prof- prefixed)
    const spAvatar = document.getElementById('prof-avatar');
    const spName = document.getElementById('prof-name');
    const spId = document.getElementById('prof-id');
    const spEmail = document.getElementById('prof-email');
    const spPhone = document.getElementById('prof-phone');
    const spDob = document.getElementById('prof-dob');
    const spSubjects = document.getElementById('prof-subjects');
    const spClasses = document.getElementById('prof-classes');
    const spAddress = document.getElementById('prof-address');
    const spPerformance = document.getElementById('prof-performance');
    const spAttendance = document.getElementById('prof-attendance');

    const sidebarEditBtn = document.querySelector('.js-sidebar-edit');
    const sidebarReportBtn = document.querySelector('.js-sidebar-report');
    const sidebarDeleteBtn = document.querySelector('.js-sidebar-delete');
    
    // Delete Modal
    const deleteModalEl = document.getElementById('deleteTeacherModal');
    const confirmDeleteTeacherBtn = document.getElementById('confirmDeleteTeacherBtn');
    const deleteModal = (deleteModalEl && window.bootstrap && bootstrap.Modal) ? new bootstrap.Modal(deleteModalEl) : null;
    let teacherIdToDelete = null;

    // Form Elements
    const tcDbId = document.getElementById('tcDbId');
    const tcFullName = document.getElementById('tcFullName');
    const tcGender = document.getElementById('tcGender');
    const tcBirthdate = document.getElementById('tcBirthdate');
    const tcEmail = document.getElementById('tcEmail');
    const tcPhone = document.getElementById('tcPhone');
    const tcShift = document.getElementById('tcShift');
    const tcStatus = document.getElementById('tcStatus');
    const tcDistrict = document.getElementById('tcDistrict');
    const tcNeighborhood = document.getElementById('tcNeighborhood');
    const tcStreet = document.getElementById('tcStreet');
    const tcPhoto = document.getElementById('tcPhoto');
    const assignmentsContainer = document.getElementById('assignmentsContainer');
    const addAssignmentRowBtn = document.getElementById('addAssignmentRowBtn');

    let teachersData = [];
    let currentTeacher = null;
    let isDirty = false;
    let currentMode = 'create';

    // --- Core Functions ---

    function showList() {
        teacherFormView.style.display = 'none';
        teachersListView.style.display = 'block';

        if (teacherListActions) teacherListActions.classList.remove('d-none');
        if (teacherFormActions) teacherFormActions.classList.add('d-none');
    }

    function showForm(mode = 'create') {
        currentMode = mode;
        isDirty = false;
        document.getElementById('teacherFormTitle').textContent = 
            mode === 'create' ? (window.I18N?.addNewTeacher || 'Register New Teacher') : (window.I18N?.editTeacher || 'Edit Teacher Profile');
        
        teachersListView.style.display = 'none';
        teacherFormView.style.display = 'block';

        if (teacherListActions) teacherListActions.classList.add('d-none');
        if (teacherFormActions) teacherFormActions.classList.remove('d-none');
        
        // Reset tabs to first
        const firstTab = document.querySelector('#teacherTabs a[href="#tab-basic"]');
        if (firstTab && window.bootstrap?.Tab) {
            new bootstrap.Tab(firstTab).show();
        }
    }

    function buildAddress(tc) {
        const parts = [tc.district, tc.neighborhood, tc.street].filter(Boolean);
        return parts.length ? parts.join(' - ') : '--';
    }

    function getInitials(name) {
        if (!name) return 'TC';
        return name.split(' ').filter(Boolean).map(p => p[0]).join('').slice(0, 2).toUpperCase();
    }

    function fillSidePanel(tc) {
        currentTeacher = tc;
        if (!spName) return;

        // Reveal Profile
        if (sidebarEmptyState) sidebarEmptyState.classList.add('d-none');
        if (teacherProfile) {
            teacherProfile.classList.remove('d-none');
            teacherProfile.classList.remove('animate-update');
            void teacherProfile.offsetWidth; // Trigger reflow
            teacherProfile.classList.add('animate-update');
        }

        spName.textContent = tc.full_name || '--';
        spId.textContent = (window.I18N?.academicIdPrefix || 'Teacher Code: ') + (tc.teacher_code || ('T-' + tc.id));
        spEmail.textContent = tc.email || '--';
        spPhone.textContent = tc.phone || '--';
        spDob.textContent = tc.birthdate || '--';
        spAddress.textContent = buildAddress(tc);

        // Assignments Display
        const subjects = Array.isArray(tc.assigned_subjects) ? tc.assigned_subjects.join(', ') : (tc.subjects || '--');
        const classes = Array.isArray(tc.assigned_class_sections) ? tc.assigned_class_sections.join(', ') : '--';
        
        if (spSubjects) spSubjects.textContent = subjects || '--';
        if (spClasses) spClasses.textContent = classes || '--';

        // Stats
        const perfVal = tc.avg_student_score || 0;
        const attVal = tc.attendance_rate || 0;

        if (spPerformance) spPerformance.textContent = perfVal + '%';
        if (spAttendance) spAttendance.textContent = attVal + '%';

        const perfBar = document.getElementById('prof-perf-bar');
        if (perfBar) perfBar.style.width = perfVal + '%';

        const attBar = document.getElementById('prof-att-bar');
        if (attBar) attBar.style.width = attVal + '%';

        if (spAvatar) {
            if (tc.photo_path) {
                spAvatar.style.backgroundImage = `url('${STORAGE_BASE_URL}/${tc.photo_path}')`;
                spAvatar.style.backgroundSize = 'cover';
                spAvatar.textContent = '';
            } else {
                spAvatar.style.backgroundImage = 'none';
                spAvatar.textContent = getInitials(tc.full_name);
            }
        }
    }

    async function addAssignmentRow(classSectionId = '', subjectId = '') {
        if (!assignmentsContainer) return;
        
        const row = document.createElement('div');
        row.className = 'assignment-row row g-2 p-2 bg-white rounded-3 shadow-sm border mb-2 align-items-center';
        
        let classOptions = `<option value="">${window.I18N?.selectClass || 'Select Class'}</option>`;
        const classes = window.ALL_CLASSES || [];
        classes.forEach(c => {
            const selected = (c.id == classSectionId) ? 'selected' : '';
            classOptions += `<option value="${c.id}" ${selected}>${c.grade} - ${c.section}</option>`;
        });

        row.innerHTML = `
            <div class="col-md-5">
                <select class="form-select class-select bg-light border-0" required>${classOptions}</select>
            </div>
            <div class="col-md-6">
                <select class="form-select subject-select bg-light border-0" required>
                    <option value="">${window.I18N?.selectSubject || 'Select Subject'}</option>
                </select>
            </div>
            <div class="col-md-1 text-center">
                <button type="button" class="btn btn-outline-danger btn-sm border-0 remove-row"><i class="bi bi-trash"></i></button>
            </div>
        `;

        const classSelect = row.querySelector('.class-select');
        const subjectSelect = row.querySelector('.subject-select');

        const populateSubjects = async (cId, sId = '') => {
            if (!window.CLASS_SUBJECTS_API) return;
            subjectSelect.innerHTML = `<option value="">${window.I18N?.selectSubject || 'Loading...'}</option>`;
            try {
                const res = await fetch(`${window.CLASS_SUBJECTS_API}?class_section_id=${cId}`);
                const data = await res.json();
                subjectSelect.innerHTML = `<option value="">${window.I18N?.selectSubject || 'Select Subject'}</option>`;
                data.forEach(s => {
                    const sel = (s.id == sId) ? 'selected' : '';
                    subjectSelect.innerHTML += `<option value="${s.id}" ${sel}>${s.name_en} (${s.name_ar})</option>`;
                });
            } catch (e) {
                subjectSelect.innerHTML = `<option value="">${window.I18N?.selectSubject || 'Select Subject'}</option>`;
            }
        };

        classSelect.addEventListener('change', () => populateSubjects(classSelect.value));
        row.querySelector('.remove-row').addEventListener('click', () => row.remove());

        if (classSectionId) await populateSubjects(classSectionId, subjectId);
        assignmentsContainer.appendChild(row);
    }

    function renderTeachers() {
        if (!teachersTableBody) return;
        teachersTableBody.innerHTML = '';

        const search = teacherSearch?.value.toLowerCase() || '';
        const subjFilter = teacherSubjectFilter?.value.toLowerCase() || '';
        const statFilter = teacherStatusFilter?.value || '';

        console.log('Teachers JS: Rendering teachers...', { search, subjFilter, statFilter });

        const filtered = teachersData.filter(tc => {
            const matchSearch = (tc.full_name || '').toLowerCase().includes(search) || (tc.teacher_code || '').toLowerCase().includes(search);
            const subjects = Array.isArray(tc.assigned_subjects) ? tc.assigned_subjects : [];
            const matchSubj = !subjFilter || subjects.some(s => s.toLowerCase().includes(subjFilter));
            const matchStat = !statFilter || tc.status === statFilter;
            return matchSearch && matchSubj && matchStat;
        });
        
        if (filtered.length === 0) {
            teachersTableBody.innerHTML = `<tr><td colspan="5" class="text-center py-5">
                <div class="empty-state anim-fade-up">
                   <i class="bi bi-person-badge text-muted" style="font-size: 3.5rem; opacity: 0.3;"></i>
                   <h5 class="mt-3 text-navy fw-bold">${window.I18N?.noTeachersRegistered || 'No teachers found'}</h5>
                   <p class="text-muted small">${window.I18N?.startByAddingTeacher || 'Try adjusting your search or add a new teacher.'}</p>
                </div>
            </td></tr>`;
            return;
        }

        filtered.forEach(tc => {
            const tr = document.createElement('tr');
            tr.className = 'cursor-pointer';
            const gender = (tc.gender || '').toLowerCase();
            const genderIcon = gender === 'female' 
                ? '<i class="bi bi-gender-female text-danger"></i>' 
                : '<i class="bi bi-gender-male text-primary"></i>';
            tr.innerHTML = `
                <td class="ps-4">
                    <div class="d-flex align-items-center gap-3">
                        <div style="font-size: 1.1rem;">${genderIcon}</div>
                        <div class="fw-bold text-navy">${tc.full_name}</div>
                    </div>
                </td>
                <td class="text-muted small">${tc.teacher_code || ('T-' + tc.id)}</td>
                <td><span class="badge bg-soft-primary text-primary rounded-pill px-3">${(tc.assigned_subjects || []).slice(0,2).join(', ')}${tc.assigned_subjects?.length > 2 ? '...' : ''}</span></td>
                <td>
                    <span class="status-pill ${tc.status === 'Active' ? 'status-active' : 'status-suspended'}">
                        ${tc.status === 'Active' ? (window.I18N?.active || 'Active') : (window.I18N?.suspended || 'Inactive')}
                    </span>
                </td>
                <td class="text-end pe-4">
                    <div class="btn-group shadow-sm rounded-pill overflow-hidden">
                        <button class="btn btn-sm btn-white border-end edit-btn" title="Edit"><i class="bi bi-pencil text-primary"></i></button>
                        <button class="btn btn-sm btn-white border-end report-btn" title="Report"><i class="bi bi-bar-chart text-info"></i></button>
                        <button class="btn btn-sm btn-white delete-btn" title="Delete"><i class="bi bi-trash text-danger"></i></button>
                    </div>
                </td>
            `;

            tr.addEventListener('click', (e) => {
                if (e.target.closest('button')) return;
                document.querySelectorAll('#teachersTable tr.selected-row').forEach(r => r.classList.remove('selected-row'));
                tr.classList.add('selected-row');
                fillSidePanel(tc);
            });

            tr.querySelector('.edit-btn').addEventListener('click', (e) => { e.stopPropagation(); editTeacher(tc); });
            tr.querySelector('.report-btn').addEventListener('click', (e) => { e.stopPropagation(); window.location.href = `/reports?teacher_id=${tc.id}`; });
            tr.querySelector('.delete-btn').addEventListener('click', (e) => { e.stopPropagation(); confirmDelete(tc.id); });

            teachersTableBody.appendChild(tr);
        });
    }

    function editTeacher(tc) {
        showForm('edit');
        tcDbId.value = tc.id;
        tcFullName.value = tc.full_name || '';
        tcGender.value = tc.gender || '';
        tcBirthdate.value = tc.birthdate ? tc.birthdate.split('T')[0] : '';
        tcEmail.value = tc.email || '';
        tcPhone.value = tc.phone || '';
        tcShift.value = tc.shift || 'Morning';
        tcStatus.value = tc.status || 'Active';
        tcDistrict.value = tc.district || '';
        tcNeighborhood.value = tc.neighborhood || '';
        tcStreet.value = tc.street || '';

        assignmentsContainer.innerHTML = '';
        if (Array.isArray(tc.assignments) && tc.assignments.length) {
            tc.assignments.forEach(a => addAssignmentRow(a.class_section_id, a.subject_id));
        } else {
            addAssignmentRow();
        }
    }

    function confirmDelete(id) {
        if (!confirm(window.I18N?.unexpectedError || 'Are you sure you want to delete this teacher?')) return;
        fetch(ROUTES.destroy(id), {
            method: 'DELETE',
            headers: { 'X-CSRF-TOKEN': csrf }
        }).then(() => fetchTeachers());
    }

    function fetchTeachers() {
        console.log('Teachers JS: Fetching teachers from ' + ROUTES.list);
        fetch(ROUTES.list).then(r => r.json()).then(data => {
            console.log('Teachers JS: Received', data.length, 'teachers');
            teachersData = data;
            renderTeachers();

            if (data.length > 0 && teacherFormView.style.display === 'none') {
                fillSidePanel(data[0]);
                const firstRow = document.querySelector('#teachersTable tbody tr');
                if (firstRow) {
                    firstRow.classList.add('selected-row');
                    if (sidebarEmptyState) sidebarEmptyState.classList.add('d-none');
                    if (teacherProfile) teacherProfile.classList.remove('d-none');
                }
            } else {
                console.log('Teachers JS: No teachers to show in side panel');
            }

            // Populating filter subjects dynamically
            const allSubjs = [...new Set(data.flatMap(t => t.assigned_subjects || []))];
            if (teacherSubjectFilter) {
                teacherSubjectFilter.innerHTML = `<option value="">${window.I18N?.allSubjects || 'All Subjects'}</option>`;
                allSubjs.forEach(s => teacherSubjectFilter.innerHTML += `<option value="${s}">${s}</option>`);
            }
        });
    }

    // Event Listeners
    if (teacherSearch) teacherSearch.addEventListener('input', renderTeachers);
    if (teacherSubjectFilter) teacherSubjectFilter.addEventListener('change', renderTeachers);
    if (teacherStatusFilter) teacherStatusFilter.addEventListener('change', renderTeachers);
    if (document.getElementById('openTeacherFormBtn')) document.getElementById('openTeacherFormBtn').addEventListener('click', () => { showForm('create'); assignmentsContainer.innerHTML = ''; addAssignmentRow(); });
    if (document.getElementById('backToTeachersBtn')) document.getElementById('backToTeachersBtn').addEventListener('click', showList);
    if (document.getElementById('cancelTeacherBtn')) document.getElementById('cancelTeacherBtn').addEventListener('click', showList);
    if (addAssignmentRowBtn) addAssignmentRowBtn.addEventListener('click', () => addAssignmentRow());

    function clearForm() {
        tcDbId.value = '';
        tcFullName.value = '';
        tcGender.value = '';
        tcBirthdate.value = '';
        tcEmail.value = '';
        tcPhone.value = '';
        tcShift.value = 'Morning';
        tcStatus.value = 'Active';
        tcDistrict.value = '';
        tcNeighborhood.value = '';
        tcStreet.value = '';
        tcPhoto.value = '';
        assignmentsContainer.innerHTML = '';
    }

    // Save Logic
    document.getElementById('saveTeacherBtn')?.addEventListener('click', () => {
        // Validation logic
        const requiredFields = [
            { el: tcFullName, label: window.I18N?.fullName || 'Full Name' },
            { el: tcGender, label: window.I18N?.gender || 'Gender' },
            { el: tcBirthdate, label: window.I18N?.birthdate || 'Birthdate' },
            { el: tcShift, label: window.I18N?.shift || 'Shift' }
        ];

        let missing = [];
        requiredFields.forEach(field => {
            if (!field.el.value || field.el.value.trim() === '') {
                missing.push(field.label);
                field.el.classList.add('is-invalid');
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

        // 2. Age Validation (18 - 70 years)
        const bday = new Date(tcBirthdate.value);
        const today = new Date();
        let age = today.getFullYear() - bday.getFullYear();
        const m = today.getMonth() - bday.getMonth();
        if (m < 0 || (m === 0 && today.getDate() < bday.getDate())) age--;

        if (age < 18 || age > 70) {
            Swal.fire({
                title: window.I18N?.error || 'Error',
                text: window.I18N?.invalidTeacherAge || 'Teacher age must be between 18 and 70 years.',
                icon: 'error',
                confirmButtonText: window.I18N?.ok || 'OK'
            });
            tcBirthdate.classList.add('is-invalid');
            return;
        }

        const formData = new FormData();
        formData.append('full_name', tcFullName.value);
        formData.append('gender', tcGender.value);
        formData.append('birthdate', tcBirthdate.value);
        formData.append('email', tcEmail.value);
        formData.append('phone', tcPhone.value);
        formData.append('shift', tcShift.value);
        formData.append('status', tcStatus.value);
        formData.append('district', tcDistrict.value);
        formData.append('neighborhood', tcNeighborhood.value);
        formData.append('street', tcStreet.value);
        if (tcPhoto.files[0]) formData.append('photo', tcPhoto.files[0]);

        const assignments = [];
        document.querySelectorAll('.assignment-row').forEach(row => {
            const cid = row.querySelector('.class-select').value;
            const sid = row.querySelector('.subject-select').value;
            if (cid && sid) assignments.push({ class_section_id: cid, subject_id: sid });
        });
        formData.append('assignments_json', JSON.stringify(assignments));

        const isEdit = currentMode === 'edit' && tcDbId.value !== '';
        const url = isEdit ? ROUTES.update(tcDbId.value) : ROUTES.store;
        if (isEdit) formData.append('_method', 'PUT');

        fetch(url, {
            method: 'POST',
            headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').getAttribute('content') },
            body: formData
        })
        .then(res => {
            if (!res.ok) throw new Error('Save failed');
            return res.json();
        })
        .then(data => {
            Swal.fire({
                title: window.I18N?.success || 'Success',
                text: window.I18N?.teacherSaved || 'Teacher saved successfully',
                icon: 'success',
                confirmButtonText: window.I18N?.ok || 'OK'
            }).then(() => {
                isDirty = false;
                fetchTeachers();
                showList();
                clearForm();
            });
        })
        .catch(err => {
            console.error(err);
            Swal.fire('Error', 'Failed to save records', 'error');
        });
    });

    // Sidebar Actions
    sidebarEditBtn?.addEventListener('click', () => currentTeacher && editTeacher(currentTeacher));
    sidebarReportBtn?.addEventListener('click', () => currentTeacher && (window.location.href = `/reports?teacher_id=${currentTeacher.id}`));
    sidebarDeleteBtn?.addEventListener('click', () => {
        if (!currentTeacher) return;
        teacherIdToDelete = currentTeacher.id;
        deleteModal?.show();
    });

    confirmDeleteTeacherBtn?.addEventListener('click', () => {
        if (!teacherIdToDelete) return;
        const url = typeof ROUTES.destroy === 'function' ? ROUTES.destroy(teacherIdToDelete) : ROUTES.destroy.replace('__ID__', teacherIdToDelete);

        fetch(url, {
            method: 'DELETE',
            headers: { 'X-CSRF-TOKEN': csrf }
        })
        .then(res => {
            if (!res.ok) throw new Error('Delete failed');
            return res.json();
        })
        .then(() => {
            deleteModal?.hide();
            fetchTeachers();
            if (teacherProfile) teacherProfile.style.display = 'none';
            if (sidebarEmptyState) sidebarEmptyState.style.display = 'block';
            Swal.fire('Success', 'Teacher record deleted', 'success');
        })
        .catch(err => {
            console.error(err);
            Swal.fire('Error', 'Failed to delete record', 'error');
        });
    });

    // --- Import Functionality ---
    importTeachersBtn?.addEventListener('click', () => teacherExcelInput?.click());

    teacherExcelInput?.addEventListener('change', function(e) {
        const file = e.target.files[0];
        if (!file) return;

        const formData = new FormData();
        formData.append('file', file);

        const url = typeof ROUTES.import === 'function' ? ROUTES.import() : ROUTES.import;

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
                Swal.fire('Error', window.I18N?.importFailed || 'Import failed', 'error');
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
                    Swal.fire('Success', data.message || window.I18N?.teachersImported || 'Imported!', 'success');
                }
                fetchTeachers();
            } catch(e) { 
                if (window.loadingManager) window.loadingManager.stop();
                Swal.fire('Success', window.I18N?.teachersImported || 'Imported!', 'success');
                fetchTeachers(); 
            }
        })
        .catch(err => {
            console.error(err);
            if (window.loadingManager) window.loadingManager.stop();
            Swal.fire('Error', window.I18N?.unexpectedError || 'An unexpected error occurred', 'error');
        })
        .finally(() => {
            teacherExcelInput.value = ''; // Reset input
        });
    });

    fetchTeachers();
});
