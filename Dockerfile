#syntax=docker/dockerfile:1.4

# This Dockerfile uses the root project folder as context.

# --
# Upstream images

FROM python:3.10-slim AS python_upstream


# --
# Base image

FROM python_upstream AS app_base

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
RUN pip install --no-cache-dir \
		-r requirements_versions.txt \
		&& \
	# Clean up
	pip cache purge && \
	rm -rf /root/.cache/pip

# Set exposed port
ARG PORT=80
ENV PORT=${PORT}

# Create user 'user' and group 'app'
RUN groupadd app && \
	useradd -lMN -G app -d /app user && \
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

CMD [ "sh", "-c", "./webui.sh --listen --port \"${PORT}\"" ]


# --
# Prod image

FROM app_base AS app_prod

# Copy source code
COPY --link . .

# Expose port
EXPOSE ${PORT}

CMD [ "sh", "-c", "./webui.sh --listen --port \"${PORT}\"" ]
