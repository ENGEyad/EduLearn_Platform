document.addEventListener('DOMContentLoaded', () => {
  const ROUTES      = window.ASSIGN_ROUTES || {};
  const TEACHERS_API= window.TEACHERS_API;
  const CLASSES_API = window.CLASSES_API;
  const SUBJECTS_API= window.SUBJECTS_API;

  const tableBody = document.querySelector('#assignments-table tbody');
  const btnAdd    = document.getElementById('btnAddAssignment');
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
  const filterSubject   = document.getElementById('filterSubject');
  const btnResetFilters = document.getElementById('btnResetFilters');

  const csrfToken       = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  let teachersCache = [];
  let classesCache  = [];
  let subjectsCache = [];
  let assignments   = [];

  async function loadBaseData() {
    const [teachersRes, classesRes, subjectsRes] = await Promise.all([
      fetch(TEACHERS_API),
      fetch(CLASSES_API),
      fetch(SUBJECTS_API),
    ]);

    teachersCache = await teachersRes.json();
    classesCache  = await classesRes.json();
    subjectsCache = await subjectsRes.json();

    fillBaseSelects();
  }

  function fillBaseSelects() {
    // teacher selects
    [teacherSelect, filterTeacher].forEach(sel => {
      sel.innerHTML = '';
      if (sel === filterTeacher) {
        const opt = document.createElement('option');
        opt.value = '';
        opt.textContent = 'All teachers';
        sel.appendChild(opt);
      } else {
        const opt = document.createElement('option');
        opt.value = '';
        opt.textContent = 'Select teacher';
        sel.appendChild(opt);
      }

      teachersCache.forEach(t => {
        const o = document.createElement('option');
        o.value = t.id;
        o.textContent = `${t.full_name} (${t.teacher_code || 'no-code'})`;
        sel.appendChild(o);
      });
    });

    // class select + grade filter
    classSelect.innerHTML = '';
    const emptyClass = document.createElement('option');
    emptyClass.value = '';
    emptyClass.textContent = 'Select class';
    classSelect.appendChild(emptyClass);

    const gradesSet = new Set();

    classesCache.forEach(c => {
      const o = document.createElement('option');
      o.value = c.id;
      o.textContent = `${c.name} (${c.grade}${c.section ? '-' + c.section : ''})`;
      classSelect.appendChild(o);

      gradesSet.add(c.grade);
    });

    filterGrade.innerHTML = '';
    const optAllGrades = document.createElement('option');
    optAllGrades.value = '';
    optAllGrades.textContent = 'All grades';
    filterGrade.appendChild(optAllGrades);

    Array.from(gradesSet).sort().forEach(g => {
      const o = document.createElement('option');
      o.value = g;
      o.textContent = g;
      filterGrade.appendChild(o);
    });

    // subjects selects
    [subjectSelect, filterSubject].forEach(sel => {
      sel.innerHTML = '';
      if (sel === filterSubject) {
        const opt = document.createElement('option');
        opt.value = '';
        opt.textContent = 'All subjects';
        sel.appendChild(opt);
      } else {
        const opt = document.createElement('option');
        opt.value = '';
        opt.textContent = 'Select subject';
        sel.appendChild(opt);
      }

      subjectsCache.forEach(s => {
        const o = document.createElement('option');
        o.value = s.id;
        o.textContent = `${s.name_en} (${s.code})`;
        sel.appendChild(o);
      });
    });
  }

  function loadAssignments() {
    fetch(ROUTES.list)
      .then(res => res.json())
      .then(data => {
        assignments = data;
        renderAssignments();
      })
      .catch(err => console.error('Error loading assignments:', err));
  }

  function renderAssignments() {
    const tFilter = filterTeacher.value;
    const gFilter = filterGrade.value;
    const sFilter = filterSubject.value;

    tableBody.innerHTML = '';

    let filtered = assignments;

    if (tFilter) {
      filtered = filtered.filter(a => String(a.teacher_id) === String(tFilter));
    }

    if (gFilter) {
      filtered = filtered.filter(a => String(a.class_section?.grade ?? '') === String(gFilter));
    }

    if (sFilter) {
      filtered = filtered.filter(a => String(a.subject_id) === String(sFilter));
    }

    filtered.forEach((a, index) => {
      const tr = document.createElement('tr');

      const teacherName = a.teacher?.full_name ?? '—';
      const className   = a.class_section?.name ?? '—';
      const grade       = a.class_section?.grade ?? '—';
      const section     = a.class_section?.section ?? '—';
      const subjectName = a.subject?.name_en ?? '—';

      tr.innerHTML = `
        <td>${index + 1}</td>
        <td>${teacherName}</td>
        <td>${className}</td>
        <td>${grade}</td>
        <td>${section}</td>
        <td>${subjectName}</td>
        <td>${a.weekly_load ?? ''}</td>
        <td>
          ${a.is_active
            ? '<span class="status-pill status-active">Active</span>'
            : '<span class="status-pill status-inactive">Inactive</span>'
          }
        </td>
        <td>
          <button class="btn btn-sm btn-outline-danger btn-delete" data-id="${a.id}">
            <i class="bi bi-trash"></i>
          </button>
        </td>
      `;
      tableBody.appendChild(tr);
    });

    document.querySelectorAll('.btn-delete').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        if (!confirm('Delete this assignment?')) return;

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

  btnResetFilters.addEventListener('click', () => {
    filterTeacher.value = '';
    filterGrade.value   = '';
    filterSubject.value = '';
    renderAssignments();
  });

  btnAdd.addEventListener('click', () => {
    teacherSelect.value = '';
    classSelect.value   = '';
    subjectSelect.value = '';
    weeklyInput.value   = '';
    activeInput.checked = true;
    errorBox.style.display = 'none';
    errorBox.textContent   = '';

    assignmentModal.show();
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

    fetch(ROUTES.store, {
      method: 'POST',
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
      .catch(err => console.error(err));
  });

  (async () => {
    await loadBaseData();
    loadAssignments();
  })();
});
