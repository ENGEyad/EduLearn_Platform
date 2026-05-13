# EduLearn Communication & Support Module

## Overview
This module centralizes platform-wide communication and branding controls for Super Admins. It includes a dynamic help center, an official ticketing system, and a real-time smart notification center.

## Key Components

### 1. Unified Support Hub
Managed via `SuperAdmin\SettingController`, this system allows global control over contact channels.
- **Dynamic Repeater**: Admins can add, update, or remove contact methods (WhatsApp, Telegram, Support Emails) on the fly.
- **Support Interface**: Users can access these channels through a premium, responsive support page (`resources/views/support.blade.php`).

### 2. Smart Notification Center
A real-time broadcasting engine based on Laravel Echo and Reverb/Pusher.
- **Broadcasting Event**: `App\Events\SystemAlertBroadcast`
- **Controller**: `SuperAdmin\SystemNotificationController`
- **Priority Logic**:
    - `Normal`: Toast notifications (auto-hide).
    - `High`: Warning dialogs.
    - `Urgent`: Critical system alerts.
- **Targeting**: Send messages to `All`, `School Admins`, `Teachers`, or `Students` specifically.

## Technical Specifications

### Data Structure
Settings are stored in the `system_settings` table:
- `contact_channels`: JSON array containing type, label, and value.
- `site_logo`: Path to the branding icon.

Notifications are stored in `system_notifications`:
- `priority`: Enum (normal, high, urgent).
- `target_role`: Who receives the message.
- `action_url`: Optional link for user interaction.
- `scheduled_at`: Future publishing date.

### Front-end Integration
The system uses **SweetAlert2** for real-time delivery. The global listener is located in `layouts/app.blade.php`.
```javascript
window.Echo.channel("notifications.all")
    .listen('.system.alert', (data) => {
        // UI logic to show the popup
    });
```

---
*Created on: 2026-04-28*
*By: Antigravity AI Assistant*
