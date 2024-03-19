import Config

if Mix.env() == :test do
  config :bun,
    version: "1.0.33",
    another: [
      args: ["--version"]
    ]
end
