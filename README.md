# LogisticoTrain - Déploiement Docker

## Présentation

LogisticoTrain est un système de gestion des arrivées, sorties et réparations de rames de train dans un centre de maintenance. Ce dépôt contient l'infrastructure Docker permettant le déploiement de l'ensemble du système.

## Prérequis

- Docker Desktop installé

## Structure du projet
```
LogisticoTrain/
├── app/                        # Code source frontend React (placeholder)
├── RealtimeAPI/                # Code source API temps réel Spring (placeholder)
├── RESTApi/                    # Code source API REST Flask (placeholder)
├── docker/                     # Dockerfiles et configurations
│   ├── sql/init/               # Script SQL d'initialisation
│   │   └── init.sql            # Création des tables Voie, Rame, Tache
│   ├── nginx.Dockerfile        # Image personnalisée Nginx
│   ├── restapi.Dockerfile      # Image personnalisée Flask
│   └── rabbitmq.Dockerfile     # Image personnalisée RabbitMQ
├── secrets/                    # Fichiers secrets (ne pas versionner !)
│   ├── mariadb-root.txt        # Mot de passe root MariaDB
│   ├── mariadb-user.txt        # Mot de passe utilisateur MariaDB
│   ├── mongo-root.txt          # Mot de passe root MongoDB
│   ├── rabbitmq-user.txt       # Mot de passe utilisateur RabbitMQ
│   ├── rabbitmq.conf           # Configuration RabbitMQ
│   ├── application.properties  # Configuration wsapi (données sensibles)
│   └── mongo-express.env       # Configuration mongo-express
└── docker-compose.yml
```

## Lancement

### Important — ordre de lancement

Le build du frontend doit être effectué avant le premier lancement de la stack, ou après toute modification du code frontend.

### 1. Builder l'application frontend
```bash
docker compose --profile builder run webapp
```
Cette commande est à lancer une seule fois. Elle installe les dépendances npm et compile le frontend React avec webpack. Le résultat est stocké dans le volume `webapp-build`.

### 2. Démarrer la stack principale
```bash
docker compose up -d
```

### 3. Lancer les outils de développement (optionnel)
```bash
docker compose --profile dev-tool up -d
```

### 4. Arrêter la stack
```bash
docker compose down
```

### 5. Arrêter les outils de développement
```bash
docker compose --profile dev-tool down
```

## Accès aux services

| Service | URL | Notes |
|---|---|---|
| Application web | http://localhost | Interface principale |
| phpMyAdmin | http://localhost:8081 | Profil dev-tool uniquement, accès local uniquement |
| mongo-express | http://localhost:8082 | Profil dev-tool uniquement, accès local uniquement |

## Choix techniques

### `node:22` au lieu de `node:22-alpine` pour `webapp`
L'image alpine ne contient pas Python ni les outils de compilation nécessaires. 
L'image complète `node:22` a donc été utilisée pour éviter les erreurs de build.

### `python:3.11` au lieu de `python:3.11-slim` pour `restapi`
La version slim manque de certaines dépendances système nécessaires pour compiler les packages Python listés dans `requirements.txt`. L'image complète a été choisie pour garantir un build stable.

### `application.properties` déplacé dans `secrets/`
Le fichier de configuration de `wsapi` contient des credentials sensibles (BDD, MongoDB, broker). Il a été sorti du code source et placé dans `secrets/` pour éviter de versionner des données sensibles dans Git. Il est monté en bind mount read-only dans le conteneur `wsapi`.

### Subnets des réseaux custom
Les subnets ont été choisis pour éviter les conflits avec le réseau bridge par défaut de Docker (`172.18.0.0/16`) et un réseau existant sur la machine (`172.19.0.0/16`) :
- `db_net` → `172.21.0.0/16`
- `broker_net` → `172.20.0.0/16`
- `front_net` → `172.22.0.0/16`

### Contexte de build
- `broker` → context `./docker` car tous les fichiers nécessaires sont dans ce dossier
- `restapi` → context `.` (racine) car le Dockerfile a besoin d'accéder au dossier `RESTApi/`
- `front` → context `.` (racine) car le Dockerfile a besoin d'accéder à `vendorConfigurations/nginx/nginx.conf`

## Bugs connus

### Tables en double dans MariaDB
Spring JPA crée automatiquement les tables `rames`, `taches`, `voies` en minuscules en plus des tables `Rame`, `Tache`, `Voie` créées par le script `init.sql`. Malgré la configuration `spring.jpa.hibernate.ddl-auto=validate` et la désactivation du profil `development`, ce comportement persiste. Cela n'impacte pas le fonctionnement de l'application.

## Limites du système

- `webapp` doit être lancé manuellement avec le profil `builder` avant le premier démarrage de `front`, ou après toute modification du code frontend. Le build n'est pas automatique au `docker compose up`.
- `restapi` et `wsapi` n'exposent pas de healthcheck, le service `front` démarre donc avec `service_started` et non `service_healthy`.
- Les outils de développement (`phpmyadmin`, `mongo-express`) ne sont accessibles que depuis la machine locale (`127.0.0.1`). Identifiants mongo-express par défaut : login `admin`, mot de passe `pass`.