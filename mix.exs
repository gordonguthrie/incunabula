defmodule Incunabula.Mixfile do
  use Mix.Project

  def project do
    [app: :incunabula,
     version: "0.0.1",
     elixir: "~> 1.2",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Incunabula, []},
     applications: [
       :phoenix,
       :phoenix_pubsub,
       :phoenix_html,
       :cowboy,
       :logger,
       :gettext,
       :phoenix_ecto
     ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix,             "~> 1.2.1"},
     {:phoenix_pubsub,      "~> 1.0"},
     {:phoenix_ecto,        "~> 3.0"},
     {:phoenix_html,        "~> 2.6"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext,             "~> 0.11"},
     {:cowboy,              "~> 1.0"},
     # {:diff,                git: "https://github.com/gordonguthrie/diff.git"},
     # add_users is messy because it builds an escript as well as providing
     # functionality - so the app has the escripts name
     {:add_users,           git: "https://github.com/gordonguthrie/incunabula_utilities.git"},
     {:pbkdf2_elixir,       "~> 0.12.3"}
    ]
  end

  defp package do
    [maintainers: ["Gordon Guthrie"],
     licenses: ["GLP V.30"],
     links: %{"GitHub" => "https://github.com/gordonguthrie/incunabula"}]
  end

end
