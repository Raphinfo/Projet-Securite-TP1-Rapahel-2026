# Projet-Securite-TP1-Rapahel-2026
TP1 de sécurité informatique — VPS, surveillance, sauvegardes et honeypot OpenCanary


# Projet de sécurité TP1 — Automne 2026

## Présentation du projet

Ce projet consiste à renforcer la sécurité d'un environnement informatique composé de trois serveurs : **VPS**, **Knox** et **Canary**.

L'objectif est de mettre en œuvre des mécanismes de protection, de sauvegarde, de surveillance de l'intégrité et de détection des activités suspectes.

**Établissement :** Cégep de Matane  
**Cours :** Projet de sécurité #1  
**Session :** Automne 2026  
**Date de remise :** 13 novembre 2026

## Architecture de l'environnement

| Serveur | Adresse IP | Rôle |
|---|---|---|
| VPS | `172.105.99.9` | Hébergement Web et sécurisation des services |
| Knox | `10.1.106.34` | Sauvegardes et surveillance de l'intégrité |
| Canary | `10.1.106.32` | Pot de miel OpenCanary et détection d'intrusions |

Les machines Knox et Canary sont hébergées dans un environnement Proxmox et utilisent Ubuntu Server 22.04 LTS.

## 1. VPS — Sécurisation du serveur Web

Le VPS héberge un site Web avec une base de données et intègre plusieurs mesures de sécurité :

- Installation et configuration de l'environnement LAMP.
- Sécurisation de l'accès SSH sur le port `870`.
- Authentification SSH par clé publique.
- Configuration des utilisateurs et de leurs permissions.
- Configuration du pare-feu.
- Sécurisation d'Apache.
- Mise en place de HTTPS avec Let's Encrypt.
- Protection contre les tentatives de connexion répétées avec Fail2ban.

**Documentation :** [Procédures VPS](docs/vps/)

## 2. Knox — Sauvegardes et surveillance

Knox est chargé de protéger les données et de surveiller les modifications de fichiers sensibles.

Fonctionnalités prévues :

- Sauvegarde du répertoire `/var/www`.
- Sauvegarde du répertoire `/home`.
- Sauvegarde de la base de données.
- Vérification de l'intégrité des fichiers de configuration avec SHA-256.
- Journalisation des modifications détectées.
- Procédure de restauration des fichiers sauvegardés.

Knox est administré depuis la console Proxmox, sans service SSHD.

**Documentation :** [Procédures Knox](docs/knox/)

## 3. Canary — Détection d'activités suspectes

Canary utilise OpenCanary pour simuler des services susceptibles d'attirer des tentatives d'intrusion.

Fonctionnalités :

- Simulation d'un serveur Web Linux.
- Simulation d'un service MySQL.
- Activation du module Portscan.
- Démarrage automatique avec systemd.
- Enregistrement des événements de sécurité.
- Envoi automatique d'alertes par courriel Gmail.

Les alertes par courriel ont été testées à partir d'activités générées depuis Knox.

**Documentation :** [Procédures Canary](docs/canary/)

## 4. Tests et validation

Les procédures de validation présenteront :

- Les commandes utilisées.
- Les résultats attendus.
- Les preuves de fonctionnement.
- Les captures d'écran.
- Les problèmes rencontrés et leurs solutions.

## 5. Démonstrations vidéo

Les vidéos présenteront le fonctionnement des trois serveurs, les mécanismes de sécurité, les sauvegardes, la restauration et les alertes.

**Liens des vidéos :** à ajouter après leur réalisation.

## 6. Sécurité des informations publiées

Ce dépôt public ne doit contenir aucun mot de passe, aucune clé SSH privée, aucun jeton d'authentification ni aucune donnée confidentielle.

Les fichiers de configuration contenant des secrets seront remplacés par des exemples anonymisés.

## 7. Utilisation de l'intelligence artificielle

Une assistance par intelligence artificielle générative a été utilisée pour la recherche, l'aide à la rédaction et certaines étapes de développement ou de dépannage.

**Mention :** « Produit avec l'aide d'une intelligence artificielle générative. »

Les configurations et les procédures doivent être vérifiées sur les systèmes concernés avant leur publication.
