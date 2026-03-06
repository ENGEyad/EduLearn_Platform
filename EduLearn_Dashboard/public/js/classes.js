document.addEventListener('DOMContentLoaded', () => {
  const ROUTES = window.CLASSES_ROUTES || {};

  const tableBody = document.querySelector('#classes-table tbody');
  const btnAdd    = document.getElementById('btnAddClass');
  const modalEl   = document.getElementById('classModal');
  const formEl    = document.getElementById('classForm');
  const errorBox  = document.getElementById('classError');

  const classModal = new bootstrap.Modal(modalEl);

  const idInput    = document.getElementById('class_id');
  const gradeInput = document.getElementById('grade');
  const sectionInp = document.getElementById('section');
  const nameInput  = document.getElementById('name');
  const stageInput = document.getElementById('stage');
  const activeInput= document.getElementById('class_is_active');
  const titleEl    = document.getElementById('classModalTitle');

  const csrfToken  = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

  function loadClasses() {
    fetch(ROUTES.list)
      .then(res => res.json())
      .then(classes => {
        tableBody.innerHTML = '';
        classes.forEach((c, index) => {
          const tr = document.createElement('tr');

          tr.innerHTML = `
            <td>${index + 1}</td>
            <td>${c.grade}</td>
            <td>${c.section}</td>
            <td>${c.name}</td>
            <td>${c.stage ?? ''}</td>
            <td>
              ${c.is_active
                ? '<span class="status-pill status-active">Active</span>'
                : '<span class="status-pill status-inactive">Inactive</span>'
              }
            </td>
            <td>
              <button class="btn btn-sm btn-outline-secondary me-1 btn-edit" data-id="${c.id}">
                <i class="bi bi-pencil"></i>
              </button>
              <button class="btn btn-sm btn-outline-danger btn-delete" data-id="${c.id}">
                <i class="bi bi-trash"></i>
              </button>
            </td>
          `;
          tableBody.appendChild(tr);
        });

        attachRowEvents();
      })
      .catch(err => console.error('Error loading classes:', err));
  }

  function attachRowEvents() {
    document.querySelectorAll('.btn-edit').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        fetch(ROUTES.list)
          .then(res => res.json())
          .then(classes => {
            const c = classes.find(x => String(x.id) === String(id));
            if (!c) return;

            idInput.value       = c.id;
            gradeInput.value    = c.grade || '';
            sectionInp.value    = c.section || '';
            nameInput.value     = c.name || '';
            stageInput.value    = c.stage || '';
            activeInput.checked = !!c.is_active;

            errorBox.style.display = 'none';
            errorBox.textContent   = '';

            titleEl.textContent = 'Edit Class';
            classModal.show();
          });
      });
    });

    document.querySelectorAll('.btn-delete').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.id;
        if (!confirm('Delete this class?')) return;

        const url = ROUTES.update.replace('__ID__', id);
        fetch(url, {
          method: 'DELETE',
          headers: {
            'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        })
          .then(res => res.json())
          .then(() => loadClasses())
          .catch(err => console.error('Error deleting class:', err));
      });
    });
  }

  btnAdd.addEventListener('click', () => {
    idInput.value       = '';
    gradeInput.value    = '';
    sectionInp.value    = '';
    nameInput.value     = '';
    stageInput.value    = '';
    activeInput.checked = true;

    errorBox.style.display = 'none';
    errorBox.textContent   = '';

    titleEl.textContent = 'Add Class';
    classModal.show();
  });

  formEl.addEventListener('submit', (e) => {
    e.preventDefault();

    const id     = idInput.value;
    const isEdit = !!id;

    const url    = isEdit ? ROUTES.update.replace('__ID__', id) : ROUTES.store;
    const method = isEdit ? 'PUT' : 'POST';

    const payload = {
      grade:     gradeInput.value,
      section:   sectionInp.value,
      name:      nameInput.value,
      stage:     stageInput.value,
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
          const msg  = data.message || 'Error saving class';
          errorBox.textContent = msg;
          errorBox.style.display = 'block';
          throw new Error(msg);
        }
        return res.json();
      })
      .then(() => {
        classModal.hide();
        loadClasses();
      })
      .catch(err => console.error(err));
  });

  loadClasses();
});
