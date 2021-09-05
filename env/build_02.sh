#!/bin/bash

# enable pyenv
. /home/docker/env/init.sh

# install python
pyenv update
pyenv install

# install base package
pip install -U pip setuptools certifi poetry

# install user packages
poetry install --no-root