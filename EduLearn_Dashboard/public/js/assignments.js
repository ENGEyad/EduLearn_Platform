document.addEventListener('DOMContentLoaded', () => {
  const ROUTES      = window.ASSIGN_ROUTES || {};
  const TEACHERS_API= window.TEACHERS_API;
  const CLASSES_API = window.CLASSES_API;
  const SUBJECTS_API= window.SUBJECTS_API;
  const CS_API      = window.CLASS_SUBJECTS_API;
  const appLocale   = document.documentElement.lang || 'en';

  const tableBody = document.querySelector('#assignments-table tbody');
  const modalEl   = document.getElementById('assignmentModal');
  const formEl    = document.getElementById('assignmentForm');
  const errorBox  = document.getElementById('assignError');

  const assignmentModal = new bootstrap.Modal(modalEl);

  const teacherSelect   = document.getElementById('teacher_id');
  const classSelect     = document.getElementById('class_section_id');
  const subjectSelect   = document.getElementById('subject_id');
  const weeklyInput     = document.getElementById('weekly_load');
  const activeInput     = document.getElementById('assign_is_active');

  const filterTeacher   = document.getElementById('filterTeacher');
  const filterGrade     = document.getElementById('filterGrade');
  const filterSection   = document.getElementById('filterSection');
  const filterSubject   = document.getElementById('filterSubject');

  const csrfToken       = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  let currentAssignmentId = null;

  let teachersCache = [];
  let classesCache  = [];
  let subjectsCache = [];
  let assignments   = [];
  let classSubjects = [];

  async function loadBaseData() {
    const urls = [
        TEACHERS_API,
        CLASSES_API,
        SUBJECTS_API,
        CS_API || '/class-subjects/list'
    ];

    try {
        const results = await Promise.all(urls.map(u => fetch(u).then(r => r.ok ? r.json() : [])));
        teachersCache = results[0];
        classesCache  = results[1];
        subjectsCache = results[2];
        classSubjects = results[3];
        fillBaseSelects();
    } catch (e) {
        console.error("Base data load failed", e);
    }
  }

  function fillBaseSelects() {
    // teacher selects
    [teacherSelect, filterTeacher].forEach(sel => {
        if (!sel) return;
        sel.innerHTML = '';
        const emptyLabel = sel === filterTeacher ? (window.I18N.allTeachers || 'All teachers') : (window.I18N.selectTeacher || 'Select teacher');
        const opt = document.createElement('option');
        opt.value = '';
        opt.textContent = emptyLabel;
        sel.appendChild(opt);

        teachersCache.forEach(t => {
            const o = document.createElement('option');
            o.value = t.id;
            o.textContent = `${t.full_name} (${t.teacher_code || 'no-code'})`;
            sel.appendChild(o);
        });
    });

    // class select + grade/section filter
    if (classSelect) {
        classSelect.innerHTML = '';
        const opt = document.createElement('option');
        opt.value = '';
        opt.textContent = window.I18N.selectClass || 'Select class';
        classSelect.appendChild(opt);

        const gradesSet = new Set();
        const sectionsSet = new Set();
        
        classesCache.forEach(c => {
            const o = document.createElement('option');
            o.value = c.id;
            o.textContent = `${c.name_ar || c.name} (${c.grade}${c.section ? '-' + c.section : ''})`;
            classSelect.appendChild(o);
            
            if (c.grade) gradesSet.add(c.grade);
            if (c.section) sectionsSet.add(c.section);
        });

        if (filterGrade) {
            filterGrade.innerHTML = '';
            const optAll = document.createElement('option');
            optAll.value = '';
            optAll.textContent = window.I18N.allGrades || 'All grades';
            filterGrade.appendChild(optAll);

            Array.from(gradesSet).sort((a,b) => String(a).localeCompare(String(b), undefined, {numeric: true})).forEach(g => {
                const o = document.createElement('option');
                o.value = g;
                o.textContent = g;
                filterGrade.appendChild(o);
            });
        }

        if (filterSection) {
            filterSection.innerHTML = '';
            const optAll = document.createElement('option');
            optAll.value = '';
            optAll.textContent = window.I18N.allSections || 'All sections';
            filterSection.appendChild(optAll);

            Array.from(sectionsSet).sort().forEach(s => {
                const o = document.createElement('option');
                o.value = s;
                o.textContent = s;
                filterSection.appendChild(o);
            });
        }
    }

    // subjects selects
    [subjectSelect, filterSubject].forEach(sel => {
        if (!sel) return;
        sel.innerHTML = '';
        const emptyLabel = sel === filterSubject ? (window.I18N.allSubjects || 'All subjects') : (window.I18N.selectSubject || 'Select subject');
        const opt = document.createElement('option');
        opt.value = '';
        opt.textContent = emptyLabel;
        sel.appendChild(opt);

        subjectsCache.forEach(s => {
            const o = document.createElement('option');
            o.value = s.id;
            o.textContent = `${appLocale === 'ar' ? (s.name_ar || s.name_en) : s.name_en} (${s.code})`;
            sel.appendChild(o);
        });
    });
  }

  function loadAssignments() {
    fetch(ROUTES.list)
      .then(res => res.json())
      .then(data => {
        assignments = Array.isArray(data) ? data : [];
        updateStats();
        renderAssignments();
      })
      .catch(err => {
          console.error('Error loading assignments:', err);
          renderAssignments();
      });
  }

  function updateStats() {
      const total = assignments.length;
      const avgLoad = assignments.length > 0 
        ? (assignments.reduce((acc, a) => acc + (a.weekly_load || 0), 0) / assignments.length).toFixed(1)
        : 0;
      
      const teacherIds = new Set(assignments.map(a => a.teacher_id));
      
      // Coverage: assigned slots / total active slots (ClassSectionSubject)
      const activeSlots = Array.isArray(classSubjects) ? classSubjects.filter(cs => cs.is_active !== false).length : 0;
      const coverage = activeSlots > 0 ? Math.round((total / activeSlots) * 100) : 0;

      const totalEl = document.querySelector('.js-stat-total');
      const avgEl   = document.querySelector('.js-stat-avg-load');
      const covEl   = document.querySelector('.js-stat-coverage');
      const teachEl = document.querySelector('.js-stat-teachers');

      if (totalEl) totalEl.textContent = total;
      if (avgEl)   avgEl.textContent   = avgLoad + ' h/w';
      if (covEl)   covEl.textContent   = coverage + '%';
      if (teachEl) teachEl.textContent = teacherIds.size;

      // Unassigned Teachers Logic
      const unassignedTeachers = teachersCache.filter(t => !teacherIds.has(t.id));
      const alertEl = document.getElementById('unassigned-alert');
      const listEl = document.getElementById('unassigned-list');

      if (alertEl && listEl) {
        if (unassignedTeachers.length > 0) {
          alertEl.style.display = 'block';
          listEl.innerHTML = `<strong>${window.I18N.unassignedLabel || 'Unassigned:'}</strong> ` +
            unassignedTeachers.map(t => `<span class="badge bg-white text-dark border me-1">${t.full_name}</span>`).join(' ');
        } else {
          alertEl.style.display = 'none';
        }
      }
  }

  function renderAssignments() {
    const tFilter = filterTeacher.value;
    const gFilter = filterGrade.value;
    const secFilter = filterSection ? filterSection.value : '';
    const sFilter = filterSubject.value;

    tableBody.innerHTML = '';

    let filtered = assignments;

    if (tFilter) {
      filtered = filtered.filter(a => String(a.teacher_id) === String(tFilter));
    }

    if (gFilter) {
      filtered = filtered.filter(a => String(a.class_section?.grade ?? '') === String(gFilter));
    }

    if (secFilter) {
      filtered = filtered.filter(a => String(a.class_section?.section ?? '') === String(secFilter));
    }

    if (sFilter) {
      filtered = filtered.filter(a => String(a.subject_id) === String(sFilter));
    }

    filtered.forEach((a, index) => {
      const tr = document.createElement('tr');

      const teacherName = a.teacher?.full_name ?? '—';
      const className   = a.class_section?.display_name ?? '—';
      const subjectName = a.subject?.[appLocale === 'en' ? 'name_en' : 'name_ar'] ?? a.subject?.name_en ?? '—';
      
      const load = a.weekly_load || 0;
      let loadClass = 'bg-success';
      if (load > 20) loadClass = 'bg-warning text-dark';
      if (load > 30) loadClass = 'bg-danger';

      tr.innerHTML = `
        <td style="padding: 15px;">
            <div class="fw-bold">${teacherName}</div>
            <div class="text-muted small">${a.teacher?.teacher_code || ''}</div>
        </td>
        <td>
            <div class="badge bg-light text-dark border">${className}</div>
        </td>
        <td>${subjectName}</td>
        <td>
            <div class="d-flex align-items-center gap-2">
                <div class="progress flex-grow-1" style="height: 6px; width: 60px;">
                    <div class="progress-bar ${loadClass}" style="width: ${Math.min((load/40)*100, 100)}%"></div>
                </div>
                <span class="small fw-bold">${load} h/w</span>
            </div>
        </td>
        <td class="text-center">
          ${a.is_active
            ? `<span class="badge rounded-pill bg-primary-soft text-primary" style="font-size: 0.7rem; border:1px solid currentColor">${window.I18N.active || 'Active'}</span>`
            : `<span class="badge rounded-pill bg-secondary text-white" style="font-size: 0.7rem;">${window.I18N.inactive || 'Inactive'}</span>`
          }
        </td>
        <td class="text-end" style="padding-right: 20px;">
          <div class="btn-group shadow-sm" style="border-radius: 8px; overflow: hidden;">
              <a href="/subjects/${a.subject_id}/content" class="btn btn-sm btn-light border-end" title="${window.I18N.viewContent || 'Content'}">
                <i class="bi bi-journal-text text-muted"></i>
              </a>
              <a href="/reports?teacher_id=${a.teacher_id}" class="btn btn-sm btn-light border-end" title="${window.I18N.viewReport || 'Performance'}">
                <i class="bi bi-graph-up text-info"></i>
              </a>
              <button class="btn btn-sm btn-light border-end btn-edit" data-id="${a.id}" data-teacher="${a.teacher_id}" data-class="${a.class_section_id}" data-subject="${a.subject_id}" data-weekly="${a.weekly_load || ''}" data-active="${a.is_active}">
                <i class="bi bi-pencil text-primary"></i>
              </button>
              <button class="btn btn-sm btn-light text-danger btn-delete" data-id="${a.id}">
                <i class="bi bi-trash"></i>
              </button>
          </div>
        </td>
      `;
      tableBody.appendChild(tr);
    });

    document.querySelectorAll('.btn-edit').forEach(btn => {
      btn.addEventListener('click', () => {
        currentAssignmentId = btn.dataset.id;
        teacherSelect.value = btn.dataset.teacher;
        classSelect.value   = btn.dataset.class;
        subjectSelect.value = btn.dataset.subject;
        weeklyInput.value   = btn.dataset.weekly;
        activeInput.checked = btn.dataset.active === "1" || btn.dataset.active === "true";
        errorBox.style.display = 'none';
        errorBox.textContent   = '';
        
        document.getElementById('assignmentModalTitle').textContent = window.I18N.editAssignment || 'Modify Assignment';
        teacherSelect.disabled = true; // Prevents changing the teacher of an assignment
        assignmentModal.show();
      });
    });

    document.querySelectorAll('.btn-delete').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        if (!confirm(window.I18N.deleteAssignmentConfirm || 'Delete this assignment?')) return;

        const url = ROUTES.destroy.replace('__ID__', id);

        fetch(url, {
          method: 'DELETE',
          headers: {
            'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        })
          .then(res => res.json())
          .then(() => loadAssignments())
          .catch(err => console.error('Error deleting assignment:', err));
      });
    });

  }

  // Automatically filter when a dropdown value changes
  [filterTeacher, filterGrade, filterSection, filterSubject].forEach(el => {
    if (el) el.addEventListener('change', renderAssignments);
  });

  formEl.addEventListener('submit', (e) => {
    e.preventDefault();

    const payload = {
      teacher_id:       teacherSelect.value,
      class_section_id: classSelect.value,
      subject_id:       subjectSelect.value,
      weekly_load:      weeklyInput.value ? Number(weeklyInput.value) : null,
      is_active:        activeInput.checked ? 1 : 0,
    };

    let url = ROUTES.store;
    let method = 'POST';

    if (currentAssignmentId) {
        url = ROUTES.update.replace('__ID__', currentAssignmentId);
        method = 'PUT';
        teacherSelect.disabled = false; // re-enable before submit to get its value if needed, though we already have it
    }

    fetch(url, {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-TOKEN': csrfToken,
        'Accept': 'application/json',
      },
      body: JSON.stringify(payload),
    })
      .then(async res => {
        const data = await res.json().catch(() => ({}));
        if (!res.ok && res.status !== 409) {
          const msg = data.message || 'Error saving assignment';
          errorBox.textContent = msg;
          errorBox.style.display = 'block';
          throw new Error(msg);
        }

        if (res.status === 409) {
          const msg = data.message || 'Already exists';
          errorBox.textContent = msg;
          errorBox.style.display = 'block';
          // نسمح للمستخدم يشوف الرسالة فقط
          throw new Error(msg);
        }

        return data;
      })
      .then(() => {
        assignmentModal.hide();
        loadAssignments();
      })
      .catch(err => {
         console.error(err);
         teacherSelect.disabled = false;
      });
  });

  (async () => {
    await loadBaseData();
    loadAssignments();
  })();
});
