<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="48"></a>
<a href="https://discord.gg/gEQ8y2nfyX" target="_blank"><img align="right" src="https://raw.githubusercontent.com/dev-cetera/resources/refs/heads/main/assets/discord_icon/discord_icon.svg" height="48"></a>

Dart & Flutter Packages by dev-cetera.com & contributors.

[![pub](https://img.shields.io/pub/v/df_bulk_replace.svg)](https://pub.dev/packages/df_bulk_replace)
[![tag](https://img.shields.io/badge/tag-v0.1.6-purple)](https://github.com/dev-cetera/df_bulk_replace/tree/v0.1.6)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/dev-cetera/df_bulk_replace/main/LICENSE)

---

<!-- BEGIN _README_CONTENT -->

## Summary

A command-line tool to perform bulk replacement of file names, folder names, and file contents within a specified directory.

## How It Works

1.  The script scans the specified directory recursively and finds all files and folders.
2.  It replaces the occurrences of the `replace` pattern with the `with` pattern in the file contents, file names, and folder names.
3.  The script supports using capture groups in the replacement pattern using double curly braces `{{}}`.

## Installing

```sh
dart pub global activate df_bulk_replace
```

## Uninstalling

```sh
dart pub global deactivate df_bulk_replace
```

## Examples

```sh
# Basic replacment.
bulkreplace --input test --replace "foo" --with "bar"
bulkreplace -i test -r "bar" -w "foo"
bulkreplace -i test -r "replace_me" -w "vervang_my"
bulkreplace -i test -r "vervang_my" -w "replace_me" # change back
bulkreplace -i test -r "replace_me" -w "vervang_my" && bulkreplace -i test -r "vervang_my" -w "replace_me"

# Using handlebars.
bulkreplace -i test -r "replace_me_(\\w)_(\\w)_(\\w)" -w "replace_me_{{2}}_{{1}}_{{0}}" --no-file-names --no-folder-names

# Whitelisting or blacklisting files.
bulkreplace -i test -r "foo" -w "bar" --blacklisted-files "blacklist_me_1.txt, blacklist_me_2.txt"
bulkreplace -i test -r "foo" -w "bar" --whitelisted-files "whitelist_me_1.txt, whitelist_me_2.txt"

# Whitelisting or blacklisting folders.
bulkreplace -i test -r "foo" -w "bar" --blacklisted-folders "_blacklist_me" -v
bulkreplace -i test -r "foo" -w "bar" --whitelisted-folders "_whitelist_me" -v

# For those familiar with RegExp, you can use regular expressions and capture groups.
bulkreplace --i . --replace "my_project_template(.*)" --with "hello_world{{1}}"
```

## Arguments

Prints help: **-h** or **--help**

Specifies the directory to search in: **-i** or **--input**

Specifies the regex pattern to replace: **-r** or **--replace**

Specifies the replacement string: **-w** or **--with**

Enables verbose output: **-v** or **--verbose**

Runs the program in dry-run mode (no files will be renamed): **--dry-run**

Specifies whether to replace file names or not. Default is true: **-f** or **--file-names**

Specifies whether to replace folder names or not. Default is true: **-d** or **--folder-names**

Specifies whether to replace file content or not. Default is true: **-c** or **--content**

Specifies whether to replace content in binary files or not. Default is false: **-b** or **--binary-content**

Include file name patterns to whitelist. Separate multiple patterns with commas: **--whitelisted-files**

Include file name patterns to blacklist. Separate multiple patterns with commas: **--blacklisted-files**

Specifies whether to add the default file whitelist or not. Default is true: **--default-whitelisted-files**

Specifies whether to add the default file blacklist or not. Default is true: **--default-blacklisted-files**

Include folder name patterns to whitelist. Separate multiple patterns with commas: **--whitelisted-folders**

Include folder name patterns to blacklist. Separate multiple patterns with commas: **--blacklisted-folders**

<!-- END _README_CONTENT -->

---

Please refer to the [API reference](https://pub.dev/documentation/df_bulk_replace/) for more information.

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute

- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/dev_cetera). Your support helps cover the costs of development and keeps the project growing.
- **Find us on Discord:** Feel free to ask questions and engage with the community here: https://discord.gg/gEQ8y2nfyX.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Help others:** Engage with other users by offering advice, solutions, or troubleshooting assistance.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

### We drink a lot of coffee...

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here: https://www.buymeacoffee.com/dev_cetera

<a href="https://www.buymeacoffee.com/dev_cetera" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" height="40"></a>

## License

This project is released under the [MIT License](https://raw.githubusercontent.com/dev-cetera/df_bulk_replace/main/LICENSE). See [LICENSE](https://raw.githubusercontent.com/dev-cetera/df_bulk_replace/main/LICENSE) for more information.

