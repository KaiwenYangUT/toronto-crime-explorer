# Modernization changes

- Renamed the application Toronto Crime Explorer.
- Created an independent working directory; preserved the recovered source folder.
- Replaced the monolithic interface with a shared explorer module and pure analytical functions.
- Corrected exam-month filters, peak/off-peak boundaries, and coverage labels.
- Applied the same spatial/temporal filters to maps, charts, totals, and exports.
- Replaced positional station pairing with distance-based nearest-listed-station selection.
- Labeled bicycle theft accurately and retained all statuses for historical analysis.
- Exposed the difference between analysis-record counts and distinct event IDs.
- Zero-filled eligible dates and retained gaps for excluded dates.
- Replaced trusted HTML event labels with escaped plain text.
- Removed unnecessary Assault processing, unused boundaries, hidden output errors, duplicate imports, and old session/deployment metadata from the working copy.
- Added source checksums, schema validation, coordinate/date validation, explicit preprocessing, and a compact RDS bundle.
- Added a dependency manifest, regression checks, analytical CI, documentation, and provenance notes.

The prepared dataset contains 25,242 analysis records and 25,068 distinct event IDs. The recovered runtime bundle contained 24,997 records and 24,853 distinct IDs. Different status inclusion, retained analysis fields, and validation mean these totals are not expected to be identical.

## Follow-up interface improvements

- Restored the Introduction landing page and direct exploration buttons.
- Load street tiles automatically on both maps; removed the checkbox.
- Replace the dense daily-only trend with native Plotly weekly trends and daily/monthly options. Daily exports are unchanged.
- Add Select all categories and a specific empty-category message.
- Render complete maps to avoid hidden-tab initialization and asynchronous cluster update races.
