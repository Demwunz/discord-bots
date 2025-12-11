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

### Next Steps

If this approach does not work, I will need to ask for help from a human expert.
