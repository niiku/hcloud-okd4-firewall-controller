#!/bin/bash
set -o errexit
set -o pipefail

if [ "$DEBUG" == "true" ]; then
        echo "DEBUG enabled"
        set -o xtrace
fi
INTERVAL_SECONDS=${INTERVAL_SECONDS:-60}
set -o nounset
echo "Starting hcloud-okd4-iptables-machineconfig script..."
echo "Refreshing every $INTERVAL_SECONDS seconds"

accept_from_host() {
        IPTABLE_RULES="$IPTABLE_RULES
echo \"Allowing traffic from $1 ($2)\" >> \$LOGFILE
iptables -A INPUT -s $2 -j ACCEPT"

}

generate_iptables_commands() {
        eval "$(hcloud server list -onoheader | awk '{ print "accept_from_host " $2 " " $4 }')"
        eval "$(hcloud load-balancer list -onoheader | awk '{ print "accept_from_host " $2 " " $3 }')"

}

create_firewall_script() {
        FIREWALL_SCRIPT=$(base64 -w0 <<EOF
#!/bin/sh
LOGFILE=/var/log/custom-firewall-config.log
if [ "\$1" != "ens3" ]; then
    echo "\$0: ignoring \$1 for \$2" >> \$LOGFILE
    exit 0
fi
case "\$2" in
    pre-up)
echo "Setup custom iptable rules"  >> \$LOGFILE
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
${IPTABLE_RULES}
iptables -P INPUT DROP # Drop everything we don't accept
        ;;
    *)
echo "\$0: nothing to do with \$1 for \$2" >> \$LOGFILE
        ;;
esac
exit 0
EOF

)
}

apply_machineconfig() {
        kubectl apply -f - <<EOF
apiVersion: machineconfiguration.openshift.io/v1
kind: MachineConfig
metadata:
  name: 00-${1}-firewall-config
  labels:
    machineconfiguration.openshift.io/role: ${1}
spec:
  config:
    ignition:
      version: 2.2.0
    storage:
      files:
        - contents:
            source: >-
              data:text/plain;charset=utf;base64,${2}
          filesystem: root
          mode: 493
          overwrite: true
          path: /etc/NetworkManager/dispatcher.d/pre-up.d/00-firewall-config
EOF
}

while true; do 
        IPTABLE_RULES=""
        FIREWALL_SCRIPT=""
        generate_iptables_commands
        create_firewall_script
        apply_machineconfig "worker" $FIREWALL_SCRIPT
        apply_machineconfig "master" $FIREWALL_SCRIPT
        sleep $INTERVAL_SECONDS
done
