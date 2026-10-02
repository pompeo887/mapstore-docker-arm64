# MapStore Docker (ARM64 / AMD64)

[![Docker Hub](https://img.shields.io/badge/Docker%20Hub-pompeot1987%2Fmapstore--hardened-blue?logo=docker)](https://hub.docker.com/r/pompeot1987/mapstore-hardened)
[![License](https://img.shields.io/badge/License-BSD--2--Clause-green.svg)](LICENSE)

Immagine Docker **non ufficiale** per [MapStore](https://github.com/geosolutions-it/MapStore2) basata su Alpine Linux, Java 17 e Apache Tomcat. Supporta architetture **ARM64** (Apple Silicon, Raspberry Pi) e **AMD64**.

L'applicativo utilizza il WAR originale upstream con librerie aggiornate per la sicurezza e correzioni mirate.

---

## 🏷️ Tags Disponibili

| Tag | Descrizione | Piattaforme |
| :--- | :--- | :--- |
| `dev` | Master branch (`5613d59`, pre-2026.03), include modulo di stampa | `linux/arm64`, `linux/amd64` |
| `2026.02.01` | Release stabile (senza modulo di stampa) | *Build locale* |
| `2026.02.01-printing` | Release stabile (con modulo di stampa) | *Build locale* |

> ⚠️ **Nota:** Il tag `dev` utilizza codice in fase di sviluppo. Progetto non affiliato a GeoSolutions.

---

## 🚀 Quick Start

Scarica la configurazione ed avvia il container tramite Docker Compose:

```bash
curl -O https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/docker-compose.example.yml
mkdir -p example/datadir
curl -o example/datadir/geostore-datasource-ovr.properties \
  https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/example/datadir/geostore-datasource-ovr.properties

docker compose -f docker-compose.example.yml up -d
```

- **URL:** Accessibile su [http://localhost:8080/mapstore](http://localhost:8080/mapstore) *(esposta solo su `127.0.0.1`)*.
- **Credenziali:** Cambiare la password dell'utente `admin` al primoaccesso.
- **Persistenza:** I dati rimangono salvati in `./example/datadir`.
- **Risorse:** Riservare almeno 1 GB di RAM al container se si utilizza il modulo di stampa nel tag `dev`.

---

## 🛡️ Sicurezza e VEX

Aggiornamento al **2 ottobre 2026**:
- **Jackson:** Risolte le vulnerabilità CVE-2026-89425, CVE-2026-89407, CVE-2026-91777 e CVE-2026-91776 tramite upgrade a Jackson `2.22.3` / `3.1.7`.
- **Report residuo:** 1 CRITICAL (`print-lib 2.5.0`), 0 HIGH, 2 MEDIUM, 1 LOW.
- Per le analisi dettagliate, le mitigazioni e le valutazioni OpenVEX, consultare il file [SECURITY.md](SECURITY.md).

---

## ⚠️ Note di Migrazione

Se si esegue l'upgrade da versioni precedenti di MapStore a `dev` (H2 2.x):

1. **Database H2:** Eseguire un backup ed eseguire lo script di conversione dal formato H2 1.3:
   ```bash
   scripts/migrate-h2.sh percorso/di/geostore.h2.db
   ```
2. **Configurazione:** Se si utilizza un `localConfig.json` personalizzato, rinominare il plugin `MetadataExplorer` in `Catalog` (mantenendo il blocco `cfg`) per evitare malfunzionamenti nel menu dei layer.

---

## 🛠️ Build Locale

Costruzione manuale dell'immagine per la piattaforma locale o in multi-architettura:

```bash
# Build locale standard
docker build -f Dockerfile.dev -t mapstore-hardened:dev .

# Build multi-architettura con push
docker buildx build --platform linux/amd64,linux/arm64 -f Dockerfile.dev \
  -t <utente>/mapstore-hardened:dev --push .
```

---

## 🔗 Riferimenti

- **Sicurezza & CVE:** [SECURITY.md](SECURITY.md)
- **Licenze & Dipendenze:** [NOTICE.md](NOTICE.md)
- **Workflow CI/CD:** [.github/workflows/docker.yml](.github/workflows/docker.yml)
