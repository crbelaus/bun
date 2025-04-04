<p align="center">
  <img align="center" width="40%" src="assets/logo.svg" alt="Bun Logo">
  <h1>Bun</h1>
</p>

Mix tasks for installing and invoking [bun](https://bun.sh).

**This is an adaptation of [the Elixir esbuild installer](https://github.com/phoenixframework/esbuild) made by Wojtek Mach and José Valim.**

## Installation

If you are going to build assets in production, then you add
`bun` as dependency on all environments but only start it
in dev:

```elixir
def deps do
  [
    {:bun, "~> 1.4", runtime: Mix.env() == :dev}
  ]
end
```

However, if your assets are precompiled during development,
then it only needs to be a dev dependency:

```elixir
def deps do
  [
    {:bun, "~> 1.4", only: :dev}
  ]
end
```

Once installed, change your config (i.e. `config/config.exs` or
`config/runtime.exs`) to pick your bun version of choice:

```elixir
config :bun, version: "1.1.22"
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
_build/bun remove htmx.org
```

## Profiles

The first argument to `bun` is the execution profile.
You can define multiple execution profiles with the current
directory, the OS environment, and default arguments to the
`bun` task:

```elixir
config :bun,
  version: "1.1.22",
  assets: [
    args: [],
    cd: Path.expand("../assets", __DIR__)
  ],
  js: [
    args: ~w(build js/app.js),
    cd: Path.expand("../assets", __DIR__)
  ]
```

When `mix bun js` is invoked, it will invoke `bun build js/app.js`
appending any argument given to the task. You can also use
`mix bun assets` to run any `bun` command in the `assets` directory.

## Adding to Phoenix

To add `bun` to an application using Phoenix, you need only four steps. Installation requires that Phoenix v1.6+:

First add it as a dependency in your `mix.exs`:

```elixir
def deps do
  [
    {:phoenix, github: "phoenixframework/phoenix"},
    {:bun, "~> 1.4", runtime: Mix.env() == :dev}
  ]
end
```

Now let's change `config/config.exs` to configure `bun` to add two commands,
one to install dependencies and another to build `assets/js/app.js` as an
entry point and write to `priv/static/assets`:

```elixir
config :bun,
  version: "1.1.22",
  assets: [args: [], cd: Path.expand("../assets", __DIR__)],
  js: [
    args: ~w(build js/app.js --outdir=../priv/static/assets --external /fonts/* --external /images/*),
    cd: Path.expand("../assets", __DIR__)
  ]
```

> Make sure the "assets" directory from priv/static is listed in the
> :only option for Plug.Static in your lib/my_app_web/endpoint.ex

For development, we want to enable watch mode. So find the `watchers`
configuration in your `config/dev.exs` and add:

```elixir
  bun_js: {Bun, :install_and_run, [:js, ~w(--sourcemap=inline --watch)]}
```

Note we are inlining source maps and enabling the file system watcher.

Finally, back in your `mix.exs`, let's configure Phoenix `assets` tasks
to use `bun` instead:

```elixir
"assets.setup": ["bun.install --if-missing"],
"assets.build": ["bun js"],
"assets.deploy": ["bun js --minify", "phx.digest"],
```

### Phoenix JS libraries

By default, Phoenix comes with three JS libraries that you'll most likely use in your project: phoenix, phoenix_html and phoenix_live_view.

To tell bun about those libraries you will need to add the following to the `assets/package.json` file:

```json
{
  "workspaces": [
    "../deps/*"
  ],
  "dependencies": {
    "phoenix": "workspace:*",
    "phoenix_html": "workspace:*",
    "phoenix_live_view": "workspace:*"
  }
}
```

and then configure `mix assets.setup` to install them:

```
"assets.setup": ["bun.install --if-missing", "bun assets install"],
```

Now run `mix assets.setup` and you are good to go!

### Replace esbuild with bun

You can use `bun` to build CSS with TailwindCSS, replacing both `esbuild` and the `tailwindcss` library in Elixir.

First, update `assets/package.json`:

```json
"dependencies": {
  "phoenix": "workspace:*",
  "phoenix_html": "workspace:*",
  "phoenix_live_view": "workspace:*",
  "tailwindcss": "^4.1.0",
  "@tailwindcss/cli": "^4.1.0",
  "topbar": "^3.0.0"
}
```

Update your `:tailwind` configuration in `config/config.exs` to use `bun` instead:

```elixir
config :bun,
  css: [
    args: ~w(run tailwindcss --input=css/app.css --output=../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]
```

Make sure to remove the `:tailwind` config in this file as well.

In `config/dev.exs`, replace the watchers:

```elixir
bun_css: {Bun, :install_and_run, [:css, ~w(--watch)]}
```

Update `mix.exs` aliases:

```elixir
"assets.setup": ["bun.install --if-missing", "bun assets install"],
"assets.build": ["bun js", "bun css"],
"assets.deploy": ["bun css --minify", "bun js --minify", "phx.digest"],
```

Remove the `tailwind` and `esbuild` dependencies from your `mix.exs`.

## Third-party JS packages

If you have JavaScript dependencies, you have three options
to add them to your application:

  1. Vendor those dependencies inside your project and
     import them in your "assets/js/app.js" using a relative
     path:

         import topbar from "../vendor/topbar"

  2. Call `mix bun assets add topbar` inside your assets
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

bun source code is licensed under the [MIT License](LICENSE.md).
