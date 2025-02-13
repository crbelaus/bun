import Config

if Mix.env() == :test do
  config :bun,
    version: "1.2.2",
    another: [
      args: ["--version"]
    ]
end
