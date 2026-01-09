FROM ubuntu:22.04 AS codiax-docker-builder

# EXTRA_PACKAGES - Space separated list with additional packages to install
ARG EXTRA_PACKAGES

# Install packages needed by yocto
RUN (\
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && apt-get -y upgrade && \
    apt-get -y -qq install \
        gawk wget git diffstat unzip texinfo \
        gcc build-essential chrpath socat cpio \
        python3 python3-pip python3-pexpect \
        xz-utils debianutils iputils-ping python3-git python3-jinja2 \
        python3-subunit zstd liblz4-tool file locales libacl1 \
)


# Install packages needed by Atlas + extras
RUN (\
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && apt-get -y upgrade && \
# Install packages for build and user selected
    apt-get -y -qq install rsync dumb-init gosu \
        nano git git-extras libncursesw5-dev tmux ${EXTRA_PACKAGES} && \
    apt-get -y autoremove && apt-get clean \
    )

# Make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Set the locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
