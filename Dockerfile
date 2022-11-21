FROM alpine:3.16

ARG APP_BASE_URL=https://pavelkim.github.io/dist/check_certificates
ARG APP_FILENAME=check_certificates.sh
ARG APP_VERSION=latest

LABEL org.opencontainers.image.title="check_certificates"
LABEL org.opencontainers.image.description="Monitor your HTTPS SSL Certificate's expiration"
LABEL org.opencontainers.image.authors="Pavel Kim <hello@pavelkim.com>"
LABEL org.opencontainers.image.url="https://github.com/pavelkim/check_certificates"
LABEL org.opencontainers.image.version="${APP_VERSION}"

ARG DEFAULT_CONFIG_DIR=/etc/check_certificates/
ARG DEFAULT_CONFIG_FILE_PATH="${DEFAULT_CONFIG_DIR}/.config"
ARG DEFAULT_HTDOCS_DIR=/htdocs
ARG DEFAULT_METRICS_FILE_PATH="${DEFAULT_HTDOCS_DIR}/metrics"

RUN mkdir -pv "${DEFAULT_CONFIG_DIR}" && \
    mkdir -pv "${DEFAULT_HTDOCS_DIR}" && \
    echo "PROMETHEUS_EXPORT_FILENAME=${DEFAULT_METRICS_FILE_PATH}" > "${DEFAULT_CONFIG_FILE_PATH}" && \
    touch "${DEFAULT_METRICS_FILE_PATH}"

RUN apk --no-cache --update add bash curl openssl coreutils util-linux

ADD "${APP_FILENAME}" /check_certificates.sh

VOLUME ["/etc/check_certificates", "/htdocs"]

WORKDIR "${DEFAULT_CONFIG_DIR}"
ENTRYPOINT ["bash", "/check_certificates.sh"]
