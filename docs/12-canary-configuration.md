# Canary — Configuration des services leurres OpenCanary

**Projet :** Sécurité TP1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine :** `raphael-canary`  
**VM Proxmox :** `103`  
**Système :** Ubuntu Server 22.04 LTS  
**Adresse IP :** `10.1.106.32`  
**Solution :** OpenCanary

## 1. Objectif

Après l'installation d'OpenCanary, la deuxième étape consiste à configurer les services réseau simulés.

Le but est de créer un environnement leurre capable d'enregistrer les interactions suspectes, sans exposer les véritables services de production du projet.

La configuration retenue comprend :

- Un service FTP simulé.
- Un service HTTP simulé.
- Un service MySQL simulé.
- Un mécanisme de détection des scans de ports.

L'accès SSH administratif reste distinct des services leurres.

## 2. Emplacement de la configuration

Le fichier principal d'OpenCanary est :

```text
/etc/opencanaryd/opencanary.conf
```

Ce fichier contient les paramètres permettant d'activer les services, de définir leurs ports et de configurer leur comportement.

Pour consulter le fichier sur Canary :

```bash
sudo cat /etc/opencanaryd/opencanary.conf
```

Pour contrôler sa syntaxe JSON, si Python 3 est disponible :

```bash
sudo python3 -m json.tool /etc/opencanaryd/opencanary.conf > /dev/null
```

Cette vérification contrôle la syntaxe JSON, mais ne garantit pas à elle seule que tous les paramètres sont acceptés par OpenCanary.

## 3. Services leurres configurés

Les services suivants ont été retenus pour le projet :

| Service | Port TCP | Fonction |
|---|---|---|
| FTP | `21` | Détecter les tentatives de connexion à un service de transfert de fichiers |
| HTTP | `80` | Présenter une interface web leurre |
| MySQL | `3306` | Détecter les interactions avec un service de base de données simulé |

Ces services sont hébergés sur la machine Canary et ne correspondent pas aux services réels du VPS SportPulse.

### 3.1 Service FTP

Le service FTP simulé utilise le port :

```text
21/TCP
```

Il permet de présenter un point d'accès qui ressemble à un serveur de transfert de fichiers.

Les interactions avec ce service peuvent générer des événements dans les journaux d'OpenCanary.

**Objectif de sécurité :** repérer les tentatives d'accès à un service FTP qui n'a pas de fonction légitime dans l'environnement de production.

### 3.2 Service HTTP

Le service HTTP simulé utilise le port :

```text
80/TCP
```

La configuration mise en place présente une interface leurre imitant un équipement **Synology**.

Cette présentation vise à donner l'apparence d'une interface d'administration d'un équipement réseau.

Le service permet de détecter des interactions HTTP, notamment des requêtes dirigées vers cette interface.

Les essais réalisés depuis Knox ont permis d'obtenir des réponses HTTP, confirmant que le service était accessible.

### 3.3 Service MySQL

Le service MySQL simulé utilise le port :

```text
3306/TCP
```

Ce port est habituellement associé aux connexions MySQL.

Sur Canary, il s'agit d'un service leurre et non du serveur de base de données utilisé par SportPulse.

**Objectif de sécurité :** détecter les tentatives de connexion à une base de données supposée accessible sur le réseau.

## 4. Détection des scans de ports

La fonctionnalité de détection des scans de ports a également été activée dans OpenCanary.

Elle complète les services leurres en permettant de signaler certaines activités de reconnaissance réseau.

Un scan de ports peut constituer une étape préparatoire à une tentative d'intrusion.

Il faut toutefois distinguer :

- Les scans administratifs autorisés.
- Les analyses réalisées dans le cadre des tests.
- Les activités de reconnaissance non autorisées.

La détection d'un scan constitue un indicateur d'activité, mais ne prouve pas à elle seule une compromission.

## 5. Séparation entre SSH administratif et services leurres

La machine Canary dispose d'un accès SSH réel destiné à son administration.

Cet accès utilise le port :

```text
870/TCP
```

Il est distinct des ports simulés par OpenCanary.

| Port | Usage |
|---|---|
| `21` | FTP leurre |
| `80` | HTTP leurre |
| `3306` | MySQL leurre |
| `870` | SSH administratif réel |

Cette séparation permet de conserver un accès de maintenance à la machine sans confondre celui-ci avec les services destinés à attirer et enregistrer les interactions suspectes.

## 6. Gestion du service OpenCanary

OpenCanary est exécuté comme service système sous le nom :

```text
opencanary
```

### Consulter l'état du service

```bash
sudo systemctl status opencanary
```

### Vérifier son activation au démarrage

```bash
sudo systemctl is-enabled opencanary
```

### Redémarrer après une modification de configuration

```bash
sudo systemctl restart opencanary
```

Le redémarrage ne doit être effectué qu'après avoir enregistré et vérifié les modifications apportées à la configuration.

