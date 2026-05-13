# [Engineering Roadmap] EduLearn Mobile App Evolution (v2.0)

## Executive Summary
This document outlines the professional plan to modernize the **EduLearn_App** (Flutter) by integrating the smart communication and support systems recently implemented in the dashboard. The goal is to achieve a seamless, AI-driven, and real-time user experience across all devices.

---

## Phase 1: Unified Support Ecosystem
**Objective**: Synchronize help resources between the dashboard and mobile app.
- **Dynamic Content**: Implement a service to fetch `contact_channels` from the backend API.
- **Support Screen**: Design a high-end "Support Hub" in Flutter with:
    - Direct WhatsApp integration.
    - One-tap Email/Call features.
    - Official Ticket management interface.
- **Branding**: Ensure the "Contact Us" info matches the Super Admin's configuration in real-time.

---

## Phase 2: Smart Notification Infrastructure
**Objective**: Transition from static alerts to a real-time, interactive broadcasting system.
- **Firebase (FCM) Bridge**: Configure a push notification bridge to ensure delivery even when the app is backgrounded.
- **Real-time Engine**: Integrate `laravel_echo` or raw WebSockets in Flutter to listen to:
    - `notifications.all` (Global alerts).
    - `notifications.{role}` (Role-specific alerts).
- **Interactive Payloads**: Support deep-linking so users can jump to a specific screen (e.g., a new lesson or exam) directly from the notification.
- **Visual Feedback**: Use rich-text and priority-based icons (Blue/Orange/Red) for in-app alerts.

---

## Phase 3: AI-Powered Productivity
**Objective**: Empower teachers with AI tools directly from their smartphones.
- **AI Write Assistant**: Integrate the Gemini-powered content generator for creating school announcements.
- **Smart Templates**: Offer pre-defined AI prompts for common school events (Exams, Holidays, Meetings).

---

## Phase 4: Data-Driven Engagement (Analytics)
**Objective**: Provide the Super Admin with mobile interaction data.
- **Read Receipts**: Implement silent tracking calls when a user opens a notification.
- **Clickstream Tracking**: Log interactions with `action_urls` within the app to measure CTR (Click-Through Rate).

---

## Phase 5: Premium UI/UX Refactoring
- **Glassmorphism Design**: Update the app's theme to match the "Deep Navy & Orange" premium dashboard aesthetic.
- **Dynamic Tabs**: Implement the "Inbox" vs "Activity" tab system for a cleaner notification experience.

---

## Technical Stack Recommendation
- **Framework**: Flutter (Current).
- **Socket Client**: `laravel_echo_flutter`.
- **Push Service**: Firebase Cloud Messaging (FCM).
- **API Protocol**: RESTful JSON with Sanctum authentication.

---
*Authored by: EduLearn Engineering Team*
*Date: 2026-05-03*
