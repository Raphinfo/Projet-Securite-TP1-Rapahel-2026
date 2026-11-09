# VPS — Installation LAMP et déploiement de SportPulse

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine :** VPS Ubuntu Server 22.04  
**Adresse IP :** `172.105.99.9`  
**Domaine :** `securite.rpd-labs.com`  
**Compte administrateur :** `raphi`

## 1. Objectif

Installer et exploiter un environnement LAMP (*Linux, Apache, MySQL, PHP*) sur un VPS afin d'héberger le site Web SportPulse et sa base de données.

Cette installation sert de base aux autres mécanismes de sécurité du projet : SSH renforcé, pare-feu, HTTPS, contrôle des accès, Fail2ban et sauvegardes effectuées par Knox.

## 2. Architecture LAMP

| Composant | Version observée | Fonction |
|---|---|---|
| Ubuntu Server | 22.04, d'après les versions des paquets | Système d'exploitation |
| Apache | 2.4.52 | Serveur Web |
| MySQL | 8.0.46 | Serveur de base de données |
| PHP | 8.1 | Exécution de l'application |
| SportPulse | Application PHP | Site Web déployé |

Les services Apache et MySQL ont été vérifiés avec `systemctl is-active` et ont répondu `active`.

## 3. Connexion au VPS

**Machine : ordinateur local de l'administrateur.**

L'administration du VPS s'effectue par SSH sur le port `870` avec le compte `raphi`.

```bash
ssh -p 870 -i ~/.ssh/id_rsa_sportpulse raphi@172.105.99.9
```

Cette commande suppose que la clé privée autorisée est déjà présente sur le poste de l'administrateur.

La création des comptes, les restrictions SSH et la gestion des clés seront détaillées dans `docs/vps/02-ssh-et-utilisateurs.md`.

## 4. Installation des composants LAMP

**Machine : VPS — utilisateur disposant de `sudo`.**

Sur une nouvelle installation Ubuntu Server 22.04, actualiser les informations des paquets et installer les composants nécessaires :

```bash
sudo apt update
sudo apt install apache2 mysql-server php libapache2-mod-php php-mysql
```

Ces commandes constituent une procédure de reproduction. Les versions exactes installées peuvent évoluer selon les dépôts Ubuntu disponibles.

Activer et démarrer Apache et MySQL :

```bash
sudo systemctl enable --now apache2
sudo systemctl enable --now mysql
```

Vérifier leur état :

```bash
systemctl is-active apache2 mysql
```

Résultat attendu :

```text
active
active
```

Contrôler les versions installées :

```bash
apache2 -v
mysql --version
php -v
```

Sur le VPS du projet, les paquets observés étaient :

- `apache2` : `2.4.52-1ubuntu4.25`
- `mysql-server` : `8.0.46-0ubuntu0.22.04.4`
- `php` : `2:8.1+92ubuntu1`

## 5. Déploiement de SportPulse

**Machine : VPS.**

Le site SportPulse est hébergé dans le répertoire :

```text
/var/www/sportpulse-deploiement
```

Son arborescence comprend notamment :

```text
/var/www/sportpulse-deploiement/
├── index.php
├── configuration.php
├── actualite.php
├── joueur.php
├── contact.php
├── recherche.php
├── style.css
├── script.js
├── accesseur/
├── illustration/
├── modele/
└── partage/
```

Il s'agit d'une application PHP utilisant également des fichiers CSS et JavaScript.

Le fichier `configuration.php` peut contenir des paramètres de connexion à la base de données. **Son contenu ne doit pas être publié sans vérification et suppression des secrets.**

### 5.1 Préparation du répertoire

Pour reproduire le déploiement sur un nouveau serveur :

```bash
sudo mkdir -p /var/www/sportpulse-deploiement
```

Transférer ensuite les fichiers de l'application depuis une source autorisée, par exemple un dépôt privé ou une archive de déploiement vérifiée.

Le mécanisme exact de transfert initial utilisé sur ce VPS n'a pas été confirmé dans les vérifications récentes. Il ne faut donc pas présenter une commande de transfert hypothétique comme une opération déjà réalisée.

### 5.2 Propriétaires et permissions observés

La vérification du répertoire a montré :

- Répertoire principal : propriétaire `root`, groupe `www-data`, permissions `750`.
- Plusieurs sous-répertoires : propriétaire `root`, groupe `www-data`, permissions `750`.
- Fichiers PHP, CSS et JavaScript : propriétaire `root`, groupe `www-data`, permissions `640`.

Cette organisation permet au serveur Apache, exécuté avec le groupe `www-data`, de lire les fichiers nécessaires, tout en limitant les accès des autres utilisateurs.

Les droits d'écriture doivent rester limités aux emplacements qui en ont réellement besoin.

Vérifier les permissions :

```bash
sudo ls -lah /var/www/sportpulse-deploiement
```

## 6. Configuration des VirtualHosts Apache

**Machine : VPS.**

Deux VirtualHosts sont activés pour le domaine `securite.rpd-labs.com`.

| Protocole | Port | Fichier |
|---|---|---|
| HTTP | `80` | `/etc/apache2/sites-enabled/securite.conf` |
| HTTPS | `443` | `/etc/apache2/sites-enabled/securite-le-ssl.conf` |

Les deux configurations utilisent :

```apache
ServerName securite.rpd-labs.com
DocumentRoot /var/www/sportpulse-deploiement
```

