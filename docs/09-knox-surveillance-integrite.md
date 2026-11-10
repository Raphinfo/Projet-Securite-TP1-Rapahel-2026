# Knox — Surveillance de l'intégrité des fichiers sensibles du VPS

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine de surveillance :** `raphael-knox`  
**VM Proxmox :** `110`  
**Système :** Ubuntu Server 22.04.5 LTS  
**Adresse IP de Knox :** `10.1.106.34`  
**VPS surveillé :** `172.105.99.9`

## 1. Objectif

La surveillance d'intégrité permet de détecter les modifications apportées aux fichiers de configuration sensibles du VPS.

Knox utilise des empreintes cryptographiques SHA-256 pour comparer l'état actuel des fichiers à un état de référence enregistré précédemment.

Une différence entre les empreintes indique qu'au moins un fichier surveillé a été modifié.

Ce mécanisme permet notamment de détecter :

- Une modification de la configuration SSH.
- Une modification de la configuration HTTP d'Apache.
- Une modification de la configuration HTTPS d'Apache.
- Un changement inattendu dans les fichiers surveillés.

La surveillance détecte les changements, mais ne détermine pas automatiquement s'ils sont autorisés ou malveillants.

## 2. Architecture de surveillance

Le mécanisme fonctionne depuis la machine Knox.

| Élément | Fonction |
|---|---|
| VPS `172.105.99.9` | Héberge les fichiers de configuration |
| Knox `10.1.106.34` | Récupère et compare les empreintes |
| Compte `knoxbackup` | Permet la connexion SSH au VPS |
| Port SSH `870` | Canal de communication |
| SHA-256 | Algorithme de calcul des empreintes |
| `monitor.log` | Journal des résultats |

Knox établit une connexion SSH sortante vers le VPS.

Aucun serveur SSH n'est nécessaire sur Knox.

## 3. Fichiers surveillés

Trois fichiers sensibles du VPS sont surveillés :

| Fichier | Rôle |
|---|---|
| `/etc/ssh/sshd_config` | Configuration du service SSH |
| `/etc/apache2/sites-available/securite.conf` | Configuration HTTP du site SportPulse |
| `/etc/apache2/sites-available/securite-le-ssl.conf` | Configuration HTTPS du site SportPulse |

Ces fichiers influencent directement la sécurité et l'accessibilité des services hébergés.

## 4. Emplacement des fichiers de surveillance

Sur Knox, les fichiers utilisés sont :

| Chemin | Fonction |
|---|---|
| `/home/raphael/scripts/surveillance-integrite.sh` | Script de surveillance |
| `/home/raphael/empreintes-reference.sha256` | Empreintes de référence |
| `/home/raphael/monitor.log` | Journal de surveillance |
| `/home/raphael/.ssh/id_ed25519_knox` | Clé SSH utilisée pour joindre le VPS |

La clé SSH privée doit rester confidentielle et ne doit pas être publiée dans GitHub.

## 5. Fonctionnement de la surveillance

La surveillance repose sur quatre opérations principales.

### 5.1 Connexion au VPS

Knox établit une connexion SSH sortante vers le VPS avec les paramètres suivants :

- Utilisateur distant : `knoxbackup`.
- Port : `870`.
- Authentification : clé SSH.
- Exécution non interactive : `BatchMode=yes`.

### 5.2 Calcul des empreintes

Le script calcule les empreintes SHA-256 des trois fichiers sensibles du VPS.

Chaque empreinte est associée au chemin du fichier correspondant.

Les empreintes récupérées sont conservées temporairement sur Knox pour effectuer la comparaison.

### 5.3 Comparaison avec les références

Les empreintes actuelles sont comparées au fichier :

```text
/home/raphael/empreintes-reference.sha256
```

La comparaison permet de déterminer si les fichiers ont été modifiés depuis l'enregistrement de l'état de référence.

### 5.4 Enregistrement des résultats

Le résultat de chaque vérification est enregistré dans :

```text
/home/raphael/monitor.log
```

Trois situations peuvent être rencontrées :

| Résultat | Signification |
|---|---|
| `OK` | Aucune modification détectée |
| `ALERTE` | Différence entre les empreintes |
| `ERREUR` | Impossible de récupérer les empreintes |

Une alerte indique une différence, mais ne constitue pas automatiquement une preuve d'intrusion.

## 6. Script de surveillance

Le script de surveillance est conservé dans un fichier distinct afin de séparer le code source de la documentation technique.

**[Consulter le script de surveillance](scripts/surveillance-integrite.sh)**

Chemin du script sur Knox :

```text
/home/raphael/scripts/surveillance-integrite.sh
```

Chemin du script dans le dépôt GitHub :

```text
docs/scripts/surveillance-integrite.sh
```

Le script réalise les opérations suivantes :

1. Se connecter au VPS sur le port SSH `870`.
2. Récupérer les empreintes SHA-256 des fichiers surveillés.
3. Comparer les empreintes actuelles aux références.
4. Enregistrer le résultat dans `monitor.log`.
5. Signaler toute différence détectée.

