## 2025-05-11 - Debouncing Front-end Search Inputs
**Learning:** High-frequency UI updates during text input can cause noticeable lag, especially with large datasets, as the DOM is re-rendered on every single keystroke.
**Action:** Always implement debouncing for search/filter inputs that trigger complex filtering logic or extensive DOM manipulations. A 300ms delay is usually a good balance between responsiveness and efficiency.
