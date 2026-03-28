## 2025-05-22 - Synchronous AI bottleneck in Dashboard
**Learning:** The dashboard performs a synchronous HTTP call to an external AI service (running on port 8001) on every page load to generate insights. Since LLM responses are slow (often several seconds), this blocking call significantly degrades the admin experience and dashboard responsiveness.
**Action:** Implement caching for AI-generated insights, using a cache key based on the summarized statistics to ensure the cache is invalidated when data changes, while avoiding redundant slow calls for identical data.
