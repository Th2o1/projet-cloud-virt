#!/bin/bash
# à exécuter sur les autres vms après l'ajout d'une nouvelle vm
# Usage : ./update_node_count.sh

echo "Updating Nomad server configuration..."

NOMAD_NODE_COUNT=$(( $(nomad server members 2>/dev/null | wc -l) - 1 ))

echo "Nombre de serveur à mettre à jour est: $NOMAD_NODE_COUNT..."

NOMAD_CONFIG_FILE="/etc/nomad.d/nomad.hcl"
NOMAD_CONFIG_DIR="/etc/nomad.d"

sudo cp "$NOMAD_CONFIG_FILE" "$NOMAD_CONFIG_FILE.bak_$(date +%Y%m%d%H%M%S)"
echo "Un backup du fichier $NOMAD_CONFIG_FILE a été créé."

TMP_FILE=$(mktemp)
if sudo sed "s/^[[:space:]]*bootstrap_expect[[:space:]]*=.*$/  bootstrap_expect = $NOMAD_NODE_COUNT/" "$NOMAD_CONFIG_FILE" > "$TMP_FILE" && \
   sudo mv "$TMP_FILE" "$NOMAD_CONFIG_FILE"; then
  echo "Mise à jour réussie du bootstrap_expect à $NOMAD_NODE_COUNT dans $NOMAD_CONFIG_FILE"
else
  echo "Erreur: J'ai pas réussi à mettre à jour ton truc: $NOMAD_CONFIG_FILE"
  [ -f "$TMP_FILE" ] && rm -f "$TMP_FILE"
  exit 1
fi
[ -f "$TMP_FILE" ] && rm -f "$TMP_FILE"


echo "Redémarrage du service Nomad..."
sudo systemctl restart nomad.service

sleep 20
echo "Nomad service restarted."
echo "Current Nomad server members:"
nomad server members