### Consulter les messages du service

```bash
sudo journalctl -u opencanary --no-pager -n 30
```

Ces commandes permettent de contrôler le fonctionnement du service et de rechercher d'éventuelles erreurs.

## 7. Journalisation des événements

OpenCanary permet d'enregistrer des événements liés aux interactions avec les services simulés.

Selon le type d'événement et la configuration du logiciel, les informations collectées peuvent comprendre :

- La date et l'heure.
- L'adresse IP source.
- L'adresse IP de destination.
- Le port ou le service ciblé.
- Le type d'interaction détectée.
- Des informations complémentaires propres au service.

Ces événements constituent des traces utiles pour analyser les tentatives d'accès au serveur leurre.

Le chemin exact des fichiers de journalisation dépend des paramètres définis dans `opencanary.conf`.

Les résultats concrets des essais seront présentés dans :

**`docs/14-canary-tests.md`**

## 8. Vérifications des services

Pour consulter les ports TCP en écoute sur Canary :

```bash
sudo ss -lntp
```

Cette commande permet d'identifier les services actifs et les ports sur lesquels ils écoutent.

Les résultats doivent être comparés aux ports attendus :

| Port attendu | Service |
|---|---|
| `21/TCP` | FTP |
| `80/TCP` | HTTP |
| `3306/TCP` | MySQL |
| `870/TCP` | SSH administratif |

La présence d'un port en écoute ne garantit pas à elle seule le bon fonctionnement de toutes les fonctions de détection.

Des essais de connexion sont nécessaires pour valider le comportement du honeypot.

## 9. Tests HTTP déjà réalisés

Des requêtes HTTP ont été envoyées depuis Knox vers Canary le **5 novembre 2026**.

Les essais comprenaient :

- Une requête HTTP `GET`.
- Une requête HTTP `POST`.

Les réponses observées étaient :

| Requête | Code HTTP observé |
|---|---|
| `GET` | `302` |
| `POST` | `200` |

Le code `302` correspond à une redirection HTTP.

Le code `200` indique que la requête a reçu une réponse HTTP de succès.

Ces résultats confirment que le service HTTP leurre répondait aux requêtes envoyées depuis Knox.

Ils ne suffisent pas, à eux seuls, à confirmer l'enregistrement de chaque requête dans les journaux. Cette vérification relève de l'analyse des événements.

## 10. Intégration avec le système d'alertes

La machine Canary dispose également d'un mécanisme complémentaire de notification par Gmail.

Ce mécanisme utilise :

```text
/usr/local/bin/opencanary-gmail-alert.py
```

Le service associé est :

```text
opencanary-gmail-alert.service
```

Les paramètres sensibles nécessaires à l'envoi des messages sont conservés dans un fichier protégé, séparé de la documentation publique.

Le fonctionnement du mécanisme d'alerte sera détaillé dans :

**`docs/13-canary-alertes-gmail.md`**

Aucun mot de passe d'application ni jeton d'authentification ne doit être publié sur GitHub.

## 11. Résultats de la configuration

| Élément | État |
|---|---|
| Fichier de configuration OpenCanary | Présent |
| Service FTP sur le port `21` | Configuré |
| Service HTTP sur le port `80` | Configuré |
| Interface HTTP de type Synology | Configurée |
| Service MySQL sur le port `3306` | Configuré |
| Détection des scans de ports | Activée |
| SSH administratif sur le port `870` | Configuré |
| Service OpenCanary géré par `systemd` | Validé |
| Démarrage automatique d'OpenCanary | Validé |
| Réponse HTTP à une requête `GET` | Validée |
| Réponse HTTP à une requête `POST` | Validée |
| Envoi d'une alerte Gmail | Vérifié séparément |

## 12. Limites et précautions

Le serveur leurre a pour fonction principale de détecter et de documenter des interactions suspectes.

Il ne remplace pas :

- Un pare-feu.
- Un système de sauvegarde.
- Une politique de mises à jour.
- Un système complet de détection et de réponse aux incidents.

De plus, un service leurre ne doit pas être considéré comme un service réel pouvant héberger des données de production.

L'accès à Canary doit rester maîtrisé, et les tests doivent être réalisés uniquement dans le périmètre autorisé du projet.

## 13. Conclusion

OpenCanary a été configuré sur la machine `raphael-canary` pour simuler trois services réseau : FTP, HTTP et MySQL.

La détection des scans de ports complète ces services afin d'observer certaines activités de reconnaissance.

Les premiers essais HTTP depuis Knox ont confirmé que le service web leurre répondait aux requêtes.

Cette configuration constitue la base du dispositif de détection du projet.

Les prochaines étapes consistent à documenter les notifications Gmail et les résultats des essais de détection.

---

**Documentation associée :**

- [Installation de Canary](11-canary-installation.md)
- [Alertes Gmail](13-canary-alertes-gmail.md)
- [Tests du honeypot](14-canary-tests.md)
