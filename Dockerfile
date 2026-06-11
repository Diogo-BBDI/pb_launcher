# syntax=docker/dockerfile:1

FROM node:22-alpine AS ui-builder
WORKDIR /src/ui
COPY ui/package*.json ./
RUN npm ci
COPY ui/ ./
RUN npm run build-embed

FROM golang:1.24.5-alpine AS go-builder
WORKDIR /src
RUN apk add --no-cache git ca-certificates
COPY go.mod go.sum ./
RUN go mod download
COPY . ./
COPY --from=ui-builder /src/ui/dist ./ui/dist
ARG COMMIT=none
ARG TARGETOS=linux
ARG TARGETARCH=amd64
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build \
    -ldflags "-s -w -X main.commit=${COMMIT}" \
    -o /out/pblauncher *.go

FROM alpine:3.22
WORKDIR /app
RUN apk add --no-cache ca-certificates tzdata
COPY --from=go-builder /out/pblauncher /usr/local/bin/pblauncher

ENV TZ=UTC \
    APP_DOMAIN=pb.example.com \
    LISTEN_ADDRESS=0.0.0.0 \
    HTTP_PORT=7080 \
    HTTPS=false \
    HTTPS_PORT=8443 \
    DISABLE_HTTPS_REDIRECT=true \
    BIND_ADDRESS=127.0.0.1 \
    DOWNLOAD_DIR=/app/downloads \
    CERTIFICATES_DIR=/app/.certificates \
    ACCOUNTS_DIR=/app/.accounts \
    DATA_DIR=/app/data \
    ACME_EMAIL=

EXPOSE 7080 8443
VOLUME ["/app/pb_data", "/app/data", "/app/downloads", "/app/.certificates", "/app/.accounts"]

CMD sh -ec 'cat > /app/config.yml <<EOF
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
exec pblauncher -c /app/config.yml'
