# 01 — Architecture de l'environnement de sécurité

## 1. Objectif

Le projet consiste à sécuriser un environnement informatique en utilisant trois serveurs complémentaires :

- **VPS** : hébergement Web et protection des services.
- **Knox** : sauvegarde des données et surveillance de l'intégrité.
- **Canary** : détection des activités suspectes grâce à OpenCanary.

Cette séparation des responsabilités permet de distinguer les services de production, les mécanismes de protection des données et les outils de détection.

## 2. Inventaire des serveurs

| Élément | VPS | Knox | Canary |
|---|---|---|---|
| Adresse IP | `172.105.99.9` | `10.1.106.34` | `10.1.106.32` |
| Nom d'hôte | | `raphael-knox` | `raphael-canary` |
| Hébergement | VPS distant | Proxmox | Proxmox |
| Système | Ubuntu, version à confirmer | Ubuntu Server 22.04 LTS | Ubuntu Server 22.04 LTS |
| Fonction principale | Serveur Web sécurisé | Sauvegardes et intégrité | Pot de miel |
| Administration | SSH, port 870 | Console Proxmox | SSH, port 870 |

### Ressources des machines virtuelles

L'énoncé prévoit les ressources suivantes pour Knox et Canary :

- 1 processeur virtuel (vCPU).
- 2 048 Mo de mémoire vive.
- 25 Go d'espace disque.

Ces valeurs doivent être vérifiées dans la configuration Proxmox avant de confirmer qu'elles correspondent aux machines déployées.

## 3. Architecture logique

```text
                    Réseau / Internet
                           |
                           v
                  +------------------+
                  |       VPS        |
                  |   172.105.99.9   |
                  |                  |
                  | Site Web + BDD   |
                  | SSH : 870        |
                  | Pare-feu         |
                  | Fail2ban         |
                  +------------------+
                           ^
                           |
                  Sauvegardes et
                contrôle d'intégrité
                           |
                  +------------------+
                  |       Knox       |
                  |   10.1.106.34    |
                  |                  |
                  | Sauvegardes      |
                  | SHA-256          |
                  | monitor.log      |
                  +------------------+

                  +------------------+
                  |      Canary      |
                  |   10.1.106.32    |
                  |                  |
                  | OpenCanary       |
                  | HTTP / MySQL     |
                  | Portscan         |
                  +------------------+
                           |
                     Alertes SMTP
                           |
                           v
                         Gmail
```

Ce schéma représente les rôles logiques. Il ne constitue pas un plan détaillé des routes réseau ou des règles de pare-feu.

## 4. Serveur VPS

Le VPS héberge le site Web et sa base de données.

Les principales mesures de sécurité demandées sont :

- Mise à jour régulière des paquets.
- Déplacement du service SSH sur le port `870`.
- Interdiction des connexions SSH directes du compte `root`.
- Authentification SSH par clé publique.
- Configuration d'un pare-feu.
- Protection d'Apache.
- HTTPS avec Let's Encrypt.
- Protection SSH et phpMyAdmin avec Fail2ban.

La configuration Fail2ban attendue prévoit un blocage de six heures après quatre échecs d'authentification sur une période de quinze minutes.

## 5. Serveur Knox

Knox assure la protection des données du VPS.

### Sauvegardes

Les éléments à sauvegarder sont :

- `/var/www` : fichiers des sites Web.
- `/home` : répertoires personnels.
- Un export de la base de données.

### Surveillance de l'intégrité

Knox doit surveiller deux fichiers du VPS :

- La configuration du VirtualHost Apache.
- La configuration du service SSH.

Le principe consiste à calculer une empreinte SHA-256 de chaque fichier, puis à comparer les valeurs lors des contrôles suivants.

Une modification détectée doit être enregistrée dans `monitor.log`.

### Administration

Knox ne doit pas disposer d'un serveur SSHD. Son administration s'effectue depuis la console Proxmox.

## 6. Serveur Canary

Canary exécute OpenCanary, un pot de miel destiné à enregistrer les interactions suspectes avec des services simulés.

### Services configurés

| Service | Port | Fonction |
|---|---|---|
| HTTP | 80/TCP | Simulation d'un serveur Web |
| MySQL | 3306/TCP | Simulation d'un service de base de données |
| FTP | 21/TCP | Service simulé supplémentaire |
| SSH réel | 870/TCP | Administration du serveur |

Le module Portscan est également activé.

### Alertes

OpenCanary enregistre les événements dans un journal local. Un script Python dédié surveille les événements et transmet des alertes par Gmail via SMTP.

Le service OpenCanary et le service d'alertes sont configurés pour démarrer automatiquement avec systemd.

## 7. Flux entre les composants

| Origine | Destination | Objectif |
|---|---|---|
| Administrateur | VPS | Administration SSH |
| Knox | VPS | Récupération des sauvegardes et vérification des fichiers |
| Client de test | Canary | Simulation d'activités suspectes |
| Canary | Gmail | Transmission des alertes |

Les flux réseau doivent être autorisés uniquement lorsque cela est nécessaire au fonctionnement du projet.

## 8. Vérifications de l'architecture

La validation de l'environnement repose sur les éléments suivants :

1. Vérifier la disponibilité du site Web hébergé sur le VPS.
2. Vérifier l'accès SSH sur le port `870`.
3. Vérifier la production des sauvegardes sur Knox.
4. Vérifier la détection des modifications des fichiers surveillés.
5. Vérifier le démarrage automatique d'OpenCanary.
6. Générer un événement de test depuis Knox vers Canary.
7. Vérifier la présence de l'événement dans les journaux OpenCanary.
8. Vérifier la réception d'une alerte Gmail.

## 9. Bonnes pratiques de sécurité

Le dépôt GitHub étant public, les informations sensibles ne doivent jamais être publiées :

- Mots de passe et secrets SMTP.
- Clés SSH privées.
- Identifiants de bases de données.
- Sauvegardes contenant des données privées.
- Fichiers `.env` réels contenant des secrets.

Les procédures utiliseront des variables d'exemple lorsque des informations confidentielles sont nécessaires.

## 10. Utilisation de l'intelligence artificielle

Produit avec l'aide d'une intelligence artificielle générative.

Cette documentation doit être confrontée à la configuration réelle des serveurs avant sa validation finale.
