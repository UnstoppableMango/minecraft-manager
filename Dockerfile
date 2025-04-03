# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.24.1-bullseye AS api
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go .
COPY api/ ./api/
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /usr/bin/app

FROM oven/bun:1.2.7-slim AS web

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --production --frozen-lockfile

COPY public/ ./public/
COPY src/ ./src/
RUN bun build ./public/index.html --outdir dist

FROM scratch AS app
COPY --from=api /usr/bin/app /usr/bin/
COPY --from=web /app/dist /srv/www

EXPOSE 6969
CMD [ "/usr/bin/app" ]
