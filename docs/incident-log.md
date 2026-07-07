# Journal des Incidents-SecureCloud Lab

## Format
Chaque incident suit le format : Date · Type · Description · Résolution

---

## Incidents réels rencontrés pendant le projet

### 2026-06-29 - WSL bloqué à 0% lors de l'installation
**Type** : Incident environnement local
**Description** : La commande `wsl --install` restait bloquée à 0% sans progression
**Cause** : Fonctionnalités Windows (WSL + VirtualMachinePlatform) non activées
**Résolution** : Activation manuelle via `dism.exe` puis installation Ubuntu via Microsoft Store

### 2026-07-01 - Serveur App sans accès Internet
**Type** : Incident réseau
**Description** : `sudo apt update` échouait sur le serveur App - impossible de télécharger des paquets
**Cause** : Subnet privé sans route vers Internet Gateway - architecture voulue mais bloquante pour l'installation
**Résolution** : Configuration du Bastion comme passerelle NAT temporaire via IP forwarding et iptables

### 2026-07-02 - Terraform incompatible avec Ubuntu Resolute
**Type** : Incident compatibilité
**Description** : `apt install terraform` échouait  dépôt Hashicorp ne supportait pas Ubuntu 24.10
**Cause** : Ubuntu Resolute (24.10) trop récent pour les dépôts Hashicorp officiels
**Résolution** : Installation via Snap (`sudo snap install terraform --classic`)

### 2026-07-03 - AWS CLI introuvable sur le Bastion avec sudo
**Type** : Incident configuration
**Description** : Le script backup.sh retournait `aws: command not found` quand lancé avec sudo
**Cause** : AWS CLI installé pour l'utilisateur ubuntu mais pas dans le PATH de root
**Résolution** : Installation d'AWS CLI v2 directement sur le Bastion via le paquet officiel

## Incidents simulés (Phase 10 - Audit)

### Simulation 1 - Brute-force SSH
**Description** : Tentatives de connexion SSH répétées depuis une IP externe
**Détection** : `grep 'Failed password' /var/log/auth.log`
**Réponse** : Fail2Ban bannit l'IP après 3 échecs en 10 minutes

### Simulation 2 - Container crash
**Description** : Container payflow-api qui redémarre en boucle
**Détection** : `docker ps` montre un nombre élevé de restarts
**Réponse** : `docker logs payflow-api` pour identifier l'erreur, correction et rebuild