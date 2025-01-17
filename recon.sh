#!/bin/bash

# Check if domain is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

# Check if required tools are installed
for tool in dnsx httpx feroxbuster nmap amass; do
  if ! command -v $tool &> /dev/null; then
    echo "Error: $tool is not installed."
    exit 1
  fi
done

DOMAIN=$1

mkdir $DOMAIN

cd $DOMAIN

echo "[*] Discovering subdomains for $DOMAIN using subfinder and assetfinder..."
subfinder -d $DOMAIN -all-recursive -t 200 > subfinder.txt


assetfinder --subs-only $DOMAIN > assetfinder.txt

cat subfinder.txt assetfinder.txt | sort | uniq > subdomains.txt

cat subdomains.txt | httpx -sc > httpx_alive_domains.txt #this file is mainly for reference

echo "[*] Scan completed. Results saved to subdomains.txt."



echo "[*] Resolving subdomains for $DOMAIN using dnsx..."

dnsx -l subdomains.txt -r resolvers.txt -o dnsx_resolved.txt # Specify the path to your resolvers file

echo "[*] Scan completed. Results saved to dnsx_resolved.txt."



echo "[*] Resolving subdomain IP's for $DOMAIN using dnsx..."

dnsx -l dnsx_resolved.txt -a -resp-only -o dnsx_resolved_ips.txt

echo "[*] Scan completed. Results saved to dnsx_resolved_ips.txt."



echo "[*] Probing for $DOMAIN using httpx..."

httpx -l subdomains.txt -title -sc -location -p 80,443,8000,8080,8443 -td -cl -probe -o reference_probe_httpx.txt #This mostly has failed ones with 404 forbidden pages marked as failed

cat refference_probe_httpx.txt | grep -v "FAILED" | awk '{print $1}' | tee final_subdomains.txt # This has only domains 

echo "[*] Scan completed. Results saved to final_subdomains.txt."


# Just a extra step
echo "[*] Running scan on IP's for $DOMAIN using nmap..."

nmap -iL dnsx_resolved_ips.txt -sV > nmap_scan_on_dnsx_IPs.txt

echo "[*] Scan completed. Results saved to nmap_scan_on_dnsx_IPs.txt."


#---------------------This will give all the working subdomains---------------------#
#----------------------You can further handpick subdomains and then run feroxbuster, amass etc----------------------#