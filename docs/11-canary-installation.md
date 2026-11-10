# Canary — Installation du serveur leurre OpenCanary

**Projet :** Sécurité TP1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine :** `raphael-canary`  
**Identifiant Proxmox :** `103`  
**Système d'exploitation :** Ubuntu Server 22.04 LTS  
**Adresse IP :** `10.1.106.32`  
**Solution déployée :** OpenCanary

## 1. Objectif

L'objectif de cette étape est de mettre en place un **honeypot**, également appelé serveur leurre, afin de détecter les tentatives de connexion et les activités suspectes sur le réseau.

Contrairement au VPS qui héberge le site SportPulse, Canary n'est pas destiné à fournir des services de production.

Il simule des services réseau susceptibles d'attirer des tentatives d'accès non autorisées.

Le système doit permettre de :

- Détecter les connexions vers les services simulés.
- Enregistrer les événements suspects.
- Identifier les adresses IP à l'origine des tentatives.
- Faciliter l'analyse des comportements observés.
- Transmettre des alertes lors de certaines interactions.

La solution retenue est **OpenCanary**, un logiciel libre conçu pour déployer des services leurres.

## 2. Environnement technique

Canary a été déployé sous forme de machine virtuelle sur l'hyperviseur Proxmox.

| Élément | Configuration |
|---|---|
| Nom de la VM | `raphael-canary` |
| Identifiant Proxmox | `103` |
| Système | Ubuntu Server 22.04 LTS |
| Processeur | 1 vCPU |
| Mémoire vive | 2 Go |
| Disque | 25 Go |
| Adresse IP | `10.1.106.32` |
| Utilisateur principal | `raphael` |
| Logiciel | OpenCanary |

Un compte administratif `david` disposant des droits `sudo` a également été configuré pour permettre les vérifications du projet.

## 3. Principe de fonctionnement

OpenCanary permet de simuler plusieurs services réseau sans installer les applications réelles correspondantes.

Lorsqu'un appareil tente d'accéder à un service simulé, OpenCanary peut enregistrer l'événement dans ses journaux.

Dans notre environnement, les services leurres retenus sont :

| Service simulé | Port |
|---|---|
| FTP | `21/TCP` |
| HTTP | `80/TCP` |
| MySQL | `3306/TCP` |

Le service HTTP présente une interface leurre imitant un équipement Synology.

Ces services ne doivent pas être confondus avec les services de production du VPS.

## 4. Préparation de la machine virtuelle

La machine virtuelle `raphael-canary` a été créée sur Proxmox avec Ubuntu Server 22.04 LTS.

La préparation du système comprend :

1. L'installation du système d'exploitation.
2. La configuration du réseau.
3. La création du compte utilisateur principal.
4. La préparation des outils nécessaires à l'exécution d'OpenCanary.
5. La sécurisation de l'accès administratif.

Le serveur SSH administratif utilise le port `870`, distinct des services leurres.

Cette séparation permet d'administrer la machine sans confondre les connexions légitimes avec les interactions destinées au honeypot.

## 5. Installation d'OpenCanary

OpenCanary est installé dans un environnement virtuel Python dédié.

Répertoire utilisé :

```text
/home/raphael/opencanary/
```

Environnement virtuel :

```text
/home/raphael/opencanary/venv/
```

L'utilisation d'un environnement virtuel Python permet d'isoler les dépendances d'OpenCanary des composants Python du système.

Cette organisation facilite également la maintenance du logiciel.

### Vérification de l'environnement

La présence de l'environnement peut être contrôlée sur Canary avec :

```bash
ls -ld /home/raphael/opencanary/venv
```

Cette commande permet de vérifier que le répertoire de l'environnement virtuel existe.

## 6. Fichier de configuration

Le fichier principal de configuration d'OpenCanary est situé à l'emplacement suivant :

```text
/etc/opencanaryd/opencanary.conf
```

Ce fichier définit notamment :

- Les services leurres activés.
- Les ports utilisés.
- Les paramètres des services simulés.
- Les mécanismes de journalisation.

La configuration détaillée des services sera présentée dans le document suivant :

**`docs/12-canary-configuration.md`**

## 7. Exécution en tant que service système

OpenCanary est géré par `systemd` sous le nom :

```text
opencanary
```

Ce mécanisme permet de gérer son démarrage et son fonctionnement comme un service Linux.

### Vérification de l'état

Commande de contrôle :

```bash
sudo systemctl status opencanary
```

### Vérification de l'activation au démarrage

```bash
sudo systemctl is-enabled opencanary
```

Lors des vérifications effectuées sur Canary, le service OpenCanary était configuré pour démarrer automatiquement.

L'utilisation de `systemd` facilite également le redémarrage du service après une maintenance ou un redémarrage de la machine virtuelle.

## 8. Organisation des composants

| Composant | Emplacement ou nom |
|---|---|
| Répertoire d'installation | `/home/raphael/opencanary/` |
| Environnement Python | `/home/raphael/opencanary/venv/` |
| Configuration OpenCanary | `/etc/opencanaryd/opencanary.conf` |
| Service système | `opencanary` |
| Service d'alerte Gmail | `opencanary-gmail-alert.service` |

Le service d'alerte Gmail est un composant complémentaire. Son fonctionnement sera détaillé dans `docs/13-canary-alertes-gmail.md`.

## 9. Vérifications réalisées

Les vérifications effectuées sur la machine Canary ont permis de confirmer les éléments suivants :

| Critère | Résultat |
|---|---|
| Machine virtuelle Canary créée | Validé |
| Ubuntu Server installé | Validé |
| Adresse IP configurée | Validé |
| Environnement virtuel Python présent | Validé |
| OpenCanary installé | Validé |
| Fichier de configuration présent | Validé |
| Service `opencanary` activé | Validé |
| Services leurres FTP, HTTP et MySQL configurés | Validé |
| Interactions HTTP détectées lors des essais | Validé |

Les essais de connexion et les événements détectés seront présentés séparément dans :

**`docs/14-canary-tests.md`**

## 10. Précautions de sécurité

Un serveur leurre doit être isolé et administré avec précaution.

Les mesures retenues dans notre environnement comprennent :

- L'utilisation d'une machine virtuelle distincte du VPS de production.
- La séparation entre les services simulés et l'accès SSH administratif.
- L'utilisation d'un environnement Python dédié.
- La gestion du processus OpenCanary avec `systemd`.
- La conservation des informations sensibles en dehors de la documentation publique.

Le serveur leurre ne doit pas contenir de véritables identifiants de production ni devenir un point d'accès vers les autres machines.

## 11. Conclusion

La machine virtuelle `raphael-canary` a été préparée pour héberger OpenCanary sous Ubuntu Server 22.04 LTS.

Le logiciel est installé dans un environnement Python dédié et géré par un service `systemd` activé au démarrage.

L'environnement constitue la base technique du serveur leurre du projet.

Les prochaines étapes consistent à documenter la configuration des services simulés, le mécanisme d'alerte Gmail et les résultats des tests de détection.

---

**Document suivant :** `docs/12-canary-configuration.md`
