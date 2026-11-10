# Knox — Installation et configuration de la machine virtuelle

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant
**Plateforme :** Proxmox VE
**Identifiant de la VM :** `110`
**Nom de la machine :** `raphael-knox`
**Système :** Ubuntu Server 22.04.5 LTS

## 1. Objectif

Knox est une machine virtuelle dédiée à la protection des données et à la surveillance de l'intégrité du VPS.

Ses principales fonctions sont :

- Récupérer les sauvegardes des fichiers Web du VPS.
- Sauvegarder les répertoires personnels.
- Sauvegarder la base de données du site SportPulse.
- Surveiller les modifications de fichiers de configuration sensibles.
- Conserver des copies permettant la restauration des données.

Pour réduire sa surface d'attaque, Knox ne doit pas héberger de serveur SSH.

## 2. Architecture

L'environnement comprend deux machines distinctes :

| Machine | Adresse IP     | Fonction                                           |
| ------- | -------------- | -------------------------------------------------- |
| VPS     | `172.105.99.9` | Hébergement du site SportPulse et des services Web |
| Knox    | `10.1.106.34`  | Sauvegarde et surveillance d'intégrité             |

Knox établit une connexion SSH **sortante** vers le VPS sur le port TCP `870`.

Le VPS dispose d'un compte dédié aux sauvegardes : `knoxbackup`.

Cette architecture permet à Knox de récupérer les données nécessaires sans exposer un serveur SSH sur la machine de sauvegarde.

## 3. Création de la machine virtuelle

La VM a été créée dans Proxmox avec les caractéristiques suivantes :

| Paramètre              | Configuration           |
| ---------------------- | ----------------------- |
| VMID                   | `110`                   |
| Nom                    | `raphael-knox`          |
| Système d'exploitation | Ubuntu Server 22.04 LTS |
| Processeur             | 1 vCPU                  |
| Mémoire                | 2 Go                    |
| Disque virtuel         | 25 Go                   |
| Architecture           | x86-64                  |
| Virtualisation         | KVM                     |

La VM utilise un disque virtuel de 25 Go.

Lors de la vérification, le volume logique monté sur `/` disposait d'environ 11,5 Go. Le disque virtuel et la taille du système de fichiers ne doivent donc pas être confondus.

## 4. Vérification du système

Commande exécutée sur Knox :

```bash
hostnamectl
```

Résultats observés :

```text
Static hostname: raphael-knox
Virtualization: kvm
Operating System: Ubuntu 22.04.5 LTS
Kernel: Linux 5.15.0-198-generic
Architecture: x86-64
```

Ces informations confirment l'installation d'Ubuntu Server sur une machine virtuelle KVM.

## 5. Vérification des ressources

Commande exécutée :

```bash
lscpu | grep -E '^CPU\(s\):|^Model name:'
free -h
lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS
```

Résultats principaux :

| Ressource             | Valeur observée |
| --------------------- | --------------- |
| Nombre de processeurs | 1               |
| Mémoire vive          | Environ 1,9 Gio |
| Disque `sda`          | 25 Go           |
| Volume logique racine | Environ 11,5 Go |

Les ressources attribuées correspondent aux exigences du projet.

## 6. Configuration réseau

Commande de vérification :

```bash
ip -4 -br addr show scope global
```

Résultat :

```text
ens18 UP 10.1.106.34/24 metric 100
```

Configuration réseau observée :

- Interface : `ens18`
- Adresse IPv4 : `10.1.106.34`
- Préfixe réseau : `/24`
- Réseau : `10.1.106.0/24`

La machine Knox utilise une adresse privée pour communiquer dans l'environnement du laboratoire.

## 7. Comptes utilisateurs

Le compte principal de la machine est :

```text
raphael
```

Un compte `david` a également été créé pour l'enseignant.

Commande de vérification :

```bash
id david
```

Résultat observé :

```text
uid=1001(david) gid=1001(david) groups=1001(david),27(sudo)
```

Le compte `david` dispose donc des privilèges d'administration par l'intermédiaire du groupe `sudo`.

### Procédure de reproduction

Sur une nouvelle machine Ubuntu :

```bash
sudo adduser david
sudo usermod -aG sudo david
```

