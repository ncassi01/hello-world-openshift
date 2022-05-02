FROM registry.access.redhat.com/ubi8/openjdk-8:latest as builder

USER 0

WORKDIR /tmp/app

COPY src/ src/
COPY pom.xml pom.xml
COPY .m2 .m2

RUN mvn -q -s .m2/settings.xml \
        -Dsettings.security=.m2/settings-security.xml \
        -Dmaven.wagon.http.ssl.insecure=true \
        -Dmaven.wagon.http.ssl.allowall=true \
        -Dmaven.wagon.http.ssl.ignore.validity.dates=true \
        clean package

FROM bsc-docker-all.artifactory.bsc.bscal.com/ice/open-liberty:21.0.0.3

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

COPY --from=builder /tmp/app/target/*.war /config/dropins/
COPY --from=builder /tmp/app/src/main/liberty/config/server.xml /config/

RUN  \
  chown -R 1001:0 /config && \
  chmod -R g=u /config

USER 1001

EXPOSE 9081
