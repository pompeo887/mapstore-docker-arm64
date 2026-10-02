# Security

## How this image reduces vulnerabilities

1. **Same application as upstream.** The official `mapstore.war` (and `mapstore-printing.zip`)
   of a MapStore GitHub release is used unchanged, with its SHA-256 pinned in the Dockerfile.
2. **Patched libraries.** Vulnerable jars inside `WEB-INF/lib` are replaced by fixed releases of
   the same major line (`overrides/*.list`). Every replacement jar is downloaded from Maven Central
   and checked against a pinned SHA-256 (`overrides/checksums*.sha256`). If upstream changes a
   library version the build fails instead of silently skipping the replacement.
3. **Minimal base.** Alpine Linux + OpenJDK 17 JRE + Apache Tomcat (checksum-verified tarball),
   instead of a full Ubuntu JDK image. Unused tools are removed (see `Dockerfile.dev`).
4. **Non-root.** Tomcat runs as uid/gid 20000, like the official image.

## Current status (Docker Scout, 2026-10-02)

| Image | Critical | High | Medium | Low |
|---|---|---|---|---|
| Official `geosolutionsit/mapstore2:2026.02.01` (for reference) | 25 | 73 | 118 | 19 |
| `mapstore-hardened:2026.02.01` (no printing) | 5 | 12 | 22 | 6 |
| `mapstore-hardened:2026.02.01-printing` | 6 | 12 | 25 | 7 |
| `mapstore-hardened:dev` (MapStore `master` 5613d59, future 2026.03.00) | 1 | 0 | 2 | 1 (unfiltered scan) |

The `dev` image now contains `jackson-core` 2.22.3 and 3.1.7 and `jackson-databind` 2.22.3.
Docker Scout no longer reports CVE-2026-89425, CVE-2026-89407, CVE-2026-91777 or
CVE-2026-91776. The remaining critical finding is CVE-2020-15232 on `print-lib` 2.5.0.
Its VEX statement explains why the affected MapFish Print 3.x SLD parser is absent from this
MapFish Print 2.x fork; this is a project-maintainer assessment, not an upstream fix.

### Residual vulnerabilities of the 2026.02.x images

They are inside MapStore/GeoStore itself and cannot be removed by replacing jars:

- **Spring Framework 5.3 / Spring Security 5.7**: end of open-source support; fixes exist only
  in commercial releases or in Spring 6+. MapStore moves to Spring 7 in 2026.03.00.
- **H2 1.3.175** (3 critical): all three need the H2 web console or an attacker-controlled JDBC
  URL. The H2 console is not deployed in MapStore (`/h2`, `/h2-console`, `/console` return 404).
  Upgrading H2 requires converting the database (`scripts/migrate-h2.sh`) and comes with 2026.03.00.
- **Hibernate 5.4, jdom 1.0, acegi-security, commons-lang 2.4**: used by GeoStore, no fixed release.
- **Printing only**: `print-lib` 2.3.5 and `commons-httpclient` 3.1 (MapFish Print v2).

Recommendation: do not expose these images directly to the Internet; publish them behind a
reverse proxy, and keep the ports bound to `127.0.0.1` when used on a workstation.

### VEX (not-affected statements)

`vex/` contains an [OpenVEX](https://openvex.dev) document, also copied into the image at
`/usr/share/vex/`, explaining why the remaining findings of the dev image are not exploitable
(code not present or removed from the image). Docker Scout only trusts VEX authors you allow:

```sh
docker scout cves <image> --vex-author "MapStore hardened image maintainers"
```

Note: `docker scout quickview` shows the unfiltered numbers when a VEX excludes every finding;
use `docker scout cves` for the filtered result.

## Reporting a vulnerability

Open a [private security advisory](../../security/advisories/new) in this repository.
Vulnerabilities in MapStore itself should also be reported to GeoSolutions:
https://github.com/geosolutions-it/MapStore2/security
