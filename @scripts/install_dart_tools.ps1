# Install DF tools.
dart pub global deactivate df_generate_dart_indexes; dart pub global activate df_generate_dart_indexes
dart pub global deactivate df_generate_dart_models; dart pub global activate df_generate_dart_models
dart pub global deactivate df_generate_header_comments; dart pub global activate df_generate_header_comments
dart pub global deactivate df_generate_localization; dart pub global activate df_localization
dart pub global deactivate df_generate_screen; dart pub global activate df_generate_screen

# Install 3rd party tools.
dart pub global deactivate flutterfire_cli; dart pub global activate flutterfire_cli
dart pub global deactivate dhttpd; #dart pub global activate dhttpd