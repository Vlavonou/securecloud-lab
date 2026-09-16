# SecureCloud Lab - Infrastructure Cloud Production-Grade pour PayFlow

> Projet Cloud Engineering / DevOps / Cloud Security - Portfolio technique
> Stack : AWS · Terraform · Docker · Nginx · Prometheus/Grafana
> Statut : infrastructure déployée et fonctionnelle

---

## Résumé

Ce projet simule le déploiement d'une infrastructure cloud de niveau production pour **PayFlow**, une startup SaaS fictive de paiement B2B en phase de lancement. L'objectif n'est pas de faire tourner une simple VM isolée, mais de reproduire ce qu'une équipe Cloud/DevOps déploierait réellement pour héberger une API sensible : un réseau isolé et segmenté, des serveurs Linux durcis, un reverse proxy sécurisé, une gestion des identités selon le principe du moindre privilège, un stockage objet chiffré et sauvegardé automatiquement, une stack de supervision, et une infrastructure entièrement décrite en code (Terraform).

---

## Contexte métier

PayFlow est une startup SaaS de paiement B2B fictive, en phase de lancement. Le problème métier posé est le suivant : déployer une infrastructure cloud sécurisée, supervisée et hautement disponible pour héberger une API de paiement, avec traçabilité complète des accès, zéro exposition inutile des services internes, et une gestion fine des permissions.

## Objectifs du projet

- Concevoir un **réseau cloud isolé et segmenté** (VPC avec sous-réseaux public/privé), plutôt qu'une infrastructure "à plat" exposée directement sur Internet ;
- Déployer des **serveurs Linux durcis**, accessibles uniquement via un point d'entrée unique et contrôlé (bastion) ;
- Mettre en place une **gestion des identités et des accès (IAM)** structurée selon le principe du moindre privilège ;
- Conteneuriser l'application et l'exposer via un **reverse proxy** appliquant des règles de sécurité (rate limiting, headers de sécurité) ;
- Assurer la **sauvegarde automatisée** et chiffrée des données critiques ;
- Mettre en place une **stack de supervision** capable de détecter des comportements anormaux (brute-force, charge CPU suspecte, service down) ;
- Décrire l'ensemble de l'infrastructure en **Infrastructure as Code (Terraform)**, pour la rendre reproductible et documentée par le code lui-même.

---

## Stack technique

| Catégorie | Technologies |
|---|---|
| Cloud | AWS (EC2, S3, IAM, CloudWatch, VPC) |
| IaC | Terraform |
| Conteneurs | Docker, Docker Compose |
| Reverse Proxy | Nginx |
| Monitoring | Prometheus, Grafana, Node Exporter, CloudWatch |
| Sécurité | Fail2Ban, UFW, Lynis, AWS IAM |
| Système | Ubuntu 22.04 LTS |
| Périmètre/CDN | Cloudflare (DNS, WAF, proxy HTTP/HTTPS) |

---

## Choix techniques et justification

- **AWS Free Tier** a été retenu comme socle principal (VPC, EC2, S3, IAM, CloudWatch) pour sa maturité et sa représentativité d'un environnement cloud professionnel réel, tout en restant gratuit dans les limites du Free Tier.
- **Un VPC dédié en `10.0.0.0/16`** a été préféré à l'usage du VPC par défaut AWS, afin de garder un contrôle total sur le plan d'adressage, la segmentation et le routage - condition nécessaire pour appliquer une architecture Zero Trust.
- **Une architecture bastion + réseau privé** plutôt qu'un accès SSH direct sur le serveur applicatif : cela garantit qu'aucune machine hébergeant l'application n'est jamais directement exposée sur Internet, et centralise le point d'entrée à auditer.
- **Terraform** a été choisi pour décrire l'infrastructure en tant que code plutôt que de la construire manuellement dans la console AWS : cela rend le déploiement reproductible en une commande et documente l'infrastructure elle-même - un différenciateur important entre un ingénieur cloud et un simple administrateur qui clique dans une console.
- **Docker Compose** plutôt que Kubernetes : le projet ne visait pas l'orchestration à grande échelle, mais l'isolation propre des services (API + Nginx) avec un déploiement reproductible, suffisant à l'échelle d'un environnement de démonstration.
- **Cloudflare** en frontal (DNS, WAF, proxy) pour filtrer le trafic avant même qu'il n'atteigne l'infrastructure AWS, ajoutant une couche de défense supplémentaire en périphérie.

### Adaptation par rapport au plan initial - Oracle Cloud → AWS

