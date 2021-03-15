FROM alpine:latest AS build

ENV MIX_ENV=prod
ARG DATABASE_URL=ecto://postgres:postgres@localhost:5432/sec_filings
ARG SECRET_KEY_BASE=MOd4x4LrY1W4Ahn+MQZ7jbFYoZP3oLbV+RND/3nb23ZrXFR0nFMpsSfJI6I8PWdQ
ENV PORT=4000

WORKDIR /opt/app

RUN apk --no-cache add elixir npm

ADD . .

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get --only prod
RUN mix compile
RUN npm install --prefix ./assets
RUN npm run deploy --prefix ./assets
RUN mix phx.digest
RUN mix release

FROM alpine:latest AS deploy

ENV MIX_ENV=prod
ENV PORT=4000

WORKDIR /opt/app

RUN apk --no-cache add ncurses
COPY --from=build /opt/app/_build/prod/ /opt/app/_build/prod/

CMD ["_build/prod/rel/sec_filings/bin/sec_filings", "start"]
