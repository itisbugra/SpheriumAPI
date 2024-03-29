defmodule Spherium.Mixfile do
  use Mix.Project

  def project do
    [app: :spherium,
     version: "0.1.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: ["coveralls": :test,
                         "coveralls.detail": :test,
                         "coveralls.post": :test,
                         "coveralls.html": :test],
     deps: deps,

     # Docs
     name: "Spherium",
     source_url: "https://github.com/Chatatata/Spherium-Web-Service",
     homepage_url: "http://www.spherium.host",
     docs: [main: "Spherium",
            extras: ["README.md"]]
   ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Spherium, []},
     applications: [:phoenix, :cowboy, :logger, :gettext,
                    :phoenix_ecto, :postgrex, :comeonin,
                    :jose, :timex, :crypto, :httpoison,
                    :poison, :redix]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "src", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "src"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.2.1"},
     {:postgrex, ">= 0.0.0"},
     {:phoenix_ecto, "~> 3.0.1"},
     {:gettext, "~> 0.9"},
     {:cowboy, "~> 1.0"},
     {:comeonin, "~> 2.5.2"},
     {:ex_machina, "~> 1.0", only: :test},
     {:jose, "~> 1.8"},
     {:credo, "~> 0.4", only: [:dev, :test]},
     {:timex, "~> 3.0"},
     {:excoveralls, "~> 0.6.1", only: :test},
     {:cors_plug, "~> 1.1"},
     {:httpoison, "~> 0.10.0"},
     {:poison, "~> 3.0", override: true},
     {:ex_doc, "~> 0.14.5"},
     {:ecto_enum, "~> 1.0"},
     {:redix, "~> 0.5.1"}]
  end

  # Aliases are shortcut or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create",
                    "ecto.migrate",
                    "run priv/repo/seeds.exs",
                    "spherium.authentication.refresh_permissions"],
     "ecto.reset": ["ecto.drop",
                    "ecto.setup"],
     "test": ["ecto.create --quiet",
              "ecto.migrate", "test"]]
  end
end
