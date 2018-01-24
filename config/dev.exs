use Mix.Config

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with brunch.io to recompile .js and .css sources.
config :incunabula, Incunabula.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [node: ["node_modules/brunch/bin/brunch", "watch", "--stdin",
                    cd: Path.expand("../", __DIR__)]]


# Watch static and templates for browser reloading.
config :incunabula, Incunabula.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{web/views/.*(ex)$},
      ~r{web/templates/.*(eex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# can't use the '~' full path only
config :incunabula, :configuration,
  root_directory: "/home/vagrant/books"

#
# Don't @ me bro
#
# There is a Git Personal Access Token stored in here for a repo
# called Incunabula which is the test user that this app uses as
# a backend - and that is just ok for now - it is a segregated user
#
# the GitHub Personal Access Token created on the GitHub account
config :incunabula, :configuration,
  personal_access_token: "7ba8dd29d9e61838ce3019e3e8695438b9fcc80a"
