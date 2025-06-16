# This script reinstalls all the DF generators.

# Uninstall all generators.
dart pub global deactivate df_generate_dart_indexes;
dart pub global deactivate df_generate_dart_models;
dart pub global deactivate df_generate_header_comments;
dart pub global deactivate df_generate_screen;
dart pub global deactivate df_localization;

# Install all generators.
dart pub global activate df_generate_dart_indexes;
dart pub global activate df_generate_dart_models;
dart pub global activate df_generate_header_comments;
dart pub global activate df_generate_screen;
dart pub global activate df_localization;