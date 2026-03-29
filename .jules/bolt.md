## 2025-05-22 - AI Service Caching in Laravel
**Learning:** External API calls to an AI service (Edulearn_AI) during page loads were a major bottleneck in the EduLearn_Dashboard. Using Laravel's `Cache` facade with keys based on input statistics ensures freshness while providing a near-instant user experience for repeated views.
**Action:** Always check for synchronous external API calls in high-traffic views (like dashboards) and implement caching with intelligent keys.

## 2025-05-22 - Testing Dual-Database Laravel Apps
**Learning:** Testing a Laravel app with multiple database connections (e.g., `mysql` and `app_mysql`) using `RefreshDatabase` and SQLite memory is difficult. Migrations that check for table existence on a specific connection fail in the test environment because the connection configurations don't match the test environment's SQLite setup.
**Action:** When working with multi-connection Laravel apps, ensure tests can handle or mock secondary connections, or use a real database for integration testing if possible.