Le VirtualHost HTTPS référence le certificat :

```text
/etc/letsencrypt/live/securite.rpd-labs.com/fullchain.pem
```

Ce chemin correspond à un certificat géré dans l'arborescence Let's Encrypt. La validité et le renouvellement du certificat feront l'objet de vérifications spécifiques dans la documentation HTTPS.

### 6.1 Vérification des VirtualHosts

Afficher la configuration Apache active :

```bash
sudo apache2ctl -S
```

Le résultat observé sur le VPS indique :

- Un VirtualHost HTTPS pour `securite.rpd-labs.com` sur le port `443`.
- Un VirtualHost HTTP pour `securite.rpd-labs.com` sur le port `80`.
- Un VirtualHost Apache par défaut sur le port `80`.

La commande a également affiché un avertissement concernant l'absence d'un `ServerName` global. Cet avertissement n'empêchait pas Apache de fonctionner.

Vérifier la syntaxe Apache avant toute modification :

```bash
sudo apache2ctl configtest
```

**Important :** la configuration complète des blocs `<Directory>`, la protection du dossier `partage`, les restrictions d'affichage des répertoires et les paramètres de divulgation d'Apache seront documentés dans `docs/vps/04-apache-https.md`.

## 7. Base de données MySQL

**Machine : VPS.**

Le serveur MySQL contient les bases suivantes :

```text
information_schema
mysql
performance_schema
phpmyadmin
sport
sys
```

La base applicative identifiée dans la documentation de sauvegarde Knox est :

```text
sport
```

Le guide opérationnel Knox/VPS indique que l'export et la copie de cette base ont déjà été validés.

### 7.1 Vérification des bases

```bash
sudo mysql -e "SHOW DATABASES;"
```

### 7.2 Vérification des tables

```bash
sudo mysql -e "SHOW TABLES FROM sport;"
```

Cette seconde vérification est proposée pour contrôler la structure de la base. Son résultat détaillé n'a pas encore été recueilli dans cette phase de documentation.

### 7.3 Importation lors d'une nouvelle installation

Pour reconstruire SportPulse, il faut disposer d'une sauvegarde SQL autorisée et vérifiée.

Sur un **nouveau serveur de test**, créer la base si elle n'existe pas :

```bash
sudo mysql -e "CREATE DATABASE sport;"
```

Importer ensuite une sauvegarde compatible :

```bash
sudo mysql sport < /chemin/vers/sport.sql
```

**Précaution :** ces commandes sont destinées à une nouvelle installation ou à un environnement de restauration isolé. Ne pas les exécuter aveuglément sur la base de production existante.

Les utilisateurs MySQL, leurs privilèges et les paramètres de connexion de l'application doivent être configurés séparément, sans publier les mots de passe.

La procédure de sauvegarde de la base `sport` sera décrite dans `docs/knox/02-sauvegardes.md`.

## 8. Contrôles de fonctionnement

Les contrôles suivants permettent de vérifier les principaux composants.

**Services :**

```bash
systemctl is-active apache2 mysql
```

**Configuration Apache :**

```bash
sudo apache2ctl -S
```

**Répertoire du site :**

```bash
sudo ls -lah /var/www/sportpulse-deploiement
```

**Base de données :**

```bash
sudo mysql -e "SHOW DATABASES;"
```

**Réponse HTTP et HTTPS :**

```bash
curl -I http://securite.rpd-labs.com
curl -I https://securite.rpd-labs.com
```

Les deux dernières commandes constituent des tests à réaliser et à documenter avec leurs résultats. La présence d'un VirtualHost HTTPS ne suffit pas, à elle seule, à démontrer que le site répond correctement depuis Internet.

## 9. Résultats confirmés

| Vérification | Résultat |
|---|---|
| Apache installé | Confirmé |
| MySQL installé | Confirmé |
| PHP installé | Confirmé |
| Apache actif | Confirmé |
| MySQL actif | Confirmé |
| VirtualHost HTTP | Confirmé |
| VirtualHost HTTPS | Confirmé |
| Répertoire SportPulse | Confirmé |
| Fichiers de l'application présents | Confirmé |
| Base `sport` présente | Confirmé |
| Export de `sport` par Knox | Documenté comme validé dans le guide Knox/VPS |
| Tables et contenu de `sport` | À vérifier dans cette phase |
| Réponse HTTPS externe | À vérifier dans cette phase |
| Renouvellement automatique du certificat | À vérifier dans la section HTTPS |

## 10. Sécurité et bonnes pratiques

- Ne jamais publier de mots de passe, clés privées SSH ou identifiants MySQL.
- Limiter les permissions des fichiers applicatifs.
- Protéger les fichiers contenant des paramètres de connexion.
- Tester les modifications Apache avant de recharger le service.
- Sauvegarder les fichiers du site et la base de données avant les opérations sensibles.
- Conserver une documentation distinguant les contrôles réellement effectués des procédures proposées pour reproduire l'environnement.

Les autres mesures de sécurité sont détaillées dans les documents suivants :

- `docs/vps/02-ssh-et-utilisateurs.md`
- `docs/vps/03-pare-feu.md`
- `docs/vps/04-apache-https.md`
- `docs/vps/05-fail2ban.md`

---

**Mention relative à l'utilisation de l'IA :** Produit par une intelligence artificielle générative. Document établi à partir des résultats techniques fournis et de la documentation antérieure du projet. Les procédures proposées doivent être vérifiées lors de leur exécution.
