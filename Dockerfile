# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.24.6-bullseye AS api
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go .
COPY api/ ./api/
COPY env/ ./env/
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /usr/bin/app

FROM oven/bun:1.2.19-slim AS web

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY public/ ./public/
COPY src/ ./src/
COPY index.html vite.config.ts tsconfig.* ./
RUN bun run build:prod

FROM scratch AS app
COPY --from=api /usr/bin/app /usr/bin/
COPY --from=web /app/dist /srv/www

EXPOSE 6969
CMD ["/usr/bin/app"]
