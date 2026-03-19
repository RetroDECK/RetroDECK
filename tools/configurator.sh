# START THE CONFIGURATOR

if ! declare -F "configurator_welcome_dialog" > /dev/null; then
  log d "Configurator functions not loaded yet, sourcing..."
  source "/app/libexec/global.sh"
fi

configurator_navigation
log i "Configurator closing"
