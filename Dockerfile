# Dockerfile for Elixir umbrella project

# Builder image
FROM hexpm/elixir:1.15.7-erlang-26.2.2-alpine-3.18.5 AS builder

# Install build tools
RUN apk add --no-cache build-base git

# Set the working directory
WORKDIR /app

# Install Hex and Rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy the mix files and download dependencies
COPY mix.exs mix.lock ./
COPY apps/raffle_bot/mix.exs ./apps/raffle_bot/

RUN mix deps.get --only prod
RUN mix deps.compile

# Copy the rest of the application code
COPY . .

# Build the release
RUN mix release --app raffle_bot

# Final image
FROM alpine:3.18.5 AS app

# Install runtime dependencies
RUN apk add --no-cache libstdc++ ncurses-libs

# Set the working directory
WORKDIR /app

# Copy the release from the builder
COPY --from=builder /app/_build/prod/rel/raffle_bot .

# Set the entrypoint and default command
ENTRYPOINT ["/app/bin/raffle_bot"]
CMD ["start"]
