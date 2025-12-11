# Dockerfile for Elixir umbrella project

# Builder image
ARG ELIXIR_VERSION=1.15.8
ARG OTP_VERSION=26.2.5.2
ARG DEBIAN_VERSION=bookworm-20240812-slim
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION} AS builder

# Install build tools
RUN apt-get update && apt-get install -y build-essential git

# Set the working directory
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy the mix files and download dependencies
COPY mix.exs mix.lock ./
COPY apps/raffle_bot/mix.exs ./apps/raffle_bot/

# Set the mix environment to prod
ENV MIX_ENV=prod

RUN mix deps.get --only prod && mix deps.compile

# Copy the rest of the application code
COPY . .

# Build the release
RUN mix release

# Final image
FROM debian:${DEBIAN_VERSION} AS app

# Install runtime dependencies
RUN apt-get update && apt-get install -y libstdc++6 libncurses6

# Set the working directory
WORKDIR /app

# Copy the release from the builder
COPY --from=builder /app/_build/prod/rel/raffle_bot .

# Set the entrypoint and default command
ENTRYPOINT ["/app/bin/raffle_bot"]
CMD ["start"]
