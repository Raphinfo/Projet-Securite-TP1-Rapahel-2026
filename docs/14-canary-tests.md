# Canary — Tests de détection et validation du honeypot OpenCanary

**Projet :** Sécurité TP1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine testée :** `raphael-canary`  
**VM Proxmox :** `103`  
**Système :** Ubuntu Server 22.04 LTS  
**Adresse IP de Canary :** `10.1.106.32`  
**Machine utilisée pour les essais :** `raphael-knox`  
**Adresse IP de Knox :** `10.1.106.34`

## 1. Objectif

L'objectif de cette étape est de vérifier le fonctionnement du serveur leurre OpenCanary après son installation et sa configuration.

Les essais permettent de contrôler :

- L'accessibilité du service HTTP simulé.
- Les réponses du serveur aux requêtes envoyées depuis Knox.
- Le fonctionnement du mécanisme de notification Gmail.
- La capacité du dispositif à fournir des informations exploitables pour la surveillance.

Les tests sont réalisés dans un environnement autorisé, sur les machines virtuelles du projet.

## 2. Environnement de test

Les essais reposent sur deux machines virtuelles distinctes.

| Machine | Adresse IP | Rôle |
|---|---|---|
| `raphael-canary` | `10.1.106.32` | Héberge OpenCanary et ses services leurres |
| `raphael-knox` | `10.1.106.34` | Envoie les requêtes de test |

La machine Knox joue ici le rôle d'un client qui interagit avec le service leurre.

Le VPS de production SportPulse n'est pas utilisé comme cible de ces essais.

## 3. Services configurés sur Canary

La configuration OpenCanary comprend les services suivants :

| Service | Port | État |
|---|---|---|
| FTP simulé | `21/TCP` | Configuré |
| HTTP simulé | `80/TCP` | Configuré et testé |
| MySQL simulé | `3306/TCP` | Configuré |
| Détection des scans de ports | Selon la configuration | Activée |
| SSH administratif réel | `870/TCP` | Configuré |

Les résultats détaillés présentés dans ce document concernent principalement le service HTTP et le mécanisme d'alerte Gmail.

La configuration d'un service ne constitue pas, à elle seule, une preuve qu'un test de détection a été effectué sur celui-ci.

## 4. Test HTTP GET

**Date du test : 5 novembre 2026**

Une requête HTTP de type `GET` a été envoyée depuis Knox vers l'adresse IP de Canary.

### Objectif

Vérifier que le service HTTP simulé répond aux connexions entrantes.

### Commande de vérification

Une requête équivalente peut être reproduite depuis Knox avec :

```bash
curl -i http://10.1.106.32/
```

L'option `-i` permet d'afficher les en-têtes HTTP de la réponse.

### Résultat observé

Le service HTTP de Canary a répondu avec le code :

```text
HTTP 302
```

Le code `302` correspond à une redirection HTTP.

**Résultat : réponse du service HTTP validée.**

Ce résultat confirme que le service leurre était accessible depuis Knox et qu'il répondait à la requête.

Il ne démontre pas, à lui seul, que l'événement a été enregistré dans les journaux d'OpenCanary.

## 5. Test HTTP POST

**Date du test : 5 novembre 2026**

Une requête HTTP de type `POST` a également été envoyée depuis Knox vers Canary.

### Objectif

Vérifier que le service HTTP simulé réagit à une requête différente d'un simple accès à la page.

### Exemple de commande reproductible

```bash
curl -i -X POST http://10.1.106.32/
```

Cette commande illustre le type de requête utilisé. Elle n'est pas présentée comme une transcription exacte de la commande exécutée lors du test initial.

### Résultat observé

Le service a retourné :

```text
HTTP 200
```

Le code `200` indique que le serveur a répondu avec un statut HTTP de succès.

**Résultat : réponse à une requête POST validée.**

Ce test confirme que le service HTTP simulé acceptait et traitait une requête POST au niveau du protocole HTTP.

Il ne valide pas à lui seul un mécanisme d'authentification ou une tentative d'intrusion.

## 6. Interface HTTP leurre

Le service HTTP d'OpenCanary a été configuré pour présenter une interface simulant un équipement Synology.

L'objectif est de proposer un service crédible pouvant attirer des interactions non sollicitées.

Cette interface ne correspond pas à un véritable équipement Synology utilisé pour la production.

Les réponses HTTP observées lors des tests confirment que le service web simulé était accessible.

## 7. Test du mécanisme d'alerte Gmail

**Date de vérification : 9 novembre 2026**

Un mécanisme complémentaire de notification par Gmail a été installé sur Canary.

