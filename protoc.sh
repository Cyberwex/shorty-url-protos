#!/bin/bash

SERVICE_NAME=$1
RELEASE_VERSION=$2
SERVICE_NAME_HYPHEN=${SERVICE_NAME//_/-}

#Generate the GO files from the proto files

PROTO_PATH="./proto/${SERVICE_NAME}"
GO_OUT_PATH="./golang/${SERVICE_NAME}"

if ! protoc -I${PROTO_PATH} ${PROTO_PATH}/*.proto \
    --go_out=${GO_OUT_PATH} \
    --go_opt=paths=source_relative \
    --go-grpc_out=${GO_OUT_PATH} \
    --go-grpc_opt=paths=source_relative; then
  echo "Error generating Go files for ${SERVICE_NAME}"
  exit 1
fi


# Check for changes
if  git diff-index --quiet HEAD --; then
    echo "No changes detected in ${SERVICE_NAME} proto files."
    exit 1
fi

# Add changes to git
if ! git add . || ! git commit -am "proto update"; then
  echo "Failed to create commit for ${SERVICE_NAME}"
  exit 1
fi

# Push changes to the repository
if ! git push origin HEAD:main; then
    echo "Error pushing changes for ${SERVICE_NAME}"
    exit 1
fi

# Creaate and push a tag
if git show-ref --tags | grep -q "refs/tags/${SERVICE_NAME_HYPHEN}/${RELEASE_VERSION}$"; then
    echo "Tag ${SERVICE_NAME_HYPHEN}-${RELEASE_VERSION} already exists."
else
    if ! git tag -a "${SERVICE_NAME_HYPHEN}-${RELEASE_VERSION}" -m "Release ${SERVICE_NAME_HYPHEN} version ${RELEASE_VERSION}"; then
        echo "Failed to create tag for ${SERVICE_NAME}"
        exit 1
    fi

    if ! git push origin "${SERVICE_NAME_HYPHEN}-${RELEASE_VERSION}"; then
        echo "Failed to push tag for ${SERVICE_NAME}"
        exit 1
    fi
fi

echo "Successfully generated and pushed proto files for ${SERVICE_NAME} with tag ${SERVICE_NAME_HYPHEN}-${RELEASE_VERSION}"

# ./protoc.sh shorty v0.1.0