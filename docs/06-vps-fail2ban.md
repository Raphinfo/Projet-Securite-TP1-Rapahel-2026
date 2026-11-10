# VPS — Protection SSH et phpMyAdmin avec Fail2ban

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Système :** Ubuntu Server 22.04  
**Machine :** VPS  
**Adresse IP :** `172.105.99.9`  
**Port SSH :** `870`

## 1. Objectif

Fail2ban permet de surveiller les échecs d'authentification et de bannir temporairement les adresses IP qui dépassent un seuil défini.

Dans ce projet, deux services doivent être protégés :

- SSH, utilisé pour l'administration du VPS.
- phpMyAdmin, utilisé pour l'administration des bases de données.

Les paramètres exigés sont :

| Paramètre | Valeur |
|---|---|
| Nombre maximal de tentatives | 4 |
| Période d'observation | 15 minutes |
| Durée du bannissement | 6 heures |

## 2. Installation et activation

Sur Ubuntu Server, Fail2ban peut être installé avec :

```bash
sudo apt update
sudo apt install fail2ban
```

Pour activer son démarrage automatique :

```bash
sudo systemctl enable --now fail2ban
```

Ces commandes sont fournies pour reproduire l'installation sur un nouveau serveur.

Sur le VPS du projet, le service est installé et fonctionne.

## 3. Vérification des protections actives

Commande exécutée :

```bash
sudo fail2ban-client status
```

Résultat obtenu :

