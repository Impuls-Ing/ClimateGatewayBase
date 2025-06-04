#!/bin/bash
# This script will clone or update the required linux-toradex git repo given
# the required branch and commit.

REQUESTED_BRANCH=$1
REQUESTED_COMMIT=$2
REQUESTED_COMMIT_LENGTH=${#REQUESTED_COMMIT}

if [ -z "$REQUESTED_BRANCH" ] || [ -z "$REQUESTED_COMMIT" ]; then
    echo "Error: REQUESTED_BRANCH or REQUESTED_COMMIT is empty"
    echo "Usage: clone-linux-toradex.sh branch commit_hash"
    exit 1
fi

echo "Branch to check out: ${REQUESTED_BRANCH}"
echo "Commit to check out: ${REQUESTED_COMMIT}"

REPO_URL="git://git.toradex.com/linux-toradex.git"
DIR="cache/linux-toradex"

if [ -d "${DIR}" ]; then
    echo "Directory ${DIR} exists."

    pushd "${DIR}" || exit 1

    echo "Make sure repo is clean..."
    git clean -fdx
    git reset --hard
    git fetch origin "${REQUESTED_BRANCH}"
    git checkout "${REQUESTED_COMMIT}"

    CURRENT_COMMIT=$(git rev-parse HEAD | cut -c1-"$REQUESTED_COMMIT_LENGTH")
    echo "Current commit hash: ${CURRENT_COMMIT} | Wanted hash: ${REQUESTED_COMMIT}"

    if [ "${CURRENT_COMMIT}" = "${REQUESTED_COMMIT}" ]; then
        echo "Commit hash is correct."
    else
        echo "Commit hash is not correct. Trying to get the right commit..."
        git checkout "${REQUESTED_COMMIT}"
        if [ "${CURRENT_COMMIT}" = "${REQUESTED_COMMIT}" ]; then
            echo "Commit hash is correct after retry."
        else
            echo "Commit hash still incorrect. Exiting."
            exit 1
        fi
    fi

    popd || exit 1
else
    echo "Cloning branch ${REQUESTED_BRANCH} and checking out commit ${REQUESTED_COMMIT}"
    git clone --branch "${REQUESTED_BRANCH}" "${REPO_URL}" "${DIR}"
    pushd "${DIR}" || exit 1
    git checkout "${REQUESTED_COMMIT}"
    popd || exit 1
fi
