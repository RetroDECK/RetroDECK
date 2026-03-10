# START THE CONFIGURATOR

if ! declare -F "configurator_welcome_dialog" > /dev/null; then
  log d "Configurator functions not loaded yet, sourcing..."
  source "/app/libexec/global.sh"
fi

# Show loading screen
(
  echo "0"
  echo "# Loading RetroDECK Configurator..."
  sleep 2  # Simulate a brief delay for the loading screen
  echo "100"
) 

rd_zenity --progress --no-cancel --pulsate --auto-close \
  --title="RetroDECK Configurator" \
  --text="Starting RetroDECK Configurator" \
  --width=400 --height=100 &

configurator_navigation
log i "Configurator closing"
