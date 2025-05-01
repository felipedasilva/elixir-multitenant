[
  import_deps: [:oban, :ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations", "priv/*/migrations_tenant"],
  plugins: [Phoenix.LiveView.HTMLFormatter],
  inputs: ["*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}", "priv/*/seeds.exs"]
]
