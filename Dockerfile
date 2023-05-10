ARG IMAGE=registry.fedoraproject.org/fedora-minimal
FROM ${IMAGE}

# Pass in build command arguments
ARG DOTFILES_URL
ARG DOTS_PASS

WORKDIR /root

COPY . /root

# Dots: bootstrap
ENV TERM=xterm-256color
RUN ./dots bootstrap

# Dots: add dots "executable" to PATH
RUN echo "PATH=\"\$HOME/.local/bin:\$PATH\"" >> ~/.bashrc

# Dots: Update passphrase file with PASSPHRASE ARG, if passed in
RUN echo "${DOTS_PASS}" >> /root/.config/dots/passfile

# Dots: setup dotfiles and install Dotsfile configuration
RUN ./dots setup ${DOTFILES_URL}
