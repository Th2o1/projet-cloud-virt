#!/bin/bash

# Script pour ajouter un nœud client au cluster Nomad et Consul
# Usage : ./add_node.sh <node_name> <node_ip>

NODE_NAME=$1
NODE_IP=$2
NODE_COUNT=$(( $(nomad server members 2>/dev/null | wc -l) - 1 ))


if [ -z "$NODE_NAME" ] || [ -z "$NODE_IP" ]; then
  echo "Erreur : Veuillez fournir le nom du nœud et son IP (ex. : ./add_node.sh nouveau-noeud 172.16.12.103)"
  exit 1
fi

echo "Ajout du nœud $NODE_NAME avec l'IP $NODE_IP..."

echo "Configuration de Consul..."
sudo mkdir -p /etc/consul.d
cat <<EOF | sudo tee /etc/consul.d/consul.hcl
datacenter = "perle"
data_dir = "/opt/consul"
node_name = "$NODE_NAME"
advertise_addr = "$NODE_IP"
client_addr = "0.0.0.0"
retry_join = ["perle.internal.100do.se"]
server = true
EOF

echo "Redémarrage du service Consul..."
sudo systemctl restart consul.service

# Créer le fichier de configuration Nomad
echo "Configuration de Nomad..."
sudo mkdir -p /etc/nomad.d
cat <<EOF | sudo tee /etc/nomad.d/nomad.hcl
datacenter = "perle"
data_dir = "/opt/nomad"
bind_addr = "0.0.0.0"
name = "$NODE_NAME"
advertise {
  http = "$NODE_IP"
  rpc = "$NODE_IP"
  serf = "$NODE_IP"
}
server {
  enabled = true
  bootstrap_expect = "$NODE_COUNT"
}

client {
  enabled = true
  servers = ["perle.internal.100do.se"]
}

consul {
  address = "127.0.0.1:8500"
}
EOF

echo "Redémarrage du service Nomad..."
sudo systemctl restart nomad.service

# Vérifier l'intégration
echo "Vérification de l'intégration du nœud..."
sleep 10
consul members | grep "$NODE_NAME" && echo "Nœud $NODE_NAME ajouté à Consul !" || echo "Erreur : Nœud non détecté dans Consul."
nomad node status | grep "$NODE_NAME" && echo "Nœud $NODE_NAME ajouté à Nomad !" || echo "Erreur : Nœud non détecté dans Nomad."