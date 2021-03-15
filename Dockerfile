FROM alpine:latest AS build

ENV MIX_ENV=prod
ARG DATABASE_URL=ecto://postgres:postgres@localhost:5432/sec_filings
ARG SECRET_KEY_BASE=MOd4x4LrY1W4Ahn+MQZ7jbFYoZP3oLbV+RND/3nb23ZrXFR0nFMpsSfJI6I8PWdQ
ARG PORT=4000

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
ARG SECRET_KEY_BASE=MOd4x4LrY1W4Ahn+MQZ7jbFYoZP3oLbV+RND/3nb23ZrXFR0nFMpsSfJI6I8PWdQ

WORKDIR /opt/app

RUN apk --no-cache add ncurses elixir npm
COPY --from=build /opt/app/ /opt/app/

CMD ["_build/prod/rel/sec_filings/bin/sec_filings", "start"]
