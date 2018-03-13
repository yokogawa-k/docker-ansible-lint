FROM python:2.7-alpine
# ansible-lint use `except foo, e` syntax...

ENV VERSION 3.4.21
RUN apk add --no-cache git \
 && apk add --no-cache --virtual .build-deps \
    make \
    gcc \
    libc-dev \
    openssl-dev \
    python-dev \
    libffi-dev \
 && pip install ansible-lint==${VERSION} \
 && runDeps="$( \
      scanelf --needed --nobanner --recursive /usr/local \
      | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
      | sort -u \
      | xargs -r apk info --installed \
      | sort -u \
    )" \
 && apk add --no-cache --virtual .ansible-lint-rundeps $runDeps \
 && apk del .build-deps \
 && rm -rf ~/.cache/

ENV ANSIBLE_LOCAL_TEMP /tmp
WORKDIR /work
CMD ["ansible-lint", "--help"]