Il repose sur :

- Un script Python de notification.
- Un service `systemd`.
- Un fichier d'environnement protégé contenant les paramètres nécessaires à l'envoi des messages.

### Composants utilisés

Script :

```text
/usr/local/bin/opencanary-gmail-alert.py
```

Service :

```text
opencanary-gmail-alert.service
```

Configuration sensible :

```text
/etc/opencanary-alerts/gmail.env
```

### Résultat observé

Une alerte a été reçue dans la boîte Gmail configurée.

**Résultat : réception d'une notification validée.**

Cette vérification confirme que le mécanisme de notification était opérationnel au moment du test.

Elle ne démontre pas que chaque événement OpenCanary déclenche systématiquement un courriel.

## 8. Vérification des services

Pour examiner l'état des composants sur Canary, les commandes suivantes peuvent être utilisées.

### État d'OpenCanary

```bash
sudo systemctl status opencanary
```

### État du mécanisme d'alerte

```bash
sudo systemctl status opencanary-gmail-alert.service
```

### Ports en écoute

```bash
sudo ss -lntp
```

### Journaux du service OpenCanary

```bash
sudo journalctl -u opencanary --no-pager -n 30
```

### Journaux du service d'alerte

```bash
sudo journalctl -u opencanary-gmail-alert.service --no-pager -n 30
```

Ces commandes constituent une procédure de contrôle reproductible. Leur présence dans ce document ne signifie pas qu'elles ont toutes été réexécutées pendant la rédaction.

## 9. Synthèse des résultats

| Vérification | Résultat |
|---|---|
| Installation d'OpenCanary | Validée |
| Configuration des services leurres | Validée |
| Configuration HTTP de type Synology | Validée |
| Réponse HTTP GET depuis Knox | Validée — `302` |
| Réponse HTTP POST depuis Knox | Validée — `200` |
| Installation du mécanisme Gmail | Validée |
| Réception d'une alerte Gmail | Validée |
| Détection détaillée d'une tentative FTP | Non documentée dans les essais présentés |
| Détection détaillée d'une tentative MySQL | Non documentée dans les essais présentés |
| Détection effective d'un scan de ports | Non documentée dans les essais présentés |
| Correspondance entre chaque requête HTTP et une entrée de journal | Non établie par les seuls codes HTTP |
| Notification Gmail pour chaque type de service | Non vérifiée individuellement |

## 10. Limites des tests

Les essais réalisés permettent de confirmer plusieurs fonctions essentielles du dispositif, mais ne constituent pas une validation exhaustive de tous les scénarios d'attaque.

Les principales limites sont :

- Les réponses HTTP démontrent l'accessibilité du service, mais pas nécessairement la création d'un événement de détection.
- Les services FTP et MySQL sont configurés, mais leurs résultats de tests détaillés ne sont pas présentés ici.
- La détection des scans de ports n'est pas validée par un résultat de test documenté dans cette section.
- La réception d'une alerte Gmail démontre un envoi réussi, mais pas la disponibilité permanente du mécanisme.
- Aucun test d'intrusion complet n'est revendiqué.

Ces limites permettent de présenter fidèlement la portée des vérifications réalisées.

## 11. Captures et preuves

Les preuves visuelles du projet peuvent être conservées dans le dossier :

```text
captures/
```

Les captures pertinentes comprennent notamment :

- La configuration ou l'état du service OpenCanary.
- Les résultats des requêtes HTTP depuis Knox.
- Les journaux présentant les événements détectés.
- La réception d'une alerte Gmail, après masquage des informations personnelles.

Les captures doivent correspondre aux tests réellement effectués.

Aucun mot de passe, jeton d'authentification ou secret de messagerie ne doit apparaître dans les fichiers publiés.

## 12. Conclusion

Les essais réalisés ont permis de confirmer que le service HTTP leurre d'OpenCanary répondait aux requêtes envoyées depuis Knox.

Le **5 novembre 2026**, les requêtes GET et POST ont produit respectivement des réponses HTTP `302` et `200`.

Le **9 novembre 2026**, la réception d'une alerte Gmail a également été confirmée.

Ces résultats valident l'accessibilité du service HTTP simulé et le fonctionnement ponctuel du mécanisme de notification.

Les tests détaillés des autres services et la corrélation complète entre interactions, journaux et notifications constituent des vérifications complémentaires possibles.

---

**Documentation associée :**

- [Installation de Canary](11-canary-installation.md)
- [Configuration des services leurres](12-canary-configuration.md)
- [Alertes Gmail](13-canary-alertes-gmail.md)
