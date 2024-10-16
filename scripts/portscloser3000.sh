#!/bin/bash
#:Title: portscloser3000.sh
#:Date: 10/15/2024
#:Author: Pablo Fernández López
#:Version: 1.o
#:Description: Script to manage open ports on a Linux system, allowing the closure of all ports not specified.
#:Additionally, it allows saving the closed ports and associated processes, and offers the option to reopen them in future executions.
#:Usage:
#:     - By default, it closes all open ports except the vital ones: 53 (DNS), 80 (HTTP), and 443 (HTTPS).
#:     - Other ports can be added as arguments to keep them open.
#:     - Use the '--reopen' or '-r' option to reopen the ports closed during the previous execution of the script.
#:     - Requires root privileges.
#:Dependencies:
#:     - ss or netstat to list open ports.
#:     - lsof to identify processes using the ports.
#:     - iptables to block traffic on closed ports.
#:     - nc to open ports and test the functionality of the script.

# File where closed ports and processes used in the previous execution are saved
closed_ports_file="/var/log/closed_ports.log"

## Help message ##
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo -e "portscloser3000.sh (v1.0)\n\nUsage:\n1. To close ports not specified in the list (53, 80, 443) that are open, run without additional arguments.\n2. To reopen the ports and services closed in the last execution, use the --reopen or -r option.\n"
    exit 0
fi

# Permission check
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

# Default vital ports list
declare -a default_ports=("53" "80" "443")
declare -a allowed_ports=("${default_ports[@]}")

# If the user provides additional ports, add them to the allowed ports list
for arg in "$@"; do
    if [[ "$arg" =~ ^[0-9]+$ ]]; then  # Check if the argument is a number
        allowed_ports+=("$arg")
    elif [[ "$arg" == "--reopen" || "$arg" == "-r" ]]; then
        # Reopen previously closed ports
        if [[ -f "$closed_ports_file" ]]; then
            echo -e "\nReopening previously closed ports:\n"
            while IFS=',' read -r port process; do
                echo "Restarting process $process on port $port"
                if [[ "$process" == "nc" ]]; then
                    # If the process was 'nc' (netcat), restart it manually
                    nc -l "$port" &
                    if [[ $? -eq 0 ]]; then
                        echo "Port $port successfully reopened."
                    else
                        echo "Error trying to reopen port $port."
                    fi
                else
                    echo "Warning: Unable to recognize how to restart process $process for port $port."
                fi
            done < "$closed_ports_file"

            # Clear the file after reopening the ports
            > "$closed_ports_file"
        else
            echo "No previously closed ports to reopen."
        fi
        exit 0
    else
        echo "Warning: '$arg' is not a valid number and will be ignored."
    fi
done

# Show open ports before closing
echo -e "\nOpen ports before closure:\n"
ss -tuln | awk '/LISTEN/ {print $5}' | awk -F':' '{print $NF}' | sort -n | uniq
echo -e "\n"

# Close all open ports that are not vital
closed_ports=()  # List to store closed ports and associated processes
for port in $(ss -tuln | awk '/LISTEN/ {print $5}' | awk -F':' '{print $NF}' | sort -n | uniq); do
    if [[ ! " ${allowed_ports[@]} " =~ " ${port} " ]]; then
        echo -e "----------------------------------"
        echo -e "Closing port $port"
        echo -e "----------------------------------"
        # Kill the process using the port if it exists
        pid=$(lsof -t -i:$port)
        if [ -n "$pid" ]; then
            process=$(ps -p "$pid" -o comm=)
            echo "Port number $port, occupied by process $process, has been closed."
            { kill -9 $pid; } >/dev/null 2>&1
            closed_ports+=("$port,$process")
        fi
    else
        echo -e "----------------------------------"
        echo -e "Keeping port $port open"
        echo -e "----------------------------------"
    fi
done

# If ports were closed, save them to a file for future reopening
if [[ ${#closed_ports[@]} -gt 0 ]]; then
    echo -e "\nSaving closed ports to $closed_ports_file"
    printf "%s\n" "${closed_ports[@]}" > "$closed_ports_file"
fi

# Show open ports after closure
echo -e "\nOpen ports after closure:\n"
ss -tuln | awk '/LISTEN/ {print $5}' | awk -F':' '{print $NF}' | sort -n | uniq
echo -e "\nEnd of port management process (ignore):"
