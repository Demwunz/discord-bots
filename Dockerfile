# Dockerfile for Elixir umbrella project
# Supports multiple apps via APP_NAME build arg
#
# Usage:
#   Local:  docker build --build-arg APP_NAME=raffle_bot -t my-bot .
#   Fly.io: Configured via fly.toml [build] section

# Builder image
ARG ELIXIR_VERSION=1.15.8
ARG OTP_VERSION=26.2.5.2
ARG DEBIAN_VERSION=bookworm-20240812-slim
ARG APP_NAME=raffle_bot

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS builder

# Re-declare APP_NAME for use in this stage
ARG APP_NAME

# Install build tools
RUN apt-get update && apt-get install -y build-essential git

# Set the working directory
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy umbrella mix files
COPY mix.exs mix.lock ./
COPY config ./config

# Copy all app mix files (needed for umbrella dependency resolution)
COPY apps ./apps

# Set the mix environment to prod
ENV MIX_ENV=prod

# Get and compile dependencies
RUN mix deps.get --only prod && mix deps.compile

# Build the release for the specified app
RUN echo "Building release for app: ${APP_NAME}" && \
    mix release ${APP_NAME}

# Verify the release was built
RUN ls -la /app/_build/prod/rel/${APP_NAME}/bin/ && \
    test -f /app/_build/prod/rel/${APP_NAME}/bin/${APP_NAME} || \
    (echo "ERROR: Release binary not found for ${APP_NAME}!" && exit 1)

# Final image
ARG DEBIAN_VERSION=bookworm-20240812-slim
ARG APP_NAME

FROM debian:${DEBIAN_VERSION} AS app

# Re-declare APP_NAME for use in this stage
ARG APP_NAME

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libstdc++6 \
    libncurses6 \
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy the release from the builder
COPY --from=builder /app/_build/prod/rel/${APP_NAME} .

# Set the entrypoint and default command
# Note: We create a wrapper script to properly expand APP_NAME
RUN echo "#!/bin/sh" > /entrypoint.sh && \
    echo "exec /app/bin/\${APP_NAME} \"\$@\"" >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Set APP_NAME as environment variable so it's available at runtime
ENV APP_NAME=${APP_NAME}

ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]
