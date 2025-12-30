#!/bin/bash
#
# This script gathers system information on an Ubuntu/Debian-based system
# and generates a formatted HTML report. It is a re-implementation of
# a Solaris-based inventory script for modern Linux.
#
# Ensure the script is run with root privileges for full hardware details.
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root to gather all system details." >&2
  exit 1
fi

# --- Variable Definitions ---
HOSTNAME=$(hostname -f)
HOSTID=$(hostid)
LOGFILE="/tmp/${HOSTNAME}-${HOSTID}-$(date +%d-%m-%Y).html"
OS_RELEASE=$(grep PRETTY_NAME /etc/os-release | cut -d'=' -f2 | tr -d '"')
KERNEL_VERSION=$(uname -r)
ARCH=$(uname -m)
PROCESSOR_TYPE=$(uname -p)
MODEL=$(dmidecode -s system-product-name)
SERIALNO=$(dmidecode -s system-serial-number)
BIOS_VERSION=$(dmidecode -s bios-version)
MEMORY_GB=$(free -m | awk '/^Mem:/{printf "%.2f", $2/1024}')
MEMORY_CONFIG=$(dmidecode -t memory 2>/dev/null | grep 'Size:' | grep -v 'No Module Installed' | awk '{print $2 $3}' | sort | uniq -c | awk '{print $1 " x " $2}')
CPU_MODEL=$(lscpu | grep "Model name:" | awk -F': +' '{print $2}')
CPU_COUNT=$(lscpu | grep "^CPU(s):" | awk '{print $2}')
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
JAVA_VERSION=$(java -version 2>&1 | grep version | sed -e 's/"//g' | awk '{print $3}' || echo "Not Installed")

