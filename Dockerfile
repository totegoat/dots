FROM ubuntu:latest

# passed in from build command
# ARG DEVENV_PASS

WORKDIR /root

COPY . /root

# bootstrap
# RUN cd dev/devenv && ./bootstrap.sh no-sudo 

# locales
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
RUN apt-get update && apt-get install -y locales && locale-gen en_US.UTF-8

# passphrase file
# RUN echo "${DEVENV_PASS}" >> .devenv_pass

# sync dotfiles and config
# RUN cd dev/devenv && ./devenv.sh sync no-sudo 
