# Canary — Configuration des alertes Gmail

**Projet :** Sécurité TP1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine :** `raphael-canary`  
**VM Proxmox :** `103`  
**Système :** Ubuntu Server 22.04 LTS  
**Adresse IP :** `10.1.106.32`  
**Solution de détection :** OpenCanary  
**Système de notification :** Gmail

## 1. Objectif

Un serveur leurre permet d'enregistrer les tentatives de connexion et les activités suspectes. Cependant, la consultation manuelle des journaux ne garantit pas qu'un événement sera remarqué rapidement.

Pour améliorer la surveillance, un mécanisme de notification par courriel a été ajouté à OpenCanary.

L'objectif est de permettre l'envoi d'une alerte Gmail lorsqu'un événement détecté par le honeypot est pris en charge par le mécanisme de notification.

Cette fonctionnalité complète les journaux locaux en facilitant la prise de connaissance des événements suspects.

## 2. Architecture du système d'alertes

Le système repose sur plusieurs composants :

| Composant | Fonction |
|---|---|
| OpenCanary | Détecte les interactions avec les services leurres |
| Journaux OpenCanary | Conservent les événements détectés |
| Script Python | Traite les événements destinés aux notifications |
| Service `systemd` | Assure l'exécution du mécanisme d'alerte |
| Gmail | Reçoit les notifications par courriel |

Le fonctionnement général est le suivant :

1. Une machine interagit avec un service leurre de Canary.
2. OpenCanary détecte l'interaction et produit un événement.
3. Le mécanisme de notification traite l'événement.
4. Un message est envoyé vers la boîte Gmail configurée.
5. L'administrateur peut consulter l'alerte et examiner les journaux pour obtenir davantage d'informations.

L'envoi d'un courriel dépend du bon fonctionnement du script, du service de notification et de la connexion au serveur de messagerie.

## 3. Script de notification Python

Le script de notification est installé sur Canary à l'emplacement suivant :

```text
/usr/local/bin/opencanary-gmail-alert.py
```

Il constitue le composant chargé du traitement des événements pour l'envoi des alertes.

Son rôle est distinct de celui d'OpenCanary :

- **OpenCanary** assure la détection des interactions.
- **Le script Python** prend en charge les notifications.
- **Gmail** constitue le canal de réception.

Cette séparation permet de conserver le mécanisme de notification indépendamment de la configuration des services leurres.

### Vérification de la présence du script

Sur la machine Canary :

```bash
ls -l /usr/local/bin/opencanary-gmail-alert.py
```

Cette commande permet de vérifier la présence du fichier.

Le code source du script peut être documenté séparément dans le dossier `docs/scripts/`, après vérification et suppression de toute information confidentielle.

## 4. Gestion du service de notification

Le script de notification est exécuté par un service `systemd` nommé :

```text
opencanary-gmail-alert.service
```

L'utilisation de `systemd` facilite la gestion du processus et son suivi.

### Vérification de l'état du service

```bash
sudo systemctl status opencanary-gmail-alert.service
```

### Vérification de l'activation au démarrage

```bash
sudo systemctl is-enabled opencanary-gmail-alert.service
```

### Consultation des journaux du service

```bash
sudo journalctl -u opencanary-gmail-alert.service --no-pager -n 30
```

Ces commandes permettent de contrôler le fonctionnement du mécanisme de notification et de rechercher d'éventuelles erreurs.

## 5. Configuration des paramètres sensibles

Les informations nécessaires à l'authentification auprès de Gmail sont conservées dans un fichier distinct :

```text
/etc/opencanary-alerts/gmail.env
```

Ce fichier contient les paramètres sensibles utilisés par le mécanisme de notification, notamment les informations d'authentification nécessaires à l'envoi des messages.

Le mot de passe d'application Gmail ne doit pas être inscrit directement dans le code source publié sur GitHub.

### Protection du fichier

Le fichier de configuration est protégé par des permissions restrictives.

La configuration observée utilise :

```text
600
```

Ces permissions limitent la lecture et l'écriture au propriétaire du fichier.

Pour consulter les permissions sans afficher les informations confidentielles :

```bash
sudo stat -c '%a %U:%G %n' /etc/opencanary-alerts/gmail.env
```

**Important :** le contenu de `gmail.env`, les mots de passe d'application et les autres secrets d'authentification ne doivent jamais être publiés dans le dépôt GitHub.

## 6. Utilisation de Gmail

L'envoi des alertes repose sur une authentification permettant au script de communiquer avec le service de messagerie.

Un mot de passe d'application Gmail a été utilisé pour le mécanisme de notification.

Cette méthode permet d'éviter de placer le mot de passe principal du compte Google dans le script.

