#!/bin/bash

# Etape 0 : Cleanup

redis_name="redis"
worker_name="worker"
web_name="web"
haproxy_name="haproxy"

# Nettoyage des anciens conteneurs s'ils existent
echo "Arrêt et suppression des anciens conteneurs (Redis, Web, Worker, HAProxy)..."
docker stop $redis_name $worker_name $web_name $haproxy_name
docker rm $redis_name $worker_name $web_name $haproxy_name

# Étape 1 : Lancer Redis dans un conteneur Docker
echo "Lancement du conteneur Redis..."
CONTAINER_ID=$(docker run -d --name $redis_name redis:latest)

echo "Le conteneur Redis a été créé avec l'ID : $CONTAINER_ID"

# Étape 2 : Récupérer l'adresse IP du conteneur Redis
REDIS_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'  $CONTAINER_ID)

# Vérifier si l'IP a été récupérée correctement
if [ -z "$REDIS_IP" ]; then
  echo "Erreur : Impossible de récupérer l'adresse IP du conteneur Redis."
  exit 1
fi

echo "Adresse IP du conteneur Redis : $REDIS_IP"

# Étape 3 : Créer le fichier redis-service.json pour Consul
echo "Création du fichier redis-service.json..."

cat <<EOF > redis-service.json
{
  "service": {
    "name": "redis$CONTAINER_ID",
    "tags": ["redis", "cache"],
    "address": "$REDIS_IP",
    "port": 6379
  }
}
EOF

echo "Fichier redis-service.json créé avec succès."

# Étape 4 : Enregistrer le service dans Consul
echo "Enregistrement du service Redis dans Consul..."
consul services register redis-service.json

# Vérifier si l'enregistrement a réussi
if [ $? -eq 0 ]; then
  echo "Le service Redis a été enregistré avec succès dans Consul."
else
  echo "Erreur lors de l'enregistrement du service dans Consul."
  exit 1
fi

# Optionnel : Supprimer le fichier JSON temporaire
rm redis-service.json
echo "Le fichier redis-service.json a été supprimé."

# Étape 5 : Lancer HAProxy (répartiteur de charge)
echo "Lancement de HAProxy..."
cat <<EOF > /etc/haproxy/haproxy.cfg
global
  daemon
  maxconn 1024

defaults
  balance roundrobin
  timeout client 60s
  timeout connect 60s
  timeout server 60s

frontend stats
  bind *:8404
  mode http
  stats enable
  stats uri /stats
  stats refresh 10s
  stats admin if TRUE

frontend http
  bind *:8080
  mode http
  default_backend web

backend web
  balance roundrobin
  mode http
  server web $REDIS_IP:8080
EOF

docker run -d --name $haproxy_name -p 8080:8080 -p 8404:8404 -v /etc/haproxy/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg haproxy:latest

echo "HAProxy a été lancé avec succès."

# Étape 6 : Lancer les services Web et Worker
echo "Lancement du serveur web et de l’exécuteur de tâches..."

WEB_ID=$(docker run -d --name $web_name -e CELERY_BROKER_URL=redis://redis.service.consul:6379/0 -e CELERY_RESULT_BACKEND=redis://redis.service.consul:6379/1 ghcr.io/sandhose/tp-siris-service-discovery/web -p 8080:8080)

WORKER_ID=$(docker run -d --name $worker_name -e CELERY_BROKER_URL=redis://redis.service.consul:6379/0 -e CELERY_RESULT_BACKEND=redis://redis.service.consul:6379/1 ghcr.io/sandhose/tp-siris-service-discovery/worker -p 8080:8080)

echo "Création du service web avec l'id : $WEB_ID, Création du serveur worker : $WORKER_ID"

echo "Processus terminé ! Redis, Web et Worker sont maintenant en cours d'exécution. HAProxy est également actif."

# Étape 7 : Cleanup des anciens conteneurs (au cas où on redémarre ou qu'on supprime un service)
docker stop $redis_name $worker_name $web_name $haproxy_name
docker rm $redis_name $worker_name $web_name $haproxy_name
echo "Nettoyage terminé."