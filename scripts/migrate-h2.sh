#!/bin/sh
# Converts a MapStore/GeoStore H2 1.3 database (geostore.h2.db, MapStore <= 2026.02.x)
# to the H2 2.x format (geostore.mv.db) used by MapStore >= 2026.03 (GeoStore 2.7).
#
# Usage: scripts/migrate-h2.sh <path/to/geostore.h2.db> [image]
# The original file is never modified; geostore.mv.db is written next to it.
# A row-count comparison between the old and new database is printed at the end.
set -eu
SRC="$1"; IMAGE="${2:-mapstore-hardened:dev}"
[ -f "$SRC" ] || { echo "not found: $SRC" >&2; exit 1; }
DIR=$(cd "$(dirname "$SRC")" && pwd); WORK=$(mktemp -d)
H2_OLD_URL=https://repo1.maven.org/maven2/com/h2database/h2/1.3.175/h2-1.3.175.jar
mkdir -p "$WORK/old" "$WORK/new"; cp "$SRC" "$WORK/old/geostore.h2.db"
curl -fsSL "$H2_OLD_URL" -o "$WORK/h2-old.jar"
[ "$(shasum -a 1 "$WORK/h2-old.jar" | cut -c1-40)" = "$(curl -fsSL "$H2_OLD_URL.sha1" | cut -c1-40)" ] || { echo "h2 1.3 jar checksum mismatch" >&2; exit 1; }
cat > "$WORK/count.sql" <<'SQL'
SELECT 'resources', COUNT(*) FROM GS_RESOURCE UNION ALL SELECT 'stored_data', COUNT(*) FROM GS_STORED_DATA UNION ALL SELECT 'users', COUNT(*) FROM GS_USER UNION ALL SELECT 'bytes', SUM(LENGTH(STORED_DATA)) FROM GS_STORED_DATA;
SQL
docker run --rm -u 0 -v "$WORK:/w" --entrypoint sh "$IMAGE" -c '
set -e; cd /w; NEW=$(ls /usr/local/tomcat/webapps/mapstore/WEB-INF/lib/h2-2.*.jar)
# geostore/geostore are the default internal H2 credentials of MapStore
java -cp h2-old.jar org.h2.tools.Script -url "jdbc:h2:/w/old/geostore;IFEXISTS=TRUE" -user geostore -password geostore -script dump.sql
java -cp "$NEW" org.h2.tools.RunScript -url "jdbc:h2:/w/new/geostore" -user geostore -password geostore -script dump.sql -options FROM_1X
java -cp h2-old.jar org.h2.tools.Shell -url "jdbc:h2:/w/old/geostore;IFEXISTS=TRUE" -user geostore -password geostore -sql "$(cat count.sql)" | grep "|" > old.txt
java -cp "$NEW"     org.h2.tools.Shell -url "jdbc:h2:/w/new/geostore;IFEXISTS=TRUE" -user geostore -password geostore -sql "$(cat count.sql)" | grep "|" > new.txt
chmod 666 new/geostore.mv.db'
if diff "$WORK/old.txt" "$WORK/new.txt" >/dev/null; then
  cp "$WORK/new/geostore.mv.db" "$DIR/geostore.mv.db"; echo "OK: $DIR/geostore.mv.db"; cat "$WORK/new.txt"
else
  echo "row counts differ, not writing output:" >&2; diff "$WORK/old.txt" "$WORK/new.txt" >&2; exit 1
fi
rm -rf "$WORK"
