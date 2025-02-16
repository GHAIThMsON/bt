#!/bin/bash

# Deep Web Enumeration Automation
# Usage: ./deep_web_enum.sh <target>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <target>"
    exit 1
fi

TARGET=$1
OUTPUT_FILE="web_enum_report_$(date +%Y%m%d_%H%M%S).txt"

echo "==============================================" | tee -a $OUTPUT_FILE
echo "[+] Target: $TARGET" | tee -a $OUTPUT_FILE
echo "==============================================" | tee -a $OUTPUT_FILE

# 1. Subdomain Enumeration
echo "[*] Enumerating subdomains..." | tee -a $OUTPUT_FILE
subdomains=$(curl -s "https://crt.sh/?q=%25.$TARGET&output=json" | jq -r '.[].name_value' | sort -u)
echo "$subdomains" | tee -a $OUTPUT_FILE
amass enum -d $TARGET -o amass_subs.txt
cat amass_subs.txt | tee -a $OUTPUT_FILE

# 2. Port Scanning
echo "[*] Scanning ports..." | tee -a $OUTPUT_FILE
nmap -p- --min-rate=1000 -T4 -Pn $TARGET -oN nmap_scan.txt
cat nmap_scan.txt | tee -a $OUTPUT_FILE

# 3. Web Technology Detection
echo "[*] Detecting web technologies..." | tee -a $OUTPUT_FILE
whatweb $TARGET --log-verbose=whatweb.txt
cat whatweb.txt | tee -a $OUTPUT_FILE

# 4. Hidden Directories & API Discovery
echo "[*] Brute-forcing directories and APIs..." | tee -a $OUTPUT_FILE
gobuster dir -u http://$TARGET -w /usr/share/wordlists/dirb/common.txt -o gobuster.txt
cat gobuster.txt | tee -a $OUTPUT_FILE

# 5. Extracting Parameters & Endpoints
echo "[*] Extracting parameters and hidden endpoints..." | tee -a $OUTPUT_FILE
echo $TARGET | waybackurls | tee -a wayback.txt
cat wayback.txt | tee -a $OUTPUT_FILE

# 6. Basic Vulnerability Scan (Nikto)
echo "[*] Running Nikto scan..." | tee -a $OUTPUT_FILE
nikto -h http://$TARGET -o nikto.txt
cat nikto.txt | tee -a $OUTPUT_FILE

echo "==============================================" | tee -a $OUTPUT_FILE
echo "[+] Enumeration complete. Full report saved as $OUTPUT_FILE" | tee -a $OUTPUT_FILE
