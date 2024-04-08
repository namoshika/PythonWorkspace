FROM nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04

# install apt basic package
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo
RUN apt update \
    && apt install -y --no-install-recommends apt-utils language-pack-ja language-pack-ja-base git curl 2>&1 \
    && locale-gen ja_JP.UTF-8

# set locale
ENV LANGUAGE=ja_JP:ja
ENV LANG=ja_JP.UTF-8
ENV LC_TIME=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8

# install apt dev package
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt update \
    # dependencies for pyenv
    && apt install -y --no-install-recommends build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    # dependencies for opencv
    # && apt install -y --no-install-recommends python-opencv \
    # dependencies for jupyter extensions
    && apt install -y --no-install-recommends nodejs \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/*

# install fixuid
RUN USER=docker && GROUP=docker \
    && addgroup --gid 1000 $USER \
    && adduser --uid 1000 --ingroup docker --home /home/docker --disabled-password --gecos "" $GROUP \
    && curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.5/fixuid-0.5-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - \
    && chown root:root /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid \
    && mkdir -p /etc/fixuid \
    && printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

# set env for python
ENV PATH=/home/docker/.pyenv/plugins/pyenv-virtualenv/shims:/home/docker/.pyenv/shims:/home/docker/.pyenv/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# switch to non-root user
USER docker:docker

# setup dev environment
COPY --chown=docker:docker ./env /home/docker/env
RUN find /home/docker/env -type f -name '*.sh' | xargs chmod u+x && /home/docker/env/build_01.sh

# make workspace dir
RUN mkdir -p /home/docker/workspace && chown docker:docker /home/docker/workspace && chmod 766 /home/docker/workspace
WORKDIR /home/docker/workspace

# reserve operations for the start of build workspace
ARG WORK_DIR="./workspace"
COPY --chown=docker:docker ${WORK_DIR}/.python-version ${WORK_DIR}/pyproject.toml /home/docker/workspace/
RUN /home/docker/env/build_02.sh

ENTRYPOINT [ "/usr/local/bin/fixuid" ]
CMD [ "/bin/bash" ]
