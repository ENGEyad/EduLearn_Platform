import puppeteer from 'puppeteer';
import path from 'path';
import fs from 'fs';

const ARTIFACT_DIR = 'C:/Users/EYAD/.gemini/antigravity/brain/4d54d588-c0b6-47ed-b461-f11ccc845380/';

async function captureScreenshots() {
    console.log('Launching browser...');
    const browser = await puppeteer.launch({ 
        headless: 'new',
        defaultViewport: { width: 1440, height: 900 }
    });
    
    const page = await browser.newPage();
    
    // Login as Super Admin
    console.log('Logging in as Super Admin...');
    await page.goto('http://localhost:8000/login');
    await page.type('#email', 'admin@edulearn.com');
    await page.type('#password', 'password');
    await Promise.all([
        page.waitForNavigation(),
        page.click('button[type="submit"]')
    ]);

    // 1. Super Admin Dashboard
    console.log('Capturing Super Admin Dashboard...');
    // wait for anim-fade-up to finish
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: path.join(ARTIFACT_DIR, 'super_admin_dashboard.png'), fullPage: true });

    // 2. Schools Page
    console.log('Capturing Schools Page...');
    await page.goto('http://localhost:8000/schools');
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: path.join(ARTIFACT_DIR, 'super_admin_schools.png'), fullPage: true });

    // Logout
    console.log('Logging out...');
    await page.goto('http://localhost:8000/'); 
    // actually, best way is to post to /logout or click it. Let's just evaluation.
    await page.evaluate(() => {
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = '/logout';
        const token = document.querySelector('meta[name="csrf-token"]').content;
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = '_token';
        input.value = token;
        form.appendChild(input);
        document.body.appendChild(form);
        form.submit();
    });
    await page.waitForNavigation();

    // Login as School Admin
    console.log('Logging in as School Admin...');
    await page.goto('http://localhost:8000/login');
    await page.type('#email', 'eyadmufleh@gmail.com');
    await page.type('#password', 'password');
    await Promise.all([
        page.waitForNavigation(),
        page.click('button[type="submit"]')
    ]);

    // 3. School Admin Dashboard
    console.log('Capturing School Admin Dashboard...');
    await new Promise(r => setTimeout(r, 1000));
    await page.screenshot({ path: path.join(ARTIFACT_DIR, 'school_admin_dashboard.png'), fullPage: true });

    // 4. Assignments Page
    console.log('Capturing Assignments Update...');
    await page.goto('http://localhost:8000/assignments');
    await new Promise(r => setTimeout(r, 1500)); // wait for anim and data
    await page.screenshot({ path: path.join(ARTIFACT_DIR, 'school_admin_assignments.png'), fullPage: true });

    // 5. Students Page
    console.log('Capturing Students Page...');
    await page.goto('http://localhost:8000/students');
    await new Promise(r => setTimeout(r, 1500));
    await page.screenshot({ path: path.join(ARTIFACT_DIR, 'school_admin_students.png'), fullPage: true });
    
    // 6. Teachers Page
    console.log('Capturing Teachers Page...');
    await page.goto('http://localhost:8000/teachers');
    await new Promise(r => setTimeout(r, 1500));
    await page.screenshot({ path: path.join(ARTIFACT_DIR, 'school_admin_teachers.png'), fullPage: true });

    console.log('Screenshots captured successfully!');
    await browser.close();
}

captureScreenshots().catch(err => {
    console.error(err);
    process.exit(1);
});
