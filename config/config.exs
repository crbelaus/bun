import Config

if Mix.env() == :test do
  config :bun,
    version: "1.1.34",
    another: [
      args: ["--version"]
    ]
end
