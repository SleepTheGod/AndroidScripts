#!/data/data/com.termux/files/usr/bin/bash

#===============================================================================
# Comprehensive Device Information Script
# For Motorola G Play - All System Details via Termux
#===============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

clear
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║     COMPREHENSIVE DEVICE INFORMATION SYSTEM v2.0              ║
║     Motorola Device Inspector - All System Details            ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if running in Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo -e "${RED}[!] This script must be run in Termux${NC}"
    exit 1
fi

# Function to get property safely
get_prop() {
    local result=$(getprop "$1" 2>/dev/null)
    if [ -z "$result" ]; then
        echo "Not Available"
    else
        echo "$result"
    fi
}

# Function to read file safely
read_file() {
    if [ -f "$1" ]; then
        cat "$1" 2>/dev/null || echo "Permission Denied"
    elif [ -d "$1" ]; then
        echo "Directory"
    else
        echo "Not Found"
    fi
}

# Function to create section headers
section_header() {
    echo -e "\n${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}${BOLD}$1${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
}

# Function for key-value display
kv_display() {
    printf "${GREEN}%-25s${NC} ${WHITE}:${NC} ${CYAN}%s${NC}\n" "$1" "$2"
}

#===================================
# SECTION 1: DEVICE IDENTITY
#===================================
section_header "📱 DEVICE IDENTITY & MODEL INFORMATION"

# Brand & Manufacturer
kv_display "Manufacturer" "$(get_prop ro.product.manufacturer)"
kv_display "Brand" "$(get_prop ro.product.brand)"
kv_display "Model" "$(get_prop ro.product.model)"
kv_display "Device Name" "$(get_prop ro.product.name)"
kv_display "Market Name" "$(get_prop ro.product.marketname)"
kv_display "Device Code" "$(get_prop ro.product.device)"
kv_display "Board Platform" "$(get_prop ro.board.platform)"

#===================================
# SECTION 2: FIRMWARE & BUILD
#===================================
section_header "🔧 FIRMWARE & BUILD INFORMATION"

# Android Version
kv_display "Android Version" "$(get_prop ro.build.version.release)"
kv_display "SDK Level" "$(get_prop ro.build.version.sdk)"
kv_display "Build ID" "$(get_prop ro.build.id)"
kv_display "Build Number" "$(get_prop ro.build.display.id)"
kv_display "Build Date" "$(get_prop ro.build.date)"
kv_display "Build Type" "$(get_prop ro.build.type)"
kv_display "Build Tags" "$(get_prop ro.build.tags)"

# Motorola Specific
kv_display "Moto Build Version" "$(get_prop ro.mot.build.version.release)"
kv_display "Moto Build Number" "$(get_prop ro.mot.build.version.sdk)"
kv_display "Software Channel" "$(get_prop ro.mot.build.customerid)"
kv_display "Software Version" "$(get_prop ro.mot.build.version.incremental)"

# Firmware specific
kv_display "Baseband Version" "$(get_prop gsm.version.baseband)"
kv_display "Bootloader Version" "$(get_prop ro.bootloader)"
kv_display "Radio Version" "$(get_prop ro.boot.radio)"

#===================================
# SECTION 3: HARDWARE SPECS
#===================================
section_header "💻 HARDWARE SPECIFICATIONS"

