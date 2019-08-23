# Docker Image for [ansible/ansible\-lint](https://github.com/ansible/ansible-lint)

[![CircleCI](https://circleci.com/gh/yokogawa-k/docker-ansible-lint/tree/master.svg?style=svg)](https://circleci.com/gh/yokogawa-k/docker-ansible-lint/tree/master)
[![](https://images.microbadger.com/badges/image/yokogawa/ansible-lint.svg)](https://microbadger.com/images/yokogawa/ansible-lint "Get your own image badge on microbadger.com")

## Supported tags and respective `Dockerfile` links

- [`latest` (python3/Dockerfile)][ansible-lint]

## How to use this image

#### show usage

```console
$ docker run --rm yokogawa/ansible-lint
```

#### example

with find
```console
$ docker run --rm -v ${PWD}:/work -w /work yokogawa/ansible-lint sh -c 'find . -name "*.yml" | xargs -r ansible-lint --force-color'
```

with git ls-files
```console
$ docker run --rm -v ${PWD}:/work -w /work yokogawa/ansible-lint sh -c 'git ls-files -z "*.yml" | xargs -r -0 ansible-lint'
```

[ansible-lint]: https://github.com/yokogawa-k/docker-ansible-lint/blob/master/Dockerfile
