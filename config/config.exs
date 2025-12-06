import Config

if Mix.env() == :test do
  config :bun,
    version: "1.3.0",
    another: [
      args: ["--version"]
    ]
end
