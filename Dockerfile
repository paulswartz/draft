# first, get the elixir dependencies within an elixir container
FROM hexpm/elixir:1.11.4-erlang-23.3-debian-buster-20210208 as elixir-builder

ENV LANG=C.UTF-8 \
  MIX_ENV=prod

WORKDIR /root
ADD . .

RUN mix do local.hex --force, local.rebar --force
RUN mix do deps.get --only prod

# next, build the frontend assets within a node.js container
FROM node:14 as assets-builder

WORKDIR /root
ADD . .

# copy in elixir deps required to build node modules for phoenix
COPY --from=elixir-builder /root/deps ./deps

RUN npm --prefix assets ci
RUN npm --prefix assets run deploy

# now, build the application back in the elixir container
FROM elixir-builder as app-builder

ENV LANG="C.UTF-8" MIX_ENV="prod"

WORKDIR /root

# add frontend assets compiled in node container, required by phx.digest
COPY --from=assets-builder /root/priv/static ./priv/static

RUN mix do compile --force, phx.digest, release

# finally, use a debian container for the runtime environment
FROM debian:buster

RUN apt-get update && apt-get install -y --no-install-recommends \
  libssl1.1 libsctp1 curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /root
EXPOSE 4000
ENV MIX_ENV=prod TERM=xterm LANG="C.UTF-8" PORT=4000

COPY --from=app-builder /root/_build/prod/rel/draft .

CMD ["bin/draft", "start"]
