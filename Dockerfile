ARG IMAGE=registry.fedoraproject.org/fedora-minimal
FROM ${IMAGE}

# Pass in symmetric encryption passphrase from build command
ARG DOTS_PASS

WORKDIR /root

COPY . /root

# Dots: bootstrap
ENV TERM=xterm-256color
RUN ./dots bootstrap

# Update passphase file with PASSPHRASE ARG
RUN echo "${DOTS_PASS}" >> /root/.config/dots/passfile

# Dots: install dotfiles
