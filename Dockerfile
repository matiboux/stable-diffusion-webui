#syntax=docker/dockerfile:1.4

# Versions
FROM python:3.10-slim AS python_upstream


# --
# App image
FROM python_upstream AS app_prod

WORKDIR /app

# Install dependencies
RUN apt-get update && \
	apt-get install -y --no-install-recommends \
		wget \
		git \
		python3 python3-venv \
		libgl1 \
		libglib2.0-0 \
		libtcmalloc-minimal4 \
		&& \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

# Switch to non-root user
RUN useradd -m app && \
	chown -R app:app /app
USER app

# Create venv folder
RUN mkdir -p /app/venv && \
	touch /app/venv/.keep

# Run app
CMD [ "./webui.sh" ]
