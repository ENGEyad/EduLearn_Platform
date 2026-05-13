const { Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType } = require('docx');
const fs = require('fs');
const path = require('path');

// Fixed Code Snippets
const controllerCode = `/**
 * إرجاع قائمة الطلاب JSON للـ JS (مفلترة حسب المدرسة)
 */
public function list()
{
    // نختار كل الأعمدة ما عدا photo_data لأن حجمها كبير جداً وتعطل المتصفح في القائمة
    return Student::where('school_id', auth()->user()->school_id)
        ->select('id', 'school_id', 'full_name', 'academic_id', 'gender', 'birthdate', 'email', 'status', 'grade', 'class_section', 'class_section_id', 'address_governorate', 'address_city', 'address_street', 'guardian_name', 'guardian_relation', 'guardian_relation_other', 'guardian_phone', 'performance_avg', 'attendance_rate', 'photo_path', 'photo_mime', 'notes', 'created_at', 'updated_at')
        ->orderBy('id', 'desc')
        ->get();
}`;

const modelCode = `public function getPhotoUrlAttribute(): ?string
{
    if ($this->photo_data) {
        return route('students.photo', ['student' => $this->id]);
    }
    if ($this->photo_path) {
        return asset('storage/' . $this->photo_path);
    }
    return null;
}

public function getThumbUrlAttribute(): ?string
{
    return $this->photo_url;
}`;

const jsCode = `// Handle Photo Preview in editStudent
if (formPhotoPreview) {
    if (st.photo_url) {
        formPhotoPreview.style.backgroundImage = \`url('\${st.photo_url}')\`;
        formPhotoPreview.style.display = 'block';
    } else {
        formPhotoPreview.style.backgroundImage = 'none';
        formPhotoPreview.style.display = 'none';
    }
}

// Improved Grade/Section mapping in editStudent
if (stClassSection) {
    const checkAndSetSection = () => {
        const sectionMap = { 'أ': 'A', 'ب': 'B', 'ج': 'C', 'د': 'D', 'هـ': 'E', 'و': 'F', 'ز': 'G', 'ح': 'H' };
        const targetSection = sectionMap[st.class_section] || st.class_section;
        stClassSection.value = targetSection;
        if (!stClassSection.value && st.class_section) {
            Array.from(stClassSection.options).forEach(opt => {
                if (opt.textContent.trim() === st.class_section || opt.value === st.class_section) {
                    stClassSection.value = opt.value;
                }
            });
        }
    };
    checkAndSetSection();
    setTimeout(checkAndSetSection, 100);
    setTimeout(checkAndSetSection, 300);
}`;

const doc = new Document({
    sections: [{
        properties: {
            page: {
                size: {
                    width: 12240,
                    height: 15840
                },
                margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 }
            }
        },
        children: [
            new Paragraph({
                text: "EduLearn: Student Update Logic Fixes",
                heading: HeadingLevel.HEADING_1,
                alignment: AlignmentType.CENTER,
            }),
            new Paragraph({
                children: [new TextRun({ text: "This document contains the fixed code for the student updating approach, addressing performance issues with binary storage and UI synchronization bugs.", italics: true })],
                spacing: { after: 400 }
            }),

            new Paragraph({ text: "1. StudentController.php (Optimized List)", heading: HeadingLevel.HEADING_2 }),
            new Paragraph({
                children: [new TextRun({ text: controllerCode, font: "Courier New", size: 18 })],
                spacing: { after: 300 }
            }),

            new Paragraph({ text: "2. Student.php (Robust Photo URL)", heading: HeadingLevel.HEADING_2 }),
            new Paragraph({
                children: [new TextRun({ text: modelCode, font: "Courier New", size: 18 })],
                spacing: { after: 300 }
            }),

            new Paragraph({ text: "3. students.js (UI & Mapping Fixes)", heading: HeadingLevel.HEADING_2 }),
            new Paragraph({
                children: [new TextRun({ text: jsCode, font: "Courier New", size: 18 })],
                spacing: { after: 300 }
            }),
            
            new Paragraph({ text: "Key Fixes Applied:", heading: HeadingLevel.HEADING_3 }),
            new Paragraph({
                text: "- Excluded photo_data from student list JSON to prevent browser lag/hangs.",
                bullet: { level: 0 }
            }),
            new Paragraph({
                text: "- Updated photo URL logic to support both legacy filesystem paths and new database blob storage.",
                bullet: { level: 0 }
            }),
            new Paragraph({
                text: "- Fixed race condition in Edit mode where class sections wouldn't load before mapping values.",
                bullet: { level: 0 }
            }),
            new Paragraph({
                text: "- Improved view-switching robustness to ensure the list view is correctly toggled.",
                bullet: { level: 0 }
            }),
        ],
    }],
});

Packer.toBuffer(doc).then((buffer) => {
    fs.writeFileSync("student_update_fixes.docx", buffer);
    console.log("Document created: student_update_fixes.docx");
});
