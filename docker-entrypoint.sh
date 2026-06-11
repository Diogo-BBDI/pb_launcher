#!/bin/sh
set -eu

cat > /app/config.yml <<EOF
# Generated at container startup. Configure these values with environment variables.
domain: ${APP_DOMAIN}
bind_address: ${BIND_ADDRESS}
listen_address: ${LISTEN_ADDRESS}
http_port: "${HTTP_PORT}"
https: ${HTTPS}
https_port: "${HTTPS_PORT}"
disable_https_redirect: ${DISABLE_HTTPS_REDIRECT}
download_dir: ${DOWNLOAD_DIR}
certificates_dir: ${CERTIFICATES_DIR}
accounts_dir: ${ACCOUNTS_DIR}
data_dir: ${DATA_DIR}
acme_email: "${ACME_EMAIL}"
min_certificate_ttl: 720h
max_domain_cert_attempts: 1
cert_request_planner_interval: 5m
cert_request_executor_interval: 1m
certificate_check_interval: 1m
release_sync_interval: 5m
command_check_interval: 10s
EOF

exec pblauncher -c /app/config.yml
