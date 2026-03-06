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
  const brandColors = ['#2563eb','#22c55e','#f59e0b','#9ca3af','#ef4444','#a855f7','#06b6d4'];

  /* ========== Routes (بدون تغيير في الباك) ========== */
  const ROUTES = window.REPORTS_ROUTES || {};
  const urlList     = ROUTES.list    || '/reports/list';
  const urlClass    = (grade, section) => (ROUTES.class   || '/reports/class/__GRADE__/__SECTION__')
                         .replace('__GRADE__', encodeURIComponent(grade || ''))
                         .replace('__SECTION__', encodeURIComponent(section || ''));
  const urlStudent  = (id) => (ROUTES.student || '/reports/student/__ID__').replace('__ID__', id);
  // جديد (اختياري): إن وفّرت راوت للموضوع
  const urlSubject  = (studentId, subjectId) => (ROUTES.subject || '/reports/student/__SID__/subject/__SUBID__')
                         .replace('__SID__', studentId)
                         .replace('__SUBID__', subjectId);

  /* ========== Views ========== */
  const reportsListView   = document.getElementById('reportsListView');
  const classReportView   = document.getElementById('classReportView');
  const studentReportView = document.getElementById('studentReportView');
  const subjectReportView = document.getElementById('subjectReportView');

  /* ========== List/Table UI ========== */
  const tBody = document.querySelector('#classesTable tbody');
  const resultsInfo = document.getElementById('resultsInfo');
  const pager = document.getElementById('pager');

  const filterSearch  = document.getElementById('filterSearch');
  const filterYear    = document.getElementById('filterYear');
  const filterTeacher = document.getElementById('filterTeacher');

  const classTitleEl      = classReportView?.querySelector('.js-class-title');
  const statStudentsEl    = classReportView?.querySelector('.js-students-count');
  const statAvgScoreEl    = classReportView?.querySelector('.js-avg-score');
  const statPassRateEl    = classReportView?.querySelector('.js-pass-rate');
  const statAttendanceEl  = classReportView?.querySelector('.js-attendance');
  const statStudyTimeEl   = classReportView?.querySelector('.js-study-time');

  let gradeChart, progressChart, timeChart, completionChart, testsChart;
  const safeDestroy = (c) => { try { c?.destroy?.(); } catch(e){} };

  const state = { page: 1, perPage: 6, total: 0, items: [], search: '' };
  let currentStudentId = null; // لملاحة تقرير المادة

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
      id:'barCountsReports',
      afterDatasetsDraw(c){
        if (c !== gradeChart) return;
        const {ctx} = c, meta = c.getDatasetMeta(0);
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
    safeDestroy(progressChart); safeDestroy(timeChart);
    const pctx = document.getElementById('progressChart');
    const tctx = document.getElementById('timeChart');
    if (pctx && progress?.labels && progress?.values) {
      progressChart = new Chart(pctx, {
        type: 'line',
        data: { labels: progress.labels, datasets: [{ label: 'Score %', data: progress.values, borderWidth: 2, fill: false, pointRadius: 3 }] },
        options: quietOpts
      });
    }
    if (tctx && timeBySubject?.labels && timeBySubject?.values) {
      timeChart = new Chart(tctx, {
        type: 'bar',
        data: { labels: timeBySubject.labels, datasets: [{ label: 'Hours', data: timeBySubject.values, borderRadius: 10, barThickness: 20 }] },
        options: quietOpts
      });
    }
  }

  function drawSubjectCharts(completionPct, tests) {
    // Completion doughnut with center %
    safeDestroy(completionChart); safeDestroy(testsChart);
    const cctx = document.getElementById('completionChart');
    const tctx = document.getElementById('testsChart');
    if (cctx) {
      completionChart = new Chart(cctx, {
        type: 'doughnut',
        data: { labels: ['Completed','Remaining'], datasets: [{ data: [completionPct, 100 - completionPct], borderWidth: 0 }] },
        options: { plugins:{ legend:{display:false}, tooltip:{enabled:false} }, cutout: '72%' }
      });
      // center text
      Chart.register({
        id:'centerTextSR',
        afterDraw(chart){
          if (chart !== completionChart) return;
          const {ctx} = chart, meta = chart.getDatasetMeta(0).data?.[0];
          if (!meta) return;
          ctx.save(); ctx.font = '800 34px Inter'; ctx.fillStyle = '#0f172a';
          ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
          ctx.fillText(`${Math.round(completionPct)}%`, meta.x, meta.y);
          ctx.restore();
        }
      });
      completionChart.update();
    }
    if (tctx && tests?.labels && tests?.values) {
      testsChart = new Chart(tctx, {
        type: 'bar',
        data: { labels: tests.labels, datasets: [{ label:'Score %', data: tests.values, borderRadius: 8 }] },
        options: quietOpts
      });
    }
  }

  /* ===== Data: Classes list ===== */
  async function fetchClasses() {
    const qs = new URLSearchParams();
    if (state.search) qs.set('search', state.search);
    if (filterYear?.value) qs.set('year', filterYear.value);
    if (filterTeacher?.value) qs.set('teacher', filterTeacher.value);

    const res = await fetch(`${urlList}?${qs.toString()}`);
    if (!res.ok) { console.error('Failed to load classes'); return; }
    const json = await res.json();
    state.items = json.data || [];
    state.total = (json.meta && json.meta.total) || state.items.length;

    renderTable();
    renderPager();

    // fill Year/Teacher if not provided by API
    if (filterYear && !filterYear.dataset.filled) {
      const years = [...new Set(state.items.map(i => i.year).filter(Boolean))].sort().reverse();
      years.forEach(y => filterYear.insertAdjacentHTML('beforeend', `<option value="${y}">${y}</option>`));
      filterYear.dataset.filled = '1';
    }
    if (filterTeacher && !filterTeacher.dataset.filled) {
      const teachers = [...new Set(state.items.map(i => i.teacher).filter(Boolean))].sort();
      teachers.forEach(t => filterTeacher.insertAdjacentHTML('beforeend', `<option value="${t}">${t}</option>`));
      filterTeacher.dataset.filled = '1';
    }
  }

  function renderTable(){
    tBody.innerHTML = '';
    if (!state.items.length) {
      tBody.innerHTML = `<tr><td colspan="2" class="text-center text-muted py-4">No matching results</td></tr>`;
      resultsInfo.textContent = `Showing 0 of 0 result(s) (page ${state.page})`;
      return;
    }
    const start = (state.page - 1) * state.perPage;
    const pageItems = state.items.slice(start, start + state.perPage);

    pageItems.forEach(row => {
      const display = `${row.grade ?? ''} - ${row.class_section ?? ''}`;
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>
          <span class="fw-semibold">${display}</span>
          <span class="text-muted small ms-2">${row.students_count} students</span>
        </td>
        <td class="text-end">
          <button class="btn btn-sm btn-outline-primary" data-grade="${row.grade ?? ''}" data-section="${row.class_section ?? ''}">
            View Report
          </button>
        </td>
      `;
      tBody.appendChild(tr);
    });

    resultsInfo.textContent = `Showing ${pageItems.length} of ${state.total} result(s) (page ${state.page})`;

    tBody.querySelectorAll('button[data-grade]').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const grade = e.currentTarget.getAttribute('data-grade');
        const section = e.currentTarget.getAttribute('data-section');
        await openClassReport(grade, section);
      });
    });
  }

  function renderPager(){
    pager.innerHTML = '';
    const totalPages = Math.max(1, Math.ceil(state.total / state.perPage));
    const add = (label, page, disabled=false, active=false) => {
      const li = document.createElement('li');
      li.className = `page-item ${disabled?'disabled':''} ${active?'active':''}`;
      const a = document.createElement('a');
      a.className = 'page-link';
      a.href = '#';
      a.textContent = label;
      a.onclick = (ev) => { ev.preventDefault(); if(disabled||active) return; state.page = page; renderTable(); renderPager(); };
      li.appendChild(a); pager.appendChild(li);
    };
    add('Previous', state.page-1, state.page===1);
    const totalPagesToShow = Math.min(totalPages, 5);
    let start = Math.max(1, state.page - 2);
    let end = Math.min(totalPages, start + totalPagesToShow - 1);
    if(end - start < totalPagesToShow - 1){ start = Math.max(1, end - totalPagesToShow + 1); }
    for(let p=start; p<=end; p++) add(String(p), p, false, p===state.page);
    add('Next', state.page+1, state.page===totalPages);
  }

  /* ===== Class report ===== */
  async function openClassReport(grade, section){
    const res = await fetch(urlClass(grade, section));
    if (!res.ok) { alert('Failed to load class report'); return; }
    const json = await res.json();

    classTitleEl && (classTitleEl.textContent = `${json.grade ?? grade} - Section ${json.section ?? section}`);
    statStudentsEl   && (statStudentsEl.textContent   = json.stats?.students ?? '--');
    statAvgScoreEl   && (statAvgScoreEl.textContent   = (json.stats?.avg_score ?? 0).toString());
    statPassRateEl   && (statPassRateEl.textContent   = ((json.stats?.pass_rate ?? 0)*100).toFixed(0)+'%');
    statAttendanceEl && (statAttendanceEl.textContent = ((json.stats?.attendance ?? 0)*100).toFixed(0)+'%');
    statStudyTimeEl  && (statStudyTimeEl.textContent  = (json.stats?.study_time ?? 0)+' hrs');

    // students table
    const sTbody = document.querySelector('#studentsTable tbody');
    sTbody.innerHTML = '';
    (json.students || []).forEach(s => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${s.name ?? ''}</td>
        <td>${s.academic_id ?? ('S'+s.id)}</td>
        <td>${s.section ?? ''}</td>
        <td>${s.score ?? ''}</td>
        <td>${s.attendance ?? ''}</td>
        <td><a class="action-link js-open-student" href="#" data-student="${s.id}">View student report</a></td>
      `;
      sTbody.appendChild(tr);
    });
    sTbody.querySelectorAll('.js-open-student').forEach(a=>{
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
  async function openStudentReport(id){
    const res = await fetch(urlStudent(id));
    if (!res.ok) { alert('Failed to load student report'); return; }
    const json = await res.json();
    currentStudentId = id;

    const name    = json.student?.name || '--';
    const cls     = json.student?.class || '--';
    const section = json.student?.section || '--';

    const nameEl   = document.querySelector('.student-head .js-student-name');
    const crumbsEl = document.querySelector('.js-student-name-breadcrumb');
    const avatarEl = document.querySelector('.student-head .avatar');
    const classEl  = document.querySelector('.student-head .js-student-class');

    nameEl && (nameEl.textContent = name);
    crumbsEl && (crumbsEl.textContent = name);
    avatarEl && name && (avatarEl.textContent = name.split(' ').map(p=>p[0]).join('').slice(0,2).toUpperCase());
    classEl && (classEl.textContent = `${cls}, Section ${section}`);

    const set = (sel, txt) => { const el = document.querySelector(sel); if (el) el.textContent = txt; };
    set('.js-s-avg',  (json.stats?.avg_score  != null) ? (json.stats.avg_score*100).toFixed(0)+'%' : '--');
    set('.js-s-pass', (json.stats?.pass_rate  != null) ? (json.stats.pass_rate*100).toFixed(0)+'%' : '--');
    set('.js-s-att',  (json.stats?.attendance != null) ? (json.stats.attendance*100).toFixed(0)+'%' : '--');
    set('.js-s-time', (json.stats?.study_time != null) ? (json.stats.study_time+' hrs') : '--');

    // subjects table (نضيف data-subject + data-student)
    const subjTbody = document.querySelector('.js-subjects-table tbody');
    if (subjTbody) {
      subjTbody.innerHTML = '';
      (json.subjects || []).forEach(sub => {
        const sid = sub.id ?? sub.name; // fallback على الاسم لو ما في id
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${sub.name}</td>
          <td>${(sub.score*100).toFixed(0)}%</td>
          <td>${sub.rank}</td>
          <td>${sub.time}</td>
          <td><span class="badge rounded-pill ${sub.status === 'Pass' ? 'badge-pass' : 'badge-fail'} px-3 py-2">${sub.status}</span></td>
          <td class="text-end">
            <a href="#" class="action-link js-open-subject" data-student="${id}" data-subject="${sid}" data-subject-name="${sub.name}">View report</a>
          </td>
        `;
        subjTbody.appendChild(tr);
      });

      subjTbody.querySelectorAll('.js-open-subject').forEach(a=>{
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
  async function openSubjectReport(studentId, subjectId, subjectName){
    // نجرب جلب API لو موجود، وإلا نركّب عرض افتراضي من بيانات الطالب
    let json = null, ok = false;
    try {
      const res = await fetch(urlSubject(studentId, subjectId));
      ok = res.ok;
      if (ok) json = await res.json();
    } catch(e){ /* ignore */ }

    // تعبئة الهيدر
    const sNameEl = document.querySelector('.js-sr-student');
    const subjEl  = document.querySelector('.js-sr-subject');
    const titleEl = document.querySelector('.js-sr-title');
    const subttl  = document.querySelector('.js-sr-subtitle');

    sNameEl && (sNameEl.textContent = document.querySelector('.student-head .js-student-name')?.textContent || '--');
    subjEl && (subjEl.textContent = subjectName || json?.subject?.name || 'Subject');
    titleEl && (titleEl.textContent = `${subjectName || json?.subject?.name || 'Subject'} Progress`);
    subttl && (subttl.textContent = `${sNameEl?.textContent || '--'} | Teacher: ${json?.teacher ?? (document.querySelector('.js-student-teacher')?.textContent.replace('Supervising Teacher: ','') || '--')}`);

    // إحصاءات مصغّرة
    const avg = json?.stats?.avg_score != null ? Math.round(json.stats.avg_score*100)+'%' : '--';
    const time = json?.stats?.study_time ?? '—';
    const trend = json?.stats?.trend ?? '+0%';
    document.querySelector('.js-sr-avg')?.replaceChildren(document.createTextNode(avg));
    document.querySelector('.js-sr-time')?.replaceChildren(document.createTextNode(time));
    document.querySelector('.js-sr-trend')?.replaceChildren(document.createTextNode(trend));

    // ملاحظات إكمال المادة
    const completionPct = json?.stats?.completion_pct ?? 76;
    const noteEl = document.querySelector('.js-sr-completion-note');
    noteEl && (noteEl.textContent = completionPct >= 100 ? 'Excellent! Subject completed.' : 'Great job! Keep up the momentum to reach 100%.');

    // إنجازات (شكل)
    document.querySelector('.js-sr-ach1')?.replaceChildren(document.createTextNode(json?.achievements?.[0]?.title ?? 'Perfect Score'));
    document.querySelector('.js-sr-ach1-sub')?.replaceChildren(document.createTextNode(json?.achievements?.[0]?.sub ?? 'Quiz 4'));
    document.querySelector('.js-sr-ach2')?.replaceChildren(document.createTextNode(json?.achievements?.[1]?.title ?? 'Chapter Master'));
    document.querySelector('.js-sr-ach2-sub')?.replaceChildren(document.createTextNode(json?.achievements?.[1]?.sub ?? 'Latest Chapter'));

    // Charts
    const tests = json?.charts?.tests ?? { labels: ['Test 1','Test 2','Test 3','Test 4','Test 5'], values: [72,65,78,90,95] };
    drawSubjectCharts(completionPct, tests);

    // Switch views
    reportsListView.style.display = 'none';
    classReportView.style.display = 'none';
    studentReportView.style.display = 'none';
    subjectReportView.style.display = '';
  }

  // Back from subject to student
  document.querySelector('.js-back-to-student')?.addEventListener('click', (e)=>{
    e.preventDefault();
    if (currentStudentId) {
      studentReportView.style.display = '';
      subjectReportView.style.display = 'none';
    }
  });

  /* ===== Filters & actions ===== */
  filterSearch?.addEventListener('input', () => { state.search = filterSearch.value.trim(); state.page = 1; fetchClasses(); });
  filterYear?.addEventListener('change', () => { state.page = 1; fetchClasses(); });
  filterTeacher?.addEventListener('change', () => { state.page = 1; fetchClasses(); });

  document.querySelectorAll('.js-print').forEach(b => b.addEventListener('click', () => window.print()));
  document.querySelectorAll('.js-export').forEach(b => b.addEventListener('click', () => window.print()));

  /* ===== First load ===== */
  fetchClasses();
});
