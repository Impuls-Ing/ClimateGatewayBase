#!/bin/bash

# This script will parse the required linux-toradex branch 
# and clone it into the linux-toradex folder. We do it this way because 
# git submodule add with a specific branch and depth=1 isn't working...

RELEASE_VERSION=13
URL="https://artifacts.toradex.com:443/artifactory/torizoncore-oe-prod-frankfurt/scarthgap-7.x.y/release/${RELEASE_VERSION}/verdin-am62/torizon/torizon-docker/oedeploy/.kernel_scmbranch"

BRANCH=$(curl -s "$URL")
echo "Kernel SCM Branch: ${BRANCH}"

REPO_URL="git://git.toradex.com/linux-toradex.git"
DIR="cache/linux-toradex"

if [ -d "${DIR}" ]; then
    echo "Directory ${DIR} exists."

    cd "${DIR}" || exit 1

    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    echo "Current branch: ${CURRENT_BRANCH} | Wanted branch: ${BRANCH}"

    echo "Make sure repo is clean..."
    git clean -fdx
    git reset --hard

    if [ "${CURRENT_BRANCH}" = "${BRANCH}" ]; then
        echo "Branch is correct. Checking if up to date..."

        git fetch origin "${BRANCH}"
        LOCAL_HASH=$(git rev-parse HEAD)
        REMOTE_HASH=$(git rev-parse origin/"${BRANCH}")

        if [ "${LOCAL_HASH}" = "${REMOTE_HASH}" ]; then
            echo "Branch is up to date."
        else
            echo "Branch is outdated. Pulling latest changes..."
            git pull --ff-only
        fi
    else
        echo "Branch mismatch. Checking out correct branch..."
        git fetch origin "${BRANCH}"
        git checkout "${BRANCH}"
        git pull --ff-only
    fi

    cd ..
else
    echo "Cloning branch ${BRANCH} with depth=1"
    git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${DIR}"
fi
