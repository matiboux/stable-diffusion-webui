#syntax=docker/dockerfile:1.4

# This Dockerfile uses the root project folder as context.

# Dockerfile global arguments
# PYTHON_BASE valid values: base, cuda, rocm
ARG PYTHON_BASE='base'
ARG PYTHON_VERSION='3.10'
ARG CUDA_VERSION='12.1.1'
ARG ROCM_VERSION='5.6'


# --
# Upstream images

FROM python:${PYTHON_VERSION}-slim AS python_upstream
FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-runtime-ubuntu22.04 AS cuda_upstream


# --
# Python Base image

FROM python_upstream AS python_base


# --
# Python CUDA image

FROM cuda_upstream AS python_cuda

ARG PYTHON_VERSION
ARG DEBIAN_FRONTEND='noninteractive'

# Install Python
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		python${PYTHON_VERSION} \
		python3-pip \
		&& \
	# Change default python version
	ln -sf python${PYTHON_VERSION} /usr/bin/python && \
	# Clean up
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*


# --
# Python ROCm image

FROM python_upstream AS python_rocm


# --
# Base image

FROM python_${PYTHON_BASE} AS app_base

WORKDIR /app

# Install dependencies
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		wget \
		git \
		python3 \
		python3-venv \
		libgl1 \
		libglib2.0-0 \
		libtcmalloc-minimal4 \
		&& \
	# Clean up
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Install requirements
COPY --link ./requirements_versions.txt .
RUN if [ "${PYTHON_BASE}" = 'cuda' ]; then \
		pip install --no-cache-dir \
			--index-url "https://download.pytorch.org/whl/cu$(echo "${CUDA_VERSION}" | cut -d '.' -f 1,2 | tr -d '.')" \
			-r requirements_versions.txt \
		; \
	else \
		pip install --no-cache-dir \
			-r requirements_versions.txt \
		; \
	fi && \
	# Clean up
	pip cache purge && \
	rm -rf /root/.cache/pip

# Set exposed port
ARG PORT=80
ENV PORT=${PORT}

# Create user 'user' and group 'app'
RUN groupadd app && \
	useradd -lm -G app user && \
	chown -R user:app /app
USER user

# Create venv folder
RUN mkdir -p /app/venv && \
	touch /app/venv/.keep


# --
# Dev image

FROM app_base AS app_dev

# Mount source code as volume
VOLUME /app

# Expose port
EXPOSE ${PORT}

CMD [ "/bin/sh", "-c", "./webui.sh --listen --port \"${PORT}\"" ]


# --
# Prod image

FROM app_base AS app_prod

# Copy source code
COPY --link . .

# Expose port
EXPOSE ${PORT}

CMD [ "/bin/sh", "-c", "./webui.sh --listen --port \"${PORT}\"" ]
