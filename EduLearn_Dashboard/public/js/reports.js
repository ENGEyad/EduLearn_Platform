document.addEventListener('DOMContentLoaded', () => {
  /* ========== Chart.js defaults (شكل) ========== */
  if (window.Chart) {
    Chart.defaults.responsive = true;
    Chart.defaults.maintainAspectRatio = false;
    Chart.defaults.animation = false;
    Chart.defaults.resizeDelay = 200;
    Chart.defaults.font.family = 'Inter, system-ui, -apple-system, Segoe UI, Roboto, Arial';
    Chart.defaults.color = '#6b7280';
    Chart.defaults.scale.grid.color = '#eef2f7';
    Chart.defaults.elements.bar.borderRadius = 10;
    Chart.defaults.elements.line.tension = 0.35;
    Chart.defaults.plugins.legend.display = false;
    Chart.defaults.plugins.tooltip.enabled = true;
  }
  const quietOpts = {
    responsive: true,
    maintainAspectRatio: false,
    animation: false,
    plugins: { legend: { display: false } },
    scales: {
      y: { beginAtZero: true, ticks: { precision: 0 } },
      x: { ticks: { autoSkip: true, maxRotation: 0 } }
    }
  };
  const brandColors = ['#001A33', '#FF6600', '#003366', '#FF8533', '#1e293b', '#94a3b8', '#10b981'];


  /* ========== Routes (بدون تغيير في الباك) ========== */
  const ROUTES = window.REPORTS_ROUTES || {};
  const urlList = ROUTES.list || '/reports/list';
  const urlClass = (grade, section) => (ROUTES.class || '/reports/class/__GRADE__/__SECTION__')
    .replace('__GRADE__', encodeURIComponent(grade || ''))
    .replace('__SECTION__', encodeURIComponent(section || ''));
  const urlStudent = (id) => (ROUTES.student || '/reports/student/__ID__').replace('__ID__', id);
  // جديد (اختياري): إن وفّرت راوت للموضوع
  const urlSubject = (studentId, subjectId) => (ROUTES.subject || '/reports/student/__SID__/subject/__SUBID__')
    .replace('__SID__', studentId)
    .replace('__SUBID__', subjectId);
  const urlTeacher = (id) => (ROUTES.teacher || '/reports/teacher/__ID__').replace('__ID__', id);

  /* ========== Views ========== */
  const reportsListView = document.getElementById('reportsListView');
  const classReportView = document.getElementById('classReportView');
  const studentReportView = document.getElementById('studentReportView');
  const subjectReportView = document.getElementById('subjectReportView');
  const classCardsView = document.getElementById('classCardsView');
  const teacherReportView = document.getElementById('teacherReportView');
  const atRiskReportView = document.getElementById('atRiskReportView');
  const generateModal = new bootstrap.Modal(document.getElementById('generateReportModal'));
  const aiReportModalEl = document.getElementById('aiAnalyticsReportModal');
  const aiReportModal = aiReportModalEl ? new bootstrap.Modal(aiReportModalEl) : null;
  const aiArchiveModalEl = document.getElementById('aiReportsArchiveModal');
  const aiArchiveModal = aiArchiveModalEl ? new bootstrap.Modal(aiArchiveModalEl) : null;

  /* ========== List/Table UI ========== */
  const tBody = document.querySelector('#classesTable tbody');
  const resultsInfo = document.getElementById('resultsInfo');
  const pager = document.getElementById('pager');

  const filterSearch = document.getElementById('filterSearch');
  const filterClass = document.getElementById('filterClass');
  const filterSubject = document.getElementById('filterSubject');

  const classTitleEl = classReportView?.querySelector('.js-class-title');
  const statStudentsEl = classReportView?.querySelector('.js-students-count');
  const statAvgScoreEl = classReportView?.querySelector('.js-avg-score');
  const statPassRateEl = classReportView?.querySelector('.js-pass-rate');
  const statAttendanceEl = classReportView?.querySelector('.js-attendance');
  const statStudyTimeEl = classReportView?.querySelector('.js-study-time');
  const studentCardsContainer = document.getElementById('studentCardsContainer');
  const cardsClassTitleEl = document.querySelector('.js-cards-class-title');

  let gradeChart, progressChart, timeChart, completionChart, testsChart;
  let teacherActivityChart, teacherClassChart;
  const safeDestroy = (c) => { try { c?.destroy?.(); } catch (e) { } };

  const state = { page: 1, perPage: 6, total: 0, items: [], students: [], search: '' };
  let currentGrade = null;
  let currentSection = null;
  let currentStudentId = null; // لملاحة تقرير المادة
  let currentTeacherId = null;
  let currentSubjectId = null;
  let currentSubjectName = null;

  /* ===== Helpers to draw charts ===== */
  function drawGradeChart(items) {
    const ctx = document.getElementById('gradeChart');
    if (!ctx) return;
    safeDestroy(gradeChart);
    const labels = items.map(i => i.label ?? i.name ?? '');
    const values = items.map(i => i.value ?? i.count ?? 0);
    const colors = labels.map((_, idx) => brandColors[idx % brandColors.length]);

    gradeChart = new Chart(ctx, {
      type: 'bar',
      data: { labels, datasets: [{ label: 'Students', data: values, backgroundColor: colors, borderWidth: 0, borderRadius: 10, barThickness: 20 }] },
      options: { ...quietOpts, indexAxis: 'y' }
    });

    Chart.register({
      id: 'barCountsReports',
      afterDatasetsDraw(c) {
        if (c !== gradeChart) return;
        const { ctx } = c, meta = c.getDatasetMeta(0);
        ctx.save(); ctx.fillStyle = '#0f172a'; ctx.font = '700 12px Inter';
        c.data.datasets[0].data.forEach((val, i) => {
          const bar = meta.data[i]; if (!bar) return;
          ctx.textAlign = 'right'; ctx.textBaseline = 'middle';
          ctx.fillText(val, bar.x - 8, bar.y);
        });
        ctx.restore();
      }
    });
    gradeChart.update();
  }

  function drawStudentCharts(progress, timeBySubject) {
    const pctx = document.getElementById('progressChart');
    if (pctx && progress?.labels && progress?.values) {
      const ctx = pctx.getContext('2d');
      const grad = ctx.createLinearGradient(0, 0, 0, 300);
      grad.addColorStop(0, 'rgba(0, 26, 51, 0.2)');
      grad.addColorStop(1, 'rgba(0, 26, 51, 0)');

      safeDestroy(progressChart);
      progressChart = new Chart(pctx, {
        type: 'line',
        data: {
          labels: progress.labels,
          datasets: [{ 
            label: 'Score %', 
            data: progress.values, 
            borderColor: '#001A33', 
            backgroundColor: grad, 
            fill: true, 
            tension: 0.4,
            pointRadius: 4,
            pointBackgroundColor: '#001A33' 
          }]
        },
        options: quietOpts
      });
    }

    const tctx = document.getElementById('timeChart');
    if (tctx && timeBySubject?.labels && timeBySubject?.values) {
      safeDestroy(timeChart);
      timeChart = new Chart(tctx, {
        type: 'doughnut',
        data: {
          labels: timeBySubject.labels,
          datasets: [{ data: timeBySubject.values, backgroundColor: brandColors, borderWidth: 0 }]
        },
        options: {
          ...quietOpts,
          cutout: '70%',
          plugins: {
            legend: { display: true, position: 'right', labels: { usePointStyle: true, boxWidth: 8, font: { size: 11, family: 'Inter' } } }
          }
        }
      });
    }
  }

  function drawSubjectCharts(completion, tests) {
    const cctx = document.getElementById('completionChart');
    if (cctx && completion != null) {
      safeDestroy(completionChart);
      completionChart = new Chart(cctx, {
        type: 'doughnut',
        data: {
          labels: [window.I18N?.completed || 'Completed', window.I18N?.remaining || 'Remaining'],
          datasets: [{ data: [completion, Math.max(0, 100 - completion)], backgroundColor: [brandColors[1], '#e2e8f0'], borderWidth: 0 }]
        },
        options: { ...quietOpts, cutout: '75%', plugins: { tooltip: { enabled: false } } },
        plugins: [{
          id: 'textCenter',
          beforeDraw: function (chart) {
            const width = chart.width, height = chart.height, ctx = chart.ctx;
            ctx.restore();
            const fontSize = (height / 80).toFixed(2);
            ctx.font = `600 ${fontSize}em Inter`;
            ctx.textBaseline = 'middle';
            ctx.fillStyle = '#0f172a';
            const text = completion + '%', textX = Math.round((width - ctx.measureText(text).width) / 2), textY = height / 2;
            ctx.fillText(text, textX, textY);
            ctx.save();
          }
        }]
      });
    }

    const tctx = document.getElementById('testsChart');
    if (tctx && tests?.labels && tests?.values) {
      safeDestroy(testsChart);
      testsChart = new Chart(tctx, {
        type: 'bar',
        data: { labels: tests.labels, datasets: [{ label: 'Score %', data: tests.values, borderRadius: 8 }] },
        options: quietOpts
      });
    }
  }

  function drawTeacherCharts(timeline, contentStats) {
    const actCtx = document.getElementById('teacherActivityChart');
    if (actCtx && timeline) {
      const ctx = actCtx.getContext('2d');
      const grad1 = ctx.createLinearGradient(0, 0, 0, 300);
      grad1.addColorStop(0, 'rgba(0, 26, 51, 0.2)');
      grad1.addColorStop(1, 'rgba(0, 26, 51, 0)');

      const grad2 = ctx.createLinearGradient(0, 0, 0, 300);
      grad2.addColorStop(0, 'rgba(255, 102, 0, 0.2)');
      grad2.addColorStop(1, 'rgba(255, 102, 0, 0)');

      safeDestroy(teacherActivityChart);
      teacherActivityChart = new Chart(actCtx, {
        type: 'line',
        data: {
          labels: timeline.labels,
          datasets: [
            { 
                label: window.I18N?.lessons || 'Lessons', 
                data: timeline.lessons, 
                borderColor: '#001A33', 
                backgroundColor: grad1, 
                fill: true,
                tension: 0.4,
                pointRadius: 4,
                pointBackgroundColor: '#001A33'
            },
            { 
                label: window.I18N?.exercises || 'Exercises', 
                data: timeline.exercises, 
                borderColor: '#FF6600', 
                backgroundColor: grad2, 
                fill: true,
                tension: 0.4,
                pointRadius: 4,
                pointBackgroundColor: '#FF6600'
            }
          ]
        },
        options: { ...quietOpts, plugins: { legend: { display: true } } }
      });
    }

    const clsCtx = document.getElementById('teacherClassChart');
    if (clsCtx && contentStats) {
      safeDestroy(teacherClassChart);
      teacherClassChart = new Chart(clsCtx, {
        type: 'bar',
        data: {
          labels: contentStats.map(c => c.class),
          datasets: [{
            label: 'Avg Score %',
            data: contentStats.map(c => c.avg_score),
            backgroundColor: brandColors[2],
            borderRadius: 8
          }]
        },
        options: { ...quietOpts, indexAxis: 'y' }
      });
    }
  }

  /* ===== Data: Classes list ===== */
  async function fetchClasses() {
    const qs = new URLSearchParams();
    if (state.search) qs.set('search', state.search);
    if (filterClass?.value) qs.set('class', filterClass.value);
    if (filterSubject?.value) qs.set('subject', filterSubject.value);

    const res = await fetch(`${urlList}?${qs.toString()}`);
    if (!res.ok) { console.error('Failed to load classes'); return; }
    const json = await res.json();
    state.total = (json.meta && json.meta.total) || (state.items.length + state.students.length);

    // Update Top Stats Widgets (Simulated or from JSON)
    const topStudents = document.getElementById('topStatStudents');
    const topAvg = document.getElementById('topStatAvg');
    const topAtt = document.getElementById('topStatAtt');
    const topLessons = document.getElementById('topStatLessons');

    if(topStudents) topStudents.textContent = json.school_stats?.total_students || state.total;
    if(topAvg) topAvg.textContent = (json.school_stats?.avg_score || 84) + '%';
    if(topAtt) topAtt.textContent = (json.school_stats?.attendance || 92) + '%';
    if(topLessons) topLessons.textContent = json.school_stats?.total_lessons || 1240;

    renderTable();
    renderPager();

    // We are now fetching filters statically from Blade, so we removed the dynamic fill logic.
  }

  function renderTable() {
    tBody.innerHTML = '';

    // Combine items + students for pagination
    const combined = [...state.items, ...state.students];

    if (!combined.length) {
      tBody.innerHTML = `<tr><td colspan="2" class="text-center text-muted py-4">${window.I18N?.noMatchingResults || 'No matching results'}</td></tr>`;
      resultsInfo.textContent = (window.I18N?.showingResults || 'Showing :count of :total result(s) (page :page)')
        .replace(':count', '0').replace(':total', '0').replace(':page', state.page);
      return;
    }
    const start = (state.page - 1) * state.perPage;
    const pageItems = combined.slice(start, start + state.perPage);

    pageItems.forEach(row => {
      const tr = document.createElement('tr');

      // Is it a student or a class?
      if (row.full_name) {
        // Student Row
        const display = `${row.full_name} (${row.academic_id || 'ID N/A'})`;
        const classInfo = `${row.grade ?? ''} - ${row.class_section ?? ''}`;
        const avatarSrc = row.photo_url ? row.photo_url : window.DEFAULT_AVATAR;
        
        tr.innerHTML = `
          <td>
            <div class="d-flex align-items-center">
                <img class="avatar-circle me-3" src="${avatarSrc}" loading="lazy" decoding="async" alt="Student" style="width: 32px; height: 32px; object-fit: cover; border-radius: 50%;">
                <div>
                    <span class="fw-semibold d-block">${display}</span>
                    <span class="text-muted small">${classInfo}</span>
                </div>
            </div>
          </td>
          <td class="text-end">
            <button class="btn btn-sm btn-outline-info js-open-student-direct" data-student="${row.id}">
              ${window.I18N?.viewStudentReport || 'View Student Report'}
            </button>
          </td>
        `;
      } else {
        // Class Row
        const display = `${row.grade ?? ''} - ${row.class_section ?? ''}`;
        tr.innerHTML = `
          <td>
            <div class="d-flex align-items-center">
                <div class="avatar-circle me-3" style="width: 32px; height: 32px; font-size: 12px; background: #F0FDF4; color: #16A34A;">CL</div>
                <div>
                    <span class="fw-semibold d-block">${display}</span>
                    <span class="text-muted small">${row.students_count} ${window.I18N?.students || 'students'}</span>
                </div>
            </div>
          </td>
          <td class="text-end">
            <button class="btn btn-sm btn-outline-primary" data-grade="${row.grade ?? ''}" data-section="${row.class_section ?? ''}">
              ${window.I18N?.viewClassReport || 'View Class Report'}
            </button>
          </td>
        `;
      }

      tBody.appendChild(tr);
    });

    resultsInfo.textContent = (window.I18N?.showingResults || 'Showing :count of :total result(s) (page :page)')
        .replace(':count', pageItems.length).replace(':total', state.total).replace(':page', state.page);

    tBody.querySelectorAll('button[data-grade]').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const grade = e.currentTarget.getAttribute('data-grade') || 'unknown';
        const section = e.currentTarget.getAttribute('data-section') || 'unknown';
        await openClassReport(grade, section);
      });
    });

    tBody.querySelectorAll('.js-open-student-direct').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const studentId = e.currentTarget.getAttribute('data-student');
        await openStudentReport(studentId);
      });
    });
  }

  function renderPager() {
    pager.innerHTML = '';
    const totalPages = Math.max(1, Math.ceil(state.total / state.perPage));
    const add = (label, page, disabled = false, active = false) => {
      const li = document.createElement('li');
      li.className = `page-item ${disabled ? 'disabled' : ''} ${active ? 'active' : ''}`;
      const a = document.createElement('a');
      a.className = 'page-link';
      a.href = '#';
      a.textContent = label;
      a.onclick = (ev) => { ev.preventDefault(); if (disabled || active) return; state.page = page; renderTable(); renderPager(); };
      li.appendChild(a); pager.appendChild(li);
    };
    add(window.I18N?.previous || 'Previous', state.page - 1, state.page === 1);
    const totalPagesToShow = Math.min(totalPages, 5);
    let start = Math.max(1, state.page - 2);
    let end = Math.min(totalPages, start + totalPagesToShow - 1);
    if (end - start < totalPagesToShow - 1) { start = Math.max(1, end - totalPagesToShow + 1); }
    for (let p = start; p <= end; p++) add(String(p), p, false, p === state.page);
    add(window.I18N?.next || 'Next', state.page + 1, state.page === totalPages);
  }

  /* ===== Class report ===== */
  async function openClassReport(grade, section) {
    currentGrade = grade;
    currentSection = section;

    const res = await fetch(urlClass(grade, section));
    if (!res.ok) { alert('Failed to load class report'); return; }
    const json = await res.json();

    classTitleEl && (classTitleEl.textContent = `${json.grade ?? grade} - ${window.I18N?.section || 'Section'} ${json.section ?? section}`);
    statStudentsEl && (statStudentsEl.textContent = json.stats?.students ?? '--');
    statAvgScoreEl && (statAvgScoreEl.textContent = (json.stats?.avg_score ?? 0).toString());
    statPassRateEl && (statPassRateEl.textContent = ((json.stats?.pass_rate ?? 0) * 100).toFixed(0) + '%');
    statAttendanceEl && (statAttendanceEl.textContent = ((json.stats?.attendance ?? 0) * 100).toFixed(0) + '%');
    statStudyTimeEl && (statStudyTimeEl.textContent = (json.stats?.study_time ?? 0) + ' ' + (window.I18N?.hrs || 'hrs'));

    // students table
    const sTbody = document.querySelector('#studentsTable tbody');
    sTbody.innerHTML = '';
    (json.students || []).forEach(s => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${s.name ?? ''}</td>
        <td>${s.academic_id ?? ('S' + s.id)}</td>
        <td>${s.section ?? ''}</td>
        <td>${s.score ?? ''}</td>
        <td>${s.attendance ?? ''}</td>
        <td><a class="action-link js-open-student" href="#" data-student="${s.id}">${window.I18N?.viewReport || 'View report'}</a></td>
      `;
      sTbody.appendChild(tr);
    });
    sTbody.querySelectorAll('.js-open-student').forEach(a => {
      a.onclick = async (ev) => { ev.preventDefault(); await openStudentReport(a.dataset.student); };
    });

    drawGradeChart(json.grade_distribution || []);

    // switch views
    reportsListView.style.display = 'none';
    classReportView.style.display = '';
    studentReportView.style.display = 'none';
    subjectReportView.style.display = 'none';
  }

  /* ===== Student report ===== */
  async function openStudentReport(id) {
    const res = await fetch(urlStudent(id));
    if (!res.ok) { alert('Failed to load student report'); return; }
    const json = await res.json();
    currentStudentId = id;

    const name = json.student?.name || '--';
    const cls = json.student?.class || '--';
    const section = json.student?.section || '--';

    const nameEl = document.querySelector('.student-head .js-student-name');
    const crumbsEl = document.querySelector('.js-student-name-breadcrumb');
    const avatarEl = document.querySelector('.student-head .avatar');
    const classEl = document.querySelector('.student-head .js-student-class');

    nameEl && (nameEl.textContent = name);
    crumbsEl && (crumbsEl.textContent = name);
    classEl && (classEl.textContent = `${cls}, ${window.I18N?.section || 'Section'} ${section}`);

    if (avatarEl) {
      avatarEl.innerHTML = '';
      avatarEl.style.padding = '0';
      avatarEl.style.overflow = 'hidden';
      const imgSrc = json.student?.photo_url ? json.student.photo_url : window.DEFAULT_AVATAR;
      avatarEl.innerHTML = `<img src="${imgSrc}" loading="lazy" decoding="async" alt="${name}" style="width: 100%; height: 100%; object-fit: cover;">`;
    }

    const set = (sel, txt) => { const el = document.querySelector(sel); if (el) el.textContent = txt; };
    set('.js-s-avg', (json.stats?.avg_score != null) ? (json.stats.avg_score).toFixed(1) + '%' : '--');
    set('.js-s-pass', (json.stats?.pass_rate != null) ? (json.stats.pass_rate * 100).toFixed(0) + '%' : '--');
    set('.js-s-att', (json.stats?.attendance != null) ? (json.stats.attendance * 100).toFixed(0) + '%' : '--');
    set('.js-s-time', (json.stats?.study_time != null) ? (json.stats.study_time + ' ' + (window.I18N?.hrs || 'hrs')) : '--');

    // subjects table (نضيف data-subject + data-student)
    const subjTbody = document.querySelector('.js-subjects-table tbody');
    if (subjTbody) {
      subjTbody.innerHTML = '';
      (json.subjects || []).forEach(sub => {
        const sid = sub.id || sub.name || ''; // Fallback properly if null or undefined
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${sub.name || '--'}</td>
          <td>${((sub.score || 0) * 100).toFixed(0)}%</td>
          <td>${sub.rank || '--'}</td>
          <td>${sub.time || '--'}</td>
          <td><span class="badge rounded-pill ${sub.status === 'Pass' ? 'badge-pass' : 'badge-fail'} px-3 py-2">${sub.status || '--'}</span></td>
          <td class="text-end">
            <a href="#" class="action-link js-open-subject" data-student="${id}" data-subject="${sid}" data-subject-name="${sub.name || ''}">${window.I18N?.viewReport || 'View report'}</a>
          </td>
        `;
        subjTbody.appendChild(tr);
      });

      subjTbody.querySelectorAll('.js-open-subject').forEach(a => {
        a.onclick = async (ev) => {
          ev.preventDefault();
          await openSubjectReport(a.dataset.student, a.dataset.subject, a.dataset.subjectName);
        };
      });
    }

    drawStudentCharts(json.charts?.progress, json.charts?.study_time_by_subject);

    // switch views
    reportsListView.style.display = 'none';
    classReportView.style.display = 'none';
    studentReportView.style.display = '';
    subjectReportView.style.display = 'none';
  }

  /* ===== Subject report (NEW) ===== */
  async function openSubjectReport(studentId, subjectId, subjectName) {
    currentSubjectId = subjectId;
    currentSubjectName = subjectName;

    // نجرب جلب API لو موجود، وإلا نركّب عرض افتراضي من بيانات الطالب
    let json = null, ok = false;
    try {
      const res = await fetch(urlSubject(studentId, subjectId));
      ok = res.ok;
      if (ok) json = await res.json();
    } catch (e) { /* ignore */ }

    // تعبئة الهيدر
    const sNameEl = document.querySelector('.js-sr-student');
    const subjEl = document.querySelector('.js-sr-subject');
    const titleEl = document.querySelector('.js-sr-title');
    const subttl = document.querySelector('.js-sr-subtitle');

    sNameEl && (sNameEl.textContent = document.querySelector('.student-head .js-student-name')?.textContent || '--');
    subjEl && (subjEl.textContent = subjectName || json?.subject?.name || window.I18N?.subject || 'Subject');
    titleEl && (titleEl.textContent = `${subjectName || json?.subject?.name || window.I18N?.subject || 'Subject'} ${window.I18N?.subjectProgress || 'Progress'}`);
    subttl && (subttl.textContent = `${sNameEl?.textContent || '--'} | Teacher: ${json?.teacher ?? (document.querySelector('.js-student-teacher')?.textContent.replace('Supervising Teacher: ', '') || '--')}`);

    // إحصاءات مصغّرة
    const avg = json?.stats?.avg_score != null ? Math.round(json.stats.avg_score * 100) + '%' : '--';
    const time = json?.stats?.study_time ?? '—';
    const trend = json?.stats?.trend ?? '+0%';
    document.querySelector('.js-sr-avg')?.replaceChildren(document.createTextNode(avg));
    document.querySelector('.js-sr-time')?.replaceChildren(document.createTextNode(time));
    document.querySelector('.js-sr-trend')?.replaceChildren(document.createTextNode(trend));

    // ملاحظات إكمال المادة
    const completionPct = json?.stats?.completion_pct ?? 76;
    const noteEl = document.querySelector('.js-sr-completion-note');
    noteEl && (noteEl.textContent = completionPct >= 100 ? (window.I18N?.excellentCompleted || 'Excellent! Subject completed.') : (window.I18N?.keepGoing || 'Great job! Keep up the momentum to reach 100%.'));

    // إنجازات (شكل)
    document.querySelector('.js-sr-ach1')?.replaceChildren(document.createTextNode(json?.achievements?.[0]?.title ?? 'Perfect Score'));
    document.querySelector('.js-sr-ach1-sub')?.replaceChildren(document.createTextNode(json?.achievements?.[0]?.sub ?? 'Quiz 4'));
    document.querySelector('.js-sr-ach2')?.replaceChildren(document.createTextNode(json?.achievements?.[1]?.title ?? 'Chapter Master'));
    document.querySelector('.js-sr-ach2-sub')?.replaceChildren(document.createTextNode(json?.achievements?.[1]?.sub ?? 'Latest Chapter'));

    // Charts
    const tests = json?.charts?.tests ?? { labels: ['Test 1', 'Test 2', 'Test 3', 'Test 4', 'Test 5'], values: [72, 65, 78, 90, 95] };
    drawSubjectCharts(completionPct, tests);

    // Switch views
    reportsListView.style.display = 'none';
    classReportView.style.display = 'none';
    studentReportView.style.display = 'none';
    subjectReportView.style.display = '';
  }

  /* ===== Student Cards Report (NEW) ===== */
  async function openClassCardsReport() {
    if (!currentGrade || !currentSection) return;

    // We can reuse the class data if we want, but let's fetch fresh or use the last one
    const res = await fetch(urlClass(currentGrade, currentSection));
    if (!res.ok) { alert('Failed to load class report for cards'); return; }
    const json = await res.json();

    cardsClassTitleEl && (cardsClassTitleEl.textContent = `${json.grade} - ${window.I18N?.section || 'Section'} ${json.section}`);
    const printClassTitle = document.querySelector('.js-cards-print-class-title');
    printClassTitle && (printClassTitle.textContent = `${json.grade} - ${window.I18N?.section || 'Section'} ${json.section}`);
    
    if (studentCardsContainer) {
        studentCardsContainer.innerHTML = '';
        const school = window.SCHOOL_INFO || {};
        const academicYear = school.academic_year || `${new Date().getFullYear()}-${new Date().getFullYear() + 1}`;
        const schoolLogo = school.logo_path ? `${window.STORAGE_BASE_URL || '/storage'}/${school.logo_path}` : null;
        const schoolName = school.name || 'EduLearn Platform';

        (json.students || []).forEach(s => {
            const col = document.createElement('div');
            col.className = 'col-md-4 col-sm-6 mb-4';
            
            // Generate initials for avatar if no image
            const initials = s.name.split(' ').map(n => n[0]).join('').slice(0, 2).toUpperCase();
            const avatarHtml = s.photo_url 
                ? `<img src="${s.photo_url}" loading="lazy" decoding="async" alt="${s.name}">`
                : `<img src="${window.DEFAULT_AVATAR}" loading="lazy" decoding="async" alt="${s.name}">`;

            const schoolLogoHtml = schoolLogo 
                ? `<img src="${schoolLogo}" loading="lazy" decoding="async" alt="Logo">` 
                : `<svg fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 14l9-5-9-5-9 5 9 5z"></path><path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"></path></svg>`;

            const acId = s.academic_id || Math.floor(100000 + Math.random() * 900000).toString();

            col.innerHTML = `
                <div class="card-scale-wrapper mb-4 position-relative">
                    <div class="no-print position-absolute top-0 start-0 m-2" style="z-index: 20;">
                        <input class="form-check-input card-print-select" type="checkbox" style="width: 24px; height: 24px; cursor: pointer; border: 2px solid #0ea5e9;">
                    </div>
                    <div class="student-id-card-new">
                        <!-- Background Elements -->
                        <div class="bg-accent-navy"></div>
                        <div class="bg-accent-orange"></div>
                        <div class="card-decorative-circles"></div>


                        <!-- Header Ribbon -->
                        <div class="ribbon-banner">
                            <div class="school-logo-c">
                                ${schoolLogoHtml}
                            </div>
                            <span>${schoolName}</span>
                        </div>

                        <!-- Main Content Area -->
                        <div class="id-content">
                            <h1 class="id-title">${window.I18N?.studentIdCardTitle || 'STUDENT ID CARD'}</h1>
                            
                            <div class="id-flex-row">
                                <!-- Photo Section -->
                                <div class="profile-img-container">
                                    ${avatarHtml}
                                </div>
                                
                                <!-- Details Section -->
                                <div class="id-details">
                                    <div>
                                        <p class="id-label">${window.I18N?.nameLabel || 'Name:'}</p>
                                        <p class="id-value border-b">${s.name}</p>
                                    </div>
                                    <div>
                                        <p class="id-label">${window.I18N?.studentIdLabel || 'Student ID:'}</p>
                                        <p class="id-value border-b academic-id-text">${acId}</p>
                                    </div>
                                    <div>
                                        <p class="id-label">${window.I18N?.programLabel || 'Program:'}</p>
                                        <p class="id-value border-b">${window.I18N?.elementary?.toUpperCase() || ''} (${json.grade},  ${json.section})</p>
                                    </div>
                                    <div>
                                        <p class="id-label">${window.I18N?.yearLabel || 'Year:'}</p>
                                        <p class="id-value border-b">${academicYear}</p>
                                    </div>
                                </div>
                            </div>

                            <!-- Footer Elements -->
                            <div class="id-footer">
                                <div class="id-valid">
                                    <p class="v-label">${window.I18N?.validUntilLabel || 'Valid Until:'}</p>
                                    <p class="v-val">AUGUST ${academicYear.split('-')[1] || new Date().getFullYear()+1}</p>
                                </div>
                                <div class="barcode-area">
                                    <div class="barcode-font">${acId}</div>
                                    <div class="barcode-text">ID-${acId}</div>
                                </div>
                                <div class="id-footer-spacer" style="width: 128px;"></div> <!-- Spacer -->
                            </div>
                        </div>
                    </div>
                </div>
            `;
            studentCardsContainer.appendChild(col);
        });
    }

    // Switch views
    reportsListView.style.display = 'none';
    classReportView.style.display = 'none';
    studentReportView.style.display = 'none';
    subjectReportView.style.display = 'none';
    classCardsView.style.display = 'block';
  }

  // Back from cards to class report
  document.querySelector('.js-back-to-class-report')?.addEventListener('click', (e) => {
    e.preventDefault();
    classCardsView.style.display = 'none';
    classReportView.style.display = 'block';
  });

  // Open cards report from class report
  document.querySelector('.js-view-cards')?.addEventListener('click', (e) => {
    e.preventDefault();
    openClassCardsReport();
  });

  // Print cards
  document.querySelector('.js-print-cards')?.addEventListener('click', () => {
    document.body.classList.add('printing-id-cards');
    document.querySelectorAll('.card-scale-wrapper').forEach(card => card.classList.remove('d-none-print'));
    window.print();
  });

  // Select all cards
  document.querySelector('.js-select-all-cards')?.addEventListener('change', (e) => {
    const isChecked = e.target.checked;
    document.querySelectorAll('.card-print-select').forEach(cb => cb.checked = isChecked);
  });

  // Print selected cards
  document.querySelector('.js-print-selected-cards')?.addEventListener('click', () => {
    const selected = document.querySelectorAll('.card-print-select:checked');
    if (selected.length === 0) {
        alert(window.I18N?.selectAtLeastOne || 'Please select at least one card to print.');
        return;
    }

    // Hide unselected
    document.querySelectorAll('.card-scale-wrapper').forEach(wrapper => {
        const cb = wrapper.querySelector('.card-print-select');
        if (cb && !cb.checked) {
            wrapper.classList.add('d-none-print');
        } else {
            wrapper.classList.remove('d-none-print');
        }
    });
    document.body.classList.add('printing-id-cards');
    window.print();
  });

  // Cleanup printing class after print dialog is closed
  window.addEventListener('afterprint', () => {
    document.body.classList.remove('printing-id-cards');
  });

  // Back from subject to student
  document.querySelector('.js-back-to-student')?.addEventListener('click', (e) => {
    e.preventDefault();
    if (currentStudentId) {
      studentReportView.style.display = '';
      subjectReportView.style.display = 'none';
      classReportView.style.display = 'none';
      reportsListView.style.display = 'none';
    }
  });

  // Back from student to class
  document.querySelector('.js-back-to-class')?.addEventListener('click', (e) => {
    e.preventDefault();
    studentReportView.style.display = 'none';
    subjectReportView.style.display = 'none';
    classReportView.style.display = '';
    reportsListView.style.display = 'none';
  });

  // Back from class to list
  document.querySelectorAll('.js-back-to-list').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      studentReportView.style.display = 'none';
      subjectReportView.style.display = 'none';
      classReportView.style.display = 'none';
      if (teacherReportView) teacherReportView.style.display = 'none';
      if (atRiskReportView) atRiskReportView.style.display = 'none';
      reportsListView.style.display = '';
      fetchClasses(); // refresh list to be safe
    });
  });

  const applyFiltersBtn = document.getElementById('applyFiltersBtn');

  /* ===== Filters & actions ===== */
  applyFiltersBtn?.addEventListener('click', () => {
    state.search = filterSearch?.value.trim() || '';
    state.page = 1;
    fetchClasses();
  });

  // List view refresh
  document.querySelector('.js-refresh-list')?.addEventListener('click', (e) => {
    e.preventDefault();
    fetchClasses();
  });

  /* ===== Generate Report Logic ===== */
  document.querySelector('.js-generate')?.addEventListener('click', () => {
    generateModal.show();
  });

  /* ===== Strategic AI Report Logic (Async & Background) ===== */
  document.querySelector('.js-generate-ai')?.addEventListener('click', async () => {
    if (!aiReportModal) return;
    
    const loadingEl = document.getElementById('aiReportLoading');
    const contentEl = document.getElementById('aiReportContent');
    const markdownEl = document.getElementById('aiReportMarkdown');
    
    try {
      const qs = new URLSearchParams();
      if (filterClass?.value) {
          const parts = filterClass.value.split(' - ');
          if (parts.length === 2) {
              qs.set('grade', parts[0]);
              qs.set('class_section', parts[1]);
          }
      }
      
      const res = await fetch(`${ROUTES.aiAnalytics || '/reports/generate-ai-analytics'}?${qs.toString()}`);
      const data = await res.json();
      
      if (data.status === 'success') {
          // Show non-blocking notification
          if (window.Swal) {
              Swal.fire({
                  title: window.I18N?.generatingReport || 'Generating Report',
                  text: window.I18N?.backgroundGenerationNote || 'The AI is analyzing school data in the background. You can continue using the site.',
                  icon: 'info',
                  toast: true,
                  position: 'top-end',
                  showConfirmButton: false,
                  timer: 5000,
                  timerProgressBar: true
              });
          }

          // Start polling for status in the background
          startPollingAiReport(data.report_id);
      } else {
          throw new Error(data.message || 'Failed to start AI report generation');
      }
    } catch (err) {
      console.error(err);
      handleAiReportError(err.message);
    }
  });

  function startPollingAiReport(reportId) {
      const interval = setInterval(async () => {
          try {
              const url = (ROUTES.aiReportStatus || '/reports/ai-report-status/__ID__').replace('__ID__', reportId);
              const res = await fetch(url);
              const data = await res.json();

              if (data.status === 'completed') {
                  clearInterval(interval);
                  renderAiReportContent(data.content);
                  
                  // Notify user if modal is closed
                  if (!document.getElementById('aiAnalyticsReportModal').classList.contains('show')) {
                      if (window.Swal) {
                          Swal.fire({
                              title: window.I18N?.aiReportReady || 'AI Report Ready!',
                              text: window.I18N?.strategicAnalysisComplete || 'Strategic analysis has been completed.',
                              icon: 'success',
                              confirmButtonText: window.I18N?.viewReport || 'View Report',
                              showCancelButton: true,
                              cancelButtonText: window.I18N?.close || 'Close'
                          }).then((result) => {
                              if (result.isConfirmed && aiReportModal) {
                                  aiReportModal.show();
                              }
                          });
                      }
                  }
              } else if (data.status === 'failed') {
                  clearInterval(interval);
                  handleAiReportError(data.error);
              }
          } catch (e) {
              console.error('Polling error:', e);
              // We don't stop polling on network error, just let it retry
          }
      }, 5000); // Poll every 5s
  }

  let latestAiReportContent = null;

  function renderAiReportContent(markdown) {
      if (!markdown) return;
      latestAiReportContent = markdown;
      
      const loadingEl = document.getElementById('aiReportLoading');
      const contentEl = document.getElementById('aiReportContent');
      const markdownEl = document.getElementById('aiReportMarkdown');

      if (markdownEl) {
          // Render markdown or fallback to raw text
          markdownEl.innerHTML = window.marked ? marked.parse(markdown) : markdown;
          
          // Force visibility toggle using multiple methods for reliability
          if (loadingEl) {
              loadingEl.style.display = 'none';
              loadingEl.classList.add('d-none');
          }
          if (contentEl) {
              contentEl.style.display = 'block';
              contentEl.classList.remove('d-none');
          }
          console.log("AI Report Rendered and UI Toggled");
      } else {
          console.error("AI Report Markdown element not found!");
      }
  }

  function handleAiReportError(errorMsg) {
      const loadingEl = document.getElementById('aiReportLoading');
      if (loadingEl) {
          loadingEl.innerHTML = `
            <div class="text-danger text-center py-5">
              <i class="bi bi-exclamation-octagon fs-1 mb-3"></i>
              <h4>${window.I18N?.error || 'Error'}</h4>
              <p>${errorMsg}</p>
              <button class="btn btn-primary mt-3" onclick="location.reload()">${window.I18N?.refresh || 'Refresh Page'}</button>
            </div>
          `;
      }
  }

  document.getElementById('confirmGenerateBtn')?.addEventListener('click', async (e) => {
    const type = document.querySelector('input[name="report_type"]:checked')?.value;
    const btn = document.getElementById('confirmGenerateBtn');
    const originalContent = btn.innerHTML;

    btn.disabled = true;
    btn.innerHTML = `<span class="spinner-border spinner-border-sm"></span> ${window.I18N?.preparingData || 'Preparing...'}`;

    try {
        if (type === 'at_risk') {
            const qs = new URLSearchParams();
            if (filterClass?.value) qs.set('class', filterClass.value);
            if (filterSubject?.value) qs.set('subject', filterSubject.value);
            
            const res = await fetch(`${ROUTES.atRisk || '/reports/at-risk'}?${qs.toString()}`);
            if (!res.ok) throw new Error('Failed to fetch data');
            const json = await res.json();
            
            if (!json.students || json.students.length === 0) {
                alert(window.I18N?.noAtRiskFound || 'No students currently meet the At-Risk criteria.');
                return;
            }

            renderAtRiskTable(json.students);
            showView(atRiskReportView);
        } else if (type === 'performance' || type === 'students') {
            // Use existing global filters
            if (filterClass?.value) {
                const parts = filterClass.value.split('-');
                if (parts.length === 2) {
                    openClassReport(parts[0].trim(), parts[1].trim());
                    // modal will close in showView/hideModal context
                } else {
                    alert('Please select a specific class first.');
                    return;
                }
            } else {
                alert('Please select a class from the filters first.');
                return;
            }
        } else {
            // Summary - stay on dashboard
            showView(reportsListView);
        }
        generateModal.hide();
    } catch (e) {
        console.error(e);
        alert('Error: ' + e.message);
    } finally {
        btn.disabled = false;
        btn.innerHTML = originalContent;
    }
  });

  /* ===== Navigation & UI Helpers ===== */
  function showView(view) {
    const views = [reportsListView, classReportView, studentReportView, subjectReportView, classCardsView, teacherReportView, atRiskReportView];
    views.forEach(v => {
      if(v) v.style.display = 'none';
    });
    if(view) view.style.display = 'block';
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function renderAtRiskTable(students) {
    const tbody = document.querySelector('#atRiskTable tbody');
    if (!tbody) return;
    tbody.innerHTML = '';
    (students || []).forEach(s => {
      const tr = document.createElement('tr');
      const scoreVal = parseFloat(s.avg_score) || 0;
      const scoreClass = scoreVal < 50 ? 'text-danger' : (scoreVal < 70 ? 'text-warning' : 'text-success');
      const badgeClass = s.risk_level === 'High' ? 'bg-danger' : 'bg-warning';
      
       tr.innerHTML = `
        <td>
            <div class="d-flex align-items-center gap-2">
                <img src="${s.photo_url || window.DEFAULT_AVATAR}" style="width:32px; height:32px; border-radius:50%; object-fit:cover;" onerror="this.src='${window.DEFAULT_AVATAR}'">
                <div><div class="fw-bold text-navy">${s.name}</div><div class="small text-muted">${s.academic_id || ''}</div></div>
            </div>
        </td>
        <td>${s.class || '--'}</td>
        <td><span class="fw-bold ${scoreClass}">${s.avg_score}</span></td>
        <td>${s.attendance}</td>
        <td>
          <span class="badge ${badgeClass} text-white px-3">${s.risk_level}</span>
          <div class="small text-muted mt-1" style="font-style:italic; max-width:200px">${s.reason || ''}</div>
        </td>
        <td class="text-end">
            <div class="d-flex justify-content-end gap-1">
                <button class="btn btn-sm btn-soft-primary js-open-student-at-risk" data-id="${s.id}" title="View Profile"><i class="bi bi-person"></i></button>
                <button class="btn btn-sm btn-soft-secondary" onclick="alert('Creating academic plan for ${s.name.replace(/'/g, "\\'")}')" title="Academic Plan"><i class="bi bi-file-earmark-medical"></i></button>
                <button class="btn btn-sm btn-soft-warning" onclick="alert('Notification sent to teacher regarding ${s.name.replace(/'/g, "\\'")}')" title="Notify Teacher"><i class="bi bi-bell"></i></button>
            </div>
        </td>
      `;
      const btn = tr.querySelector('.js-open-student-at-risk');
      if (btn) btn.onclick = () => openStudentReport(s.id);
      tbody.appendChild(tr);
    });
  }

  /* ===== Teacher report (Phase 1) ===== */
  async function openTeacherReport(id) {
    const res = await fetch(urlTeacher(id));
    if (!res.ok) { alert('Failed to load teacher report'); return; }
    const json = await res.json();
    currentTeacherId = id;

    // Fill info
    const info = json.teacher_info;
    document.querySelectorAll('.js-tr-name').forEach(el => el.textContent = info.name);
    const codeEl = document.querySelector('.js-tr-code'); if(codeEl) codeEl.textContent = info.code;
    const emailEl = document.querySelector('.js-tr-email'); if(emailEl) emailEl.textContent = info.email;
    const avatarEl = document.querySelector('.js-tr-avatar'); if(avatarEl) avatarEl.src = info.avatar || window.DEFAULT_AVATAR;

    // Fill stats
    const obs = json.overview;
    document.querySelector('.js-tr-lessons') && (document.querySelector('.js-tr-lessons').textContent = obs.total_lessons);
    document.querySelector('.js-tr-exercises') && (document.querySelector('.js-tr-exercises').textContent = obs.total_exercises);
    document.querySelector('.js-tr-students') && (document.querySelector('.js-tr-students').textContent = obs.total_students);
    const scoreVal = obs.avg_student_score || 0;
    document.querySelector('.js-tr-score') && (document.querySelector('.js-tr-score').textContent = scoreVal + '%');

    // Comparison logic
    const compEl = document.querySelector('.js-tr-comparison');
    if (compEl) {
        const schoolAvg = obs.school_avg_comparison || 0;
        const diff = scoreVal - schoolAvg;
        const color = diff >= 0 ? '#10b981' : '#ef4444'; // Green if above, Red if below
        const icon = diff >= 0 ? '↑' : '↓';
        compEl.style.color = color;
        compEl.textContent = `${icon} ${Math.abs(diff).toFixed(1)}%`;
    }

    // Table
    const tbody = document.querySelector('.js-tr-classes-table tbody');
    if (tbody) {
        tbody.innerHTML = '';
        (json.content_stats || []).forEach(c => {
            const tr = document.createElement('tr');
            tr.innerHTML = `<td>${c.class}</td><td>${c.subject}</td><td>${c.lessons}</td><td><span class="badge bg-primary text-white">${c.avg_score}%</span></td>`;
            tbody.appendChild(tr);
        });
    }

    drawTeacherCharts(json.activity_timeline, json.content_stats);
    showView(teacherReportView);
  }

  /* ===== Print & Export Logic ===== */
  function getReportTitle() {
    if (classReportView && classReportView.style.display !== 'none') return (window.I18N?.classReport || 'Class Report') + ': ' + (classTitleEl?.textContent || '');
    if (studentReportView && studentReportView.style.display !== 'none') return (window.I18N?.studentReport || 'Student Report') + ': ' + (document.querySelector('.js-student-name')?.textContent || '');
    if (subjectReportView && subjectReportView.style.display !== 'none') return (window.I18N?.subjectReport || 'Subject Report') + ': ' + (currentSubjectName || '');
    if (teacherReportView && teacherReportView.style.display !== 'none') return (window.I18N?.teacherReport || 'Teacher Report') + ': ' + (document.querySelector('.js-tr-name')?.textContent || '');
    if (atRiskReportView && atRiskReportView.style.display !== 'none') return (window.I18N?.atRiskReport || 'At-Risk Report');
    return 'EduLearn Report';
  }

  function handlePrint() {
    const reportTitle = getReportTitle();
    const printHeader = document.getElementById('globalPrintHeader');
    const printHeaderTitle = document.getElementById('printReportTitle');
    if (printHeaderTitle) printHeaderTitle.textContent = reportTitle;
    
    const originalTitle = document.title;
    document.title = reportTitle;
    window.print();
    setTimeout(() => { document.title = originalTitle; }, 500);
  }

  document.querySelectorAll('.js-print, .js-export, .js-export-pdf').forEach(btn => btn.addEventListener('click', (e) => { e.preventDefault(); handlePrint(); }));

  document.querySelectorAll('.js-export-excel').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const activeView = [classReportView, studentReportView, subjectReportView, teacherReportView, atRiskReportView].find(v => v && v.style.display !== 'none') || reportsListView;
      const table = activeView?.querySelector('table');
      if(!table) return;
      
      let csv = [];
      const rows = table.querySelectorAll('tr');
      for (let i = 0; i < rows.length; i++) {
          const row = [], cols = rows[i].querySelectorAll('td, th');
          for (let j = 0; j < cols.length; j++) {
              let text = cols[j].innerText.trim();
              if(cols[j].querySelector('.btn')) text = ''; 
              row.push('"' + text.replace(/"/g, '""') + '"');
          }
          if(row.join('').length > 0) csv.push(row.join(','));
      }
      const csvContent = "data:text/csv;charset=utf-8,\uFEFF" + csv.join("\n");
      const link = document.createElement("a");
      link.setAttribute("href", encodeURI(csvContent));
      link.setAttribute("download", "EduLearn_" + getReportTitle().replace(/\s+/g, '_') + ".csv");
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    });
  });

  /* ===== Init & Parameters ===== */
  /* ===== Strategic Report Archive Logic ===== */
  document.querySelectorAll('.js-view-all-reports').forEach(btn => {
    btn.addEventListener('click', (e) => {
        e.preventDefault();
        if (aiArchiveModal) aiArchiveModal.show();
    });
  });

  document.querySelectorAll('.js-view-archived-report').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const reportId = e.currentTarget.getAttribute('data-id');
      if (!reportId || !aiReportModal) return;
      
      const loadingEl = document.getElementById('aiReportLoading');
      const contentEl = document.getElementById('aiReportContent');
      const markdownEl = document.getElementById('aiReportMarkdown');
      
      // Reset modal state
      if (loadingEl) {
          loadingEl.style.display = 'block';
          loadingEl.classList.remove('d-none');
          loadingEl.innerHTML = `
            <div class="spinner-grow text-primary mb-3" style="width: 3rem; height: 3rem;" role="status"></div>
            <h4 class="fw-bold text-navy">${window.I18N?.loadingReport || 'Loading Archived Report...'}</h4>
          `;
      }
      if (contentEl) {
          contentEl.style.display = 'none';
          contentEl.classList.add('d-none');
      }
      
      aiReportModal.show();
      
      try {
          const url = (ROUTES.aiReportStatus || '/reports/ai-report-status/__ID__').replace('__ID__', reportId);
          const res = await fetch(url);
          if (!res.ok) throw new Error('Failed to fetch archived report');
          const data = await res.json();
          
          if (data.status === 'completed') {
              renderAiReportContent(data.content);
          } else {
              throw new Error('Report is not in completed state');
          }
      } catch (err) {
          console.error(err);
          handleAiReportError(err.message);
      }
    });
  });

  fetchClasses();
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('teacher_id')) openTeacherReport(urlParams.get('teacher_id'));
  if (urlParams.get('student_id')) openStudentReport(urlParams.get('student_id'));
});
