## 2024-04-14 - Optimized Reports list and AI insights
**Learning:** Refactoring N+1 query loops into grouped Eloquent queries can significantly reduce database load. Implementing caching for expensive external API calls like AI insights improves response times and reduces costs. Using SQLite in-memory for testing across multiple connections requires explicit configuration in Laravel to avoid 'Connection refused' errors.
**Action:** Always check for N+1 problems in list endpoints and consider caching for any external API integration.
