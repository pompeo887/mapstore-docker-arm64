# MapStore Docker image — multi-arch (arm64/amd64) and hardened

**Unofficial** Docker image of [MapStore](https://github.com/geosolutions-it/MapStore2), the
open-source WebGIS by GeoSolutions. It runs **natively on Apple Silicon / ARM64** (the official
image is amd64 only) and has **far fewer known vulnerabilities** than the official image.

> Not affiliated with or endorsed by GeoSolutions. "MapStore" is a name of GeoSolutions Group.
> The MapStore application inside the image is the official release, unchanged.

## What is different from the official image

| | Official `geosolutionsit/mapstore2` | This image |
|---|---|---|
| Architectures | linux/amd64 | linux/amd64 + linux/arm64 |
| Base | Ubuntu + full JDK 17 | Alpine + OpenJDK 17 JRE |
| MapStore application | release WAR | same upstream WAR, unchanged: release for `2026.02.01`, `master` build for `dev` (both pinned) |
| Vulnerable libraries | as released | replaced by fixed versions (`overrides/`) |
| Known CVEs | 235 (2026.02.01) | 0 (`dev`), 45–50 (2026.02.01) — see [SECURITY.md](SECURITY.md) |

## Tags

| Tag | Content | Known CVEs |
|---|---|---|
| `dev` | MapStore development branch (commit `5613d59`, future 2026.03.00): Spring 7, Tomcat 10.1, H2 2.x, printing included | **0** (5 scanner findings documented as not exploitable in `vex/`) |
| `2026.02.01` | MapStore 2026.02.01 release, like the official image (no printing) | 45 |
| `2026.02.01-printing` | same, plus the MapFish Print module (PDF printing) | 50 |

`dev` has the fewest vulnerabilities but is **development code**: GeoSolutions has not released it yet,
so it can contain bugs (for example, camera jumps while zooming in the 3D view, reproduced on the
official `master-dev` image too). Use a release tag if you need stability.

## Quick start

```sh
curl -O https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/docker-compose.example.yml
mkdir -p example/datadir
curl -o example/datadir/geostore-datasource-ovr.properties \
  https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/example/datadir/geostore-datasource-ovr.properties
docker compose -f docker-compose.example.yml up -d
```

By default the example uses the `dev` image; set `MAPSTORE_IMAGE` to use a release tag.

Open http://localhost:8080/mapstore. Default MapStore users apply: change the admin password at first login.

- Works on Linux, macOS and Windows (Docker Desktop); Docker picks the right architecture.
- The maps database is stored in `./example/datadir` on your computer, so it survives updates.
- Your own `localConfig.json` and extensions can be mounted (see comments in the compose file).
  Keep API keys/tokens in your local files only.

## Upgrading to MapStore 2026.03 (H2 database format change)

MapStore 2026.03 uses H2 2.x and cannot read the H2 1.3 database of previous versions
(`geostore.h2.db`). Convert it once, **after making a backup**:

```sh
scripts/migrate-h2.sh path/to/geostore.h2.db   # writes geostore.mv.db next to it and checks row counts
```

## Build it yourself

```sh
docker build --target mapstore          -t mapstore-hardened:2026.02.01 .
docker build --target mapstore-printing -t mapstore-hardened:2026.02.01-printing .
# multi-arch
docker buildx build --platform linux/amd64,linux/arm64 --target mapstore-printing -t <you>/mapstore-hardened:2026.02.01-printing --push .
```

`Dockerfile.dev` builds the `dev` tag: `docker build -f Dockerfile.dev -t mapstore-hardened:dev .`

## Licenses

The files of this repository are BSD 2-Clause (see [LICENSE](LICENSE)). The images contain
third-party software under its own licenses, including GPL-3.0 components (GeoStore, MapFish Print):
see [NOTICE.md](NOTICE.md) for the list and where to get the corresponding source.

## Credits

Developed with the assistance of Claude (Anthropic). Reviewed, tested and verified on a working
installation by pompeo887, who maintains this repository.
MapStore is developed by [GeoSolutions](https://www.geosolutionsgroup.com/).
