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