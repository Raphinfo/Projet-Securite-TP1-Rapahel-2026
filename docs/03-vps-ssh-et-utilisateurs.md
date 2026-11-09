# VPS — Sécurisation SSH et gestion des utilisateurs

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine :** VPS Ubuntu Server 22.04  
**Adresse IP :** `172.105.99.9`  
**Port SSH :** `870`  
**Compte administrateur :** `raphi`

## 1. Objectif

Renforcer la sécurité du service SSH du VPS afin de limiter les accès non autorisés.

Les mesures mises en place comprennent :

- Le déplacement du service SSH vers le port TCP `870`.
- L'interdiction de connexion directe du compte `root`.
- L'interdiction des mots de passe vides.
- L'utilisation de clés SSH pour l'authentification.
- La désactivation des connexions SSH par mot de passe après le déploiement de la clé du professeur.
- L'interdiction de connexion SSH pour l'utilisateur `robert`.
- La création de comptes distincts selon les responsabilités.

## 2. Comptes utilisateurs

Les comptes suivants ont été vérifiés sur le VPS :

| Compte | UID | Groupes | Fonction |
|---|---|---|---|
| `raphi` | `1000` | `raphi`, `sudo` | Administration du VPS |
| `robert` | `1001` | `robert` | Utilisateur interdit de connexion SSH |
| `knoxbackup` | `1002` | `knoxbackup`, `www-data` | Sauvegardes depuis Knox |
| `david` | `1003` | `david`, `sudo` | Administration par l'enseignant |

Vérification des comptes :

```bash
for u in raphi david knoxbackup robert; do
    id "$u" 2>&1
done
```

Le compte `knoxbackup` n'appartient pas au groupe `sudo`. Ses autorisations spécifiques de sauvegarde sont décrites dans la documentation Knox.

## 3. Création du compte du professeur

**Machine : VPS — compte administrateur `raphi`.**

Pour reproduire la création du compte :

```bash
sudo adduser david
```

L'ajouter au groupe des administrateurs :

```bash
sudo usermod -aG sudo david
```

Vérifier son appartenance aux groupes :

```bash
id david
```

Résultat confirmé sur le VPS :

```text
uid=1003(david) gid=1003(david) groups=1003(david),27(sudo)
```

Le mot de passe du compte ne doit jamais être publié dans le dépôt GitHub.

## 4. Création et utilisation d'une clé SSH

**Machine : ordinateur personnel de l'administrateur.**

Le compte `raphi` utilise une clé privée RSA enregistrée localement sous le nom :

```text
~/.ssh/id_rsa_sportpulse
```

Pour reproduire cette configuration sur un nouveau poste, générer une clé RSA de 4096 bits :

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_sportpulse
```

Lors de la génération, définir une phrase de passe robuste pour protéger la clé privée.

**Important :** cette commande concerne une nouvelle installation. Ne jamais l'exécuter sur un poste où le fichier existe déjà sans avoir prévu la conservation de la clé actuelle.

Installer ensuite uniquement la clé publique sur le serveur, dans le fichier :

```text
/home/raphi/.ssh/authorized_keys
```

La clé privée doit rester sur le poste de l'administrateur.

### 4.1 Connexion SSH par clé

Depuis l'ordinateur personnel :

```bash
ssh -p 870 -i ~/.ssh/id_rsa_sportpulse raphi@172.105.99.9
```

La connexion a été testée avec succès.

L'administrateur saisit la **phrase de passe de sa clé privée**, et non le mot de passe de son compte Linux.

### 4.2 Vérification de l'authentification par clé

```bash
ssh \
  -o PasswordAuthentication=no \
  -o KbdInteractiveAuthentication=no \
  -o IdentitiesOnly=yes \
  -p 870 \
  -i ~/.ssh/id_rsa_sportpulse \
  raphi@172.105.99.9
