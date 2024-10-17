#!/bin/bash

# Ping a Google DNS para comprobar la conectividad
if ping -c 1 8.8.8.8 &> /dev/null
then
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
    # Clonamos el repo y nos quedamos en el dir del repo.
    git clone https://github.com/alacritty/alacritty.git 2>/dev/null
    cd alacritty || { echo "No se pudo cambiar al directorio de Alacritty."; exit 1; }

    # Instalación de rustup (compiler rust y sus dependencias, establecemos cargo en el PATH)
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh 2>/dev/null
    source "$HOME/.cargo/env" || { echo "Error al configurar el entorno de Rust."; exit 1; }

    # Establecer la versión estable y actualizar
    rustup override set stable
    rustup update stable

    # Comprobar si cargo está disponible
    if ! command -v cargo &> /dev/null; then
        echo "Cargo no se pudo encontrar. Asegúrate de que Rust se haya instalado correctamente."
        exit 1
    fi

    # Instalación de dependencias
    sudo apt install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 2>/dev/null

    # Instalacion con cargo
    cargo build --release

    # Comprobar si el binario se generó
    if [[ ! -f target/release/alacritty ]]; then
        echo "Error: El binario 'alacritty' no se generó en target/release."
        exit 1
    fi

    # Comprobar si alacritty terminfo está instalado
    if infocmp alacritty &> /dev/null; then
        echo "La entrada de terminal 'alacritty' ya está instalada."
    else
        echo "La entrada de terminal 'alacritty' no está instalada. Instalando..."
        sudo tic -xe alacritty,alacritty-direct extra/alacritty.info

        if [ $? -eq 0 ]; then
            echo "La entrada de terminal 'alacritty' se ha instalado correctamente."
        else
            echo "Error: No se pudo instalar la entrada de terminal 'alacritty'."
        fi
    fi

    # Configuración final
    echo "source $(pwd)/extra/completions/alacritty.bash" >> ~/.bashrc
}

# Función para actualizar y luego instalar Alacritty
update_and_install_alacritty() {
    echo "Actualizando los paquetes e instalando Alacritty..."
    sudo apt update && sudo apt upgrade -y
}

# Función para cambiar el tema de Alacritty
change_alacritty_theme() {
    echo "Cambiando el tema de Alacritty..."
    # Aquí puedes agregar los comandos para cambiar el tema
    # Por ejemplo, copiar un archivo de configuración de tema
    cp /ruta/a/nuevo_tema/alacritty.yml ~/.config/alacritty/alacritty.yml
    echo "Tema de Alacritty cambiado exitosamente."
}

# Función para añadir un icono en el escritorio
icon_desktop_create() {
    sudo cp target/release/alacritty /usr/local/bin
    sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
    sudo desktop-file-install extra/linux/Alacritty.desktop
    sudo update-desktop-database
}

# Menú de selección
while true; do
    echo "Seleccione una opción:"
    echo "1) Instalar Alacritty sin comprobar las actualizaciones."
    echo "2) Actualizar paquetes y repositorios e instalar Alacritty."
    echo "3) Cambiar el tema de Alacritty."
    echo "4) Añadir un icono al escritorio."
    echo "5) Salir"
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
            icon_desktop_create
            ;;
        5)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            echo "Opción no válida, por favor intente nuevamente."
            ;;
    esac

    echo -e "\n"
done
