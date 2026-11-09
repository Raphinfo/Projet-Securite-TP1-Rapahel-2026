# VPS — Sécurisation Apache et HTTPS

**Projet :** Sécurité #1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine :** VPS Ubuntu Server 22.04  
**Adresse IP :** `172.105.99.9`  
**Domaine :** `securite.rpd-labs.com`  
**Site Web :** SportPulse  
**Répertoire Web :** `/var/www/sportpulse-deploiement`

## 1. Objectif

Sécuriser le serveur Web Apache du VPS en appliquant les mesures suivantes :

- Réduire les informations techniques divulguées par Apache.
- Désactiver le listage des répertoires du site.
- Autoriser exceptionnellement le listage du répertoire `partage`.
- Protéger ce répertoire par une authentification HTTP.
- Activer HTTPS avec un certificat Let's Encrypt.
- Vérifier le renouvellement automatique du certificat.
- Tester réellement les contrôles d'accès.

## 2. Configuration des sites Apache

Le serveur utilise deux fichiers de configuration de site :

```text
/etc/apache2/sites-enabled/securite.conf
/etc/apache2/sites-enabled/securite-le-ssl.conf
```

Le premier concerne HTTP, sur le port `80`.

Le second concerne HTTPS, sur le port `443`.

Les deux utilisent le répertoire Web :

```text
/var/www/sportpulse-deploiement
```

Les directives observées dans les deux configurations comprennent :

```apache
Options -Indexes +FollowSymLinks
AllowOverride All
Require all granted
```

La directive `Options -Indexes` désactive le listage automatique des répertoires dans le contexte du site.

`AllowOverride All` permet l'utilisation de directives Apache dans les fichiers `.htaccess`. Cette possibilité doit être maîtrisée, car elle autorise des modifications locales du comportement du serveur.

## 3. Réduction des informations divulguées

Les fichiers de configuration actifs contiennent :

```apache
ServerTokens Prod
ServerSignature Off
```

Ces directives ont été retrouvées notamment dans :

```text
/etc/apache2/conf-enabled/security.conf
/etc/apache2/conf-enabled/securite-serveur.conf
```

### Explication

`ServerTokens Prod` limite les informations de version d'Apache présentées dans les réponses HTTP.

`ServerSignature Off` désactive la signature détaillée du serveur sur les pages générées par Apache.

Ces réglages réduisent la divulgation d'informations techniques utiles à un attaquant.

## 4. Protection des répertoires sensibles

Le fichier suivant est activé :

```text
/etc/apache2/conf-enabled/sportpulse-protection.conf
```

La vérification de la configuration a révélé deux directives :

```apache
Require all denied
```

Elles indiquent que des restrictions d'accès sont configurées pour certains chemins.

Les chemins exacts devront être consultés dans le fichier pour documenter précisément les ressources protégées.

## 5. Répertoire de partage protégé

Le répertoire suivant constitue une exception au listage désactivé du site :

```text
/var/www/sportpulse-deploiement/partage
```

Sa configuration se trouve dans :

```text
/etc/apache2/conf-enabled/sportpulse-partage.conf
```

Configuration vérifiée :

```apache
<Directory /var/www/sportpulse-deploiement/partage>
    Options +Indexes
    AuthType Basic
    AuthName "Partage protege - SportPulse"
    AuthUserFile /etc/apache2/.htpasswd-partage
    Require valid-user
</Directory>
```

### Fonctionnement

- `Options +Indexes` autorise le listage des fichiers du répertoire.
- `AuthType Basic` active l'authentification HTTP Basic.
- `AuthName` définit le nom affiché dans la demande d'authentification.
- `AuthUserFile` désigne le fichier des identifiants.
- `Require valid-user` autorise uniquement les utilisateurs authentifiés.

Le fichier des identifiants est situé en dehors du répertoire public :

```text
/etc/apache2/.htpasswd-partage
```

Le compte HTTP configuré est :

```text
visiteur
```

Le contenu du fichier de mots de passe n'est pas publié.

**Important :** l'authentification Basic doit être utilisée avec HTTPS pour protéger les identifiants pendant leur transmission.

## 6. Vérification des accès au partage

### 6.1 Accès sans authentification

Commande exécutée :

```bash
curl -sS -o /dev/null -w 'Code HTTP : %{http_code}\n' https://securite.rpd-labs.com/partage/
```

Résultat :

```text
Code HTTP : 401
```

Le code `401 Unauthorized` confirme qu'Apache demande une authentification.

### 6.2 Accès avec authentification

Commande exécutée :

```bash
curl -sS -u visiteur -o /dev/null -w 'Code HTTP : %{http_code}\n' https://securite.rpd-labs.com/partage/
```

Le mot de passe est saisi de manière interactive dans le terminal.

Résultat :

