#!/bin/bash
#Firebase Extractor desde APKs
set -euo pipefail
IFS=$'\n\t'

# ------------------------------- CONFIGURACIÓN ------------------------------- #
APKTOOL_BIN=$(command -v apktool || true)

# ----------------------------- FUNCIONES LOG ----------------------------- #
logInfo()    { printf "[INFO] %s\n" "$1"; }
logWarn()    { printf "[WARN] %s\n" "$1"; }
logError()   { printf "[ERROR] %s\n" "$1" >&2; }
logSuccess() { printf "[OK] %s\n" "$1"; }

# --------------------------- FUNCIONES PRINCIPALES -------------------------- #

checkDependencies() {
    if [[ -z "$APKTOOL_BIN" ]]; then
        logError "apktool no está instalado. Instálalo con: apt install apktool / yay -S apktool / brew install apktool"
        exit 1
    fi
}

decompileApk() {
    local apk="$1"

    if [[ ! -f "$apk" ]]; then
        logError "Archivo $apk no encontrado."
        exit 1
    fi

    logInfo "Decompilando APK: $apk"
    apktool d -f "$apk" -o "decompiled_apk" > /dev/null || {
        logError "Falló la decompilación de $apk"
        exit 1
    }

    extractFirebaseData "decompiled_apk/res/values/strings.xml"
}

extractFirebaseData() {
    local xml_path="$1"

    if [[ ! -f "$xml_path" ]]; then
        logError "Archivo strings.xml no encontrado en $xml_path"
        exit 1
    fi

    local firebase_url=$(grep 'firebaseio' "$xml_path" | sed -n 's/.*<string name="firebase_database_url">\([^<]*\)<\/string>.*/\1/p')
    local google_api_key=$(grep 'google_api_key' "$xml_path" | sed -n 's/.*<string name="google_api_key">\([^<]*\)<\/string>.*/\1/p')
    local google_app_id=$(grep 'google_app_id' "$xml_path" | sed -n 's/.*<string name="google_app_id">\([^<]*\)<\/string>.*/\1/p')

    [[ -z "$firebase_url" || -z "$google_api_key" || -z "$google_app_id" ]] && {
        logWarn "No se pudieron extraer todos los valores. Puede que el APK no tenga configuración Firebase hardcodeada."
        exit 0
    }

    logSuccess "Firebase URL: $firebase_url"
    logSuccess "Google API Key: $google_api_key"
    logSuccess "Google App ID: $google_app_id"

    testJsonEndpoint "$firebase_url"
    testRemoteConfig "$google_app_id" "$google_api_key"
}

testJsonEndpoint() {
    local url="$1"
    logInfo "Consultando ${url}/.json..."
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" "${url}/.json")

    if [[ "$status_code" == "200" ]]; then
        logSuccess "El endpoint Firebase está expuesto públicamente."
    else
        logWarn "El endpoint Firebase respondió con código $status_code"
    fi
}

testRemoteConfig() {
    local app_id="$1"
    local api_key="$2"
    local project_id

    project_id=$(echo "$app_id" | cut -d':' -f2)

    logInfo "Probandos configuración remota (RemoteConfig API)..."
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"appId\":\"${app_id}\",\"appInstanceId\":\"PROD\"}" \
        "https://firebaseremoteconfig.googleapis.com/v1/projects/${project_id}/namespaces/firebase:fetch?key=${api_key}" | jq .

    logSuccess "Consulta enviada (revisa si el servidor responde con parámetros válidos)."
}

printBanner() {
    echo "==================================================================="
    echo "|            Firebase Hardcoded Keys Extractor                    |"
    echo "==================================================================="
}

printHelp() {
    echo "Uso: $0 --apk <archivo.apk>"
    echo ""
    echo "Opciones:"
    echo "  --apk <archivo.apk>     Decompila y extrae configuraciones Firebase"
    echo "  --help                  Muestra esta ayuda"
}

# ---------------------------- FLUJO PRINCIPAL ---------------------------- #
main() {
    printBanner
    if [[ $# -lt 1 ]]; then
        printHelp
        exit 1
    fi

    case "$1" in
        --apk)
            checkDependencies
            [[ -z "${2:-}" ]] && { logError "Debes proporcionar el archivo APK."; exit 1; }
            decompileApk "$2"
            ;;
        --help)
            printHelp
            ;;
        *)
            logError "Opción inválida: $1"
            printHelp
            exit 1
            ;;
    esac
}

main "$@"
