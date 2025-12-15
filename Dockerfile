# syntax=docker/dockerfile:1.7
FROM python:3-alpine

ARG APK_GIT_VERSION=2.52.0-r0
ARG APK_MAKE_VERSION=4.4.1-r3
ARG APK_GCC_VERSION=15.2.0-r2
ARG APK_LIBC_DEV_VERSION=1.2.5-r21
ARG APK_OPENSSL_DEV_VERSION=3.5.4-r0
ARG APK_LIBFFI_DEV_VERSION=3.5.2-r0

COPY requirements.txt /
ENV CRYPTOGRAPHY_DONT_BUILD_RUST=1
RUN --mount=type=cache,target=/var/cache/apk \
    --mount=type=cache,target=/root/.cache/pip \
    set -eux \
 && apk update \
 && apk add git=${APK_GIT_VERSION} \
 && apk add --virtual .build-deps \
    make=${APK_MAKE_VERSION} \
    gcc=${APK_GCC_VERSION} \
    libc-dev=${APK_LIBC_DEV_VERSION} \
    openssl-dev=${APK_OPENSSL_DEV_VERSION} \
    libffi-dev=${APK_LIBFFI_DEV_VERSION} \
 && PIP_CACHE_DIR=/root/.cache/pip pip install -r requirements.txt \
 && runDeps="$( \
      scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u \
      | xargs -r apk info --installed \
      | sort -u \
    )" \
 && apk add --virtual .ansible-lint-rundeps $runDeps \
 && apk del .build-deps

ENV ANSIBLE_LOCAL_TEMP=/tmp
WORKDIR /work
CMD ["ansible-lint", "--help"]
