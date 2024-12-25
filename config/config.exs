import Config

if Mix.env() == :test do
  config :bun,
    version: "1.1.42",
    another: [
      args: ["--version"]
    ]
end