# --- HTML Header ---
cat > "$LOGFILE" <<-EOF
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <title>$HOSTNAME - Server Information</title>
  <style>
    body { font-family: Arial, sans-serif; background-color: #FFFFFF; margin: 20px; }
    table { border-collapse: collapse; width: 80%; margin-left: auto; margin-right: auto; }
    th, td { border: 1px solid #000000; padding: 8px; text-align: left; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    h1, h2, h3 { text-align: center; }
    .nav { text-align: center; margin-bottom: 20px; }
    a { text-decoration: none; color: #0000EE; }
    a:hover { text-decoration: underline; }
    pre { background-color: #eee; padding: 10px; border: 1px solid #999; white-space: pre-wrap; word-wrap: break-word; }
  </style>
</head>
<body>
  <h1>Server Information</h1>
  <div class="nav">
    <a href="#Host">Host</a> |
    <a href="#HW">Hardware</a> |
    <a href="#NW">Network</a> |
    <a href="#USER">Users</a> |
    <a href="#Ver">Versions</a> |
    <a href="#Disk">Disk Usage</a> |
    <a href="#SYSTEM">Kernel</a> |
    <a href="#FILES">Files</a> |
    <a href="#CKSUM">Checksums</a>
  </div>

  <h2 id="Host">Host Information</h2>
  <table>
    <tr><td>Hostname</td><td>$HOSTNAME</td></tr>
    <tr><td>HostID</td><td>$HOSTID</td></tr>
    <tr><td>Serial No.</td><td>$SERIALNO</td></tr>
    <tr><td>BIOS Version</td><td>$BIOS_VERSION</td></tr>
    <tr><td>Arch / Processor</td><td>$ARCH / $PROCESSOR_TYPE</td></tr>
    <tr><td>Model</td><td>$MODEL</td></tr>
    <tr><td>Memory</td><td>${MEMORY_GB}GB ($MEMORY_CONFIG)</td></tr>
    <tr><td>CPU</td><td>${CPU_COUNT} x ${CPU_MODEL}</td></tr>
    <tr><td>Timezone</td><td>$TIMEZONE</td></tr>
    <tr><td>Operating System</td><td>$OS_RELEASE</td></tr>
    <tr><td>Kernel</td><td>$KERNEL_VERSION</td></tr>
  </table>

  <h2 id="HW">Hardware Summary</h2>
  <pre>
$(echo "--- CPU ---"; lscpu; echo; echo "--- PCI Devices ---"; lspci; echo; echo "--- USB Devices ---"; lsusb; echo; echo "--- System Info ---"; dmidecode -t system; echo; echo "--- Baseboard Info ---"; dmidecode -t baseboard; echo; echo "--- Chassis Info ---"; dmidecode -t chassis)
  </pre>

  <h2 id="NW">Network Information</h2>
  <table>
    <tr><th>Interface</th><th>IP Address</th><th>MAC Address</th></tr>
EOF

# --- Network Interface Info ---
for iface in $(ip -o link show | awk -F': ' '{print $2}'); do
    ip_addr=$(ip -o -4 addr show dev "$iface" | awk '{print $4}' | head -n1)
    mac_addr=$(ip -o link show dev "$iface" | awk '{print $17}')
    echo "<tr><td>$iface</td><td>${ip_addr:-N/A}</td><td>${mac_addr:-N/A}</td></tr>" >> "$LOGFILE"
done

# --- User Info ---
cat >> "$LOGFILE" <<-EOF
  </table>

  <h2 id="USER">User Accounts</h2>
  <table>
    <tr><th>Username</th><th>UID</th><th>Home Directory</th><th>Login Shell</th><th>Comment</th></tr>
EOF
getent passwd | awk -F: '{print "<tr><td>"$1"</td><td>"$3"</td><td>"$6"</td><td>"$7"</td><td>"$5"</td></tr>"}' >> "$LOGFILE"

# --- Software Versions ---
cat >> "$LOGFILE" <<-EOF
  </table>

  <h2 id="Ver">Software Versions</h2>
  <table>
    <tr><th>Software</th><th>Version</th></tr>
    <tr><td>OpenSSH</td><td>$(dpkg-query -W -f='${Version}' openssh-server 2>/dev/null || echo "Not Installed")</td></tr>
    <tr><td>Apache2</td><td>$(dpkg-query -W -f='${Version}' apache2 2>/dev/null || echo "Not Installed")</td></tr>
    <tr><td>MySQL Server</td><td>$(dpkg-query -W -f='${Version}' mysql-server 2>/dev/null || echo "Not Installed")</td></tr>
    <tr><td>Docker</td><td>$(dpkg-query -W -f='${Version}' docker-ce 2>/dev/null || echo "Not Installed")</td></tr>
    <tr><td>LVM2</td><td>$(dpkg-query -W -f='${Version}' lvm2 2>/dev/null || echo "Not Installed")</td></tr>
    <tr><td>GNU C Library</td><td>$(dpkg-query -W -f='${Version}' libc6 2>/dev/null || echo "Not Installed")</td></tr>
    <tr><td>Java</td><td>$JAVA_VERSION</td></tr>
  </table>
EOF

# --- Filesystem Usage ---
cat >> "$LOGFILE" <<-EOF
  <h2 id="Disk">Filesystem Usage</h2>
  <table>
    <tr><th>FileSystem</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted on</th></tr>
EOF
df -h | grep -vE '^Filesystem|tmpfs|udev' | awk '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"$5"</td><td>"$6"</td></tr>"}' >> "$LOGFILE"

# --- Kernel Parameters & System Files ---
cat >> "$LOGFILE" <<-EOF
  </table>

  <h2 id="SYSTEM">Kernel Parameters (/etc/sysctl.conf)</h2>
  <pre>$(cat /etc/sysctl.conf 2>/dev/null || echo "/etc/sysctl.conf not found.")</pre>

  <h2 id="FILES">System Files</h2>
  <h3>/etc/hosts</h3>
  <pre>$(cat /etc/hosts)</pre>
  <h3>/etc/fstab</h3>
  <pre>$(cat /etc/fstab)</pre>
  <h3>/etc/netplan/*.yaml</h3>
  <pre>$(cat /etc/netplan/*.yaml 2>/dev/null || echo "No netplan configuration found.")</pre>

  <h2 id="CKSUM">Configuration Checksums (sha256)</h2>
  <table>
    <tr><th>Checksum</th><th>File</th></tr>
EOF

# Checksums
for file_to_sum in /etc/hosts /etc/fstab /etc/sysctl.conf /etc/issue /etc/os-release; do
    if [ -f "$file_to_sum" ]; then
        sha256sum "$file_to_sum" | awk '{print "<tr><td>"$1"</td><td>"$2"</td></tr>"}' >> "$LOGFILE"
    fi
done

# --- Footer ---
cat >> "$LOGFILE" <<-EOF
  </table>
  <hr>
  <p style="text-align:center; font-size:small;">
    Internal Document - Generated on $(date) by $(whoami)
  </p>
</body>
</html>
EOF

echo "Inventory complete. Report saved to $LOGFILE"