```text
Code HTTP : 200
```

Le code `200 OK` confirme que le compte `visiteur` peut accéder au répertoire avec son mot de passe.

### 6.3 Bilan des tests

| Scénario | Résultat attendu | Résultat obtenu |
|---|---|---|
| Visiteur non authentifié | HTTP `401` | HTTP `401` |
| Utilisateur `visiteur` authentifié | HTTP `200` | HTTP `200` |

Les deux tests sont concluants.

## 7. Certificat HTTPS Let's Encrypt

Le site dispose d'un certificat SSL/TLS géré par Certbot.

Commande de vérification :

```bash
sudo certbot certificates
```

Résultats observés le 9 novembre 2026 :

| Élément | Valeur |
|---|---|
| Nom du certificat | `securite.rpd-labs.com` |
| Domaine couvert | `securite.rpd-labs.com` |
| Type de clé | RSA |
| Date d'expiration | 21 janvier 2027 à 13:28:17 UTC |
| État | Valide au moment de la vérification |

Chemin du certificat :

```text
/etc/letsencrypt/live/securite.rpd-labs.com/fullchain.pem
```

Chemin de la clé privée :

```text
/etc/letsencrypt/live/securite.rpd-labs.com/privkey.pem
```

La clé privée ne doit jamais être copiée dans un dépôt GitHub.

## 8. Renouvellement automatique du certificat

Commande exécutée :

```bash
systemctl list-timers --all 'certbot.timer'
```

Résultat observé :

```text
NEXT                       LAST                       UNIT
Tue 2026-11-10 02:55:05 UTC Mon 2026-11-09 13:06:49 UTC certbot.timer
```

Le minuteur `certbot.timer` déclenche le service `certbot.service`.

Cette vérification confirme que le renouvellement automatique est planifié.

Elle ne remplace pas un test de renouvellement, qui peut être effectué séparément avec :

```bash
sudo certbot renew --dry-run
```

## 9. Procédure de reproduction

Sur un serveur Ubuntu avec Apache installé :

### 9.1 Configurer la réduction des informations

Modifier le fichier :

```bash
sudo nano /etc/apache2/conf-available/security.conf
```

Configurer :

```apache
ServerTokens Prod
ServerSignature Off
```

### 9.2 Désactiver le listage du site

Dans la configuration du VirtualHost, définir pour le répertoire Web :

```apache
<Directory /var/www/sportpulse-deploiement>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
```

### 9.3 Créer une protection HTTP pour le partage

Installer l'outil de gestion des mots de passe Apache si nécessaire :

```bash
sudo apt install apache2-utils
```

Créer le fichier d'authentification et le compte `visiteur` :

```bash
sudo htpasswd -c /etc/apache2/.htpasswd-partage visiteur
```

**Attention :** l'option `-c` crée ou remplace le fichier. Ne pas l'utiliser pour ajouter un utilisateur à un fichier existant.

Configurer ensuite le répertoire `partage` avec les directives présentées à la section 5.

### 9.4 Vérifier et recharger Apache

Tester la syntaxe :

```bash
sudo apache2ctl configtest
```

Si le résultat est `Syntax OK`, recharger Apache :

```bash
sudo systemctl reload apache2
```

### 9.5 Configurer HTTPS

Sur un serveur disposant d'un domaine pointant vers son adresse IP, Certbot peut être utilisé pour demander un certificat Let's Encrypt.

Exemple de commande :

```bash
sudo certbot --apache -d securite.rpd-labs.com
```

Cette commande est fournie comme procédure de reproduction. Le certificat du VPS du projet est déjà installé.

## 10. Résultats validés

| Exigence | État |
|---|---|
| Apache configuré pour HTTP et HTTPS | Validé |
| `ServerTokens Prod` présent | Validé |
| `ServerSignature Off` présent | Validé |
| Listage général désactivé | Configuration vérifiée |
| Listage autorisé dans `partage` | Configuration vérifiée |
| Authentification Basic configurée | Validé |
| Accès anonyme au partage refusé | Test HTTP `401` réussi |
| Accès authentifié au partage autorisé | Test HTTP `200` réussi |
| Certificat Let's Encrypt présent et valide | Validé |
| Renouvellement automatique planifié | Validé |
| Test de renouvellement `--dry-run` | Non effectué dans cette série de vérifications |

## 11. Conclusion

Le serveur Apache du VPS dispose des principales protections attendues pour le projet.

Les informations techniques divulguées par Apache sont limitées, le listage général des répertoires est désactivé et le répertoire `partage` est protégé par une authentification HTTP Basic.

Les tests ont confirmé que l'accès au partage est refusé sans identifiants et autorisé avec le compte `visiteur`.

Le site possède également un certificat HTTPS Let's Encrypt valide, avec un renouvellement automatique planifié.

---

