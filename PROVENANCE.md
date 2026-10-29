# Provenance and attribution

## Project contributions

This project was developed by a team of six students as a group course project for STA 313 Data Visualization.

The new Toronto Crime Explorer implementation and documentation were prepared with Codex assistance. It retains the project's core concept, source datasets, and recovered destination/station coordinates while replacing the monolithic UI/server and implicit workspace-based data flow with shared functions, a Shiny module, an explicit build, and tests.

## Incidental metadata excluded

The working copy omits console histories, automatic R workspaces, operating-system metadata, WeChat/cache paths, recovered account/deployment records, and the old version-like directory name. The original recovered folder remains intact separately. These omissions remove irrelevant machine state; they do not erase the collaborative project history.

## Data lineage

The build consumes exactly these recovered files:

- `Bicycle_Thefts_Open_Data.csv`
- `Robbery_Open_Data.csv`
- `Theft_Over_Open_Data.csv`

Their naming/schema are consistent with Toronto police open-data exports, but source URLs, original download dates, publisher terms, and redistribution permissions have not been independently verified. Do not infer permission from filenames. The build records input filenames, MD5 integrity checksums, exclusions, deduplication counts, retained counts, and date coverage inside the output manifest. Checksums establish input identity, not provenance or rights.

The unused Assault CSV and neighborhood GeoJSON were not carried into this working copy. Destination/station coordinates were extracted from the recovered data bundle. Their original sourcing remains unknown. Two destination labels were corrected to Robarts Library and Centre Island; coordinates were preserved and should be reviewed against authoritative sources before publication.

The supplied station list is incomplete. The modern app deliberately says "nearest listed station" and computes it rather than claiming complete-network nearest-station or walking-route analysis.

## Third-party software and maps

Packages are listed in DESCRIPTION and retain their own licenses. This project does not vendor their source. The map uses Leaflet's standard OpenStreetMap tiles and preserves the attribution emitted by `addTiles()`. No tile assets are redistributed locally and no credentials are embedded. Current provider terms, capacity suitability, and service availability were not verified through network requests.

## Release decisions still needed

Confirm the project team's contribution credits and applicable permission to publish the group code; recover data and coordinate sources and terms; choose an appropriate code license with those facts established. LICENSE is explicitly a pending-status notice, not an open-source license. Generated data remains excluded from version control until redistribution is resolved.