```text
Status
|- Number of jail:      2
`- Jail list:   phpmyadmin-syslog, sshd
```

Les deux protections sont actives.

## 4. Protection SSH

La configuration SSH se trouve dans :

```text
/etc/fail2ban/jail.local
```

Les directives suivantes ont été vérifiées :

```ini
[sshd]
enabled = true
port = 870
filter = sshd
logpath = /var/log/auth.log
```

Le port `870` correspond au port réellement utilisé par le service SSH.

### 4.1 Paramètres de bannissement

Les commandes suivantes ont été exécutées :

```bash
sudo fail2ban-client get sshd maxretry
sudo fail2ban-client get sshd findtime
sudo fail2ban-client get sshd bantime
```

Résultats :

| Paramètre | Valeur confirmée |
|---|---|
| `maxretry` | `4` |
| `findtime` | `900` secondes |
| `bantime` | `21600` secondes |

Ces valeurs correspondent à quatre tentatives sur quinze minutes, avec un bannissement de six heures.

### 4.2 Action de bannissement

Commande de vérification :

```bash
sudo fail2ban-client get sshd actions
```

Résultat :

```text
The jail sshd has the following actions:
iptables-multiport
```

Fail2ban utilise donc une action fondée sur `iptables`.

## 5. Protection phpMyAdmin

La configuration de cette protection se trouve dans :

```text
/etc/fail2ban/jail.d/phpmyadmin.local
```

Directives vérifiées :

```ini
[phpmyadmin-syslog]
enabled = true
filter = phpmyadmin-syslog
port = http,https
logpath = /var/log/auth.log
```

Cette protection est configurée pour surveiller les événements correspondant au filtre `phpmyadmin-syslog`.

### 5.1 Paramètres de bannissement

Commandes exécutées :

```bash
sudo fail2ban-client get phpmyadmin-syslog maxretry
sudo fail2ban-client get phpmyadmin-syslog findtime
sudo fail2ban-client get phpmyadmin-syslog bantime
```

Résultats :

| Paramètre | Valeur confirmée |
|---|---|
| `maxretry` | `4` |
| `findtime` | `900` secondes |
| `bantime` | `21600` secondes |

Les paramètres correspondent aux exigences du projet.

**Limite de validation :** l'activation du jail et ses paramètres sont confirmés. Un test réel de détection et de bannissement phpMyAdmin reste nécessaire pour démontrer le fonctionnement complet du filtre.

## 6. Problème détecté sur la protection SSH

Pendant les vérifications, une incohérence a été découverte.

Le service SSH écoutait sur le port `870`, mais la configuration initiale de Fail2ban contenait :

```ini
port = ssh
```

Cette valeur correspond généralement au port `22`.

La vérification des règles `iptables` a confirmé le problème :

```text
-A INPUT -p tcp -m multiport --dports 22 -j f2b-sshd
```

Fail2ban était donc associé au mauvais port pour les bannissements SSH.

## 7. Correction de la configuration SSH

### 7.1 Modification du port

Le fichier suivant a été modifié :

```bash
sudo nano /etc/fail2ban/jail.local
```

La directive :

```ini
port = ssh
```

a été remplacée par :

```ini
port = 870
```

### 7.2 Vérification de la syntaxe

Commande exécutée :

```bash
sudo fail2ban-client -t
```

Résultat :

```text
OK: configuration test is successful
```

### 7.3 Rechargement de Fail2ban

La configuration a été rechargée avec :

```bash
sudo fail2ban-client reload
```

Cependant, l'ancienne règle `iptables` sur le port `22` était toujours présente.

Un redémarrage du service a également été effectué :

```bash
sudo systemctl restart fail2ban
```

La règle incorrecte persistait.

### 7.4 Identification de l'erreur

Les journaux ont été consultés avec :

```bash
sudo grep -Ei 'error|warning|iptables|f2b-sshd' /var/log/fail2ban.log | tail -n 40
```

Ils ont révélé que Fail2ban tentait de supprimer une règle sur le port `870`, alors que l'ancienne règle utilisait encore le port `22`.

Les messages comprenaient :

```text
iptables: Bad rule (does a matching rule exist in that chain?).
CHAIN_USER_DEL failed (Device or resource busy): chain f2b-sshd
```

Cette incohérence empêchait le nettoyage normal de la chaîne de bannissement.

## 8. Correction des règles iptables

La chaîne `f2b-sshd` a d'abord été examinée :

```bash
sudo iptables -S f2b-sshd
```

Résultat observé :

```text
-N f2b-sshd
```

Aucune règle de bannissement individuelle n'était présente à ce moment.

Une règle associant le port `870` à la chaîne `f2b-sshd` a ensuite été mise en place.

Pendant la correction, les deux règles suivantes ont été observées :

```text
-A INPUT -p tcp -m multiport --dports 22 -j f2b-sshd
-A INPUT -p tcp -m multiport --dports 870 -j f2b-sshd
```

L'ancienne règle a été supprimée avec :

```bash
sudo iptables -D INPUT -p tcp -m multiport --dports 22 -j f2b-sshd
```

**Attention :** cette opération était une correction ponctuelle d'un état incohérent. Elle ne doit pas être reproduite automatiquement sur un autre serveur sans examiner les règles présentes.

## 9. Vérification finale et persistance

Après la correction, la commande suivante a été exécutée :

```bash
sudo iptables -S INPUT | grep f2b-sshd
```

Résultat :

```text
-A INPUT -p tcp -m multiport --dports 870 -j f2b-sshd
```

Fail2ban a ensuite été redémarré :

```bash
sudo systemctl restart fail2ban
```

Une nouvelle vérification a donné le même résultat :

```text
-A INPUT -p tcp -m multiport --dports 870 -j f2b-sshd
```

**Conclusion :** la règle SSH correcte a persisté après le redémarrage de Fail2ban.

La persistance après un redémarrage complet du VPS n'a pas été testée dans cette série de vérifications.

## 10. Bilan des vérifications

| Critère | Résultat |
|---|---|
| Service Fail2ban opérationnel | Validé |
| Jail `sshd` actif | Validé |
| Jail `phpmyadmin-syslog` actif | Validé |
| SSH : 4 tentatives | Validé |
| SSH : 15 minutes | Validé |
| SSH : bannissement de 6 heures | Validé |
| phpMyAdmin : 4 tentatives | Validé |
| phpMyAdmin : 15 minutes | Validé |
| phpMyAdmin : bannissement de 6 heures | Validé |
| Action SSH `iptables-multiport` | Validé |
| Règle SSH appliquée au port `870` | Validé |
| Ancienne règle du port `22` supprimée | Validé |
| Correction maintenue après redémarrage de Fail2ban | Validé |
| Test réel de bannissement SSH | À effectuer |
| Test réel de bannissement phpMyAdmin | À effectuer |

## 11. Précautions et recommandations

Pour maintenir une protection efficace :

1. Vérifier que les ports Fail2ban correspondent aux ports réellement utilisés.
2. Contrôler les règles `iptables` après une modification.
3. Conserver une session SSH ouverte lors des changements sensibles.
4. Éviter de déclencher volontairement un bannissement depuis la seule adresse IP d'administration.
5. Consulter régulièrement les journaux Fail2ban.
6. Vérifier que les filtres détectent les événements attendus.
7. Tester les bannissements depuis une machine de test distincte lorsque cela est possible.

## 12. Conclusion

Fail2ban est configuré avec deux protections actives : SSH et phpMyAdmin.

Les deux protections respectent les paramètres demandés : quatre tentatives en quinze minutes et six heures de bannissement.

Une erreur de port a été identifiée et corrigée dans la protection SSH. La règle `iptables` utilise désormais le port `870` et reste correcte après le redémarrage de Fail2ban.

Les tests de bannissement réels pourront compléter cette validation lors des démonstrations du projet.

---