# CPU Information
CPU_MODEL=$(cat /proc/cpuinfo 2>/dev/null | grep "Hardware" | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(cat /proc/cpuinfo 2>/dev/null | grep "processor" | wc -l)
CPU_ARCH=$(get_prop ro.product.cpu.abi)
CPU_MAX_FREQ=""

# Try to get CPU frequency
for cpu in /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq; do
    if [ -f "$cpu" ]; then
        FREQ=$(cat $cpu 2>/dev/null)
        CPU_MAX_FREQ="$((FREQ / 1000)) MHz"
    fi
done

kv_display "CPU Model" "${CPU_MODEL:-Unknown}"
kv_display "CPU Architecture" "$(get_prop ro.product.cpu.abi)"
kv_display "CPU Cores" "$CPU_CORES"
kv_display "CPU Max Frequency" "${CPU_MAX_FREQ:-Not Available}"
kv_display "CPU ABI2" "$(get_prop ro.product.cpu.abi2)"
kv_display "CPU 64-bit Support" "$(get_prop ro.product.cpu.abilist64)"

# GPU Information
kv_display "GPU Renderer" "$(get_prop ro.hardware.egl)"
kv_display "GPU Vendor" "$(get_prop ro.hardware.vulkan)"

# Display
kv_display "Screen Density (DPI)" "$(get_prop ro.sf.lcd_density)"
kv_display "Screen Resolution" "$(wm size 2>/dev/null | cut -d: -f2 | xargs)"
kv_display "Display Density" "$(wm density 2>/dev/null | cut -d: -f2 | xargs)"

#===================================
# SECTION 4: MEMORY & STORAGE
#===================================
section_header "💾 MEMORY & STORAGE INFORMATION"

# RAM Information
TOTAL_RAM=$(free -h 2>/dev/null | grep "Mem:" | awk '{print $2}')
USED_RAM=$(free -h 2>/dev/null | grep "Mem:" | awk '{print $3}')
FREE_RAM=$(free -h 2>/dev/null | grep "Mem:" | awk '{print $4}')
SWAP_TOTAL=$(free -h 2>/dev/null | grep "Swap:" | awk '{print $2}')
SWAP_USED=$(free -h 2>/dev/null | grep "Swap:" | awk '{print $3}')

kv_display "Total RAM" "$TOTAL_RAM"
kv_display "Used RAM" "$USED_RAM"
kv_display "Free RAM" "$FREE_RAM"
kv_display "Swap Total" "${SWAP_TOTAL:-None}"
kv_display "Swap Used" "${SWAP_USED:-None}"

# Detailed RAM from /proc/meminfo
if [ -f /proc/meminfo ]; then
    MEM_TOTAL=$(grep "MemTotal" /proc/meminfo | awk '{print $2}')
    MEM_FREE=$(grep "MemFree" /proc/meminfo | awk '{print $2}')
    MEM_AVAILABLE=$(grep "MemAvailable" /proc/meminfo | awk '{print $2}')
    
    if [ ! -z "$MEM_TOTAL" ]; then
        kv_display "RAM (KB)" "$MEM_TOTAL"
        kv_display "RAM Free (KB)" "$MEM_FREE"
        kv_display "RAM Available (KB)" "$MEM_AVAILABLE"
    fi
fi

# Storage Information
echo -e "\n${CYAN}Storage Details:${NC}"
df -h /data /system /cache 2>/dev/null | grep -v "Filesystem" | while read line; do
    FS=$(echo $line | awk '{print $1}')
    SIZE=$(echo $line | awk '{print $2}')
    USED=$(echo $line | awk '{print $3}')
    AVAIL=$(echo $line | awk '{print $4}')
    MOUNT=$(echo $line | awk '{print $6}')
    printf "  ${GREEN}%-15s${NC} ${WHITE}-${NC} ${CYAN}Size: %-6s  Used: %-6s  Free: %-6s  Mount: %s${NC}\n" "$FS" "$SIZE" "$USED" "$AVAIL" "$MOUNT"
done

#===================================
# SECTION 5: BOOTLOADER & SECURITY
#===================================
section_header "🔒 BOOTLOADER & SECURITY STATUS"

# Bootloader Information
kv_display "Bootloader State" "$(get_prop ro.boot.flash.locked)"
kv_display "Bootloader Version" "$(get_prop ro.bootloader)"
kv_display "Secure Boot" "$(get_prop ro.boot.secureboot)"
kv_display "Verified Boot" "$(get_prop ro.boot.verifiedbootstate)"
kv_display "OEM Unlock Allowed" "$(get_prop sys.oem_unlock_allowed)"
kv_display "FRP Partition" "$(get_prop ro.frp.pst)"

# SELinux Status
SELINUX_MODE=$(getenforce 2>/dev/null)
kv_display "SELinux Status" "${SELINUX_MODE:-Unknown}"

# Root Status
ROOT_STATUS="Not Rooted"
[ "$(id -u)" = "0" ] && ROOT_STATUS="ROOTED"
kv_display "Root Status" "$ROOT_STATUS"

# Security Patch Level
kv_display "Security Patch" "$(get_prop ro.build.version.security_patch)"

# Encryption Status
CRYPTO_STATE=$(get_prop ro.crypto.state)
kv_display "Encryption State" "${CRYPTO_STATE:-Unknown}"

#===================================
# SECTION 6: KERNEL & SYSTEM
#===================================
section_header "🐧 KERNEL & SYSTEM INFORMATION"

# Kernel Details
KERNEL_VERSION=$(cat /proc/version 2>/dev/null)
KERNEL_RELEASE=$(uname -r 2>/dev/null)
kv_display "Kernel Release" "$KERNEL_RELEASE"
kv_display "Kernel Version" "$(echo $KERNEL_VERSION | cut -d' ' -f1-4)"

# Check if specific kernel features exist
[ -f /proc/config.gz ] && kv_display "Kernel Config" "Available" || kv_display "Kernel Config" "Not Available"

# System Uptime
UPTIME=$(cat /proc/uptime 2>/dev/null | awk '{print $1}')
UPTIME_DAYS=$((UPTIME / 86400))
UPTIME_HOURS=$(( (UPTIME % 86400) / 3600 ))
UPTIME_MINUTES=$(( (UPTIME % 3600) / 60 ))
kv_display "System Uptime" "${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MINUTES}m"

#===================================
# SECTION 7: PARTITION LAYOUT
#===================================
section_header "💿 PARTITION LAYOUT"

# List all partitions
echo -e "${CYAN}Block Device Information:${NC}"
ls -la /dev/block/by-name/ 2>/dev/null | grep -v "total" | while read line; do
    PART=$(echo $line | awk '{print $9}')
    LINK=$(echo $line | awk '{print $11}')
    printf "  ${GREEN}%-20s${NC} ${WHITE}->${NC} ${CYAN}%s${NC}\n" "$PART" "$LINK"
done

# If by-name not available, try /proc/partitions
if [ ! -d /dev/block/by-name ]; then
    echo -e "${YELLOW}Partition list from /proc/partitions:${NC}"
    cat /proc/partitions 2>/dev/null | while read major minor blocks name; do
        if [ "$blocks" != "blocks" ] && [ ! -z "$name" ]; then
            SIZE_MB=$((blocks / 2048))
            printf "  ${GREEN}%-15s${NC} ${WHITE}-${NC} ${CYAN}%s MB${NC}\n" "$name" "$SIZE_MB"
        fi
    done
fi

#===================================
# SECTION 8: NETWORK & RADIO
#===================================
section_header "📡 NETWORK & RADIO INFORMATION"

# WiFi & Mobile Network
kv_display "WiFi Interface" "$(get_prop wifi.interface)"
kv_display "Mobile Interface" "$(get_prop ro.telephony.default_network)"
kv_display "RIL Class" "$(get_prop ro.telephony.ril_class)"
kv_display "Network Mode" "$(get_prop ro.telephony.default_network)"

# Carrier Information
kv_display "SIM Operator" "$(get_prop gsm.sim.operator.alpha)"
kv_display "Network Operator" "$(get_prop gsm.operator.alpha)"
kv_display "SIM Country" "$(get_prop gsm.sim.operator.iso-country)"

# IMEI & Serial (Masked for security)
IMEI=$(service call iphonesubinfo 1 2>/dev/null | cut -c 52-66 | tr -d '.[:space:]')
[ ! -z "$IMEI" ] && kv_display "IMEI" "${IMEI:0:6}*****${IMEI: -4}" || kv_display "IMEI" "Not Accessible"

#===================================
# SECTION 9: SENSORS & HARDWARE
#===================================
section_header "🔬 SENSORS & HARDWARE COMPONENTS"

# Check for hardware features
FEATURES=""
for feature in $(pm list features 2>/dev/null | cut -d: -f2); do
    FEATURES="$FEATURES $feature"
done

echo -e "${CYAN}Available Hardware Features:${NC}"
echo "$FEATURES" | tr ' ' '\n' | grep -E "sensor|camera|gps|nfc|fingerprint|bluetooth|wifi" | while read feature; do
    printf "  ${GREEN}●${NC} %s\n" "$feature"
done

#===================================
# SECTION 10: RUNNING SERVICES & PROCESSES
#===================================
section_header "⚙️ SYSTEM SERVICES & PROCESSES"

# Count running processes
PROC_COUNT=$(ps aux 2>/dev/null | wc -l)
kv_display "Total Processes" "$PROC_COUNT"

# Top memory using processes
echo -e "\n${CYAN}Top 10 Memory-Using Processes:${NC}"
ps aux 2>/dev/null | sort -rnk 4 | head -10 | while read user pid cpu mem vsz rss tty stat start time cmd; do
    printf "  ${GREEN}%-5s${NC} ${WHITE}%-6s${NC} ${CYAN}%-30s${NC}\n" "$pid" "${mem}%" "${cmd:0:30}"
done

#===================================
# SECTION 11: BUILD PROPERTIES EXPORT
#===================================
section_header "📋 FULL BUILD PROPERTIES"

echo -e "${YELLOW}[*] Complete build.prop saved to: $HOME/device_info_$(date +%Y%m%d_%H%M%S).txt${NC}"
echo -e "${YELLOW}[*] Reading all properties...${NC}"

OUTPUT_FILE="$HOME/device_info_$(date +%Y%m%d_%H%M%S).txt"

{
    echo "========================================="
    echo "  COMPREHENSIVE DEVICE INFORMATION REPORT"
    echo "  Generated: $(date)"
    echo "  Device: $(get_prop ro.product.model)"
    echo "========================================="
    echo ""
    getprop
} > "$OUTPUT_FILE"

echo -e "${GREEN}[✓] Full device properties exported to $OUTPUT_FILE${NC}"

#===================================
# FINAL SUMMARY
#===================================
section_header "📊 DEVICE SUMMARY"

echo -e "${BOLD}Motorola G Play Quick Overview:${NC}"
echo -e "  ${CYAN}Device:${NC}    $(get_prop ro.product.model)"
echo -e "  ${CYAN}Android:${NC}   $(get_prop ro.build.version.release) (SDK $(get_prop ro.build.version.sdk))"
echo -e "  ${CYAN}Build:${NC}     $(get_prop ro.build.display.id)"
echo -e "  ${CYAN}Security:${NC}  $(get_prop ro.build.version.security_patch)"
echo -e "  ${CYAN}Bootloader:${NC} $(get_prop ro.bootloader)"
echo -e "  ${CYAN}RAM:${NC}       ${TOTAL_RAM:-Unknown}"
echo -e "  ${CYAN}CPU:${NC}       ${CPU_MODEL:-Unknown} ($CPU_CORES cores)"
echo -e "  ${CYAN}Storage:${NC}   $(df -h /data 2>/dev/null | tail -1 | awk '{print $2}')"
echo -e "  ${CYAN}Root:${NC}      ${ROOT_STATUS}"
echo -e "  ${CYAN}SELinux:${NC}   ${SELINUX_MODE:-Unknown}"

echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Device Information Collection Complete!                  ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo -e "\n${YELLOW}All details saved to: $OUTPUT_FILE${NC}"
echo -e "${YELLOW}Run 'cat $OUTPUT_FILE' to view full report${NC}\n"
