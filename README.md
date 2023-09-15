# Bun

Mix tasks for installing and invoking [bun](https://bun.sh).

**This is an adaptation of [the Elixir esbuild installer](https://github.com/phoenixframework/esbuild) made by Wojtek Mach and José Valim.**

## Installation

If you are going to build assets in production, then you add
`bun` as dependency on all environments but only start it
in dev:

```elixir
def deps do
  [
    {:elixir_bun, "~> 0.1", runtime: Mix.env() == :dev}
  ]
end
```

However, if your assets are precompiled during development,
then it only needs to be a dev dependency:

```elixir
def deps do
  [
    {:elixir_bun, "~> 0.1", only: :dev}
  ]
end
```

Once installed, change your `config/config.exs` to pick your
bun version of choice:

```elixir
config :elixir_bun, version: "1.0.1"
```

Now you can install bun by running:

```bash
$ mix bun.install
```

And invoke bun with:

```bash
$ mix bun default assets/js/app.js --outdir=priv/static/assets/
```

The executable is kept at `_build/bun`. You can access it directly to manage packages and [many more things](https://bun.sh/docs/cli):

```bash
# Install a NPM package such a htmx.org
_build/bun add htmx.org
# Install a local package such as phoenix_html
_build/bun add ./deps/phoenix_html
# Remove a dependency
_build/bun add htmx.org
```

## Profiles

The first argument to `bun` is the execution profile.
You can define multiple execution profiles with the current
directory, the OS environment, and default arguments to the
`bun` task:

```elixir
config :elixir_bun,
  version: "1.0.1",
  default: [
    args: ~w(build js/app.js),
    cd: Path.expand("../assets", __DIR__)
  ]
```

When `mix bun default` is invoked, the task arguments will be appended
to the ones configured above. Note profiles must be configured in your
`config/config.exs`, as `bun` runs without starting your application
(and therefore it won't pick settings in `config/runtime.exs`).

## Adding to Phoenix

To add `bun` to an application using Phoenix, you need only four steps.  Installation requires that Phoenix watchers can accept module-function-args tuples which is not built into Phoenix 1.5.9.

First add it as a dependency in your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix, github: "phoenixframework/phoenix"},
    {:elixir_bun, "~> 0.1", runtime: Mix.env() == :dev}
  ]
end
```

Now let's change `config/config.exs` to configure `bun` to use
`assets/js/app.js` as an entry point and write to `priv/static/assets`:

```elixir
config :elixir_bun,
  version: "1.0.1",
  default: [
    args: ~w(build js/app.js --outdir=../priv/static/assets --external /fonts/* --external /images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{}
  ]
```

> Make sure the "assets" directory from priv/static is listed in the
> :only option for Plug.Static in your lib/my_app_web/endpoint.ex

For development, we want to enable watch mode. So find the `watchers`
configuration in your `config/dev.exs` and add:

```elixir
  esbuild: {Bun, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
```

Note we are inlining source maps and enabling the file system watcher.

Finally, back in your `mix.exs`, make sure you have a `assets.deploy`
alias for deployments, which will also use the `--minify` option:

```elixir
"assets.deploy": ["bun default --minify", "phx.digest"]
```

### Phoenix JS libraries

By default, Phoenix comes with three JS libraries that you'll most likely use in your project: phoenix, phoenix_html and phoenix_live_view.

To tell bun about those libraries you will need to run the following commands:

```
_build/bun add ./deps/phoenix
_build/bun add ./deps/phoenix_html
_build/bun add ./deps/phoenix_live_view
```

## Third-party JS packages

If you have JavaScript dependencies, you have three options
to add them to your application:

  1. Vendor those dependencies inside your project and
     import them in your "assets/js/app.js" using a relative
     path:

         import topbar from "../vendor/topbar"

  2. Call `_build/bun add topbar --save` inside your assets
     directory and `bun` will be able to automatically
     pick them up:

         import topbar from "topbar"

## CSS

`bun` has support for CSS. If you import a css file at the
top of your main `.js` file, `bun` will also bundle it, and write
it to the same directory as your `app.js`:

```js
import "../css/app.css"
```

## License

Copyright (c) 2023 Cristian Álvarez.

esbuild source code is licensed under the [MIT License](LICENSE.md).
