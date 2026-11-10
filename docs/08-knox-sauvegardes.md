# Knox — Sauvegardes du VPS et vérification des données

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine de sauvegarde :** `raphael-knox` (VM Proxmox 110)  
**Système :** Ubuntu Server 22.04.5 LTS  
**Adresse IP de Knox :** `10.1.106.34`  
**VPS sauvegardé :** `172.105.99.9`  
**Compte de sauvegarde distant :** `knoxbackup`

## 1. Objectif

Knox est chargé de conserver des copies des données importantes du VPS afin de permettre leur récupération en cas de suppression accidentelle, de corruption ou d'incident de sécurité.

Les éléments concernés sont :

- Les fichiers du site Web SportPulse situés dans `/var/www`.
- Les répertoires personnels situés dans `/home`.
- La base de données MySQL `sport`.
- Les informations de permissions nécessaires à certaines restaurations.

Les sauvegardes sont conservées sur une machine virtuelle distincte du VPS.

## 2. Architecture des sauvegardes

Le VPS héberge les données de production, tandis que Knox conserve les copies de sauvegarde.

| Machine | Fonction |
|---|---|
| VPS `172.105.99.9` | Hébergement des données originales |
| Knox `10.1.106.34` | Stockage et vérification des sauvegardes |

Knox utilise une connexion SSH sortante sur le port `870`, avec le compte distant `knoxbackup`.

La clé privée utilisée sur Knox est :

```text
/home/raphael/.ssh/id_ed25519_knox
```

Cette clé privée ne doit jamais être publiée dans GitHub.

## 3. Répertoire de stockage

Les sauvegardes sont stockées dans :

```text
/home/raphael/sauvegardes-vps/
```

Commande de vérification :

```bash
ls -lh /home/raphael/sauvegardes-vps/
```

Les éléments suivants ont été observés :

```text
home/
home-acl.txt
home-complet.tar.gz
www/
```

Le répertoire contenait environ 177 Mo de données au moment du contrôle.

### Organisation

| Élément | Fonction |
|---|---|
| `www/` | Copie des fichiers Web |
| `home/` | Copie des répertoires personnels et fichiers associés |
| `home-complet.tar.gz` | Archive compressée des répertoires personnels |
| `home-acl.txt` | Informations relatives aux permissions ACL |

L'archive `home-complet.tar.gz` avait une taille d'environ 177 Mo.

## 4. Sauvegarde des fichiers Web

Les fichiers du site SportPulse sont présents sur Knox dans :

```text
/home/raphael/sauvegardes-vps/www/sportpulse-deploiement/
```

Commande de vérification :

```bash
find /home/raphael/sauvegardes-vps/www/ -type f | head -n 15
```

La commande a notamment permis de retrouver :

```text
sportpulse-deploiement/index.php
sportpulse-deploiement/alerte.js
sportpulse-deploiement/voiture.css
sportpulse-deploiement/mentions.php
sportpulse-deploiement/mes-favoris.php
sportpulse-deploiement/accesseur/FavoriSQL.php
```

Ces résultats confirment que Knox conserve une copie de plusieurs fichiers constituant le site Web.

## 5. Sauvegarde des répertoires personnels

Les données personnelles du VPS sont conservées dans le répertoire :

```text
/home/raphael/sauvegardes-vps/home/
```

Une archive compressée est également disponible :

```text
/home/raphael/sauvegardes-vps/home-complet.tar.gz
```

Les informations ACL sont conservées dans :

```text
/home/raphael/sauvegardes-vps/home-acl.txt
```

L'archive permet de conserver une copie regroupée des données personnelles. Le fichier ACL peut contribuer à la restauration de permissions particulières.

La restauration complète des permissions doit être vérifiée séparément.

## 6. Sauvegarde de la base de données MySQL

La base de données utilisée par SportPulse est nommée :

```text
sport
```

Les fichiers SQL ont été recherchés avec :

```bash
find ~/sauvegardes-vps -type f -name '*.sql' -ls
```

Deux sauvegardes ont été observées :

| Fichier | Date observée | Taille approximative |
|---|---|---|
| `home/raphi/sport.sql` | 10 novembre 2026, 02 h | 73 Ko |
| `home/raphi/sport-backup.sql` | 2 novembre 2026, 16 h 20 | 73 Ko |

Ces fichiers constituent des copies SQL disponibles sur Knox.

La présence d'un fichier SQL ne suffit pas, à elle seule, à prouver qu'une restauration complète de la base a réussi. Cette validation est distincte.

### Procédure générale de reproduction

Une sauvegarde MySQL peut être créée sur le serveur hébergeant la base avec :

```bash
mysqldump -u UTILISATEUR -p sport > sport.sql
```

Le compte MySQL utilisé doit disposer des privilèges nécessaires à la lecture des données.

