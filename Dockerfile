ARG PLATFORM=linux/amd64
ARG PG_MAJOR=14
ARG PGVECTOR_TAG=0.8.0-pg14
ARG PGVECTORS_TAG=pg14-v0.2.0-amd64
ARG VECTORCHORD_TAG=pg14-v1.1.1
ARG BITNAMI_IMAGE=docker.io/bitnamilegacy/postgresql
ARG BITNAMI_TAG=14.18.0-debian-12-r0
FROM --platform=${PLATFORM} pgvector/pgvector:${PGVECTOR_TAG} AS pgvector
FROM --platform=${PLATFORM} tensorchord/pgvecto-rs-binary:${PGVECTORS_TAG} AS pgvectors
FROM --platform=${PLATFORM} tensorchord/vchord-scratch:${VECTORCHORD_TAG} AS vchord

FROM --platform=${PLATFORM} ${BITNAMI_IMAGE}:${BITNAMI_TAG}
ARG PG_MAJOR
COPY --from=pgvector /usr/lib/postgresql/${PG_MAJOR}/lib/vector.so /tmp/extension-lib/
COPY --from=pgvector /usr/share/postgresql/${PG_MAJOR}/extension/vector* /tmp/extension-share/
COPY --from=pgvectors /pgvecto-rs-binary-release.deb /tmp/vectors.deb
COPY --from=vchord /usr/lib/postgresql/${PG_MAJOR}/lib/vchord.so /tmp/extension-lib/
COPY --from=vchord /usr/share/postgresql/${PG_MAJOR}/extension/vchord* /tmp/extension-share/
USER root
RUN apt-get install -y --no-install-recommends /tmp/vectors.deb && \
     cp /usr/lib/postgresql/*/lib/vectors.so /tmp/extension-lib/ && \
     cp /usr/share/postgresql/*/extension/vectors* /tmp/extension-share/ && \
     cp /tmp/extension-lib/* /opt/bitnami/postgresql/lib/ && \
     cp /tmp/extension-share/* /opt/bitnami/postgresql/share/extension/ && \
     apt-get purge -y vectors-pg${PG_MAJOR} && \
     rm -rf /var/lib/apt/lists/* /tmp/extension-lib /tmp/extension-share /tmp/vectors.deb
USER 1001
ENV POSTGRESQL_EXTRA_FLAGS="-c shared_preload_libraries=vchord.so,vectors.so"
