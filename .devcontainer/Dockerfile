# https://github.com/devcontainers/images/tree/main/src/python

ARG VARIANT="3.10-bullseye"
FROM mcr.microsoft.com/devcontainers/python:${VARIANT}

# [Optional] Uncomment this section to install additional OS packages.
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends httpie s3fs fio
