#!/bin/sh
# Applica un file di sostituzioni jar a una cartella WEB-INF/lib.
# Uso: apply-overrides.sh <lista> <WEB-INF/lib> <checksums.sha256>
# Ogni glob da rimuovere deve trovare almeno un jar: se MapStore cambia
# versione di una libreria il build fallisce invece di passare in silenzio.
set -eu
LIST="$1"; LIB="$2"; SUMS="$3"
MAVEN="${MAVEN_REPO:-https://repo1.maven.org/maven2}"
grep -vE '^\s*(#|$)' "$LIST" | while read -r glob coords repo; do
  if [ "$glob" != "-" ]; then
    found=0
    for f in "$LIB"/$glob; do [ -e "$f" ] && { rm -f "$f"; found=1; echo "rimosso  $(basename "$f")"; }; done
    [ "$found" = 1 ] || { echo "ERRORE: nessun jar corrisponde a $glob" >&2; exit 1; }
  fi
  if [ "$coords" != "-" ]; then
    g=$(echo "$coords" | cut -d: -f1 | tr . /); a=$(echo "$coords" | cut -d: -f2); v=$(echo "$coords" | cut -d: -f3)
    jar="$a-$v.jar"
    curl -fsSL "${repo:-$MAVEN}/$g/$a/$v/$jar" -o "$LIB/$jar"
    expected=$(grep " $jar\$" "$SUMS" | cut -d' ' -f1)
    [ -n "$expected" ] || { echo "ERRORE: checksum mancante per $jar" >&2; exit 1; }
    echo "$expected  $LIB/$jar" | sha256sum -c -s || { echo "ERRORE: checksum errato per $jar" >&2; exit 1; }
    echo "aggiunto $jar"
  fi
done
