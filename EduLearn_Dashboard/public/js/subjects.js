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

  function loadSubjects() {
    fetch(ROUTES.list)
      .then(res => res.json())
      .then(subjects => {
        tableBody.innerHTML = '';
        subjects.forEach((subject, index) => {
          const tr = document.createElement('tr');

          tr.innerHTML = `
            <td>${index + 1}</td>
            <td><span class="badge text-bg-light">${subject.code}</span></td>
            <td>${subject.name_en ?? ''}</td>
            <td>${subject.name_ar ?? ''}</td>
            <td>
              ${subject.is_active
                ? '<span class="status-pill status-active">Active</span>'
                : '<span class="status-pill status-inactive">Inactive</span>'
              }
            </td>
            <td>
              <button class="btn btn-sm btn-outline-secondary me-1 btn-edit" data-id="${subject.id}">
                <i class="bi bi-pencil"></i>
              </button>
              <button class="btn btn-sm btn-outline-danger btn-delete" data-id="${subject.id}">
                <i class="bi bi-trash"></i>
              </button>
            </td>
          `;
          tableBody.appendChild(tr);
        });

        attachRowEvents();
      })
      .catch(err => console.error('Error loading subjects:', err));
  }

  function attachRowEvents() {
    document.querySelectorAll('.btn-edit').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        fetch(ROUTES.list)
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

            titleEl.textContent = 'Edit Subject';
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

  btnAdd.addEventListener('click', () => {
    idInput.value      = '';
    codeInput.value    = '';
    nameEnInput.value  = '';
    nameArInput.value  = '';
    activeInput.checked= true;

    errorBox.style.display = 'none';
    errorBox.textContent   = '';

    titleEl.textContent = 'Add Subject';
    subjectModal.show();
  });

  formEl.addEventListener('submit', (e) => {
    e.preventDefault();

    const id     = idInput.value;
    const isEdit = !!id;

    const url    = isEdit ? ROUTES.update.replace('__ID__', id) : ROUTES.store;
    const method = isEdit ? 'PUT' : 'POST';

    const payload = {
      code:      codeInput.value,
      name_en:   nameEnInput.value,
      name_ar:   nameArInput.value,
      is_active: activeInput.checked ? 1 : 0,
    };

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
      })
      .catch(err => console.error(err));
  });

  // أول تحميل
  loadSubjects();
});
