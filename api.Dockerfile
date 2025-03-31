# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.24.1-bullseye AS build
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /usr/bin/api

FROM scratch AS release
COPY --from=build /usr/bin/api /usr/bin/api

EXPOSE 6969/tcp
CMD [ "/usr/bin/api" ]
