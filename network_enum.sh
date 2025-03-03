#!/bin/bash
# network_enum.sh - Network Service Enumeration Script using Nmap

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Default values
TARGET=""
SCAN_TYPE="default"
OUTPUT_FILE="nmap_scan_$(date +%Y%m%d_%H%M%S)"
VERBOSE=false

# Display help
show_help() {
    echo "Usage: $0 -t TARGET [options]"
    echo ""
    echo "Options:"
    echo "  -t TARGET    Target IP, range (e.g., 192.168.1.0/24) or hostname (required)"
    echo "  -s SCAN_TYPE Type of scan: default, quick, full, vuln, services (default: default)"
    echo "  -o FILE      Output filename prefix (default: nmap_scan_TIMESTAMP)"
    echo "  -v           Verbose output"
    echo "  -h           Display this help"
    exit 0
}

# Parse command line arguments
while getopts "t:s:o:vh" opt; do
    case $opt in
        t) TARGET="$OPTARG" ;;
        s) SCAN_TYPE="$OPTARG" ;;
        o) OUTPUT_FILE="$OPTARG" ;;
        v) VERBOSE=true ;;
        h) show_help ;;
        *) show_help ;;
    esac
done

# Check if target is specified
if [ -z "$TARGET" ]; then
    echo "Error: Target is required"
    show_help
fi

echo "===== Network Service Enumeration Script ====="
echo "Target: $TARGET"
echo "Scan Type: $SCAN_TYPE"
echo "Output File: $OUTPUT_FILE"
echo "=========================================="

# Function to run scan
run_scan() {
    local scan_cmd="$1"
    local file_suffix="$2"
    
    echo "[+] Running scan: $scan_cmd"
    eval "$scan_cmd"
    echo "[+] Scan completed. Results saved to ${OUTPUT_FILE}${file_suffix}"
    echo ""
}

# Create output directory if it doesn't exist
mkdir -p "nmap_scans"
cd "nmap_scans" || exit

# Run different scan types based on selection
case $SCAN_TYPE in
    "quick")
        # Quick scan - checks most common ports
        run_scan "nmap -F -sV --version-intensity 0 -oA \"${OUTPUT_FILE}_quick\" $TARGET" "_quick"
        ;;
        
    "full")
        # Full scan - comprehensive scan of all ports with service detection
        run_scan "nmap -p- -sS -sV -sC -O --osscan-guess -oA \"${OUTPUT_FILE}_full\" $TARGET" "_full"
        ;;
        
    "vuln")
        # Vulnerability scan - checks for known vulnerabilities
        run_scan "nmap -sV --script=vuln -oA \"${OUTPUT_FILE}_vuln\" $TARGET" "_vuln"
        ;;
        
    "services")
        # Detailed service enumeration
        run_scan "nmap -sV -sC --version-all -oA \"${OUTPUT_FILE}_services\" $TARGET" "_services"
        ;;
        
    *)
        # Default scan - balanced between speed and thoroughness
        echo "[+] Running default service enumeration scan"
        nmap -sV -sS -A -oA "${OUTPUT_FILE}_default" "$TARGET"
        echo "[+] Default scan completed. Results saved to ${OUTPUT_FILE}_default"
        ;;
esac

# If verbose, display summary of results
if [ "$VERBOSE" = true ]; then
    echo "[+] Scan Summary:"
    echo "----------------------------------------"
    grep -E "^[0-9]+/(tcp|udp)" "${OUTPUT_FILE}"*".nmap" | sort -n
    echo "----------------------------------------"
    echo "[+] Open ports summary:"
    grep -E "^[0-9]+/(tcp|udp).*open" "${OUTPUT_FILE}"*".nmap" | sort -n
fi

echo "[+] All scans completed!"
echo "[+] Results can be found in the nmap_scans directory"