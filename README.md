# MapStore per Docker — multi-architettura (arm64/amd64) e con meno vulnerabilità

*English summary: unofficial multi-arch (arm64 + amd64) Docker image of MapStore with patched
libraries and a minimal Alpine base; 0 known CVEs for the `dev` tag (with the VEX in `vex/`).*

Immagine Docker **non ufficiale** di [MapStore](https://github.com/geosolutions-it/MapStore2),
il WebGIS open source di GeoSolutions. Gira **nativamente su Apple Silicon e su qualsiasi
processore ARM64**, mentre l'immagine ufficiale esiste solo per amd64, e ha **molte meno
vulnerabilità note** dell'immagine ufficiale.

> Non affiliata a GeoSolutions né da loro approvata. "MapStore" è un nome di GeoSolutions Group.
> L'applicazione MapStore contenuta nell'immagine è quella originale, senza modifiche.

## In cosa è diversa dall'immagine ufficiale

| | Ufficiale `geosolutionsit/mapstore2` | Questa immagine |
|---|---|---|
| Architetture | linux/amd64 | linux/amd64 + linux/arm64 |
| Sistema di base | Ubuntu + JDK 17 completo | Alpine + OpenJDK 17 (solo runtime) |
| Applicazione MapStore | WAR della release | lo stesso WAR originale, invariato e verificato con checksum |
| Librerie vulnerabili | come rilasciate | sostituite con versioni corrette (`overrides/`) |
| Vulnerabilità note | 235 (2026.02.01) | **0** (`dev`), 45–50 (2026.02.01) — vedi [SECURITY.md](SECURITY.md) |

## Immagini disponibili

Docker Hub: https://hub.docker.com/r/pompeot1987/mapstore-hardened

```sh
docker pull pompeot1987/mapstore-hardened:dev
```

| Tag | Contenuto | Vulnerabilità note |
|---|---|---|
| `dev` | MapStore ramo di sviluppo (commit `5613d59`, futura 2026.03.00): Spring 7, Tomcat 10.1, H2 2.x, stampa PDF inclusa | **0** (5 segnalazioni dello scanner documentate come non sfruttabili in `vex/`) |
| `2026.02.01` *(si costruisce dal `Dockerfile`, non ancora su Docker Hub)* | MapStore release 2026.02.01, come l'immagine ufficiale (senza stampa) | 45 |
| `2026.02.01-printing` *(idem)* | come sopra, con il modulo di stampa MapFish Print | 50 |

`dev` è quella con meno vulnerabilità, ma è **codice di sviluppo** non ancora rilasciato da
GeoSolutions: può contenere difetti (per esempio salti della vista durante lo zoom in 3D,
riprodotti anche sull'immagine ufficiale `master-dev`). Per la massima stabilità usa una release.

## Avvio rapido

```sh
curl -O https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/docker-compose.example.yml
mkdir -p example/datadir
curl -o example/datadir/geostore-datasource-ovr.properties \
  https://raw.githubusercontent.com/pompeo887/mapstore-docker-arm64/main/example/datadir/geostore-datasource-ovr.properties
docker compose -f docker-compose.example.yml up -d
```

Poi apri http://localhost:8080/mapstore. Valgono gli utenti predefiniti di MapStore: cambia la
password di amministratore al primo accesso.

- Funziona su Linux, macOS e Windows (Docker Desktop): Docker scarica da solo la versione giusta
  per il tuo processore.
- Il database delle mappe viene salvato in `./example/datadir` sul tuo computer, quindi resta
  anche quando aggiorni l'immagine.
- Puoi montare il tuo `localConfig.json` e le tue estensioni (vedi i commenti nel file compose).
  Chiavi e token restano solo nei tuoi file locali.
- Le porte sono aperte solo su `127.0.0.1`: MapStore non è visibile in rete finché non lo decidi tu.

## Aggiornamento a MapStore 2026.03 (cambia il formato del database)

MapStore 2026.03 usa H2 2.x e non legge il database H2 1.3 delle versioni precedenti
(`geostore.h2.db`). Va convertito una volta sola, **dopo aver fatto un backup**:

```sh
scripts/migrate-h2.sh percorso/di/geostore.h2.db   # crea geostore.mv.db accanto e confronta le righe
```

Il file originale non viene modificato; se il numero di righe non coincide, lo script si ferma
senza scrivere nulla.

## Come è nato questo progetto: il lavoro del 30 settembre 2026

Questo repository è il risultato di una giornata di lavoro su un'installazione MapStore reale
(con mappe 2D/3D, estensioni personalizzate e stampa PDF) su un **Mac mini con chip Apple M4**.
Ogni passaggio è stato provato sull'installazione in uso prima di essere pubblicato.

1. **Il punto di partenza.** MapStore e GeoServer giravano in **emulazione amd64**, perché
   l'immagine ufficiale di MapStore esiste solo per processori Intel/AMD. Funzionava, ma lento.

2. **Versione nativa arm64.** MapStore è un'applicazione Java, indipendente dal processore: è
   bastato rimetterla su una base Tomcat/Java multi-architettura. Risultati misurati:
   - avvio di MapStore da 13,6 a **5,4 s**, di GeoServer da 22,8 a **6,2 s**;
   - memoria di MapStore da 1,12 a **0,74 GB**, di GeoServer da 1,02 a **0,62 GB**.

3. **Analisi delle vulnerabilità** con Docker Scout (e Gordon in Docker Desktop): l'immagine
   ufficiale 2026.02.01 ha **235 CVE**, la prima versione arm64 ne aveva 121. Ogni CVE è stata
   ricondotta alla libreria da cui proviene e verificata, distinguendo quelle realmente sfruttabili
   da quelle che non lo sono in questa installazione.

4. **Immagine "hardened" della release 2026.02.01.** Stesso WAR ufficiale, 33 librerie sostituite
   con versioni corrette della stessa serie (ognuna con checksum), base Alpine: **45 CVE** (50 con
   la stampa). Verifiche fatte: le risposte delle API sono identiche byte per byte a quelle
   dell'immagine precedente e la stampa PDF produce lo stesso risultato. Durante i test è emerso un
   difetto reale (la stampa falliva perché il Java minimale di Alpine non include la libreria dei
   font), subito corretto.

5. **Controllo del progetto originale.** Il ramo di sviluppo di MapStore è già passato a Spring 7,
   Hibernate 7 e H2 2.4, cioè proprio dove stava la maggior parte delle vulnerabilità rimaste.
   Applicando lo stesso metodo a quel codice si è scesi a **5 segnalazioni**, tutte verificate
   come non sfruttabili (codice assente o rimosso dall'immagine) e documentate con un file
   [OpenVEX](vex/): risultato **0 vulnerabilità**.

6. **Migrazione del database** da H2 1.3 a H2 2.4 con gli strumenti ufficiali di H2, verificata
   tabella per tabella (stesse righe, stesse mappe, stessa quantità di dati) prima di passare
   l'installazione in uso alla nuova versione. Il procedimento è diventato `scripts/migrate-h2.sh`.

7. **Distinguere i difetti nostri da quelli di sviluppo.** Un salto della vista durante lo zoom in
   3D è stato confrontato con l'immagine ufficiale `master-dev` senza modifiche: si presenta anche
   lì, e i 790 file del frontend sono identici byte per byte. Non dipende da questa immagine.

8. **Licenze.** MapStore è BSD, ma GeoStore e il modulo di stampa sono GPL-3.0: chi distribuisce
   l'immagine deve rendere disponibile il sorgente esatto. Per questo lo snapshot di stampa è stato
   sostituito con la release `print-lib 2.5.0` (235 classi identiche), i jar di GeoStore sono
   stati ricondotti alla build esatta pubblicata da GeoSolutions, e tutti i sorgenti sono allegati
   alla [release su GitHub](https://github.com/pompeo887/mapstore-docker-arm64/releases).

## Costruire l'immagine da soli

```sh
docker build --target mapstore          -t mapstore-hardened:2026.02.01 .
docker build --target mapstore-printing -t mapstore-hardened:2026.02.01-printing .
docker build -f Dockerfile.dev          -t mapstore-hardened:dev .
# multi-architettura
docker buildx build --platform linux/amd64,linux/arm64 -f Dockerfile.dev -t <tuo-utente>/mapstore-hardened:dev --push .
```

Struttura del repository:

| Percorso | Contenuto |
|---|---|
| `Dockerfile` | release 2026.02.01 (target `mapstore` e `mapstore-printing`) |
| `Dockerfile.dev` | ramo di sviluppo di MapStore (tag `dev`) |
| `overrides/` | elenco delle librerie sostituite e relativi checksum SHA-256 |
| `vex/` | dichiarazioni OpenVEX delle segnalazioni non sfruttabili |
| `scripts/` | sostituzione dei jar, migrazione H2, download dei sorgenti GPL |
| `docker/`, `binary/` | file originali del repository MapStore (esempi e configurazione Tomcat) |

## Licenze

I file di questo repository sono rilasciati con licenza BSD 2-Clause (vedi [LICENSE](LICENSE)).
Le immagini contengono software di terze parti con le proprie licenze, tra cui componenti
GPL-3.0 (GeoStore, MapFish Print): l'elenco e i link ai sorgenti sono in [NOTICE.md](NOTICE.md).

## Crediti

Progetto di **pompeo887**, realizzato con l'assistenza di Claude (Anthropic). pompeo887 ha
guidato il lavoro, revisionato le modifiche e verificato che tutto funzionasse sulla propria
installazione, e mantiene questo repository.
MapStore è sviluppato da [GeoSolutions](https://www.geosolutionsgroup.com/).
