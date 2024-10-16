#!/bin/bash
#:Title: cleanse.sh
#:Date: 10/10/2024
#:Author: Pablo Fernández López
#:Version: 1.0
#:Description: Script that creates a folder in the home directory acting as a recycle bin.
#:It can be used with files (but not directories) and contains two parameters for usage.
#:Options: -L (Lists all files in the recycle bin.)
#:Options: -R (Restores the specified file from the recycle bin.)

bin=/home/"$USER"/recycle_bin_of_"$USER"/  # Set the ENV for the recycle bin folder.
mkdir $bin 2>/dev/null                    # Creates the folder, suppressing error output if it already exists.

###DIRECTORY CHECKS AND HELP COMMAND###

if [[ -z "$1" || "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "cleanse (v1.0)\n\nUsage: limpiapablo.sh [OPTIONS] file\nOptions:\t-R (Restore the specified file)\n\t\t-L (List files in the recycle bin.)"
elif [[ -d "$3" || -d "$2" || -d "$1" ]]; then
    echo -e "cleanse (v1.0): A directory cannot be used.\nTry using a file or type limpiapablo.sh --help or -h for more information."

###FILE COMPRESSION AND MOVE TO RECYCLE BIN###

elif [[ -e "$3" && -f "$3" ]]; then
    tar -czf "$3".gz "$3"
    mv "$3".gz "$bin"
    rm -rf "$3"

elif [[ -e "$1" && -f "$1" ]]; then
    tar -czf "$1".gz "$1"
    mv "$1".gz "$bin"
    rm -rf "$1"

###PARAMETER BLOCK###OPTION_L_AND_OPTION_R_WITH_VARIATIONS###

elif [[ "$1" == "-L" || "$2" == "-L" ]]; then
    ls -l "$bin"

elif [[ "$1" == "-R" ]]; then
    if [[ -e "$bin$2" ]]; then
        mv "$bin$2" .
        gunzip "$2" 2>/dev/null
        echo -e "The file $2 has been restored to your current directory."
    else
        echo -e "The file $2 does not exist in the recycle bin."
    fi

elif [[ "$2" == "-R" ]]; then
    if [[ -e "$bin$3" ]]; then
        mv "$bin$3" .
        gunzip "$3" 2>/dev/null
        echo -e "The file $3 has been restored to your current directory."
    else
        echo -e "The file $3 does not exist in the recycle bin."
    fi

###HELP COMMAND OUTPUT###

else
    echo -e "cleanse (v1.0): Invalid command.\nTry using another file or type limpiapablo.sh --help or -h for more information."
fi