Les paramètres de messagerie doivent être conservés dans le fichier d'environnement protégé et accessibles uniquement aux composants autorisés.

L'adresse de destination et les secrets d'authentification ne sont pas reproduits dans cette documentation publique.

## 7. Intégration avec OpenCanary

Les notifications complètent les services leurres déjà configurés sur Canary :

| Service | Port | Fonction |
|---|---|---|
| FTP | `21/TCP` | Détection d'interactions FTP |
| HTTP | `80/TCP` | Détection d'interactions avec l'interface leurre |
| MySQL | `3306/TCP` | Détection de tentatives de connexion MySQL |
| Détection des scans | Selon la configuration | Observation de certaines activités de reconnaissance |

Lorsqu'un événement est détecté, il peut être pris en charge par le mécanisme de notification.

La présence d'un événement dans les journaux ne garantit pas nécessairement l'envoi d'un courriel pour chaque interaction. Cela dépend du comportement du script et des règles de traitement configurées.

## 8. Test de réception d'une alerte Gmail

Un test de notification a été réalisé dans le cadre du projet.

**Date de vérification : 9 novembre 2026.**

Le résultat observé a confirmé la réception d'une alerte dans la boîte Gmail configurée.

Cette vérification démontre que le mécanisme d'envoi et de réception des notifications était opérationnel lors du test.

Elle confirme également que les composants nécessaires à la transmission de l'alerte pouvaient communiquer correctement.

### Résultat du test

| Critère | Résultat |
|---|---|
| Script Python de notification installé | Validé |
| Service `systemd` de notification présent | Validé |
| Fichier de configuration Gmail présent | Validé |
| Permissions restrictives du fichier sensible | Configurées |
| Utilisation d'un mot de passe d'application | Configurée |
| Réception d'une alerte Gmail | Validée |
| Fonctionnement continu sans interruption | Non démontré par ce test ponctuel |

La réception d'un message confirme le fonctionnement du mécanisme au moment du test, mais ne remplace pas une surveillance régulière du service.

## 9. Procédure de vérification

Pour vérifier le mécanisme d'alerte sur Canary :

1. Contrôler l'état du service OpenCanary.
2. Contrôler l'état du service de notification Gmail.
3. Vérifier que le fichier d'environnement existe et possède des permissions restrictives.
4. Consulter les journaux du service de notification.
5. Réaliser, dans le périmètre autorisé, une interaction avec un service leurre.
6. Vérifier la présence de l'événement dans les journaux OpenCanary.
7. Vérifier la réception du courriel correspondant, lorsque cet événement doit déclencher une notification.

Les tests doivent être réalisés uniquement sur les machines autorisées du projet.

## 10. Sécurité et confidentialité

Le système de notification implique l'utilisation de paramètres sensibles.

Les précautions retenues sont les suivantes :

- Conservation des informations d'authentification dans un fichier séparé.
- Restriction des permissions sur `gmail.env`.
- Absence de mots de passe dans la documentation publique.
- Séparation du script de notification et des services leurres.
- Utilisation de journaux pour faciliter le diagnostic des erreurs.
- Protection des informations personnelles pouvant apparaître dans les courriels ou les captures d'écran.

Avant toute publication d'une capture d'alerte, les adresses de messagerie personnelles et les éventuelles informations sensibles doivent être masquées.

## 11. Limites du système

Le mécanisme d'alerte Gmail améliore la visibilité des événements, mais présente certaines limites :

- Il dépend de la disponibilité du service de messagerie.
- Il nécessite des paramètres d'authentification valides.
- Une interruption du service de notification peut empêcher l'envoi de messages.
- Toutes les interactions ne déclenchent pas nécessairement une notification.
- Une alerte ne constitue pas automatiquement une preuve d'intrusion.
- Le courriel ne remplace pas la conservation et l'analyse des journaux.

Il est donc important de conserver les journaux OpenCanary comme source principale d'information sur les événements détectés.

## 12. Conclusion

Un mécanisme de notification Gmail a été ajouté à la machine `raphael-canary` afin de compléter la détection assurée par OpenCanary.

Il repose sur un script Python, un service `systemd` et un fichier de configuration protégé contenant les paramètres nécessaires à l'envoi des messages.

Le test du **9 novembre 2026** a confirmé la réception d'une alerte Gmail.

Le système permet ainsi d'associer la détection locale des interactions avec un moyen de notification à distance.

---

**Documentation associée :**

- [Installation de Canary](11-canary-installation.md)
- [Configuration d'OpenCanary](12-canary-configuration.md)
- [Tests du honeypot](14-canary-tests.md)
