FROM alpine:3.16

ARG APP_VERSION=latest

LABEL org.opencontainers.image.title="check_certificates"
LABEL org.opencontainers.image.description="Monitor your HTTPS SSL Certificate's expiration"
LABEL org.opencontainers.image.authors="Pavel Kim <hello@pavelkim.com>"
LABEL org.opencontainers.image.url="https://github.com/pavelkim/check_certificates"
LABEL org.opencontainers.image.version="${APP_VERSION}"

ENV DEFAULT_CONFIG_DIR=/etc/check_certificates
ENV DEFAULT_CONFIG_FILE_PATH="${DEFAULT_CONFIG_DIR}/.config"
ENV DEFAULT_HTDOCS_DIR=/htdocs
ENV DEFAULT_METRICS_FILE_PATH="${DEFAULT_HTDOCS_DIR}/metrics"
ENV DEFAULT_CHECK_CERTIFICATES_PATH="/check_certificates.sh"
ENV DEFAULT_WRAPPER_LOOP_PATH="/wrapper_loop.sh"

ARG CHECK_INTERVAL=0
ARG CHECK_CERTIFICATES_PATH="${DEFAULT_CHECK_CERTIFICATES_PATH}"
ARG GLOBAL_LOGLEVEL=1

RUN mkdir -pv "${DEFAULT_CONFIG_DIR}" && \
    mkdir -pv "${DEFAULT_HTDOCS_DIR}" && \
    echo "PROMETHEUS_EXPORT_FILENAME=${DEFAULT_METRICS_FILE_PATH}" > "${DEFAULT_CONFIG_FILE_PATH}" && \
    touch "${DEFAULT_METRICS_FILE_PATH}"

RUN apk --no-cache --update add bash curl openssl coreutils util-linux

ADD "${APP_FILENAME}" "${DEFAULT_CHECK_CERTIFICATES_PATH}"
ADD "${APP_WRAPPER_FILENAME}" "${DEFAULT_WRAPPER_LOOP_PATH}"
RUN chmod a+x "${DEFAULT_CHECK_CERTIFICATES_PATH}" "${DEFAULT_WRAPPER_LOOP_PATH}"

VOLUME ["/etc/check_certificates", "/htdocs"]

WORKDIR "${DEFAULT_CONFIG_DIR}"
ENTRYPOINT ["bash", "/wrapper_loop.sh"]
