change_alacritty_theme() {
    echo "Cambiando el tema de Alacritty..."
    # Aquí puedes agregar los comandos para cambiar el tema
    # Por ejemplo, copiar un archivo de configuración de tema
    cp /ruta/a/nuevo_tema/alacritty.yml ~/.config/alacritty/alacritty.yml
    echo "Tema de Alacritty cambiado exitosamente."
}

# Menú de selección
while true; do
    echo "Seleccione una opción:"
    echo "1) Instalar Alacritty sin comprobar las actualizaciones."
    echo "2) Actualizar paquetes y repositorios e instalar Alacritty."
    echo "3) Cambiar el tema de Alacritty."
    echo "4) Salir"
    read -p "Ingrese su opción (1-5): " option

    case $option in
        1)
            install_alacritty
            ;;
        2)
            update_and_install_alacritty
            ;;
        3)
            change_alacritty_theme
            ;;
        4)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción no válida, por favor intente nuevamente."
            ;;
    esac

    echo -e "\n"
done
