# Validation record

## Completed

- All R files parse successfully.
- `tests/test_analysis.R`: 28 checks pass, covering exam presets, all 168 weekly peak/off-peak hours, holiday boundaries, distance calculations, composable spatial/time/category filters, date endpoints, empty selections, zero-filled daily counts, excluded-date gaps, nearest-listed-station selection, and real-data invariants.
- `tests/test_shiny.R`: destination and station modules pass checks for rendering every plot, consistent local filtering, final-exam filtering, empty-category summaries and CSV downloads, peak/off-peak partitioning, and explicit offline map zoom bounds.
- Rebuilding from the three supplied CSVs produces a byte-identical RDS file (verified with an MD5 comparison).
- Prepared data: 25,242 analysis records, 25,068 distinct event IDs, January 1, 2020 through December 31, 2023.
- Local loopback application starts successfully with Shiny 1.14.0 and R 4.5.3. Tested package versions are recorded in DEPENDENCIES.csv.
- Browser inspection confirms both tabs, charts, marker clusters, and radius selection. Little Canada within 300 m: 566 records / 563 distinct IDs. Its nearest listed station, Dundas Station, within 300 m: 702 records / 697 distinct IDs.
- Browser empty-category selection displays a clear no-results message and clears record markers.
- Browser inspection identified and resolved compressed card heights and marker clustering without a basemap (`maxZoom` must be specified).
- Source scan found no recovered machine username, account identifiers, absolute home paths, or transfer-cache paths in the new text source/configuration.

## Scope and limitations

The isolated runtime installation lives in the task's work directory, not in the user's global R library. The initial pass used tiles disabled. The follow-up browser pass verified automatic OpenStreetMap tile display. This confirms availability during the test, not future uptime or current provider usage terms. The original API-key prompt was not reproduced.

The browser emitted deprecation warnings from bundled datepicker locale files. These are third-party warnings, not failing application filters. Earlier map-clustering errors were fixed and the subsequent browser pass displayed clusters correctly.

No load/concurrency benchmark, mobile-device certification, public deployment, repository publication, or data-license verification was performed. CI currently runs the dependency-free analytical suite using synthetic records; the local module suite additionally requires runtime packages and the generated data.

The original recovered directory was not modified. Publication permissions and historical contribution details remain as documented in PROVENANCE.md.

## Introduction, maps, and trends follow-up

- Introduction is now the initial page, with working navigation buttons.
- Both complete map widgets include tiles and their selected records without relying on initialization-time proxy updates.
- Each category individually renders its full marker set in both module tests. The browser confirms robbery-only transit results (8,455 records), automatic street tiles, and Select all categories restoring the full selection.
- Five new analytical assertions cover weekly/monthly total conservation, Monday week starts, eligible-day counts, excluded-period gaps, and empty results. Module tests also verify the plotted point counts for daily, weekly, and monthly intervals.
- The previous preview's unchecked transit state came from an empty-state test; the final preview is restored to all categories and opens on Introduction.
