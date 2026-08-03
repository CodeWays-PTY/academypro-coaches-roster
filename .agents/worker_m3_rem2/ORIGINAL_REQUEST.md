## 2026-08-03T13:57:34+02:00
Examine web_admin/index.html and web_admin/uploader.html. Remove all instances of prohibited over-defensive string fallbacks such as || 'OVK'. Ensure schoolId is derived cleanly without hardcoded string fallbacks. Scan web_admin/ HTML and JS files for any other prohibited fallback strings. Run npx tsc --noEmit in worker/. Write handoff.md report and notify parent.
