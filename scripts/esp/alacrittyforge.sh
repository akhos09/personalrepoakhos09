#!/bin/bash
#:Título: alacrittyforge.sh
#:Versión: 1.0
#:Autor: Pablo Fernández López
#:Fecha: 17/10/2024
#:Descripción: Script para gestionar la instalación y configuración de Alacritty, 
# un emulador de terminal. Permite instalar Alacritty, actualizar paquetes, y cambiar 
# el tema de la terminal mediante un menú interactivo.
#:Uso:
#:        - Opción 1): Instala Alacritty sin actualizar los paquetes.
#:        - Opción 2): Actualiza los paquetes y después instala Alacritty.
#:        - Opción 3): Permite cambiar el tema de Alacritty poniendo el nombre del tema (de los disponibles en el repo alacritty/themes) de manera instantánea.
#:Dependencias:
#:        - "CMake", "Pkg-config", "libfreetype6-dev", "libfontconfig1-dev", "Cargo", "libxcb-xfixes0-dev"
#:        - "libxkbcommon-dev", "Python3", "libglib2.0-dev", "libgdk-pixbuf2.0-dev", "libxi-dev", "libxrender-dev", "libxrandr-dev", "libxinerama-dev"
#:Créditos: @chrisduerr y @kchibisov creadores de Alacritty.


# Comprobación de conectividad
if ping -c 1 8.8.8.8 &> /dev/null; then
    # Si hay conexión, mostrar "AlacrittyForge" en ASCII
    echo -e "\n-----------------------------------------------------------------------------------------------------------------"
    echo -e "-----------------------------------------------------------------------------------------------------------------\n"
    echo "  █████╗ ██╗      █████╗  ██████╗██████╗ ██╗████████╗████████╗██╗   ██╗███████╗ ██████╗ ██████╗  ██████╗ ███████╗"
    echo " ██╔══██╗██║     ██╔══██╗██╔════╝██╔══██╗██║╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝"
    echo " ███████║██║     ███████║██║     ██████╔╝██║   ██║      ██║    ╚████╔╝ █████╗  ██║   ██║██████╔╝██║  ███╗█████╗"
    echo " ██╔══██║██║     ██╔══██║██║     ██╔══██╗██║   ██║      ██║     ╚██╔╝  ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝"
    echo " ██║  ██║███████╗██║  ██║╚██████╗██║  ██║██║   ██║      ██║      ██║   ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗"
    echo " ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝      ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
    echo -e "\n-----------------------------------------------------------------------------------------------------------------"
    echo -e "-----------------------------------------------------------------------------------------------------------------\n"
else
    echo "No hay conexión a Internet. Revise la configuración del adaptador y vuelva a ejecutar el script."
    exit 1  # Salir del script si no hay conexión
fi


# Función para instalar Alacritty sin actualizar
install_alacritty() {
    echo -e "\nInstalando Alacritty sin actualizar los paquetes..."

    # Instalación de dependencias
    sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev cargo \
    libxcb-xfixes0-dev libxkbcommon-dev python3 libglib2.0-dev \
    libgdk-pixbuf2.0-dev libxi-dev libxrender-dev libxrandr-dev libxinerama-dev

    # Instalación de Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
    sudo apt install -y build-essential

    # Clonamos el repositorio y nos quedamos en el directorio del repositorio
    git clone https://github.com/alacritty/alacritty.git 2>/dev/null
    cd alacritty || { echo "No se pudo cambiar al directorio de Alacritty."; exit 1; }

    # Instalación con cargo
    cargo build --release

    # Creación de icono en la GUI
    sudo cp target/release/alacritty /usr/local/bin 
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
}


# Función para actualizar y luego instalar Alacritty
update_and_install_alacritty() {
    echo "Actualizando los paquetes e instalando Alacritty..."
    sudo apt update && sudo apt upgrade -y
    install_alacritty
}


# Función para cambiar el tema de Alacritty
change_alacritty_theme() {
    echo -e "\nSelector de temas Alacritty:"
    # Usamos el directorio de configuración predeterminado de Linux para almacenar los temas
    mkdir -p ~/.config/alacritty/themes 2>/dev/null
    git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

    echo -e "\nTemas disponibles y apariencia en el repositorio adjunto: https://github.com/alacritty/alacritty-theme"

    # Solicitar al usuario que ingrese el nombre del tema
    read -p "Ingrese el nombre del tema de Alacritty (ej. aura, blood_moon, gruvbox_dark): " theme

    # Verificar que el directorio y archivo del tema existen
    theme_file="$HOME/.config/alacritty/themes/themes/${theme}.toml"
    if [[ -f "$theme_file" ]]; then
        # Archivo de configuración de Alacritty
        config_file="$HOME/.config/alacritty/alacritty.toml"

        # Crear la línea de importación en el formato correcto
        new_import_line="import = [\"$theme_file\"]"

        # Verificar si la sección de importaciones ya existe
        if grep -q "^import =" "$config_file"; then
            # Reemplazar la línea existente de importación
            sed -i "s|^import = .*|$new_import_line|" "$config_file"
            echo "Tema '$theme' reemplazado exitosamente en la configuración."
        else
            # Si no existe, agregar la nueva línea de importación
            echo -e "$new_import_line\n" >> "$config_file"
            echo "Tema '$theme' agregado exitosamente a la configuración."
        fi

        # Migra el archivo para hacer instantáneo el cambio de temas
        echo "Iniciando Alacritty con el tema '$theme'..."
        alacritty migrate
    else
        echo "El tema '$theme' no existe. Por favor, asegúrate de que el archivo ${theme}.toml esté en la carpeta ~/.config/alacritty/themes/themes/"
        exit 1
    fi
}


# Menú de selección
while true; do
    echo "Seleccione una opción:"
    echo "1) Instalar Alacritty sin comprobar las actualizaciones."
    echo "2) Actualizar paquetes y repositorios e instalar Alacritty."
    echo "3) Cambiar el tema de Alacritty."
    echo "4) Salir"

    read -p "Ingrese su opción (1-4): " option

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
