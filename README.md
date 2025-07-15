# Firebase Hardcoded Keys Extractor

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Bash](https://img.shields.io/badge/script-Bash-blue)
![apktool](https://img.shields.io/badge/dependency-apktool-critical)

---


Este script automatiza la extracción de credenciales sensibles hardcodeadas en archivos `strings.xml` de aplicaciones Android (`.apk`), particularmente enfocadas en configuraciones de **Firebase**.  
Realiza:

- **Decompilación del APK** mediante `apktool`.
- Extracción de:
  - `firebase_database_url`
  - `google_api_key`
  - `google_app_id`
- Comprobaciones de exposición:
  - Endpoint Firebase `.json` público
  - Acceso no autenticado a la API de `RemoteConfig`

---

## ⚙️ Requisitos

- `bash` (>= 4.0)
- [`apktool`](https://ibotpeaches.github.io/Apktool/)
- [`curl`](https://curl.se/)
- [`jq`](https://stedolan.github.io/jq/) (opcional pero recomendado para legibilidad)

Instalación de dependencias (ejemplos):

```bash
# Debian/Ubuntu
sudo apt install apktool curl jq

# Arch Linux
yay -S apktool curl jq

# macOS (Homebrew)
brew install apktool curl jq

# USAGE
chmod +x extract_firebase.sh
./extract_firebase.sh --apk path/to/apk.apk


# Adventencia
Este script no explota vulnerabilidades, sino que identifica malas prácticas de desarrollo: incluir claves en texto plano dentro de APKs.
Debe ser utilizado exclusivamente con fines educativos, de auditoría propia o con consentimiento explícito.
