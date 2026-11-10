# Knox — Vérification et restauration des sauvegardes du VPS

**Projet :** Sécurité TP1 — Renforcement de l'environnement informatique et piège pour attaquant  
**Machine :** `raphael-knox`  
**VM Proxmox :** `110`  
**Système :** Ubuntu Server 22.04.5 LTS  
**Adresse IP de Knox :** `10.1.106.34`  
**VPS sauvegardé :** `172.105.99.9`

## 1. Objectif

La réalisation de sauvegardes ne suffit pas à garantir la récupération des données après un incident.

Il est également nécessaire de vérifier que les fichiers sauvegardés sont accessibles, lisibles et récupérables.

L'objectif de cette étape est de vérifier la possibilité de restaurer un fichier du site web SportPulse à partir d'une sauvegarde présente sur Knox.

Le test a été réalisé dans un répertoire distinct afin de ne pas modifier le site en production.

## 2. Architecture de restauration

Knox conserve localement des copies de données récupérées depuis le VPS par SSH et `rsync`.

Les sauvegardes sont stockées dans le répertoire :

```text
/home/raphael/sauvegardes-vps/
```

Les principaux éléments présents sont :

| Élément | Description |
|---|---|
| `www/` | Copie des fichiers du serveur web |
| `home/` | Copie de fichiers personnels et sauvegardes SQL |
| `home-complet.tar.gz` | Archive du répertoire `/home` du VPS |
| `home-acl.txt` | Informations de sauvegarde relatives aux permissions ACL |

Ces éléments constituent les sources disponibles pour une éventuelle opération de restauration.

## 3. Principe du test

Le test consiste à :

1. Identifier un fichier présent dans la sauvegarde du site SportPulse.
2. Créer un répertoire de restauration indépendant.
3. Copier le fichier sauvegardé vers ce répertoire.
4. Ouvrir le fichier restauré pour vérifier sa lisibilité.
5. Comparer les empreintes SHA-256 de la source et de la copie.

Le fichier choisi est :

```text
index.php
```

Il s'agit d'un fichier du site SportPulse présent dans la sauvegarde web.

## 4. Création du répertoire de restauration

**Machine utilisée : Knox**

La commande suivante a été exécutée :

```bash
mkdir -p ~/test-restauration
```

Ce répertoire permet de réaliser le test sans modifier les fichiers originaux de sauvegarde ni le contenu du VPS.

Le répertoire créé est :

```text
/home/raphael/test-restauration/
```

## 5. Restauration du fichier web

Le fichier `index.php` a été copié depuis la sauvegarde vers le répertoire de test.

Commande exécutée :

```bash
cp ~/sauvegardes-vps/www/sportpulse-deploiement/index.php ~/test-restauration/index.php
```

La source correspond à la copie sauvegardée du site SportPulse.

La destination correspond au répertoire de restauration local sur Knox.

Cette opération simule la récupération d'un fichier web à partir d'une sauvegarde disponible.

## 6. Vérification de la lisibilité

Après la copie, le fichier restauré a été ouvert avec la commande :

```bash
less ~/test-restauration/index.php
```

**Résultat observé :** le fichier a pu être ouvert et son contenu consulté.

Cette vérification confirme que la copie restaurée est accessible et lisible.

Elle ne constitue toutefois pas un test d'exécution de l'application PHP dans un serveur web.

## 7. Vérification de l'intégrité avec SHA-256

Pour confirmer que la copie restaurée correspond au fichier sauvegardé, les empreintes SHA-256 ont été calculées.

Commande exécutée :

```bash
sha256sum ~/sauvegardes-vps/www/sportpulse-deploiement/index.php ~/test-restauration/index.php
```

Le résultat affichait deux empreintes SHA-256 identiques.

Cela signifie que le contenu du fichier restauré correspond exactement, au moment du test, au contenu du fichier présent dans la sauvegarde.

**Résultat : test d'intégrité réussi.**

