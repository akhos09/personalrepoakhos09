#!/bin/bash
#:Título: donlimpio.sh
#:Fecha: 10/10/2024
#:Autor: Pablo Fernández López
#:Version: 1.0
#:Descripción: Script que genera una carpeta en el directorio personal que actúa como papelera de reciclaje.
#:Se puede usar con ficheros y no directorios, y contiene dos parámetros para su uso.
#:Options: -L (Lista todos los ficheros de la papelera de reciclaje.)
#:Options: -R (Restaura el fichero especificado de la papelera de reciclaje.)

bin=/home/"$USER"/papelera_reciclaje_de_"$USER"/  #Establecemos la ENV para la carpeta de la papelera.
mkdir $bin 2>/dev/null                         #Crea la carpeta y si ya fue creada no muestra el output del error.

###COMPROBACIONES DE DIRECTORIO Y COMANDO AYUDA###

if [[ -z "$1" || "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "limpiapablo (v1.0)\n\nUso: limpiapablo.sh [OPCIONES] archivo\nOpciones:\t-R (Restaura el archivo especificado)\n\t\t-L (Lista los archivos de la papelera de reciclaje.)"
elif [[ -d "$3" || -d "$2" || -d "$1" ]]; then
    echo -e "limpiapablo (v1.0): No se puede introducir un directorio.\nIntenta usar un archivo o escribe limpiapablo.sh --help o -h para más información."

###PROCESO_DE_COMPRESIÓN_DE_ARCHIVO_SELECCIONADO_Y_ENVÍO_A_PAPELERA###

elif [[ -e "$3" && -f "$3" ]]; then
    tar -czf "$3".gz "$3"
    mv "$3".gz "$bin"
    rm -rf "$3"

elif [[ -e "$1" && -f "$1" ]]; then
    tar -czf "$1".gz "$1"
    mv "$1".gz "$bin"
    rm -rf "$1"

###BLOQUE_DE_PARÁMETROS###OPCIÓN_L_Y_OPCIÓN_R_CON_DIFERENTES_VARIANTES###

elif [[ "$1" == "-L" || "$2" == "-L" ]]; then
    ls -l "$bin"

elif [[ "$1" == "-R" ]]; then
    if [[ -e "$bin$2" ]]; then
    	mv "$bin$2" .
    	gunzip "$2" 2>/dev/null
    	echo -e "El archivo $2 ha sido restaurado en tu directorio actual."
    else
    	echo -e "El archivo $2 no existe en la papelera de reciclaje."
    fi

elif [[ "$2" == "-R" ]]; then
    if [[ -e "$bin$3" ]]; then
        mv "$bin$3" .
        gunzip "$3" 2>/dev/null
        echo -e "El archivo $3 ha sido restaurado en tu directorio actual."
    else
    	echo -e "El archivo $3 no existe en la papelera de reciclaje."
    fi

###OUTPUT_DE_AYUDA###

else
    echo -e "limpiapablo (v1.0): Comando mal introducido.\nPrueba a usar otro archivo o escribe limpiapablo.sh --help o -h para más información."
fi
