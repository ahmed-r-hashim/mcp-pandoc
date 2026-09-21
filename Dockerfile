### ---- Base stage: OS-level deps shared by builder and runtime ---- ###
# NOTE: pydantic-core has no prebuilt musl wheel for Python 3.14 yet (and its
# pinned PyO3 version doesn't even support 3.14), so we stay on 3.13 to get
# prebuilt wheels instead of compiling from source.
FROM valkama.saunalahti.fi/image/python:3.13-alpine AS base

# System dependencies: pandoc (conversion engine) and TeX Live's xelatex
# engine (required for PDF output). See CLAUDE.md "Dependency Management".
# texmf-dist-latexrecommended provides xcolor.sty and other packages pandoc's
# default PDF template requires; texlive-xetex alone does not pull it in.
# Installed once here so both the builder and runtime stages inherit the same
# pinned set of packages instead of the runtime stage re-resolving them.
RUN apk add --no-cache \
    pandoc \
    texlive-xetex \
    texmf-dist-latexrecommended \
    ttf-freefont

# Create a non-root user up front. WORKDIR creates /app as root before any
# COPY runs, so chown it in the same RUN as user creation - a --chown on a
# later COPY only affects the copied contents, not a pre-existing directory.
RUN addgroup -g 1001 app \
    && adduser -D -u 1001 -G app app \
    && mkdir -p /app \
    && chown app:app /app

WORKDIR /app

### ---- Builder stage: install deps into a venv using uv ---- ###
FROM base AS builder

# Install uv for locked dependency installation
RUN pip install --no-cache-dir uv

# Use a cache dir outside /app so it never ends up owned by root inside the app tree
ENV UV_CACHE_DIR=/tmp/uv-cache \
    UV_PROJECT_ENVIRONMENT=/app/.venv

# Copy project files
COPY pyproject.toml uv.lock ./
COPY src ./src
COPY LICENSE README.md CONTRIBUTING.md ./

# Install dependencies using the lock file for reproducible builds
RUN uv sync --frozen --no-dev

### ---- Runtime stage: base image (pandoc/TeX already installed) + compiled app ---- ###
FROM base AS runtime

COPY --from=builder --chown=app:app /app /app

ENV PATH="/app/.venv/bin:$PATH" \
    UV_CACHE_DIR=/tmp/uv-cache

# Default command to start the MCP server
EXPOSE 8055
USER app
CMD ["mcp-pandoc"]
