# this base image is from the infra cloud engineering team
# TODO blocked by image scanning... we need a solution to pull in latest from dockerhub
# FROM bsc-docker-all.artifactory.bsc.bscal.com/ice/open-liberty:21.0.0.3
FROM quay.io/ohthree/open-liberty:22.0.0.4
# The version of the packaged software. The version MAY match a label or tag in the source code repository or MAY be Semantic versioning-compatible.
ARG IMG_VERSION=1.0
# The source control revision identifier for the packaged software.
ARG IMG_REVISION=0.0.1-SNAPSHOT
ARG IMG_NAME=helloworldopenshift

# See https://docs.openshift.com/container-platform/4.9/openshift_images/create-images.html#defining-image-metadata
LABEL \
  io.openshift.tags="open-liberty" \
  io.openshift.wants="open-liberty" \
  io.k8s.description="This image contains the $IMG_NAME microservice running with the Open Liberty runtime." \
  io.openshift.non-scalable="false" \
  io.openshift.min-memory="1Gi" \
  io.openshift.min-cpu="100m"

# See https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL \
  org.opencontainers.image.authors="agimei01@blueshieldca.com" \
  org.opencontainers.image.vendor="BSC" \
  org.opencontainers.image.url="https://bsc-docker-all.artifactory.bsc.bscal.com/atc/$IMG_NAME" \
  org.opencontainers.image.source="https://bitbucket.blueshieldca.com/scm/atc/$IMG_NAME" \
  org.opencontainers.image.version="$IMG_VERSION" \
  org.opencontainers.image.revision="$IMG_REVISION"

# other labels
LABEL \
  name="$IMG_NAME"

USER 0

COPY ./target/*.war /config/apps/
COPY ./src/main/liberty/config/server.xml /config/

RUN \
  chown -R 1001:0 /config && \
  chmod -R g=u /config

USER 1001

EXPOSE 9081
