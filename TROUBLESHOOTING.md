# Troubleshooting

This document lists the issues we have faced during the development of this project and the solutions we have tried.

## GLIBC Version Mismatch

### Problem

The `exqlite` NIF is compiled against a newer version of `glibc` than the one on the Fly.io machine. This causes the following error:

```
Failed to load NIF library: '/lib/x86_64-linux-gnu/libc.so.6: version GLIBC_2.33' not found
```

### Solutions Tried

1.  **Use a `bookworm` image:** I tried to use a `debian:bookworm` image, which has a newer version of `glibc`. This failed because I could not find a `hexpm/elixir` image that was based on `bookworm`.

2.  **Use `asdf` to install Elixir and Erlang:** I tried to use `asdf` to install Elixir and Erlang in the `Dockerfile`. This failed because you preferred not to use `asdf` in a production environment.

3.  **Force recompilation of `exqlite`:** I tried to force the recompilation of `exqlite` from source by running `mix deps.compile exqlite --force`. This failed because the pre-compiled version of `exqlite` was still being used.

4.  **Clean all dependencies:** I tried to clean all of the dependencies before compiling by running `mix deps.clean --all`. This failed for the same reason as the previous attempt.

5.  **Set `EXQLITE_FORCE_BUILD=true`:** I tried to set the `EXQLITE_FORCE_BUILD` environment variable to `true` in the `Dockerfile`. This failed for the same reason as the previous attempts.

6.  **Set `ELIXIR_ERL_OPTIONS="+fnu"`:** I tried to set the `ELIXIR_ERL_OPTIONS` environment variable to `+fnu` in the `Dockerfile`. This was a desperate attempt and it did not work.

7.  **Use a specific Debian-based image:** I am now trying to use a specific Debian-based image with the `DEBIAN_VERSION` explicitly set. This should ensure that the `glibc` version is compatible with the pre-compiled `exqlite` NIF.

8.  **Switch to Debian Bookworm with valid Docker image:** The original Bullseye image tag (`bullseye-20230904-slim`) was deprecated and removed from Docker Hub. Switching to a Debian Bookworm-based image (`bookworm-20240812-slim`) with Elixir 1.15.8 and Erlang 26.2.5.2 solves both the Docker image availability issue and the GLIBC compatibility issue, as Bookworm includes glibc 2.36+.

### Solution

✅ **RESOLVED:** Using `hexpm/elixir:1.15.8-erlang-26.2.5.2-debian-bookworm-20240812-slim` as the base image. Debian Bookworm provides glibc 2.36, which is compatible with the pre-compiled `exqlite` NIF.

---

## Docker Build Failures

### Problem

Multiple Docker build and runtime configuration issues prevented successful deployment:

#### 1. Missing ARG in Final Docker Stage
```
Error: invalid reference format
```
The `DEBIAN_VERSION` ARG was not declared in the final Docker stage, causing Docker to fail when building the runtime image.

#### 2. Missing Config Directory
The release was missing `runtime.exs` because the `config/` directory wasn't copied to the builder stage.

#### 3. Missing Runtime Dependencies
The final image lacked essential dependencies like `openssl` and `ca-certificates` needed for HTTPS/Discord API calls.

### Solution

✅ **RESOLVED:**
- Added `ARG DEBIAN_VERSION=bookworm-20240812-slim` before the final `FROM` statement
- Added `COPY config ./config` to the builder stage
- Added `openssl` and `ca-certificates` to runtime dependencies
- Added release verification step: `test -f /app/_build/prod/rel/raffle_bot/bin/raffle_bot`

---

## Fly.io Command Path Issues

### Problem

The app failed to start with error:
```
ERROR: Unknown command /app/bin/raffle_bot
Usage: raffle_bot COMMAND [ARGS]
```

This occurred because Fly.io automatically prepends the Docker ENTRYPOINT to all commands in `fly.toml`, resulting in duplicate paths like:
```
/app/bin/raffle_bot /app/bin/raffle_bot start
```

### Solution

✅ **RESOLVED:** Removed the full binary path from all fly.toml commands:
- `console_command`: Changed from `/app/bin/raffle_bot remote` to `remote`
- `processes.app`: Changed from `/app/bin/raffle_bot start` to `start`
- `release_command`: Changed from `/app/bin/raffle_bot eval ...` to `eval ...`

---

## Phoenix Not Listening on Expected Address

### Problem

The app started but Fly.io couldn't connect to it:
```
WARNING The app is not listening on the expected address and will not be reachable by fly-proxy.
You can fix this by configuring your app to listen on the following addresses:
  - 0.0.0.0:8080
```

The Phoenix endpoint was configured to listen on IPv6 `{0, 0, 0, 0, 0, 0, 0, 0}` but Fly.io needed IPv4 `0.0.0.0:8080`.

### Solution

✅ **RESOLVED:** Changed `config/runtime.exs` Phoenix endpoint configuration:
- Changed `ip: {0, 0, 0, 0, 0, 0, 0, 0}` (IPv6) to `ip: {0, 0, 0, 0}` (IPv4 = 0.0.0.0)
- Added explicit port configuration in the http block
- Added `PHX_SERVER=true` to `fly.toml` env vars to ensure Phoenix server starts

---

## Missing Bandit HTTP Server Dependency

### Problem

The application crashed on startup with:
```
** (UndefinedFunctionError) function Bandit.PhoenixAdapter.child_specs/2 is undefined
(module Bandit.PhoenixAdapter is not available)
```

The Phoenix endpoint was configured to use `Bandit.PhoenixAdapter` in `config/config.exs`, but the `bandit` package was missing from dependencies. The project had `plug_cowboy` instead, which is incompatible with Bandit adapter configuration.

### Solution

✅ **RESOLVED:**
- Added `{:bandit, "~> 1.0"}` to `apps/raffle_bot/mix.exs` dependencies
- Removed `{:plug_cowboy, "~> 2.5"}` (incompatible with Bandit)
- Ran `mix deps.get` to update lock file
- Bandit and its dependencies (`hpax`, `thousand_island`) were successfully added

---

## Summary of Successful Deployment Configuration

The following configuration successfully deploys the Discord bot to Fly.io:

**Dockerfile:**
- Base image: `hexpm/elixir:1.15.8-erlang-26.2.5.2-debian-bookworm-20240812-slim`
- Runtime dependencies: `libstdc++6`, `libncurses6`, `openssl`, `ca-certificates`
- Config directory copied to builder stage
- ARG properly declared in both builder and final stages

**fly.toml:**
- Commands use only arguments (no full paths)
- `PHX_SERVER=true` environment variable set
- IPv4 binding in endpoint configuration

**Dependencies:**
- Using `bandit` instead of `plug_cowboy`
- All Phoenix 1.7 compatible packages

**Required Fly.io Secrets:**
```bash
fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
fly secrets set DISCORD_BOT_TOKEN=your_discord_bot_token_here
```
