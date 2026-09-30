#!/bin/sh
# Downloads the corresponding source of the GPL components shipped in the `dev` image,
# to be attached to the GitHub release (GPL-3.0 section 6). Output: ./gpl-sources/
set -eu
OUT=gpl-sources; mkdir -p "$OUT"
# GeoStore 2.7-SNAPSHOT build used by MapStore master 5613d59 (jar SHA-1 verified identical)
GS=https://maven.geo-solutions.it/it/geosolutions/geostore; B=2.7-20260914.152649-22
for m in geostore-model geostore-persistence geostore-rest-api geostore-rest-extjs geostore-rest-impl \
         geostore-security geostore-services-api geostore-services-impl; do
  curl -fsSL "$GS/$m/2.7-SNAPSHOT/$m-$B-sources.jar" -o "$OUT/$m-$B-sources.jar" || echo "missing: $m" >&2
done
# print-lib 2.5.0 (classes identical to the print-lib-2.5-SNAPSHOT inside the MapStore WAR)
curl -fsSL https://github.com/mapfish/mapfish-print-v2/archive/refs/tags/release/2.5.0.tar.gz -o "$OUT/mapfish-print-v2-release-2.5.0.tar.gz"
# MapStore (BSD, included for completeness)
curl -fsSL https://github.com/geosolutions-it/MapStore2/archive/5613d59a71b973a4e34e8b6cc6452b5cfcb638ad.tar.gz -o "$OUT/MapStore2-5613d59.tar.gz"
ls -la "$OUT"