Le projet prévoyait initialement de répartir la charge entre AWS (réseau, bastion) et Oracle Cloud Always Free (serveur applicatif, pour bénéficier de ressources plus généreuses gratuitement). Suite à une contrainte liée à la carte bancaire requise pour l'inscription Oracle Cloud, le **serveur applicatif a finalement été déployé sur une deuxième instance EC2 (`t3.micro`) dans le sous-réseau privé AWS**, plutôt que sur Oracle Cloud. Les compétences techniques démontrées restent identiques ; seul le fournisseur cloud change pour cette machine.

---

## Architecture

```
Internet → Cloudflare (WAF/DNS) → AWS VPC
                                      ├── Subnet Public  → Bastion Host (SSH Gateway)
                                      └── Subnet Privé   → Nginx + PayFlow API (Docker)
                                                                    ↓
                                                              AWS S3 (Backups)
                                                                    ↓
                                                         Prometheus + Grafana + CloudWatch
```

### Plan d'adressage et segmentation

| Composant | Détail |
|---|---|
| VPC CIDR | `10.0.0.0/16` |
| Subnet public | `10.0.1.0/24` - Bastion Host uniquement |
| Subnet privé | `10.0.2.0/24` - Nginx + API applicative (deuxième instance EC2) |
| Internet Gateway | attaché au VPC, route le trafic du subnet public vers Internet |
| Table de routage privée | aucune route vers l'Internet Gateway - trafic interne uniquement |

### Security Groups (principe du moindre privilège réseau)

| Security Group | Règle entrante | Source | Justification |
|---|---|---|---|
| SG-Bastion | SSH (22) | IP publique de l'administrateur uniquement | Seul point d'accès SSH depuis Internet |
| SG-App | HTTP (80) / HTTPS (443) / SSH (22) | SG-Bastion uniquement | Le serveur applicatif n'est jamais exposé directement à Internet |

Cette organisation matérialise une logique **Zero Trust** : le seul chemin valide vers l'application est *Internet → Cloudflare → Bastion → Nginx → API* ; aucune règle ne permet d'atteindre directement le serveur applicatif depuis l'extérieur.

---

## Démarche de mise en œuvre

Le projet a été mené en neuf phases successives, chacune validée avant de passer à la suivante :