```

Ce test a réussi après le rechargement de la configuration SSH.

## 5. Clé publique du professeur

Le compte `david` dispose du fichier :

```text
/home/david/.ssh/authorized_keys
```

La vérification de la clé publique a été réalisée avec :

```bash
sudo ssh-keygen -lf /home/david/.ssh/authorized_keys
```

Résultat observé :

```text
4096 SHA256:6cjbBaU0fK/JX4ma3fRdJ8qsk81CTl3TTp6IqiNcWUU Turcottedavid@DESKTOP-O7EKDDQ (RSA)
```

La clé est de type RSA et possède une longueur de 4096 bits.

L'enseignant a confirmé avoir déployé sa clé et réussi sa connexion SSH.

La désactivation des mots de passe a été effectuée après cette confirmation.

## 6. Configuration du service SSH

**Machine : VPS.**

Le fichier principal est :

```text
/etc/ssh/sshd_config
```

Pour le modifier :

```bash
sudo nano /etc/ssh/sshd_config
```

Les paramètres effectifs vérifiés sont :

```text
Port 870
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
DenyUsers robert
```

Ces paramètres permettent :

- D'écouter sur le port SSH `870`.
- D'interdire la connexion directe du compte `root`.
- D'autoriser les clés publiques.
- De refuser l'authentification SSH par mot de passe.
- De désactiver l'authentification interactive.
- De refuser les mots de passe vides.
- De bloquer les connexions SSH du compte `robert`.

La directive `UsePAM` est également active (`yes`). Elle ne réactive pas à elle seule l'authentification par mot de passe lorsque les méthodes SSH correspondantes sont désactivées.

## 7. Passage à l'authentification par clé uniquement

Au début de la configuration, la directive suivante était active :

```text
PasswordAuthentication yes
```

Ce réglage avait été conservé temporairement pour permettre à l'enseignant de déployer sa clé publique.

Après sa confirmation, la directive a été modifiée :

```text
PasswordAuthentication no
```

### 7.1 Vérifier la syntaxe

Avant d'appliquer la modification :

```bash
sudo sshd -t
```

**Résultat obtenu :** aucune erreur.

### 7.2 Recharger le service

```bash
sudo systemctl reload ssh
```

La commande a été exécutée sans erreur.

**Précaution :** conserver une session SSH administrative ouverte pendant toute modification, puis tester une nouvelle connexion avant de fermer la session existante.

### 7.3 Vérifier la configuration effective

```bash
sudo sshd -T | grep -Ei '^(port|pubkeyauthentication|passwordauthentication|kbdinteractiveauthentication|permitrootlogin|permitemptypasswords|denyusers) '
```

Résultat confirmé :

```text
port 870
permitrootlogin no
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
permitemptypasswords no
denyusers robert
```

Une nouvelle connexion SSH du compte `raphi` avec sa clé RSA a ensuite été réussie.

## 8. Vérifications complémentaires

### 8.1 Vérifier les permissions des clés publiques

Sur le VPS :

```bash
sudo ls -ld /home/raphi/.ssh /home/david/.ssh
sudo ls -l /home/raphi/.ssh/authorized_keys /home/david/.ssh/authorized_keys
```

Permissions habituellement recommandées :

- Répertoire `.ssh` : `700`.
- Fichier `authorized_keys` : `600`.
- Propriétaire : utilisateur concerné.

Ces permissions doivent être contrôlées avant toute correction. Elles ne sont pas présentées ici comme des résultats déjà vérifiés.

### 8.2 Vérifier le refus d'une authentification par mot de passe

Depuis un poste client, un test peut être réalisé avec :

```bash
ssh \
  -o PubkeyAuthentication=no \
  -o PreferredAuthentications=password \
  -o KbdInteractiveAuthentication=no \
  -p 870 \
  raphi@172.105.99.9
```

**Résultat attendu :** refus de connexion.

Ce test complémentaire doit être exécuté et son résultat conservé comme preuve. La configuration effective confirme déjà `PasswordAuthentication no`.

### 8.3 Vérifier le blocage de `robert`

La configuration effective contient :

```text
DenyUsers robert
```

Cette directive interdit à `robert` de s'authentifier par SSH, même s'il dispose d'un compte Linux local.

## 9. Résultats validés

| Critère | Résultat |
|---|---|
| Port SSH `870` | Validé |
| Connexion directe de root interdite | Validé |
| Mots de passe vides interdits | Validé |
| Clé SSH RSA de l'administrateur | Connexion validée |
| Phrase de passe protégeant la clé | Validée |
| Compte `david` présent | Validé |
| Compte `david` membre de `sudo` | Validé |
| Clé RSA 4096 bits du professeur | Présence confirmée |
| Connexion du professeur par clé | Confirmée par l'enseignant |
| Authentification SSH par mot de passe désactivée | Configuration effective vérifiée |
| Authentification interactive désactivée | Validé |
| `robert` interdit de SSH | Configuration effective vérifiée |
| Nouvelle connexion de `raphi` après rechargement | Validée |

## 10. Recommandations de sécurité

Ne jamais publier dans GitHub :

- Les clés SSH privées.
- Les phrases de passe des clés.
- Les mots de passe des comptes.
- Les fichiers contenant des identifiants confidentiels.

Pour toute future modification du service SSH :

1. Conserver une session administrative ouverte.
2. Modifier uniquement les paramètres nécessaires.
3. Vérifier la syntaxe avec `sudo sshd -t`.
4. Recharger le service.
5. Tester une nouvelle connexion par clé.
6. Fermer l'ancienne session uniquement après validation.

---
