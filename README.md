# Docker Image for [willthames/ansible-lint](https://github.com/willthames/ansible-lint)

[![CircleCI](https://circleci.com/gh/yokogawa-k/docker-ansible-lint/tree/master.svg?style=svg)](https://circleci.com/gh/yokogawa-k/docker-ansible-lint/tree/master)

## Usage

#### show usage

```console
$ docker run --rm yokogawa/ansible-lint
```

#### exsample

with find
```console
$ docker run --rm -v ${PWD}:/work -w /work yokogawa/ansible-lint sh -c 'find . -name "*.yml" | xargs -r ansible-lint --force-color
```

with git ls-files
```console
$ docker run --rm -v ${PWD}:/work -w /work yokogawa/ansible-lint sh -c 'git ls-files -z "*.yml" | xargs -r -0 ansible-lint'
```