Cette comparaison valide la fidélité de la copie restaurée par rapport à la sauvegarde. Elle ne prouve pas à elle seule que la sauvegarde est identique à la version actuellement présente sur le VPS.

## 8. Sauvegardes de la base MySQL

Les fichiers SQL suivants ont également été repérés dans les sauvegardes de Knox :

```text
/home/raphael/sauvegardes-vps/home/raphi/sport.sql
/home/raphael/sauvegardes-vps/home/raphi/sport-backup.sql
```

Ils correspondent à des exports de la base de données utilisée par SportPulse.

Leur présence constitue une ressource importante pour une restauration future de la base MySQL.

Cependant, le test de restauration décrit dans ce document concerne uniquement un fichier web.

**Aucune réimportation complète de la base MySQL n'est attestée par ce test.**

Une validation complète de la restauration de la base nécessiterait une importation dans un environnement de test isolé, suivie de contrôles sur les tables et les données.

## 9. Autres éléments disponibles pour la restauration

Knox conserve également une archive :

```text
/home/raphael/sauvegardes-vps/home-complet.tar.gz
```

Cette archive est destinée à faciliter la récupération des fichiers du répertoire `/home` du VPS.

Un fichier de sauvegarde des informations ACL est également présent :

```text
/home/raphael/sauvegardes-vps/home-acl.txt
```

Ces éléments peuvent contribuer à une procédure de reprise après incident.

Toutefois, leur présence ne signifie pas qu'une restauration intégrale du VPS, des permissions et des services a été effectuée.

## 10. Résultats du test

| Critère | Résultat |
|---|---|
| Répertoire de sauvegarde accessible sur Knox | Validé |
| Fichier `index.php` présent dans la sauvegarde | Validé |
| Création d'un répertoire de restauration isolé | Validé |
| Copie du fichier sauvegardé | Validé |
| Ouverture et lecture du fichier restauré | Validé |
| Comparaison des empreintes SHA-256 | Validé |
| Empreintes SHA-256 identiques | Validé |
| Présence de sauvegardes SQL | Vérifiée |
| Restauration complète de MySQL | Non validée dans ce test |
| Restauration intégrale du VPS | Non réalisée |
| Vérification du fonctionnement du site après restauration | Non réalisée |

## 11. Limites et précautions

Le test réalisé valide la restauration locale d'un fichier, mais ne couvre pas tous les scénarios de reprise après incident.

Les limites principales sont :

- Le fichier a été restauré sur Knox et non sur le VPS de production.
- Aucun remplacement de fichier en production n'a été effectué.
- L'application SportPulse n'a pas été redémarrée ou testée à partir de cette copie.
- Les bases de données et les permissions du système n'ont pas fait l'objet d'une restauration complète dans ce test.
- La comparaison SHA-256 a été effectuée entre la sauvegarde et la copie restaurée, et non entre la copie restaurée et le fichier actuel du VPS.

En cas d'incident réel, une restauration complète devrait être réalisée selon une procédure contrôlée, en vérifiant notamment les services, les permissions, la base de données et l'accessibilité du site.

## 12. Conclusion

Le test effectué sur Knox confirme qu'un fichier web du site SportPulse peut être récupéré depuis les sauvegardes locales.

Le fichier `index.php` a été copié dans un répertoire de restauration indépendant, ouvert avec succès, puis comparé à sa source par SHA-256.

Les empreintes identiques démontrent que **le fichier restauré est conforme au fichier sauvegardé**.

Cette vérification constitue une première validation concrète de la capacité de récupération des données.

La restauration complète de l'environnement de production reste une opération distincte qui nécessiterait des vérifications supplémentaires.

---

**Documentation associée :**

- [Installation de Knox](07-knox-installation.md)
- [Sauvegardes du VPS](08-knox-sauvegardes.md)
- [Surveillance d'intégrité](09-knox-surveillance-integrite.md)
- [Script de sauvegarde](scripts/sauvegarde-vps.sh)
- [Automatisation Cron](scripts/crontab-knox.txt)
