# DF Packages

A project designed to help manage all df packages from one location.

## Public Repo Setup

```sh
brew install gh
gh auth login
git init
git add .
git commit -m "Initial commit"
gh repo create df_generate_d --public
git remote add origin https://github.com/dev-cetera/YOUR_PROJECT_NAME.git
git push -u origin main
```

## Publishing

1. Make your changes.
1. Run `dart analyze` to check for errors.
1. Run `dart fix --apply` to apply fixes.
1. Run `dart format .` to format the code.
1. Update the version number in `pubspec.yaml`.
1. Update the version number in `CHANGELOG.md`.
1. Run `dart pub publish --dry-run` to check for errors.
1. Run `dart pub publish` to publish the package.

## Commmit Tag Descriptions

- `feat`: New feature or enhancement
- `fix`: Bug fix or issue resolution
- `chore`: Routine tasks or maintenance
- `refactor`: Code improvements (no functionality change)
- `docs`: Documentation updates
- `style`: Code style or formatting changes
- `test`: Tests additions or modifications
- `build`: Build system or external dependencies changes
- `perf`: Performance improvements
- `ci`: Continuous integration configuration changes
- `revert`: Revert a previous commit
- `security`: Security-related changes or fixes
- `release`: Marks a release or version update