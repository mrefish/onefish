# syntax=docker/dockerfile:1
#############################################
FROM python:3.9.17-slim-bullseye AS base

# Setup environment variables
ENV APP_ROOT="/app"
ENV LOCAL_BIN_PATH="/root/.local/bin"
ENV PYTHONPATH='.'
ENV VIRTUAL_ENV="${APP_ROOT}/.venv"

# Setup $PATH
ENV PATH="${LOCAL_BIN_PATH}:${PATH}"
ENV PATH="${VIRTUAL_ENV}/bin:${APP_ROOT}:${PATH}"

RUN mkdir ${APP_ROOT}
WORKDIR ${APP_ROOT}

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ca-certificates \
    curl \
    git \
    tree \
    vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 -

COPY . /app

#############################################
FROM base as installed

RUN poetry install

#############################################
FROM installed as broken
RUN poetry add git+https://github.com/mrefish/nofish.git
