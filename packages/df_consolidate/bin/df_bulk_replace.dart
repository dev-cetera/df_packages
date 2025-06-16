//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:io';
import 'package:args/args.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:glob/glob.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

const VERSION = 'v0.1.0';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void main(List<String> args) {
  print('Running df_bulk_replace...');
  try {
    // CREATE ARGUMENT PARSER
    final parser = ArgParser()
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Prints this help',
        negatable: false,
        defaultsTo: false,
      )
      ..addOption(
        'input',
        abbr: 'i',
        help: 'Specifies the directory to search in',
        defaultsTo: '.',
      )
      ..addOption(
        'replace',
        abbr: 'r',
        help: 'Specifies the regex pattern to replace',
      )
      ..addOption(
        'with',
        abbr: 'w',
        help: 'Specifies the replacement string',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enables verbose output',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Runs the program in dry-run mode (no files will be renamed)',
        negatable: false,
      )
      ..addFlag(
        'file-names',
        abbr: 'f',
        help: 'Specifies whether to replace file names or not',
        negatable: true,
        defaultsTo: true,
      )
      ..addFlag(
        'folder-names',
        abbr: 'd',
        help: 'Specifies whether to replace folder names or not',
        negatable: true,
        defaultsTo: true,
      )
      ..addFlag(
        'content',
        abbr: 'c',
        help: 'Specifies whether to replace file content or not',
        negatable: true,
        defaultsTo: true,
      )
      ..addFlag(
        'binary-content',
        abbr: 'b',
        help: 'Specifies whether to replace content in binary files or not',
        negatable: false,
        defaultsTo: false,
      )
      ..addMultiOption(
        'whitelisted-files',
        help: 'Include file name patters to whitelist',
        splitCommas: true,
        defaultsTo: [],
      )
      ..addMultiOption(
        'blacklisted-files',
        help: 'Include file name patterns to blacklist',
        splitCommas: true,
        defaultsTo: [],
      )
      ..addFlag(
        'default-whitelisted-files',
        help: 'Specifies whether to add the default file whitelist or not',
        negatable: true,
        defaultsTo: false,
      )
      ..addFlag(
        'default-blacklisted-files',
        help: 'Specifies whether to add the default folder blacklist or not',
        negatable: true,
        defaultsTo: false,
      )
      ..addMultiOption(
        'whitelisted-folders',
        help: 'Include folder name patters to whitelist',
        splitCommas: true,
        defaultsTo: [],
      )
      ..addMultiOption(
        'blacklisted-folders',
        help: 'Include folder name patters to blacklist',
        splitCommas: true,
        defaultsTo: [],
      );

    // PARSE ARGUMENTS
    final argsResult = parser.parse(args);
    final argHelp = argsResult['help'] as bool;
    if (argHelp) {
      printHelp(parser);
      return;
    }
    final argInput = argsResult['input'] as String?;
    final argReplace = argsResult['replace'] as String?;
    final argWith = argsResult['with'] as String?;
    final argVerbose = argsResult['verbose'] as bool;
    final argDryRun = argsResult['dry-run'] as bool;
    final argReplaceBinaryContent = argsResult['binary-content'] as bool;
    final argFileNames = argsResult['file-names'] as bool;
    final argFolderNames = argsResult['folder-names'] as bool;
    final argContent = argsResult['content'] as bool;
    final argWhitelistedFiles = (argsResult['whitelisted-files'] as List).map((e) {
      return e.toString().toLowerCase();
    }).toList();
    final argBlacklistedFiles = (argsResult['blacklisted-files'] as List).map((e) {
      return e.toString().toLowerCase();
    }).toList();
    final argWhitelistedFolders = (argsResult['whitelisted-folders'] as List).map((e) {
      return e.toString().toLowerCase();
    }).toList();
    final argBlacklistedFolders = (argsResult['blacklisted-folders'] as List).map((e) {
      return e.toString().toLowerCase();
    }).toList();
    final argDefaultWhitelistedFiles = argsResult['default-whitelisted-files'] as bool;
    final argDefaultBlacklistedFiles = argsResult['default-blacklisted-files'] as bool;

    // VALIDATE ARGUMENTS
    if (argInput == null || argReplace == null || argWith == null) {
      print('Missing required arguments');
      print(parser.usage);
      exit(1);
    }

    // GET A LIST OF FILES
    final files = Glob(
      '*',
      recursive: true,
    ).listSync(root: argInput).whereType<File>().toList();
    if (argVerbose) {
      print(
        "Considering files:\n${files.map((e) => "- ${e.path}").join("\n")}",
      );
    }

    files.removeWhere((file) {
      final path = file.path;

      // SKIP BINARY FILES
      if (!argReplaceBinaryContent) {
        final yes = isBinaryFile(file);
        if (yes) {
          if (argVerbose) {
            print('Skipping binary file $path');
          }
          return true;
        }
      }

      // SKIP FILES THAT ARE NOT WHITELISTED
      if (argWhitelistedFiles.isNotEmpty || argDefaultWhitelistedFiles) {
        if (!containsPatterns(path, [
          if (argDefaultWhitelistedFiles) ...DEFAULT_FILE_WHITELIST,
          ...argWhitelistedFiles,
        ])) {
          if (argVerbose) {
            print("Skipping file $path because it's not whitelisted");
          }
          return true;
        }
      }

      // SKIP FILES THAT ARE BLACKLISTED
      if (argBlacklistedFiles.isNotEmpty || argDefaultBlacklistedFiles) {
        if (containsPatterns(path, [
          if (argDefaultBlacklistedFiles) ...DEFAULT_FILE_BLACKLIST,
          ...argBlacklistedFiles,
        ])) {
          if (argVerbose) {
            print("Skipping file $path because it's blacklisted");
          }
          return true;
        }
      }

      // SKIP FILES THAT ARE IN FOLDERS THAT ARE NOT WHITELISTED
      if (argWhitelistedFolders.isNotEmpty) {
        final segments = p.split(path);
        final length = segments.length;
        if (length > 1) {
          final folderPath = p.fromUri(segments.sublist(0, length - 1).join('/'));
          if (!containsPatterns(folderPath, argWhitelistedFolders)) {
            if (argVerbose) {
              print(
                "Skipping file $path in folder $folderPath because it's not whitelisted",
              );
            }
            return true;
          }
        }
      }

      // SKIP FILES THAT ARE IN FOLDERS THAT ARE BLACKLISTED
      if (argBlacklistedFolders.isNotEmpty) {
        final segments = p.split(path);
        final length = segments.length;
        if (length > 1) {
          final folderPath = p.fromUri(segments.sublist(0, length - 1).join('/'));
          if (containsPatterns(folderPath, argBlacklistedFolders)) {
            if (argVerbose) {
              print(
                "Skipping file $path in folder $folderPath because it's blacklisted",
              );
            }
            return true;
          }
        }
      }

      return false;
    });

    // GET A LIST OF FOLDERS
    final folders = Glob(
      '*/',
      recursive: true,
    ).listSync(root: argInput).whereType<Directory>().toList();
    if (argVerbose) {
      print(
        "Considering folders:\n${folders.map((e) => "- ${e.path}").join("\n")}",
      );
    }
    folders.sort((a, b) {
      return b.path.split(p.separator).length.compareTo(a.path.split(p.separator).length);
    });

    folders.removeWhere((folder) {
      final path = folder.path;

      // SKIP FOLDERS THAT ARE NOT WHITELISTED
      if (argWhitelistedFolders.isNotEmpty) {
        if (!containsPatterns(path, argWhitelistedFolders)) {
          if (argVerbose) {
            print("Skipping folder $path because it's not whitelisted");
          }
          return true;
        }
      }
      // SKIP FOLDERS THAT ARE BLACKLISTED
      if (argBlacklistedFolders.isNotEmpty) {
        if (containsPatterns(path, argBlacklistedFolders)) {
          if (argVerbose) {
            print("Skipping folder $path because it's blacklisted");
          }
          return true;
        }
      }
      return false;
    });

    // REPLACE FILE CONTENT
    if (argContent) {
      for (final file in files) {
        final filePath = file.path;

        // REPLACE FILE CONTENT
        final before = file.readAsStringSync();
        final after = replaceWithPattern(before, argReplace, argWith);
        if (argVerbose && before != after) {
          print('Replacing content in file $filePath');
        }

        if (!argDryRun) {
          file.writeAsStringSync(after);
        }
      }
    }

    // REPLACE FILE NAMES
    if (argFileNames) {
      for (final file in files) {
        final path = file.path;
        final segments = p.split(path);
        final before =
            segments.length == 1 ? null : segments.sublist(0, segments.length - 1).join('/');
        final last = segments.last;
        final after = replaceWithPattern(last, argReplace, argWith);
        final result = [if (before != null) before, after].join('/');
        if (argVerbose && path != result) {
          print('Renaming file from $path to $result');
        }
        if (!argDryRun) {
          file.renameSync(result);
        }
      }
    }

    // REPLACE FOLDER NAMES
    if (argFolderNames) {
      for (final folder in folders) {
        final path = folder.path;
        final segments = p.split(path);
        final before =
            segments.length == 1 ? null : segments.sublist(0, segments.length - 1).join('/');
        final last = segments.last;
        final after = replaceWithPattern(last, argReplace, argWith);
        final result = [if (before != null) before, after].join('/');
        if (argVerbose && path != result) {
          print('Renaming folder from $path to $result');
        }
        if (!argDryRun) {
          folder.renameSync(result);
        }
      }
    }
    print('Success!!! :D');
  } catch (e) {
    print('Failure!!! :(\nAn error occurred: ${e.toString()}');
    exit(1);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

void printHelp(ArgParser parser) {
  print(
    'bulk_replace [$VERSION]\n\n'
    'Usage: dart bulk_replace.dart [OPTIONS]\n\n'
    'A command-line tool to perform bulk replacement of file names, folder names, and file contents within a specified directory.\n\n'
    'Options:\n'
    '${parser.usage}\n\n'
    'Example:\n'
    'dart bulk_replace.dart -i some_folder -r "foo" -w "bar" -v\n',
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String replaceWithPattern(
  String input,
  String argReplace,
  String argWith,
) {
  try {
    final expression = RegExp(argReplace);
    // Replace all occurrences of the matched pattern with argWith
    return input.replaceAllMapped(expression, (match) {
      // Start with the argWith string
      var result = argWith;
      for (var i = 0; i < match.groupCount; i++) {
        // Get the group value at the current index
        final group = match.group(i + 1);
        if (group != null) {
          // Replace placeholders
          result = result.replaceAll('{{$i}}', group);
        }
      }
      return result;
    });
  } catch (e) {
    print('An error occurred during pattern replacement: ${e.toString()}');
    return input;
  }
}
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

bool isBinaryFile(File file) {
  try {
    final bytes = file.readAsBytesSync();
    return isBinaryData(bytes);
  } catch (e) {
    print('Error reading file as bytes: ${file.path}');
    // Treat it as binary on failure.
    return true;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// This function takes a list of integers as input and checks if it contains binary data.
bool isBinaryData(List<int> data) {
  for (final byte in data) {
    // Check if the current byte is a non-printable ASCII character (less than 32),
    // and not a tab, newline, or carriage return character.
    if (byte < 32 && byte != 9 && byte != 10 && byte != 13) {
      return true;
    }
  }
  return false;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

bool containsPatterns(String text, List<String> patterns) {
  return patterns.any((pattern) => RegExp(pattern).hasMatch(text));
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

const DEFAULT_FILE_WHITELIST = [
  r'\.c$',
  r'\.cpp$',
  r'\.h$',
  r'\.hpp$',
  r'\.java$',
  r'\.js$',
  r'\.ts$',
  r'\.py$',
  r'\.rb$',
  r'\.go$',
  r'\.rs$',
  r'\.swift$',
  r'\.php$',
  r'\.cs$',
  r'\.dart$',
  r'\.sh$',
  r'\.m$',
  r'\.kt$',
  r'\.scala$',
  r'\.groovy$',
  r'\.lua$',
  r'\.r$',
  r'\.pl$',
  r'\.jl$',
  r'\.hs$',
  r'\.erl$',
  r'\.md$',
  r'\.tex$',
  r'\.xml$',
  r'\.html$',
  r'\.css$',
  r'\.scss$',
  r'\.yaml$',
  r'\.yml$',
  r'\.json$',
  r'\.ini$',
  r'\.sql$',
  r'\.bat$',
  r'\.ps1$',
];

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

const DEFAULT_FILE_BLACKLIST = [
  r'\.exe$',
  r'\.dll$',
  r'\.so$',
  r'\.dylib$',
  r'\.class$',
  r'\.jar$',
  r'\.war$',
  r'\.a$',
  r'\.o$',
  r'\.lib$',
  r'\.pdb$',
  r'\.app$',
  r'\.dmg$',
  r'\.iso$',
  r'\.img$',
  r'\.zip$',
  r'\.rar$',
  r'\.tar$',
  r'\.gz$',
  r'\.xz$',
  r'\.bz2$',
  r'\.7z$',
  r'\.apk$',
  r'\.bin$',
  r'\.deb$',
  r'\.pdf$',
  r'\.docx$',
  r'\.pptx$',
  r'\.xlsx$',
  r'\.jpg$',
  r'\.jpeg$',
  r'\.png$',
  r'\.gif$',
  r'\.bmp$',
  r'\.ico$',
  r'\.mp3$',
  r'\.wav$',
  r'\.ogg$',
  r'\.flac$',
  r'\.mp4$',
  r'\.mkv$',
  r'\.avi$',
  r'\.mov$',
  r'\.wmv$',
];
