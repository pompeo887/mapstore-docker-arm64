# MapStore — multi-arch (arm64 + amd64), hardened

**Unofficial** Docker image of [MapStore](https://github.com/geosolutions-it/MapStore2), the open-source WebGIS by GeoSolutions.
Runs **natively on ARM64** (tested on Apple Silicon; should also run on AWS Graviton, Ampere or a 64-bit Raspberry Pi 4/5, not tested) as well as amd64, with **far fewer known vulnerabilities** than the official image.

> Not affiliated with or endorsed by GeoSolutions. The MapStore application inside is the **original upstream build, unchanged**.

## Why you can trust it

- **Open source recipe:** everything is in https://github.com/pompeo887/mapstore-docker-arm64 — Dockerfiles, scripts, the list of replaced libraries.
- **Built in public CI:** images are built and pushed by [GitHub Actions](https://github.com/pompeo887/mapstore-docker-arm64/actions), not on a personal machine. Every build log is public.
- **Unmodified MapStore:** the upstream WAR is taken from the official release / official `master-dev` image, pinned by SHA-256 / digest. The 790 frontend files are byte-identical to the official image.
- **Pinned dependencies:** each replaced jar comes from Maven Central and is checked against a pinned SHA-256 (`overrides/`). Tomcat is checksum-verified too.
- **No secrets inside:** no API keys, tokens or personal data (scanned with Trivy). Bring your own Google / Cesium keys via your config.
- **Non-root:** Tomcat runs as uid 20000.
- **Licenses respected:** GPL components (GeoStore, MapFish Print) with their exact sources attached to the [GitHub release](https://github.com/pompeo887/mapstore-docker-arm64/releases).

## Tags

| Tag | Content | Known CVEs (Docker Scout) |
|---|---|---|
| `dev` | MapStore `master` (commit `5613d59`, future 2026.03.00): Spring 7, Tomcat 10.1, H2 2.x, printing included | **0** (4 findings documented as not exploitable, OpenVEX) |

For comparison, the official `geosolutionsit/mapstore2:2026.02.01` has 235 known CVEs.
`dev` is **development code** not yet released by GeoSolutions: great for testing, use with care in production.

## Verify it yourself

```sh
# architectures and digest
docker buildx imagetools inspect pompeot1987/mapstore-hardened:dev

# vulnerability scan (the VEX statements are embedded in /usr/share/vex)
docker scout cves pompeot1987/mapstore-hardened:dev --vex-author "MapStore hardened image maintainers"

# rebuild it from source and compare
git clone https://github.com/pompeo887/mapstore-docker-arm64 && cd mapstore-docker-arm64
docker build -f Dockerfile.dev -t mapstore-hardened:dev .
```

## Quick start

```sh
docker run -d --name mapstore -p 127.0.0.1:8080:8080 pompeot1987/mapstore-hardened:dev
```

Open http://localhost:8080/mapstore (default MapStore users: change the admin password at first login).
To keep maps across updates, use the `docker-compose.example.yml` in the GitHub repository (stores the database on your disk).

Upgrading from MapStore ≤ 2026.02 (H2 1.3 database)? Convert it once with `scripts/migrate-h2.sh` from the repository — back up first.

## Memory sizing

`JAVA_OPTS` makes the Java heap a **percentage of the container memory limit**
(`MaxRAMPercentage=60`, 70 for the `-printing` variant), with the serial GC, capped
metaspace/code cache/thread stacks and `ExitOnOutOfMemoryError`. Map layers are fetched by the
browser and the MapStore proxy streams data, so only PDF printing (included in `dev`) causes
real peaks on the server.

| Image | Limit | Idle | After 120 requests | Peak while printing (A4, 300 dpi) |
|---|---|---|---|---|
| `dev`, previous settings (`-Xms512m -Xmx2048m`) | 3 GB | 621 MB | 663 MB | 1285 MB |
| `dev` | 768 MB | 338 MB | 367 MB | 479 MB |
| `mapstore-printing` | 1 GB | 285 MB | 311 MB | 509 MB |

Recommended limits: **512 MB** for a demo without printing, **768 MB – 1 GB** for normal use and
for `dev` (at 512 MB a burst of 300 dpi prints can get the container OOM-killed),
**1 – 1.5 GB** with frequent printing. Override `JAVA_OPTS` if needed, keeping
`-Ddatadir.location=/usr/local/tomcat/datadir`.

- Behind a TLS-inspecting proxy, MapStore's proxy fails with `PKIX path building failed`: import
  your corporate CA into the container's Java truststore (`keytool -importcert -cacerts`) in a
  derived image. Never disable certificate validation.
- The proxy only forwards URLs matching `reqtypeWhitelist` in `proxy.properties` (SSRF
  protection); add other services explicitly.
- The `admin` user starts with MapStore's default password: change it before exposing the service.

## Links

- Source, documentation, security notes: https://github.com/pompeo887/mapstore-docker-arm64
- Security details and residual findings: [SECURITY.md](https://github.com/pompeo887/mapstore-docker-arm64/blob/main/SECURITY.md)
- Licenses and GPL sources: [NOTICE.md](https://github.com/pompeo887/mapstore-docker-arm64/blob/main/NOTICE.md)
- Issues: https://github.com/pompeo887/mapstore-docker-arm64/issues

Maintained by pompeo887, built with the assistance of Claude (Anthropic). MapStore is developed by [GeoSolutions](https://www.geosolutionsgroup.com/).