Les identifiants de connexion ne doivent jamais être inscrits directement dans un script publié.

## 7. Vérification de l'accès au VPS

Une connexion SSH sortante a été testée depuis Knox :

```bash
ssh -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -p 870 \
    -i ~/.ssh/id_ed25519_knox \
    knoxbackup@172.105.99.9 \
    'echo CONNEXION_KNOX_OK'
```

Résultat :

```text
CONNEXION_KNOX_OK
```

Ce test confirme que Knox peut accéder au VPS avec la clé du compte de sauvegarde.

Knox ne nécessite pas de serveur SSH entrant pour effectuer cette opération.

## 8. Test de récupération d'un fichier sauvegardé

Un test pratique a été réalisé avec le fichier `index.php` du site SportPulse.

L'objectif était de démontrer qu'un fichier présent dans une sauvegarde pouvait être récupéré, ouvert et vérifié sans toucher au site de production.

### 8.1 Création d'un dossier de restauration

Commande exécutée sur Knox :

```bash
mkdir -p ~/test-restauration && \
cp ~/sauvegardes-vps/www/sportpulse-deploiement/index.php \
   ~/test-restauration/index.php
```

Cette commande copie le fichier sauvegardé dans un répertoire temporaire.

Elle ne modifie pas le fichier original du VPS.

### 8.2 Lecture du fichier restauré

Commande exécutée :

```bash
less ~/test-restauration/index.php
```

Le fichier `index.php` s'est ouvert correctement.

Son contenu PHP et HTML était consultable.

**Résultat : récupération et lecture réussies.**

### 8.3 Vérification de l'intégrité SHA-256

Les empreintes des deux fichiers ont été comparées :

```bash
sha256sum \
  ~/sauvegardes-vps/www/sportpulse-deploiement/index.php \
  ~/test-restauration/index.php
```

Les deux commandes ont produit la même empreinte SHA-256.

Cela confirme que le fichier restauré est identique, octet par octet, à celui présent dans la sauvegarde.

Ce test ne compare pas la sauvegarde au fichier actuellement présent sur le VPS ; il vérifie l'intégrité de la copie restaurée par rapport à la sauvegarde utilisée.

## 9. Automatisation des sauvegardes

L'environnement Knox dispose d'une organisation de sauvegarde automatisée, avec des scripts situés dans :

```text
/home/raphael/scripts/
```

Une planification quotidienne à 02 h a été configurée lors des travaux précédents.

La présence du fichier `sport.sql` daté du 10 novembre à 02 h est cohérente avec cette planification.

Pour examiner les tâches programmées :

```bash
crontab -l
```

Pour vérifier les scripts :

```bash
ls -lh /home/raphael/scripts/
```

Les commandes exactes et les mécanismes de chaque script doivent être documentés à partir de leur contenu réel avant publication.

## 10. Résultats des vérifications

| Critère | Résultat |
|---|---|
| Répertoire de sauvegarde présent | Validé |
| Fichiers Web de SportPulse disponibles | Validé |
| Répertoires personnels sauvegardés | Copies présentes |
| Archive `home-complet.tar.gz` présente | Validé |
| Fichier de permissions ACL présent | Validé |
| Fichiers SQL de la base `sport` présents | Validé |
| Connexion SSH sortante de Knox vers le VPS | Validé |
| Récupération de `index.php` | Validé |
| Ouverture et lecture de `index.php` | Validé |
| Empreintes SHA-256 identiques | Validé |
| Restauration complète du site | Non testée dans cette démonstration |
| Importation complète de la base SQL | Non testée dans cette démonstration |
| Restauration complète des ACL | Non testée dans cette démonstration |

## 11. Recommandations

Pour maintenir des sauvegardes exploitables :

1. Contrôler régulièrement l'exécution des sauvegardes automatiques.
2. Vérifier que les fichiers produits ne sont pas vides.
3. Conserver plusieurs versions lorsque l'espace disponible le permet.
4. Tester périodiquement la récupération de fichiers.
5. Vérifier les empreintes SHA-256 après restauration.
6. Tester séparément la restauration de la base MySQL.
7. Éviter de restaurer directement sur le serveur de production pendant les démonstrations.
8. Protéger les archives et les fichiers SQL contre les accès non autorisés.

## 12. Conclusion

Knox dispose de sauvegardes des fichiers Web, des répertoires personnels et de la base de données du VPS.

Un test pratique a démontré qu'un fichier `index.php` pouvait être récupéré depuis la sauvegarde, ouvert et comparé à sa copie originale de sauvegarde.

Les empreintes SHA-256 identiques confirment l'intégrité du fichier restauré.

Cette démonstration constitue une preuve concrète de la capacité de Knox à récupérer des données sauvegardées.

---

