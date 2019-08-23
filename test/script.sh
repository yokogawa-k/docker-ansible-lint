#!/bin/sh

set -e
set -u

TEST_DIR=$(cd $(dirname $0); pwd)
ANSIBLE_LINT_VERSION=$(grep ansible-lint requirements.txt | cut -f 3 -d " ")

echo "Start test container"
docker run -itd --init --rm --name ansible-lint yokogawa/ansible-lint sleep 600

echo "Check python version"
RESULT=$(docker exec ansible-lint python -c 'import sys; print(sys.version_info.major)')
if [ "${RESULT}" -eq 3 ]; then
  :
else
  echo "**Failed python version check**"
  echo "Want: 3"
  echo "Reuslt: ${RESULT}"
  exit 1
fi

echo "Check ansible-lint version"
RESULT=$(docker exec ansible-lint ansible-lint --version)
if [ "${RESULT}" = "ansible-lint ${ANSIBLE_LINT_VERSION}" ]; then
  :
else
  echo "**Failed ansible-lint version check**"
  echo "Want: ansible-lint ${ANSIBLE_LINT_VERSION}"
  echo "Reuslt: ${RESULT}"
  exit 1
fi

echo "Check simple playbook lint"
docker cp ${TEST_DIR}/success/ ansible-lint:/work
docker exec ansible-lint sh -c 'set -o pipefail; find ./success/ -name "*.yml" | xargs -r ansible-lint -vvv --force-color'

echo "!!! The test was successful !!!"

docker stop ansible-lint