Puis vérifier :

```bash
id david
```

Les mots de passe des comptes ne doivent pas être publiés dans le dépôt GitHub.

## 8. Absence de serveur SSH

L'une des exigences du projet est de ne pas installer de serveur SSH sur Knox.

La vérification a été réalisée avec :

```bash
dpkg -l openssh-server 2>/dev/null
systemctl is-active ssh 2>/dev/null
```

Résultats observés :

```text
un  openssh-server  <aucune>  <aucune>
inactive
```

Ces résultats indiquent que le paquet `openssh-server` n'est pas installé et que le service SSH n'est pas actif.

Knox est administré directement depuis la console Proxmox.

**Important :** l'absence de&#x20;

1.

serveur SSH n'empêche pas Knox d'utiliser un client SSH pour établir des connexions sortantes vers le VPS.

## 9. Authentification SSH sortante vers le VPS

Knox utilise une clé SSH dédiée aux sauvegardes.

Chemin de la clé privée sur Knox :

```text
/home/raphael/.ssh/id_ed25519_knox
```

Le compte distant utilisé est :

```text
knoxbackup
```

Le service SSH du VPS écoute sur le port :

```text
870/tcp
```

### 9.1 Procédure de création d'une clé

Pour reproduire cette configuration sur une nouvelle installation :

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_knox
```

La clé publique doit être autorisée sur le VPS pour le compte `knoxbackup`.

La clé privée reste exclusivement sur Knox.

**Attention :** ne pas écraser une clé existante, car cela pourrait interrompre les sauvegardes.

### 9.2 Test de connexion

Commande exécutée depuis Knox :

```bash
ssh -o BatchMode=yes \
    -o ConnectTimeout=10 \
    -p 870 \
    -i ~/.ssh/id_ed25519_knox \
    knoxbackup@172.105.99.9 \
    'echo CONNEXION_KNOX_OK'
```

Résultat obtenu :

```text
CONNEXION_KNOX_OK
```

Ce test confirme que :

1. Knox peut joindre le service SSH du VPS.
2. Le port `870` est accessible depuis Knox.
3. La clé SSH de sauvegarde est acceptée.
4. Le compte `knoxbackup` peut exécuter une commande distante.

La connexion fonctionne sans authentification interactive par mot de passe.

## 10. Principes de sécurité

La configuration de Knox repose sur plusieurs mesures :

- Séparation des rôles entre le VPS et la machine de sauvegarde.
- Utilisation d'un compte distant dédié : `knoxbackup`.
- Authentification par clé SSH pour les connexions sortantes.
- Absence de serveur SSH sur Knox.
- Administration de Knox par la console Proxmox.
- Présence d'un compte administrateur pour l'enseignant.
- Conservation des clés privées hors du dépôt GitHub.

Les mécanismes de sauvegarde, de surveillance et de restauration sont documentés séparément.

## 11. Résultats des vérifications

| Critère                                         | État     |
| ----------------------------------------------- | -------- |
| VM Knox présente dans Proxmox                   | Validé   |
| Identifiant VM `110`                            | Confirmé |
| Ubuntu Server 22.04 LTS                         | Validé   |
| 1 vCPU                                          | Validé   |
| 2 Go de RAM                                     | Validé   |
| Disque virtuel de 25 Go                         | Validé   |
| Adresse IP `10.1.106.34/24`                     | Validé   |
| Compte `david` présent                          | Validé   |
| Compte `david` membre de `sudo`                 | Validé   |
| Paquet `openssh-server` absent                  | Validé   |
| Service SSH inactif                             | Validé   |
| Connexion SSH sortante vers le VPS              | Validé   |
| Authentification du compte `knoxbackup` par clé | Validé   |

## 12. Conclusion

La machine virtuelle Knox est installée sur Proxmox et respecte les caractéristiques matérielles et système demandées.

Elle possède une interface réseau fonctionnelle, un compte administrateur pour l'enseignant et aucun serveur SSH actif.

La connexion sortante par clé SSH vers le compte `knoxbackup` du VPS a été testée avec succès.

Knox est donc prête à assurer ses fonctions de sauvegarde et de surveillance d'intégrité.

---

**Document suivant :** `docs/08-knox-sauvegardes.md`
