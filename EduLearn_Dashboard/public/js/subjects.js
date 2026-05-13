document.addEventListener('DOMContentLoaded', () => {
  const ROUTES = window.SUBJECTS_ROUTES || {};

  const tableBody = document.querySelector('#subjects-table tbody');
  const btnAdd    = document.getElementById('btnAddSubject');
  const modalEl   = document.getElementById('subjectModal');
  const formEl    = document.getElementById('subjectForm');
  const errorBox  = document.getElementById('subjectError');

  const subjectModal = new bootstrap.Modal(modalEl);

  const idInput     = document.getElementById('subject_id');
  const codeInput   = document.getElementById('code');
  const nameEnInput = document.getElementById('name_en');
  const nameArInput = document.getElementById('name_ar');
  const activeInput = document.getElementById('is_active');
  const titleEl     = document.getElementById('subjectModalTitle');

  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  let classesCache = [];

  async function loadClasses() {
    if (!window.CLASSES_API) return;
    try {
      const res = await fetch(window.CLASSES_API);
      classesCache = await res.json();
    } catch (err) {
      console.error('Error loading classes:', err);
    }
  }

  function renderClassCheckboxes(selectedIds = []) {
    const container = document.getElementById('classCheckboxes');
    if (!container) return;
    
    if (classesCache.length === 0) {
      container.innerHTML = `<div class="text-center small text-muted py-2">${window.I18N?.noClasses || 'No classes available'}</div>`;
      return;
    }

    container.innerHTML = '';
    classesCache.forEach(cls => {
      const isChecked = selectedIds.includes(Number(cls.id));
      const html = `
        <div class="form-check mb-2 p-2 rounded-2 transition-all hover-bg-light" style="border: 1px solid transparent;">
          <input class="form-check-input ms-0 me-3 subject-class-chk" type="checkbox" value="${cls.id}" id="chk_cls_${cls.id}" ${isChecked ? 'checked' : ''}>
          <label class="form-check-label d-block cursor-pointer" for="chk_cls_${cls.id}" style="font-size: 0.9rem;">
            <span class="fw-semibold text-dark">${cls.name}</span>
            <span class="d-block text-muted small" style="font-size: 0.75rem;">${cls.grade}${cls.section ? ' - ' + cls.section : ''}</span>
          </label>
        </div>
      `;
      container.insertAdjacentHTML('beforeend', html);
    });
  }

  function loadSubjects() {
    tableBody.innerHTML = `<tr><td colspan="6" class="text-center py-4">
      <div class="spinner-border spinner-border-sm text-primary me-2"></div> ${window.I18N?.loading || 'Loading subjects...'}
    </td></tr>`;
    
    fetch(ROUTES.list + '?t=' + Date.now())
      .then(res => res.json())
      .then(subjects => {
        tableBody.innerHTML = '';
        if (subjects.length === 0) {
          tableBody.innerHTML = `<tr><td colspan="5" class="text-center py-5">
            <div class="empty-state">
               <i class="bi bi-journal-x text-muted" style="font-size: 3rem; opacity: 0.5;"></i>
               <h6 class="mt-3 text-muted fw-bold">${window.I18N?.noData || 'ليس لديك أي مواد حالياً'}</h6>
            </div>
          </td></tr>`;
          return;
        }

        let activeCount = 0;
        let realTeachers = 0;

        subjects.forEach((subject, index) => {
          const isActive = subject.pivot && subject.pivot.is_active || subject.is_active;
          if (isActive) {
             activeCount++;
             realTeachers += subject.teachers_count || 0;
          }

          const tr = document.createElement('tr');

          tr.innerHTML = `
            <td class="text-muted fw-bold" style="padding: 15px;">${index + 1}</td>
            <td>
              <div class="fw-bold text-dark">${subject.name_en ?? '—'}</div>
              <div class="text-muted small" style="font-family: monospace;">${subject.code}</div>
            </td>
            <td class="fw-semibold text-dark">${subject.name_ar ?? '—'}</td>
            <td class="text-center">
              ${isActive 
                ? `<span class="badge rounded-pill bg-success-soft text-success px-3" style="font-size: 0.75rem; border:1px solid currentColor">${window.I18N?.active || 'Active'}</span>`
                : `<span class="badge rounded-pill bg-secondary px-3" style="font-size: 0.75rem;">${window.I18N?.inactive || 'Inactive'}</span>`
              }
            </td>
            <td class="text-end" style="padding-right: 20px;">
              <div class="btn-group shadow-sm" style="border-radius: 8px; overflow: hidden;">
                  <a href="/subjects/${subject.id}/content" class="btn btn-sm btn-light border-end" title="${window.I18N?.content || 'Manage Content'}">
                    <i class="bi bi-folder2-open text-primary"></i> <span class="d-none d-md-inline ms-1 text-dark" style="font-size: 0.75rem; font-weight: 600;">المحتوى</span>
                  </a>
                  <button class="btn btn-sm btn-light border-end btn-edit" data-id="${subject.id}" title="${window.I18N?.editSubject || 'Edit'}">
                    <i class="bi bi-pencil text-muted"></i>
                  </button>
                  <button class="btn btn-sm btn-light btn-delete" data-id="${subject.id}" title="${window.I18N?.deleteSubjectConfirm || 'Delete'}">
                    <i class="bi bi-trash text-danger"></i>
                  </button>
              </div>
            </td>
          `;
          tableBody.appendChild(tr);
        });

        // Update Stat Cards with Real Data
        const totalStat = document.querySelector('.js-stat-total');
        if (totalStat) totalStat.textContent = activeCount;
        
        const teachersStat = document.querySelector('.js-stat-teachers');
        if (teachersStat) teachersStat.textContent = realTeachers; // Total assignments in active subjects

        const coverageStat = document.querySelector('.js-stat-coverage');
        // Coverage is 100% if every active subject has at least one teacher
        const subjectsWithTeachers = subjects.filter(s => (s.pivot && s.pivot.is_active || s.is_active) && s.teachers_count > 0).length;
        const coveragePcnt = activeCount > 0 ? Math.round((subjectsWithTeachers / activeCount) * 100) : 0;
        if (coverageStat) coverageStat.textContent = coveragePcnt + '%';

        attachRowEvents();
      })
      .catch(err => {
        console.error('Error loading subjects:', err);
        tableBody.innerHTML = `<tr><td colspan="5" class="text-center py-4 text-danger">
          <i class="bi bi-exclamation-triangle me-2"></i> ${window.I18N?.errorLoading || 'Error loading subjects. Please try again.'}
        </td></tr>`;
      });
  }

  function attachRowEvents() {
    document.querySelectorAll('.btn-edit').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        fetch(ROUTES.list + '?t=' + Date.now())
          .then(res => res.json())
          .then(subjects => {
            const subject = subjects.find(s => String(s.id) === String(id));
            if (!subject) return;

            idInput.value      = subject.id;
            codeInput.value    = subject.code;
            nameEnInput.value  = subject.name_en || '';
            nameArInput.value  = subject.name_ar || '';
            activeInput.checked= !!subject.is_active;

            errorBox.style.display = 'none';
            errorBox.textContent   = '';

            titleEl.textContent = window.I18N.editSubject || 'Edit Subject';
            
            // Render class checkboxes and tick the assigned ones
            const assignedClassIds = (subject.class_sections || []).map(cs => Number(cs.id));
            renderClassCheckboxes(assignedClassIds);

            subjectModal.show();
          });
      });
    });

    document.querySelectorAll('.btn-delete').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        if (!confirm('Delete this subject?')) return;

        const url = ROUTES.update.replace('__ID__', id);

        fetch(url, {
          method: 'DELETE',
          headers: {
            'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        })
          .then(res => res.json())
          .then(() => loadSubjects())
          .catch(err => console.error('Error deleting subject:', err));
      });
    });
  }

  if (btnAdd) {
    btnAdd.addEventListener('click', () => {
      idInput.value      = '';
      codeInput.value    = '';
      nameEnInput.value  = '';
      nameArInput.value  = '';
      activeInput.checked= true;

      errorBox.style.display = 'none';
      errorBox.textContent   = '';

      titleEl.textContent = window.I18N.addSubject || 'Add Subject';
      
      // Render class checkboxes all unchecked
      renderClassCheckboxes([]);
      
      subjectModal.show();
    });
  }

  formEl.addEventListener('submit', (e) => {
    e.preventDefault();

    const id     = idInput.value;
    const isEdit = !!id;

    const url    = isEdit ? ROUTES.update.replace('__ID__', id) : ROUTES.store;
    const method = isEdit ? 'PUT' : 'POST';

    const selectedClasses = [];
    document.querySelectorAll('.subject-class-chk:checked').forEach(chk => {
      selectedClasses.push(Number(chk.value));
    });

    const payload = {
      code:      codeInput.value,
      name_en:   nameEnInput.value,
      name_ar:   nameArInput.value,
      is_active: activeInput.checked ? 1 : 0,
      class_section_ids: selectedClasses,
    };

    const submitBtn = formEl.querySelector('button[type="submit"]');
    const originalHtml = submitBtn.innerHTML;
    submitBtn.disabled = true;
    submitBtn.innerHTML = `<span class="spinner-border spinner-border-sm me-2"></span> ${window.I18N?.saving || 'Saving...'}`;

    fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': csrfToken,
        'Accept': 'application/json',
      },
      body: JSON.stringify(payload),
    })
      .then(async res => {
        if (!res.ok) {
          const data = await res.json().catch(() => ({}));
          const msg = data.message || 'Error saving subject';
          errorBox.textContent = msg;
          errorBox.style.display = 'block';
          throw new Error(msg);
        }
        return res.json();
      })
      .then(() => {
        subjectModal.hide();
        loadSubjects();
        if (window.showToast) window.showToast('success', 'Saved successfully');
      })
      .catch(err => {
        console.error('Save error:', err);
        if (!errorBox.style.display || errorBox.style.display === 'none') {
            errorBox.textContent = err.message || 'Error saving subject';
            errorBox.style.display = 'block';
        }
      })
      .finally(() => {
        submitBtn.disabled = false;
        submitBtn.innerHTML = originalHtml;
      });
  });

  const refreshBtn = document.querySelector('.js-refresh-list');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      loadSubjects();
    });
  }

  // أول تحميل
  (async () => {
    const container = document.getElementById('classCheckboxes');
    if (container) container.innerHTML = `<div class="text-center small text-muted py-2"><div class="spinner-border spinner-border-sm"></div></div>`;
    
    await loadClasses();
    loadSubjects();
  })();
});
