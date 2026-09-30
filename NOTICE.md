# Third-party software in the images

The images built from this repository **redistribute, unmodified**, software
owned by third parties. This repository only contains the build recipe.
This is an **unofficial** image, not affiliated with or endorsed by GeoSolutions.
"MapStore" is a name of GeoSolutions Group.

| Component | License | Corresponding source |
|---|---|---|
| MapStore (web application, `mapstore.war`) | BSD 2-Clause | https://github.com/geosolutions-it/MapStore2 (tag of the release used, e.g. `v2026.02.01`) |
| GeoStore (backend jars `geostore-*.jar` inside the WAR) | GPL-3.0 | https://github.com/geosolutions-it/geostore (version shown in the jar name) |
| MapFish Print v2 fork (`print-lib-*.jar`, printing module) | GPL-3.0-or-later | https://github.com/geosolutions-it/mapfish-print |
| Files in `docker/` and `binary/` (copied from the MapStore repository) | BSD 2-Clause | https://github.com/geosolutions-it/MapStore2 |
| Replacement libraries listed in `overrides/*.list` (Jackson, Log4j, Bouncy Castle, CXF, PostgreSQL JDBC, Batik, Xerces, ...) | Apache-2.0 / MIT / BSD / EPL / LGPL (license file inside each jar) | Maven Central, coordinates listed in `overrides/*.list` |
| Apache Tomcat | Apache-2.0 | https://archive.apache.org/dist/tomcat/ |
| OpenJDK 17 (Alpine package) | GPL-2.0 with Classpath Exception | https://gitlab.alpinelinux.org/alpine/aports |
| Alpine Linux base and packages (busybox, musl, fontconfig, ...) | various, including GPL-2.0 | https://gitlab.alpinelinux.org/alpine/aports |

## Exact sources of the `dev` image (MapStore master 5613d59)

| Component in the image | Exact source |
|---|---|
| MapStore WAR `master-dev-SNAPSHOT-5613d59` | https://github.com/geosolutions-it/MapStore2/tree/5613d59a71b973a4e34e8b6cc6452b5cfcb638ad |
| `geostore-*-2.7-SNAPSHOT.jar` (GPL-3.0) | build `2.7-20260914.152649-22` (SHA-1 verified), `*-sources.jar` at https://maven.geo-solutions.it/it/geosolutions/geostore/ |
| `print-lib-2.5.0.jar` (GPL-3.0-or-later) | tag `release/2.5.0` of https://github.com/mapfish/mapfish-print-v2 |

`scripts/fetch-gpl-sources.sh` downloads all of them; they are attached to each GitHub release,
so they stay available even if the upstream snapshot repository removes old builds.

## Other images

To obtain the exact source of the GPL components of a given image, use the
MapStore release tag written in the image tag and the jar versions listed with
`docker run --rm <image> ls /usr/local/tomcat/webapps/mapstore/WEB-INF/lib`.
If a source link stops working, open an issue in this repository and it will be provided.
