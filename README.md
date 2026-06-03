# Corilus Docker Image for [ansible/ansible\-lint](https://github.com/ansible/ansible-lint)

[![Build](https://github.com/Corilus/docker-ansible-lint/actions/workflows/docker-image.yml/badge.svg?branch=master)](https://github.com/Corilus/docker-ansible-lint/actions/workflows/docker-image.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/corilus/ansible-lint?label=docker%20pulls)](https://hub.docker.com/r/corilus/ansible-lint)

## Supported tags and respective `Dockerfile` links

- [`latest` (python3/Dockerfile)][ansible-lint]

## How to use this image

#### show usage

```console
$ docker run --rm corilus/ansible-lint
```

#### example

with find

```console
$ docker run --rm -v ${PWD}:/work -w /work corilus/ansible-lint sh -c 'find . -name "*.yml" | xargs -r ansible-lint --force-color'
```

with git ls-files

```console
$ docker run --rm -v ${PWD}:/work -w /work corilus/ansible-lint sh -c 'git ls-files -z "*.yml" | xargs -r -0 ansible-lint'
```

## Maintenance

### Update pinned APK package versions

Dependabot updates `requirements.txt` (pip), but it does not update versions pinned in `apk add package=version` lines.
Use the update script to refresh `APK_*_VERSION` in `Dockerfile` from the current base image:

```console
$ ./scripts/update-apk-pins.sh
```

If you only want to preview changes:

```console
$ ./scripts/update-apk-pins.sh --dry-run
```

After updating pins, validate:

```console
$ docker build -t corilus/ansible-lint:latest . && ./test/script.sh
```

[ansible-lint]: https://github.com/Corilus/docker-ansible-lint/blob/master/Dockerfile
