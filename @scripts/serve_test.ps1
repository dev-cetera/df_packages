pwsh scripts/kill_port_8080.ps1
Set-Location apps/main_app
flutter build web --wasm --optimization-level 4
dhttpd --path build/web --port 8080
Set-Location ..