
# bump: opencoreamr /OPENCOREAMR_VERSION=([\d.]+)/ fetch:https://sourceforge.net/projects/opencore-amr/files/opencore-amr/|/opencore-amr-([\d.]+).tar.gz/
# bump: opencoreamr after ./hashupdate Dockerfile OPENCOREAMR $LATEST
# bump: opencoreamr link "ChangeLog" https://sourceforge.net/p/opencore-amr/code/ci/master/tree/ChangeLog
ARG OPENCOREAMR_VERSION=0.1.6
ARG OPENCOREAMR_URL="https://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-$OPENCOREAMR_VERSION.tar.gz"
ARG OPENCOREAMR_SHA256=483eb4061088e2b34b358e47540b5d495a96cd468e361050fae615b1809dc4a1

# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.16.2 AS base

FROM base AS download
ARG OPENCOREAMR_URL
ARG OPENCOREAMR_SHA256
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503 -nv"
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    coreutils wget tar && \
  wget $WGET_OPTS -O opencoreamr.tar.gz "$OPENCOREAMR_URL" && \
  echo "$OPENCOREAMR_SHA256  opencoreamr.tar.gz" | sha256sum --status -c - && \
  mkdir opencoreamr && \
  tar xf opencoreamr.tar.gz -C opencoreamr --strip-components=1 && \
  rm opencoreamr.tar.gz && \
  apk del download

FROM base AS build 
COPY --from=download /tmp/opencoreamr/ /tmp/opencoreamr/
WORKDIR /tmp/opencoreamr
RUN \
  apk add --no-cache --virtual build \
    build-base && \
  ./configure --enable-static --disable-shared && \
  make -j$(nproc) install && \
  apk del build

FROM scratch
ARG OPENCOREAMR_VERSION
COPY --from=build /usr/local/lib/libopencore-amr* /usr/local/lib/
COPY --from=build /usr/local/lib/pkgconfig/opencore-amr* /usr/local/lib/pkgconfig/
COPY --from=build /usr/local/include/opencore-amrnb/ /usr/local/include/opencore-amrnb/
COPY --from=build /usr/local/include/opencore-amrwb/ /usr/local/include/opencore-amrwb/
