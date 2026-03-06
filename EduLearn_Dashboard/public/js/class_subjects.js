document.addEventListener('DOMContentLoaded', () => {
  const ROUTES       = window.CLASS_SUBJECT_ROUTES || {};
  const CLASSES_API  = window.CLASSES_API;
  const SUBJECTS_API = window.SUBJECTS_API; // ممكن ما نحتاجه الآن، لكن نخليه للاستخدام المستقبلي

  const classSelect        = document.getElementById('class_section_id');
  const selectedClassInfo  = document.getElementById('selectedClassInfo');
  const btnSave            = document.getElementById('btnSaveClassSubjects');
  const noClassSelectedBox = document.getElementById('noClassSelected');
  const tableWrapper       = document.getElementById('subjectsTableWrapper');
  const tableBody          = document.querySelector('#class-subjects-table tbody');

  const errorBox   = document.getElementById('classSubjectsError');
  const successBox = document.getElementById('classSubjectsSuccess');

  const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  let classesCache  = [];
  let subjectsCache = []; // البيانات الحالية للمواد لهذا الصف/الشعبة

  // تحميل الفصول/الشعب
  async function loadClasses() {
    try {
      const res = await fetch(CLASSES_API);
      classesCache = await res.json();

      classSelect.innerHTML = '';
      const opt = document.createElement('option');
      opt.value = '';
      opt.textContent = 'Select class';
      classSelect.appendChild(opt);

      classesCache.forEach(c => {
        const o = document.createElement('option');
        o.value = c.id;
        o.textContent = `${c.name} (${c.grade}${c.section ? '-' + c.section : ''})`;
        classSelect.appendChild(o);
      });
    } catch (err) {
      console.error('Error loading classes:', err);
    }
  }

  // تحميل المواد لهذا الصف/الشعبة
  async function loadClassSubjects() {
    const classId = classSelect.value;
    if (!classId) {
      subjectsCache = [];
      tableBody.innerHTML = '';
      noClassSelectedBox.style.display = 'block';
      tableWrapper.style.display       = 'none';
      btnSave.disabled                 = true;
      selectedClassInfo.textContent    = '';
      return;
    }

    try {
      const url = `${ROUTES.list}?class_section_id=${encodeURIComponent(classId)}`;
      const res = await fetch(url);
      subjectsCache = await res.json();

      renderSubjectsTable();

      const cls = classesCache.find(c => String(c.id) === String(classId));
      if (cls) {
        selectedClassInfo.textContent = `Selected: ${cls.name} (Grade: ${cls.grade}, Section: ${cls.section})`;
      } else {
        selectedClassInfo.textContent = '';
      }

      noClassSelectedBox.style.display = 'none';
      tableWrapper.style.display       = 'block';
      btnSave.disabled                 = false;
      hideMessages();
    } catch (err) {
      console.error('Error loading class subjects:', err);
    }
  }

  function renderSubjectsTable() {
    tableBody.innerHTML = '';

    subjectsCache.forEach((s, index) => {
      const tr = document.createElement('tr');

      const isAssigned = !!s.is_assigned;
      const isSubjectActive = !!s.is_active;

      tr.innerHTML = `
        <td>${index + 1}</td>
        <td><span class="badge text-bg-light">${s.code}</span></td>
        <td>${s.name_en ?? ''}</td>
        <td>${s.name_ar ?? ''}</td>
        <td>
          ${isSubjectActive
            ? '<span class="status-pill status-active">Active</span>'
            : '<span class="status-pill status-inactive">Inactive</span>'
          }
        </td>
        <td class="text-center">
          <input type="checkbox" class="form-check-input subject-assign-checkbox"
            data-id="${s.id}" ${isAssigned ? 'checked' : ''}>
        </td>
      `;

      tableBody.appendChild(tr);
    });
  }

  function hideMessages() {
    errorBox.style.display   = 'none';
    errorBox.textContent     = '';
    successBox.style.display = 'none';
    successBox.textContent   = '';
  }

  // حفظ المواد المختارة
  async function saveClassSubjects() {
    const classId = classSelect.value;
    if (!classId) return;

    hideMessages();

    // نجمع الـ IDs للمواد التي عليها تشيك
    const checkedIds = [];
    document.querySelectorAll('.subject-assign-checkbox').forEach(chk => {
      if (chk.checked) {
        checkedIds.push(Number(chk.dataset.id));
      }
    });

    const payload = {
      class_section_id: Number(classId),
      subject_ids: checkedIds,
    };

    try {
      const res = await fetch(ROUTES.save, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': csrfToken,
          'Accept': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      const data = await res.json().catch(() => ({}));

      if (!res.ok) {
        const msg = data.message || 'Error saving class subjects';
        errorBox.textContent = msg;
        errorBox.style.display = 'block';
        throw new Error(msg);
      }

      successBox.textContent = data.message || 'Saved successfully';
      successBox.style.display = 'block';

      // نعيد التحميل للتأكد من تزامن البيانات
      await loadClassSubjects();
    } catch (err) {
      console.error(err);
    }
  }

  classSelect.addEventListener('change', () => {
    loadClassSubjects();
  });

  btnSave.addEventListener('click', () => {
    saveClassSubjects();
  });

  // تحميل أولي
  (async () => {
    await loadClasses();
    // لا نحمل المواد حتى يختار المستخدم صف/شعبة
  })();
});
