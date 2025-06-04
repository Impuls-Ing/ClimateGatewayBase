#!/bin/bash
# This script will build a TorizonCore base image for ClimateGateway

set -e

# NOTE: this does not work for zsh
urldecode() {
    local url="${1//+/ }"
    printf '%b' "${url//%/\\x}"
}

# Search for base image on https://artifacts.toradex.com
ARTIFACTS_OEDEPLOY="https://artifacts.toradex.com:443/artifactory/torizoncore-oe-prerelease-frankfurt/scarthgap-7.x.y/monthly/8/verdin-am62/torizon/torizon-docker/oedeploy/"
BASE_IMAGE_URL="${ARTIFACTS_OEDEPLOY}torizon-docker-verdin-am62-Tezi_7.3.0-devel-202505%2Bbuild.8.tar"
ARTIFACTS_KERNEL_COMMIT_URL="${ARTIFACTS_OEDEPLOY}.kernel_scmversion"
ARTIFACTS_KERNEL_BRANCH_URL="${ARTIFACTS_OEDEPLOY}.kernel_scmbranch"
ARTIFACTS_KERNEL_COMMIT=$(curl -s $ARTIFACTS_KERNEL_COMMIT_URL)
ARTIFACTS_KERNEL_BRANCH=$(curl -s $ARTIFACTS_KERNEL_BRANCH_URL)

CACHE="cache"

BASE_IMAGE_NAME=$(basename "$BASE_IMAGE_URL")
BASE_IMAGE_NAME=$(urldecode "$BASE_IMAGE_NAME")
BASE_IMAGE_VERSION=$(echo "$BASE_IMAGE_NAME" | grep -Po "(?<=torizon-docker-verdin-am62-Tezi_).+(?=\.tar)")
OSTREE_REFERENCE="ClimateGatewayBase"
OUTPUT_IMAGE="${OSTREE_REFERENCE}_${BASE_IMAGE_VERSION}"

DOCKER_VOLUME_NAME="storage_${BASE_IMAGE_NAME//[^a-zA-Z0-9]/_}"
TCB_VERSION="3.12.0"

KERNEL_DIR="cache/linux-toradex"

echo ""
echo "######## TorizonCore Builder Command that is being used: #################"
echo "alias torizoncore-builder=\"docker run --rm -v /deploy -v $(pwd):/workdir -v ${DOCKER_VOLUME_NAME}:/storage --network=host torizon/torizoncore-builder:${TCB_VERSION}\""
echo ""
torizoncore-builder() {
    docker run --rm -v /deploy -v "$(pwd)":/workdir -v "${DOCKER_VOLUME_NAME}:/storage" --network=host "torizon/torizoncore-builder:${TCB_VERSION}" "$@"
}

if [ -d "$OUTPUT_IMAGE" ]; then
    echo "Output image already present, rebuild? [y/n]"
    read -r answer
    if [ "$answer" != "y" ]; then
        echo "Aborted."
        exit 1
    else
        rm -rf "$OUTPUT_IMAGE"
    fi
fi

./clone-linux-toradex.sh "$ARTIFACTS_KERNEL_BRANCH" "$ARTIFACTS_KERNEL_COMMIT" || exit 1

if [ ! -d "$CACHE" ]; then
    mkdir $CACHE
fi

if [ ! -f "${CACHE}/${BASE_IMAGE_NAME}" ]; then
    wget -P "$CACHE" "$BASE_IMAGE_URL"
fi

docker volume rm "$DOCKER_VOLUME_NAME" > /dev/null 2>&1 || true
torizoncore-builder images unpack "${CACHE}/${BASE_IMAGE_NAME}"

torizoncore-builder dt apply \
    --include-dir "$KERNEL_DIR/arch/arm64/boot/dts/ti/" \
    --include-dir "$KERNEL_DIR/include/" \
    "$KERNEL_DIR/arch/arm64/boot/dts/ti/k3-am625-verdin-nonwifi-ivy.dts"

torizoncore-builder union "$OSTREE_REFERENCE" \
    --changes-directory rootfs-overlay/tailscale/

torizoncore-builder deploy \
    --output-directory "$OUTPUT_IMAGE" \
    --image-name "ClimateGatewayBase" \
    --image-description "Base image for ClimateGateway booting with Ivy device-tree" \
    --image-accept-licence \
    --image-autoreboot \
    "$OSTREE_REFERENCE"

# Save variables for GitHub workflows
GITHUB_ENV=${GITHUB_ENV:-""}
if [ -n "$GITHUB_ENV" ]; then
    {  echo "OUTPUT_IMAGE=${OUTPUT_IMAGE}";
       echo "OSTREE_REFERENCE=${OSTREE_REFERENCE}";
    } >> "$GITHUB_ENV"
fi
