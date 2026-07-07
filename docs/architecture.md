# Architecture Technique SecureCloud Lab

## Schéma réseau
INTERNET
|
[Cloudflare]
DNS · WAF · Proxy · DDoS Protection
|
| HTTPS :443
|
[AWS VPC 10.0.0.0/16]
|
├── [PUBLIC SUBNET 10.0.1.0/24]
│       |
│   [BASTION HOST]
│   EC2 t3.micro
│   SSH :22 (mon IP uniquement)
│       |
│       | SSH interne
│       |
└── [PRIVATE SUBNET 10.0.2.0/24]
|
[NGINX Reverse Proxy :80]
|
[PayFlow API :3000]
Node.js dans Docker
|
[AWS S3] ← Backups chiffrés AES-256
|
[CloudWatch] ← Logs auth + syslog
[Prometheus + Grafana] ← Métriques temps réel

## Justification des choix techniques

### Pourquoi deux subnets séparés
Le subnet public expose uniquement le Bastion Host à Internet. Le subnet privé héberge l'application aucune route vers Internet, aucune IP publique. Même si le Bastion est compromis, l'application reste protégée par une couche réseau supplémentaire.

### Pourquoi un Bastion Host
Plutôt que d'ouvrir SSH sur le serveur App directement, le Bastion est le seul point d'entrée SSH. Il est renforcé avec Fail2Ban, SSH hardening, et son accès est restreint à une seule IP.

### Pourquoi Docker pour l'application
Docker isole l'application du système hôte. Si l'application est compromise, l'attaquant reste dans le container sans accès direct au système Linux sous-jacent.

### Pourquoi Nginx comme reverse proxy
Nginx ajoute une couche de protection devant l'API rate limiting (10 req/s), headers de sécurité (X-Frame-Options, X-XSS-Protection), et masque la version du serveur.

### Pourquoi IAM Roles plutôt que Access Keys
Les IAM Roles fournissent des credentials temporaires automatiques (1h) renouvelés par AWS. Pas de clés stockées sur les serveurs si le serveur est compromis, l'attaquant n'a pas de credentials AWS permanents.

### Pourquoi Terraform
L'infrastructure as Code permet de recréer toute l'infrastructure en une commande. C'est reproductible, versionnable sur Git et documenté comme du code.
