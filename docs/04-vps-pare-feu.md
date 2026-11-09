# VPS — Configuration et sécurisation du pare-feu UFW

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Système :** Ubuntu Server 22.04  
**Machine :** VPS  
**Adresse IP :** `172.105.99.9`  
**Utilisateur administrateur :** `raphi`

## 1. Objectif

L'objectif est de protéger le VPS contre les connexions réseau non autorisées en utilisant le pare-feu UFW (*Uncomplicated Firewall*).

La politique de sécurité retenue consiste à refuser les connexions entrantes par défaut et à autoriser uniquement les services nécessaires :

- SSH sur le port TCP `870`.
- HTTP sur le port TCP `80`.
- HTTPS sur le port TCP `443`.

Le pare-feu doit également être actif automatiquement au démarrage du serveur.

## 2. Politique de sécurité

La configuration effective du VPS applique les règles suivantes :

| Type de trafic | Politique |
|---|---|
| Connexions entrantes | Refusées par défaut |
| Connexions sortantes | Autorisées par défaut |
| Trafic routé | Désactivé |
| Journalisation | Activée, niveau `low` |

Cette approche réduit la surface d'exposition du serveur en limitant les ports accessibles depuis Internet.

## 3. Configuration reproductible

**Attention :** avant d'activer UFW sur un serveur distant, il faut impérativement autoriser le port SSH utilisé pour l'administration. Sinon, l'accès au serveur pourrait être interrompu.

### 3.1 Définir les politiques par défaut

Sur le VPS :

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### 3.2 Autoriser le port SSH

Le service SSH du projet utilise le port TCP `870`.

```bash
sudo ufw allow 870/tcp
```

Cette règle doit être présente avant l'activation du pare-feu.

### 3.3 Autoriser les services Web

Autoriser HTTP :

```bash
sudo ufw allow 80/tcp
```

Autoriser HTTPS :

```bash
sudo ufw allow 443/tcp
```

### 3.4 Activer le pare-feu

Après avoir vérifié les règles :

```bash
sudo ufw enable
```

**Remarque :** ces commandes décrivent la procédure de reproduction. Sur le VPS du projet, UFW est déjà actif et les règles sont déjà en place.

## 4. Vérification des règles actives

Commande exécutée sur le VPS :

```bash
sudo ufw status verbose
```

Résultat observé :

```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
870/tcp                    ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
870/tcp (v6)               ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
```

### Interprétation

Les ports suivants sont explicitement autorisés :

| Port | Protocole | Service | IPv4 | IPv6 |
|---|---|---|---|---|
| `870` | TCP | SSH | Autorisé | Autorisé |
| `80` | TCP | HTTP | Autorisé | Autorisé |
| `443` | TCP | HTTPS | Autorisé | Autorisé |

Les autres connexions entrantes sont refusées par défaut, sauf disposition particulière non visible dans cette sortie.

La journalisation UFW est activée au niveau `low`.

## 5. Démarrage automatique

Le pare-feu doit être configuré pour démarrer automatiquement avec le serveur.

Commande de vérification :

```bash
systemctl is-enabled ufw
```

Résultat obtenu :

```text
enabled
```

Cela confirme que le service UFW est activé au démarrage.

## 6. Vérification de l'accès SSH

La configuration du pare-feu doit rester cohérente avec celle du service SSH.

Le serveur SSH utilise le port `870`, et UFW autorise les connexions TCP entrantes sur ce port.

Une nouvelle connexion SSH par clé a été testée avec succès après le renforcement de l'authentification SSH.

Commande utilisée depuis le poste local :

```bash
ssh \
  -o PasswordAuthentication=no \
  -o KbdInteractiveAuthentication=no \
  -o IdentitiesOnly=yes \
  -p 870 \
  -i ~/.ssh/id_rsa_sportpulse \
  raphi@172.105.99.9
```

**Résultat :** connexion réussie.

Ce test confirme que l'administration distante demeure accessible.

## 7. Résultats de validation

| Critère | Résultat |
|---|---|
| UFW installé et actif | Validé |
| Connexions entrantes refusées par défaut | Validé |
| Connexions sortantes autorisées | Validé |
| SSH TCP `870` autorisé | Validé |
| HTTP TCP `80` autorisé | Validé |
| HTTPS TCP `443` autorisé | Validé |
| Règles IPv4 présentes | Validé |
| Règles IPv6 présentes | Validé |
| Journalisation activée | Validé |
| Démarrage automatique d'UFW | Validé |
| Connexion SSH administrative fonctionnelle | Validé |

## 8. Bonnes pratiques

Pour conserver une configuration sécurisée :

1. Maintenir la politique de refus des connexions entrantes.
2. N'ouvrir que les ports nécessaires au fonctionnement du projet.
3. Vérifier les règles avant toute modification.
4. Conserver une session SSH ouverte lors des changements sensibles.
5. Tester l'accès distant avant de fermer la session administrative.
6. Supprimer les règles devenues inutiles.
7. Vérifier régulièrement l'état du pare-feu.

## 9. Conclusion

Le pare-feu UFW du VPS est actif et configuré selon une politique restrictive.

Les ports SSH `870`, HTTP `80` et HTTPS `443` sont autorisés en IPv4 et IPv6. Les autres connexions entrantes sont refusées par défaut.

Le service UFW est également activé au démarrage du système.

Cette configuration constitue une couche de protection réseau complémentaire au renforcement du service SSH.

---

