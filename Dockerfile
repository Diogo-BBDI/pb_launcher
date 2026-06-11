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
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

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

CMD ["docker-entrypoint.sh"]
