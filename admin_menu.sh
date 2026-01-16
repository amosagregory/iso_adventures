#!/bin/bash

# A simple menu script for Ubuntu

# --- Colors ---
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
NC=$(tput sgr0) # No Color

# --- Functions ---

# Function to run the inventory script
run_inventory() {
    echo -e "${YELLOW}Running inventory script...${NC}"
    if [ -f ./inventory.sh ]; then
        sudo ./inventory.sh
        echo -e "${GREEN}Inventory script finished.${NC}"
        # The report is saved in /tmp, let's notify the user
        logfile=$(sudo ls -t /tmp/*-*-*.html 2>/dev/null | head -n 1)
        if [ -n "$logfile" ]; then
            echo "Report saved to: $logfile"
        fi
    else
        echo -e "${RED}inventory.sh not found!${NC}"
    fi
    echo -e "\nPress [Enter] to continue..."
    read
}

# Function to show system information
show_system_info() {
    echo -e "${YELLOW}--- System Information ---${NC}"
    echo -e "Hostname: $(hostname -f)"
    echo -e "Operating System: $(lsb_release -d | cut -f2-)"
    echo -e "Kernel: $(uname -r)"
    echo -e "Architecture: $(uname -m)"
    echo -e "Uptime: $(uptime -p)"
    echo -e "\n${YELLOW}--- CPU Information ---${NC}"
    lscpu | grep -E 'Model name|CPU(s)|Vendor ID'
    echo -e "\n${YELLOW}--- Memory Information ---${NC}"
    free -h
    echo -e "\nPress [Enter] to continue..."
    read
}

# Function to show disk usage
show_disk_usage() {
    echo -e "${YELLOW}--- Disk Usage ---${NC}"
    df -h
    echo -e "\nPress [Enter] to continue..."
    read
}

# --- Main Menu ---
while true; do
    clear
    echo -e "${BLUE}===============================${NC}"
    echo -e "${GREEN}      UBUNTU ADMIN MENU      ${NC}"
    echo -e "${BLUE}===============================${NC}"
    echo "1. Run Inventory Script"
    echo "2. Show System Information"
    echo "3. Show Disk Usage"
    echo "4. Exit"
    echo -e "${BLUE}-------------------------------"    echo -n "Enter your choice [1-4]: "
    read choice

    case $choice in
        1)
            run_inventory
            ;;
        2)
            show_system_info
            ;;
        3)
            show_disk_usage
            ;;
        4)
            echo -e "${YELLOW}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac
done
