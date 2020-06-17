# Etog
It's my personal blog "Experience to Graph" or short - "Etog" (there’s a small wordplay here, as the abbreviation is like “Resume” in Russian). Here I summarize some of my projects, completed courses or finished books, and try to share my experience and knowledge.
This is my attempt to try new or interesting technologies on something more tangible than artificial projects. 

The basis of the project is:

  * [Phoenix](https://github.com/phoenixframework/phoenix)
  * [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view)
  * Graph database [Node4j](https://neo4j.com/)

# Development

To install elixir

  * MacOS: `brew update && brew install elixir` (or follow the instructions `https://elixir-lang.org/install.html`)

To install Neo4j

  * Check docs [here](https://neo4j.com/docs/operations-manual/current/installation/)

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Install Stylelint `cd assets && npm install -g stylelint prettier eslint`
  * Install Lefthook for git hooks:
    * `brew install Arkweid/lefthook/lefthook` [https://github.com/Arkweid/lefthook](github.com/Arkweid/lefthook)
    * `lefthook install && lefthook run pre-commit` 
  * Load ENV variables `source config/.env`
  * Start Phoenix endpoint with `mix phx.server`

To add translations:

  * `mix gettext.extract && mix gettext.merge priv/gettext && mix gettext.merge priv/gettext --locale LOCALE`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Build

To build a release you need a docker container. Build it (only for first release):

  * `docker build -t etog:latest .`

Build a full release:

  * `docker run -v $(pwd):/opt/app --rm -it etog:latest /opt/app/bin/build`

Or build an upgrade release:

  * `docker run -v $(pwd):/opt/app -e RELEASE_TYPE=upgrade --rm -it etog:latest /opt/app/bin/build`

## Deploy

To start the release you have built:

  * Extract the release in `releases/VERSION` directly: `tar xvf etog-VERSION.tar.gz`
  * Update a symlink and restart container: `cd ~/apps/etog && rm current && ln -s releases/VERSION current && cd ~/docker && docker-compose restart etog`

To upgrade a previous release:

  * Copy the new release to `~/apps/etog/releases/VERSION` and rename it to `etog.tar.gz`
  * Hot reload `docker exec -ti etog bach -c "./bin/etog upgrade VERSION"`

Useful commands:
  * Start a shell, like 'iex -S mix' `_build/prod/rel/etog/bin/etog console`
  * Start in the foreground, like 'mix run --no-halt' `_build/prod/rel/etog/bin/etog foreground`
  * Start in the background, must be stopped with the 'stop' command `_build/prod/rel/etog/bin/etog start`
  * Connects a local shell to the running node `_build/prod/rel/etog/bin/etog remote_console`
  * Connects directly to the running node's console `_build/prod/rel/etog/bin/etog attach`
  * Show a complete listing of commands and their use `_build/prod/rel/etog/bin/etog help`
