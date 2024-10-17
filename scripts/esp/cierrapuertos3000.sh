#!/bin/bash
#:Título: cierrapuertos3000.sh
#:Fecha: 15/10/2024
#:Autor: Pablo Fernández López
#:Version: 1.0
#:Descripción:Script que Gestiona los puertos abiertos en un sistema Linux, permitiendo cerrar todos los puertos no especificados.
#:Además, permite guardar los puertos cerrados y los procesos asociados, y ofrece la opción de reabrirlos en futuras ejecuciones.
#:Uso:
#:     - Por defecto, cierra todos los puertos abiertos excepto los vitales: 53 (DNS), 80 (HTTP), y 443 (HTTPS).
#:     - Se pueden añadir otros puertos como argumentos para mantenerlos abiertos.
#:     - Usa la opción '--reopen' o '-r' para reabrir los puertos cerrados en la ejecución anterior del script.
#:     - Requiere privilegios de root.
#:Dependencias:
#:     - ss o netstat para listar puertos abiertos.
#:     - lsof para identificar procesos en uso en los puertos.
#:     - iptables para bloquear el tráfico en los puertos cerrados.
#:     - nc para abrir puertos y testear el funcionamiento del script.

# Archivo donde se guardan los procesos cerrados y los puertos usados en la ejecución anterior
closed_ports_file="/var/log/puertos_cerrados.log"

## Mensaje de ayuda ##
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "cierrapuertos3000 (v1.0)\n\nUso:\n1. Para cerrar puertos no especificados en la lista (53, 80, 443) que estén abiertos, ejecutar sin argumentos adicionales.\n2. Para reabrir los puertos y servicios cerrados en la última ejecución, usar la opción --reopen o -r.\n"
    exit 0
fi

# Comprobación de permisos
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ser ejecutado como root"
   exit 1
fi

# Lista de puertos vitales por defecto
declare -a default_ports=("53" "80" "443")
declare -a allowed_ports=("${default_ports[@]}")

# Si el usuario pasa puertos adicionales, añadirlos a la lista de puertos permitidos
for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then  # Verifica que el argumento sea un número
        allowed_ports+=("$arg")
    elif [[ "$arg" == "--reopen" || "$arg" == "-r" ]]; then
        # Reabrir los puertos cerrados previamente
        if [[ -f "$closed_ports_file" ]]; then
            echo -e "\nReabriendo los puertos cerrados previamente:\n"
            while IFS=',' read -r port process; do
                echo "Reiniciando proceso $process en el puerto $port"
                if [[ "$process" == "nc" ]]; then
                    # Si el proceso era 'nc' (netcat), reiniciarlo manualmente
                    nc -l "$port" &
                    if [[ $? -eq 0 ]]; then
                        echo "Puerto $port reabierto con éxito"
                    else
                        echo "Error al intentar reabrir el puerto $port."
                    fi
                else
                    echo "Advertencia: No se reconoce cómo reiniciar el proceso $process para el puerto $port."
                fi
            done < "$closed_ports_file"

            # Limpiar el archivo después de reabrir los puertos
            > "$closed_ports_file"
        else
            echo "No hay puertos previamente cerrados para reabrir."
        fi
        exit 0
    else
        echo "Advertencia: '$arg' no es un número válido y será ignorado."
    fi
done


# Mostrar puertos abiertos antes de cerrar
echo -e "\nPuertos abiertos antes del cierre:\n"
ss -tuln | awk '/LISTEN/ {print $5}' | awk -F':' '{print $NF}' | sort -n | uniq
echo -e "\n"
# Cerrar todos los puertos abiertos que no sean los vitales
closed_ports=()  # Lista para almacenar los puertos y procesos que serán cerrados
for port in $(ss -tuln | awk '/LISTEN/ {print $5}' | awk -F':' '{print $NF}' | sort -n | uniq); do
    if [[ ! " ${allowed_ports[@]} " =~ " ${port} " ]]; then
        echo -e "----------------------------------"
        echo -e "Cerrando puerto $port"
        echo -e "----------------------------------"
        # Termina el proceso que está utilizando el puerto si existe
        pid=$(lsof -t -i:$port)
        if [ -n "$pid" ]; then
            process=$(ps -p "$pid" -o comm=)
            echo "El puerto número $port, ocupado por el proceso $process, ha sido cerrado."
            { kill -9 $pid; } >/dev/null 2>&1
            closed_ports+=("$port,$process")
        fi
    else
        echo -e "----------------------------------"
        echo -e "Manteniendo puerto $port abierto"
        echo -e "----------------------------------"
    fi
done


# Si se cerraron puertos, guardarlos en un archivo para futuras reaperturas
if [[ ${#closed_ports[@]} -gt 0 ]]; then
    echo -e "\nGuardando los puertos cerrados en $closed_ports_file"
    printf "%s\n" "${closed_ports[@]}" > "$closed_ports_file"
fi

# Mostrar los puertos abiertos después del cierre
echo -e "\nPuertos abiertos después del cierre:\n"
ss -tuln | awk '/LISTEN/ {print $5}' | awk -F':' '{print $NF}' | sort -n | uniq
echo -e "\nMensaje de final del proceso de puertos (ignorar):"
