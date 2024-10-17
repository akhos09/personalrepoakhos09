#!/bin/bash

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

# Comprobación de permisos
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root"
   exit 1
fi

# Función para instalar Alacritty sin actualizar
install_alacritty() {
    echo -e "\nInstalando Alacritty sin actualizar los paquetes..."

    # Instalación de dependencias
    sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev cargo\
    libxcb-xfixes0-dev libxkbcommon-dev python3 libglib2.0-dev cargo\
    libgdk-pixbuf2.0-dev libxi-dev libxrender-dev libxrandr-dev cargo\
    libxinerama-dev cargo

    # Instalación de Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env
    sudo apt install -y build-essential

    # Clonamos el repo y nos quedamos en el dir del repo.
    git clone https://github.com/alacritty/alacritty.git 2>/dev/null
    cd alacritty || { echo "No se pudo cambiar al directorio de Alacritty."; exit 1; }

    # Instalación con cargo
    cargo build --release

    if ! infocmp alacritty &> /dev/null; then
        sudo tic -xe alacritty,alacritty-direct extra/alacritty.info
    fi

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
    echo -e "\nSelector temas Alacritty:"
   # We use Alacritty's default Linux config directory as our storage location here.
    mkdir -p ~/.config/alacritty/themes
    git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

    echo -e "\nTemas disponibles y apariencia en el repositorio adjunto: https://github.com/alacritty/alacritty-theme"
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
