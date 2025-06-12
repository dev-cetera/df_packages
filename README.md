# DF Packages

A project designed to help manage all df packages from one location. It uses [melos](https://pub.dev/packages/melos) to manage the packages, as well as additional helper scripts. Please read the melos documentation [here](https://melos.invertase.dev/~melos-latest/) for more information.

## Melos Quick-Notes

### Installing

This installs melos onto your system, so you can run the `melos` command.

```zsh
dart pub global activate melos
```

You may also want to install the VS Code package [here](https://marketplace.visualstudio.com/items?itemName=blaugold.melos-code).

### Analyzing

This command checks for any issues.

```zsh
melos analyze
```

### Bootstrapping

This installs dependencies internally, and links all packages locally.

```zsh
melos bootstrap
```

### Publishing

This publishes all packages that are ready to `pub.dev`.

```zsh
melos publish --dry-run
melos publish
```
