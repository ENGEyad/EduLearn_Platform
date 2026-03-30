## 2024-05-22 - AI Insight Caching
**Learning:** External AI services (like the one at 8001) introduce significant latency (up to 10s per request). Caching these responses based on input parameters (period + data hash) eliminates this overhead for repeated dashboard views.
**Action:** Always consider caching expensive AI-generated content in dashboards where data doesn't change every second.

## Expected Performance Impact:
- **Response Time:** Reduced from ~1-10 seconds (AI latency) to ~20ms (Cache hit).
- **External Calls:** One call per hour per period, instead of every page load.
- **Resource Usage:** Significant reduction in AI service costs and server-side waiting time.
