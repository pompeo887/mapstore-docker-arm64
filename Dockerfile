# MapStore "hardened": stesso WAR ufficiale della release GitHub, con le
# librerie vulnerabili sostituite da versioni corrette compatibili e una base
# minimale (Alpine + OpenJDK 17 JRE + Tomcat 9). Multi-architettura (amd64, arm64).
#
# Target:
#   mapstore           -> come l'immagine ufficiale geosolutionsit/mapstore2 (senza stampa)
#   mapstore-printing  -> con il modulo di stampa MapFish Print (mapstore-printing.zip)
#
# Build:
#   docker build --target mapstore          -t mapstore-hardened:2026.02.01 .
#   docker build --target mapstore-printing -t mapstore-printing-hardened:2026.02.01 .

ARG MAPSTORE_VERSION=2026.02.01
ARG MAPSTORE_WAR_SHA256=3d4e2ce88fafdbdfc134c87b1fd7e706fe4c83d98420953bf6b04e6591dbd6e6
ARG MAPSTORE_PRINTING_SHA256=e8d5fb40057c492c54ac290e00e42002a34e61edf988662689c8d79e76c0baba
ARG TOMCAT_VERSION=9.0.122
ARG TOMCAT_SHA512=1f2f7d822a407999d954e7eb4fb1e78998c2a9372bb466d27e8cefd2521ef779183744f39dfa50a77ce3b798e7fe30bf2fd43fd1d6a2e6135617af1ddda6ba2a

# ---------------------------------------------------------------- sorgenti
FROM --platform=$BUILDPLATFORM alpine:3.23 AS fetch
RUN apk add --no-cache curl unzip zip
ARG MAPSTORE_VERSION MAPSTORE_WAR_SHA256 MAPSTORE_PRINTING_SHA256 TOMCAT_VERSION TOMCAT_SHA512
WORKDIR /build
RUN set -eux; \
    base="https://github.com/geosolutions-it/MapStore2/releases/download/v${MAPSTORE_VERSION}"; \
    curl -fsSL "$base/mapstore.war" -o mapstore.war; \
    echo "${MAPSTORE_WAR_SHA256}  mapstore.war" | sha256sum -c -; \
    curl -fsSL "$base/mapstore-printing.zip" -o mapstore-printing.zip; \
    echo "${MAPSTORE_PRINTING_SHA256}  mapstore-printing.zip" | sha256sum -c -; \
    curl -fsSL "https://archive.apache.org/dist/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" -o tomcat.tar.gz; \
    echo "${TOMCAT_SHA512}  tomcat.tar.gz" | sha512sum -c -; \
    mkdir tomcat && tar -xzf tomcat.tar.gz -C tomcat --strip-components=1; \
    rm -rf tomcat/webapps/* tomcat/bin/*.bat tomcat/bin/*.tar.gz tomcat/temp/*; \
    mkdir mapstore && unzip -q mapstore.war -d mapstore

COPY overrides/ /build/overrides/
COPY scripts/apply-overrides.sh /usr/local/bin/apply-overrides

# ehcache-2.10.6 incorpora un classpath REST opzionale (con Jackson 2.9.6) mai usato da MapStore
RUN set -eux; \
    zip -q -d mapstore/WEB-INF/lib/ehcache-2.10.6.jar 'rest-management-private-classpath/*'; \
    apply-overrides overrides/base.list mapstore/WEB-INF/lib overrides/checksums.sha256

# Variante con stampa: il modulo ufficiale sovrapposto al WAR, poi le sue sostituzioni
RUN set -eux; \
    cp -a mapstore mapstore-printing; \
    unzip -q -o mapstore-printing.zip -d mapstore-printing; \
    apply-overrides overrides/printing.list mapstore-printing/WEB-INF/lib overrides/checksums.sha256

# ---------------------------------------------------------------- runtime comune
FROM alpine:3.23 AS runtime
ARG UID=20000
ARG GID=20000
ARG UNAME=mapstore
ENV CATALINA_HOME=/usr/local/tomcat \
    CATALINA_BASE=/usr/local/tomcat \
    MAPSTORE_WEBAPP_DST=/usr/local/tomcat/webapps \
    GEOSTORE_OVR_OPT="" \
    JAVA_OPTS=" -Xms512m -Xmx512m -Ddatadir.location=/usr/local/tomcat/datadir" \
    TERM=xterm \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk \
    PATH=/usr/local/tomcat/bin:$PATH

# Java 17 (come l'immagine ufficiale) dai pacchetti Alpine, disponibili per amd64 e arm64.
# bash + psql servono a wait-for-postgres.sh (come nell'immagine ufficiale).
RUN apk upgrade --no-cache \
 && apk add --no-cache openjdk17-jre-headless bash postgresql17-client \
 && addgroup -g $GID $UNAME \
 && adduser -D -u $UID -G $UNAME $UNAME

COPY --from=fetch /build/tomcat /usr/local/tomcat
COPY binary/tomcat/conf/server.xml /usr/local/tomcat/conf/server.xml
COPY docker/ /usr/local/tomcat/docker/
RUN cp /usr/local/tomcat/docker/wait-for-postgres.sh /usr/bin/wait-for-postgres \
 && mkdir -p /usr/local/tomcat/datadir \
 && chown -R $UID:$GID /usr/local/tomcat

WORKDIR /usr/local/tomcat
VOLUME ["/usr/local/tomcat/datadir"]
EXPOSE 8080
CMD ["catalina.sh", "run"]

# ---------------------------------------------------------------- target finali
FROM runtime AS mapstore-printing
# La stampa disegna mappe e testi con Java2D: serve libfontmanager, che su Alpine
# e' nel pacchetto openjdk17-jre (non nella variante headless), piu' i font.
USER root
RUN apk add --no-cache openjdk17-jre fontconfig ttf-dejavu
COPY --from=fetch --chown=20000:20000 /build/mapstore-printing /usr/local/tomcat/webapps/mapstore
USER 20000

FROM runtime AS mapstore
COPY --from=fetch --chown=20000:20000 /build/mapstore /usr/local/tomcat/webapps/mapstore
USER 20000
