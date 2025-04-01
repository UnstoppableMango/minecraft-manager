# syntax=docker/dockerfile:1
FROM golang:1.24.1-bullseye AS api

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go .
COPY api/ ./api/
RUN go build -o /usr/bin/app ./

FROM oven/bun:1.2.7-slim AS web

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --production --frozen-lockfile

COPY public/ ./
RUN bun build ./index.html --outdir dist

FROM scratch AS app
COPY --from=api /usr/bin/app /usr/bin/
COPY --from=web /app/dist /srv/www

CMD [ "/usr/bin/app" ]