Le script est publié séparément pour faciliter sa consultation et sa maintenance.

La clé privée SSH de Knox n'est pas incluse dans le dépôt.

## 7. Empreintes de référence

Les empreintes de référence sont conservées dans :

```text
/home/raphael/empreintes-reference.sha256
```

Commande de consultation :

```bash
cat /home/raphael/empreintes-reference.sha256
```

Ce fichier contient une empreinte SHA-256 pour chacun des trois fichiers surveillés.

Les empreintes correspondent à un état antérieur du VPS.

Après une modification administrative autorisée, il est possible que les empreintes actuelles ne correspondent plus aux références.

**Une référence ne doit être actualisée qu'après vérification et validation de la configuration concernée.**

## 8. Vérification du journal

La commande suivante a été exécutée sur Knox :

```bash
tail -n 20 /home/raphael/monitor.log
```

Le journal contenait des vérifications datées du **10 novembre 2026**, notamment à :

- 14 h UTC.
- 15 h UTC.

Les vérifications affichaient le message :

```text
ALERTE : modification détectée dans les fichiers surveillés !
```

Le journal présentait également les différences entre les empreintes de référence et les empreintes actuelles.

Cela confirme que le mécanisme détecte et journalise les changements.

## 9. Modification détectée sur SSH

L'examen des différences a montré une modification de l'empreinte associée au fichier :

```text
/etc/ssh/sshd_config
```

Les deux fichiers de configuration Apache ne présentaient pas de différence dans l'extrait examiné.

Cette alerte est cohérente avec les travaux de renforcement SSH effectués sur le VPS, notamment la désactivation de l'authentification par mot de passe.

La configuration SSH effective avait été vérifiée :

```text
port 870
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
permitemptypasswords no
denyusers robert
```

Le changement d'empreinte montre que Knox a détecté une différence entre la configuration actuelle et la configuration enregistrée précédemment.

**Cette différence est cohérente avec une intervention administrative autorisée et ne prouve pas une intrusion.**

## 10. Automatisation de la surveillance

La surveillance a été configurée pour une exécution horaire lors des travaux précédents.

Les entrées observées dans `monitor.log` à 14 h et 15 h UTC sont cohérentes avec cette planification.

La configuration Cron peut être consultée sur Knox avec :

```bash
crontab -l
```

Une planification horaire peut prendre la forme suivante :

```cron
0 * * * * /bin/bash /home/raphael/scripts/surveillance-integrite.sh
```

Cette ligne est un exemple de configuration reproductible. Elle doit être comparée à la planification réellement installée avant toute modification.

## 11. Procédure de vérification

Pour contrôler le fonctionnement de la surveillance :

1. Vérifier la présence du script et du fichier de référence.
2. Consulter les dernières entrées de `monitor.log`.
3. Confirmer que les vérifications sont exécutées régulièrement.
4. Examiner les différences SHA-256 lorsqu'une alerte apparaît.
5. Vérifier si les modifications correspondent à une intervention autorisée.
6. Conserver les journaux comme preuves des événements détectés.

Une modification volontaire de configuration ne doit pas être effectuée sur un serveur de production uniquement pour provoquer une alerte.

## 12. Limites du mécanisme

La surveillance présente certaines limites :

- Elle porte uniquement sur les trois fichiers configurés.
- Elle ne détecte pas nécessairement une modification temporaire survenue entre deux vérifications.
- Elle ne distingue pas automatiquement une modification autorisée d'une attaque.
- Le message d'alerte est global ; l'identification du fichier modifié nécessite d'examiner les différences enregistrées.
- Elle dépend de la disponibilité de la connexion SSH vers le VPS.
- Les empreintes de référence doivent être protégées contre les modifications non autorisées.

## 13. Résultats des vérifications

| Critère | Résultat |
|---|---|
| Script de surveillance présent | Validé |
| Connexion SSH sortante vers le VPS | Validé |
| Surveillance de `sshd_config` | Validé |
| Surveillance de la configuration HTTP | Validé |
| Surveillance de la configuration HTTPS | Validé |
| Fichier de référence SHA-256 présent | Validé |
| Journal `monitor.log` présent | Validé |
| Vérifications horodatées | Validé |
| Détection d'une différence SHA-256 | Validé |
| Enregistrement d'une alerte | Validé |
| Identification d'une différence sur `sshd_config` | Validé |
| Notification externe par courriel | Non prévue par ce mécanisme |

## 14. Conclusion

Knox dispose d'un mécanisme de surveillance d'intégrité fondé sur les empreintes SHA-256.

Le script compare régulièrement trois fichiers sensibles du VPS avec des empreintes de référence.

Les journaux consultés montrent que le mécanisme a détecté une modification de la configuration SSH et enregistré une alerte.

La surveillance fonctionne et fournit des traces permettant d'identifier les modifications des fichiers sensibles.

---

**Document suivant :** `docs/10-knox-restauration.md`
