ARG IMAGE=registry.fedoraproject.org/fedora-minimal
FROM ${IMAGE}

# Pass in symmetric encryption passphrase from build command
ARG TOTER_PASS

WORKDIR /root

COPY . /root

# Toter: bootstrap
ENV TERM=xterm-256color
RUN ./base.sh bootstrap

# Update passphase file with PASSPHRASE ARG
RUN echo "${TOTER_PASS}" >> /root/.config/toter/passfile

# Toter: configure dotfiles