1. **Préparation** : création des comptes cloud (AWS, Cloudflare), installation des outils locaux (AWS CLI, Terraform, Docker), génération d'une paire de clés SSH dédiée.
2. **Infrastructure réseau** : création du VPC, des deux sous-réseaux (public/privé), de l'Internet Gateway, des tables de routage et des Security Groups.
3. **Compute & Bastion** : déploiement du bastion (EC2 `t2.micro`, Ubuntu 22.04) et de l'instance applicative, premiers accès SSH, durcissement initial de la configuration SSH (désactivation du login root, authentification par clé uniquement, bannière légale) et mise en place de Fail2Ban contre le brute-force.
4. **Stack applicative** : conteneurisation de l'API PayFlow (Node.js) et d'un reverse proxy Nginx via Docker Compose, avec limitation de débit (*rate limiting*) et ajout de headers de sécurité (`X-Frame-Options`, `X-Content-Type-Options`, etc.) ; l'API n'expose aucun port directement, tout le trafic transite par Nginx.
5. **IAM & gestion des accès** : structuration des comptes selon le principe du moindre privilège - un compte root protégé et jamais utilisé au quotidien, des comptes séparés (administrateur, déploiement CI/CD, audit en lecture seule), et un rôle IAM attaché aux instances EC2 pour éviter tout stockage de clés d'accès sur les serveurs.
6. **Stockage & sauvegarde** : création d'un bucket S3 avec versioning, blocage de tout accès public et chiffrement par défaut, puis mise en place d'un script de sauvegarde automatisé (logs, configuration Docker/Nginx) exécuté quotidiennement via cron.
7. **Supervision** : déploiement d'une stack Prometheus + Grafana + Node Exporter pour la métrologie système et applicative, en complément de CloudWatch côté AWS pour la centralisation des logs (`auth.log`, `syslog`).
8. **Durcissement système complet** : mises à jour automatiques, pare-feu UFW en politique restrictive par défaut, désactivation des services inutiles, paramètres kernel renforcés (sysctl : protection SYN flood, désactivation du source routing et de l'IP forwarding), permissions restreintes sur les fichiers sensibles, audit via Lynis.
9. **Automatisation avec Terraform** : réécriture de l'ensemble de l'infrastructure réseau et compute en Infrastructure as Code (VPC, subnets, Security Groups, instance bastion), avec un état Terraform stocké dans S3 plutôt qu'en local.

---

## Sécurité appliquée

### Réseau - Zero Trust

- Le serveur applicatif n'est **jamais accessible directement depuis Internet** ;
- Un unique point d'entrée SSH (le bastion), restreint à l'IP publique de l'administrateur ;
- Une table de routage privée sans route vers l'Internet Gateway pour le sous-réseau applicatif.

### IAM

- Compte root protégé, jamais utilisé au quotidien ;
- Séparation des comptes selon leur usage : administrateur, déploiement (accès restreint à EC2 en lecture et à un bucket S3 précis), audit (lecture seule) ;
- Rôle IAM attaché aux instances EC2 pour l'accès à S3, évitant tout stockage de clés d'accès sur les serveurs.

### Durcissement Linux

- SSH : authentification par clé uniquement, connexion root désactivée, nombre de tentatives limité, Fail2Ban actif ;
- Pare-feu UFW avec politique par défaut restrictive (`deny incoming`), seuls les ports strictement nécessaires ouverts ;
- Paramètres kernel renforcés (sysctl) contre le SYN flood, le source routing et les redirections ICMP ;
- Audit système avec Lynis (indice de durcissement visé : > 70/100) ;
- Permissions restreintes sur les fichiers de configuration sensibles (`sshd_config`, `authorized_keys`, `crontab`).

### Application

- Reverse proxy Nginx masquant la version du serveur, appliquant une limitation de débit (10 requêtes/seconde/IP) et des headers de sécurité standard ;
- Bucket S3 sans accès public, chiffrement par défaut activé, versioning activé pour la résilience des sauvegardes.

---

## Statut du projet

| Phase | Description | Statut |
|---|---|---|
| Phase 1 | Préparation & comptes cloud | ✅ Terminé |
| Phase 2 | Infrastructure réseau (VPC) | ✅ Terminé |
| Phase 3 | Compute & bastion host | ✅ Terminé |
| Phase 4 | Stack applicative Docker | ✅ Terminé |
| Phase 5 | IAM & gestion des accès | ✅ Terminé |
| Phase 6 | Stockage & backup S3 | ✅ Terminé |
| Phase 7 | Monitoring & logging | ✅ Terminé |
| Phase 8 | Sécurité & hardening Linux | ✅ Terminé |
| Phase 9 | Automatisation avec Terraform | ✅ Terminé |

---

## Leçons apprises

- La séparation réseau via sous-réseaux public/privé s'est révélée plus robuste et plus lisible qu'une simple règle de Security Group pour matérialiser une frontière de confiance.
- Les rôles IAM attachés aux instances EC2 évitent efficacement de stocker des identifiants d'accès sur les serveurs.
- Un sous-réseau privé sans accès Internet complique l'installation de paquets sur les machines qu'il héberge, et nécessite une passerelle NAT (ou une solution alternative) pour les mises à jour système.
- Terraform permet de documenter l'infrastructure comme du code reproductible en une seule commande, ce qui en fait à la fois un outil de déploiement et un outil de documentation vivante.

---

## Utilisation

### Prérequis

- Compte AWS
- Compte Cloudflare
- Terraform installé
- AWS CLI configuré

### Déploiement avec Terraform

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

### Lancer l'application

```bash
cd docker/
docker-compose up -d --build
```

### Tester l'API

```bash
# Health check
curl http://localhost/health

# Test paiement
curl -X POST http://localhost/api/payment \
  -H 'Content-Type: application/json' \
  -d '{"amount":100,"currency":"EUR"}'
```

---

## Limites et perspectives

Ce projet reste un environnement de démonstration : les instances utilisées relèvent du Free Tier AWS (`t2.micro`/`t3.micro`), dimensionnées pour un usage de portfolio et non pour une charge de production réelle. La couverture de sécurité pourrait être approfondie par un audit plus formalisé (règles AWS Config, revue systématique via AWS Security Hub) au-delà du durcissement Lynis déjà réalisé.

---

## Technologies utilisées

- **AWS** - EC2, S3, IAM, CloudWatch, VPC
- **Terraform** (Infrastructure as Code)
- **Docker**, **Docker Compose**
- **Nginx** (reverse proxy)
- **Prometheus**, **Grafana**, **Node Exporter**
- **Fail2Ban**, **UFW**, **Lynis** (sécurité et durcissement)
- **Cloudflare** (DNS, WAF, proxy)
- **Ubuntu 22.04 LTS**

---

## Portfolio

[senghorvl.vlsenghor97.workers.dev](https://senghorvl.vlsenghor97.workers.dev)

## Auteur

**Senghor Padraic VLAVONOU**
Licence en Sécurité Informatique - IFRI, Bénin
Junior Cloud / DevOps / Security Engineer
