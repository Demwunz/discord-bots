# Dockerfile for Elixir umbrella project

# Builder image
FROM hexpm/elixir:1.15.7-erlang-26.2.2-debian-bullseye-20240130-slim AS builder

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

RUN mix deps.clean --all && mix deps.get --only prod && mix deps.compile

# Copy the rest of the application code
COPY . .

# Build the release
RUN mix release

# Final image
FROM debian:bullseye-slim AS app

# Install runtime dependencies
RUN apt-get update && apt-get install -y libstdc++6 libncurses6

# Set the working directory
WORKDIR /app

# Copy the release from the builder
COPY --from=builder /app/_build/prod/rel/raffle_bot .

# Set the entrypoint and default command
ENTRYPOINT ["/app/bin/raffle_bot"]
CMD ["start"]
