# MapStore Docker per ARM64 e AMD64

Immagine **non ufficiale** di [MapStore](https://github.com/geosolutions-it/MapStore2),
utilizzabile nativamente su Apple Silicon e su Linux ARM64 o AMD64. Usa Alpine, Java 17 e
Tomcat; il WAR proviene da MapStore upstream. Alcune librerie sono sostituite con versioni
corrette e il tag `dev` include una correzione CSS per la timeline.

Docker Hub: [pompeot1987/mapstore-hardened](https://hub.docker.com/r/pompeot1987/mapstore-hardened)

| Tag | Contenuto |
| --- | --- |
| `dev` | MapStore master (`5613d59`, futura 2026.03), stampa PDF inclusa; ARM64 e AMD64 |
| `2026.02.01` | Release stabile, senza stampa; solo build locale per ora |
| `2026.02.01-printing` | Release stabile con stampa; solo build locale per ora |

Il tag `dev` usa codice upstream di sviluppo. Il progetto non è affiliato a GeoSolutions.

## Avvio rapido

```sh
curl -O https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/docker-compose.example.yml
mkdir -p example/datadir
curl -o example/datadir/geostore-datasource-ovr.properties \
  https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/example/datadir/geostore-datasource-ovr.properties
docker compose -f docker-compose.example.yml up -d
```

Apri <http://localhost:8080/mapstore>. Il database resta in `./example/datadir` anche dopo
l'aggiornamento dell'immagine. Cambia la password dell'utente amministratore al primo accesso.
Per il tag `dev` assegna almeno 1 GB di memoria al container se usi la stampa PDF. Le porte
dell'esempio sono accessibili solo da `127.0.0.1`.

## Sicurezza

Nella scansione Docker Scout del **2 ottobre 2026**, il tag `dev` aggiornato presenta
**1 CRITICAL, 0 HIGH, 2 MEDIUM e 1 LOW** nel report non filtrato. Le quattro nuove CVE di
Jackson (`CVE-2026-89425`, `CVE-2026-89407`, `CVE-2026-91777`, `CVE-2026-91776`) non
compaiono più dopo l'aggiornamento a Jackson `2.22.3` e `3.1.7`. La segnalazione critica
residua riguarda `print-lib 2.5.0`; l'analisi e le dichiarazioni OpenVEX sono in
[SECURITY.md](SECURITY.md). Le dichiarazioni VEX sono valutazioni del progetto, non patch.

## Aggiornamento da MapStore precedente

MapStore 2026.03 usa H2 2.x. Prima di avviare `dev` con un database H2 1.3, fai una copia
di sicurezza e convertilo:

```sh
scripts/migrate-h2.sh percorso/di/geostore.h2.db
```

Se monti un vecchio `localConfig.json`, rinomina il plugin `MetadataExplorer` in `Catalog`
conservando il suo `cfg`; altrimenti il pulsante «Aggiungi layer» può sparire.

## Build e documentazione

```sh
docker build -f Dockerfile.dev -t mapstore-hardened:dev .
docker buildx build --platform linux/amd64,linux/arm64 -f Dockerfile.dev \
  -t <utente>/mapstore-hardened:dev --push .
```

Il [workflow GitHub](.github/workflows/docker.yml) pubblica il tag `dev` su Docker Hub
quando viene inviato un tag Git che inizia con `dev`. Per librerie, checksum e valutazione
delle CVE vedi [SECURITY.md](SECURITY.md); per sorgenti e licenze vedi
[NOTICE.md](NOTICE.md). Il codice di questo repository è BSD 2-Clause
([LICENSE](LICENSE)).
