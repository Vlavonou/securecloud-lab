# SecureCloud Lab : Infrastructure cloud sécurisée pour PayFlow

Projet d'apprentissage Cloud / DevOps / Cloud Security
Stack : AWS · Terraform · Docker · Nginx · Prometheus/Grafana
**Statut : socle d'infrastructure déployé (phases 1 à 9). Exposition publique via Cloudflare non réalisée (voir « Ce qui n'a pas été fait »).**

## À propos de ce projet

Il s'agit de mon **premier projet d'infrastructure cloud** monté en autonomie. L'objectif est d'apprendre en pratique les fondamentaux : segmentation réseau (VPC), accès administrateur contrôlé (bastion), durcissement Linux, conteneurisation, gestion des identités (IAM), sauvegarde, supervision et Infrastructure as Code.

Le scénario est fictif : PayFlow, une startup SaaS de paiement B2B qui doit héberger une API de façon sécurisée. Les points non terminés ou perfectibles sont documentés honnêtement plus bas.

## Objectifs

- Concevoir un réseau isolé et segmenté (VPC avec sous-réseaux public/privé)
- Déployer des serveurs Linux durcis, administrés uniquement via un bastion
- Structurer les accès selon le principe du moindre privilège (IAM)
- Conteneuriser l'API et la placer derrière un reverse proxy (rate limiting, headers de sécurité)
- Automatiser des sauvegardes chiffrées vers S3
- Mettre en place une supervision (logs, métriques)
- Décrire une partie de l'infrastructure en code (Terraform)

## Stack technique

| Catégorie | Technologies |
|---|---|
| Cloud | AWS (EC2, S3, IAM, CloudWatch, VPC) |
| IaC | Terraform |
| Conteneurs | Docker, Docker Compose |
| Reverse proxy | Nginx |
| Monitoring | Prometheus, Grafana, Node Exporter, CloudWatch |
| Sécurité | Fail2Ban, UFW, Lynis, AWS IAM |
| Système | Ubuntu 22.04 LTS |

## Architecture réalisée

```
Admin (SSH, IP /32)
     │
     ▼
AWS VPC 10.0.0.0/16
 ├── Subnet public 10.0.1.0/24 → Bastion Host (point d'entrée SSH unique)
 └── Subnet privé  10.0.2.0/24 → Serveur applicatif (Nginx + API PayFlow en Docker)
                                        │
                                        ▼
                                  AWS S3 (backups chiffrés)

Supervision : Prometheus + Grafana + Node Exporter, CloudWatch (logs)
```

### Plan d'adressage

| Composant | Détail |
|---|---|
| VPC | 10.0.0.0/16 |
| Subnet public | 10.0.1.0/24, Bastion uniquement |
| Subnet privé | 10.0.2.0/24, serveur applicatif (EC2 t3.micro) |
| Internet Gateway | Rattachée au VPC, utilisée par le subnet public |
| Route table privée | Aucune route vers l'Internet Gateway |

### Security Groups

| SG | Entrant | Source |
|---|---|---|
| sg-bastion | SSH 22 | IP publique de l'administrateur (/32) |
| sg-app | SSH 22, HTTP 80 | sg-bastion uniquement |

Le serveur applicatif n'a pas d'IP publique et n'est joignable depuis Internet par aucun chemin.

### Administration

```
Admin → Bastion (SSH) → Serveur applicatif (SSH)
```

C'est le seul chemin d'accès au serveur applicatif.

## Ce qui n'a pas été fait : exposition publique via Cloudflare

L'architecture initiale prévoyait Cloudflare (DNS, WAF, proxy) devant l'application. **Cette partie n'a pas été mise en œuvre.** Seul un compte Cloudflare a été créé. Raisons :

1. **Le serveur applicatif est volontairement injoignable depuis Internet.** Pour que Cloudflare lui transmette du trafic, il faut soit l'exposer (ce qui annule la segmentation), soit établir un **Cloudflare Tunnel** : une connexion *sortante* ouverte par le serveur vers Cloudflare.
2. **Le tunnel exige un accès sortant depuis le subnet privé**, donc une passerelle NAT. La NAT Gateway AWS est payante (environ 30 USD/mois), incompatible avec la contrainte « 0 USD » du projet. Une instance NAT auto-gérée est possible, mais demande un travail supplémentaire (source/dest check, forwarding, règles iptables).
3. **Utiliser Cloudflare en production demande un nom de domaine**, qui est un coût supplémentaire et n'était pas prévu.
4. **Priorité à l'apprentissage des fondamentaux** : réseau, bastion, durcissement, IAM, IaC. J'ai choisi de les consolider avant d'aborder la publication de l'application.

Une conception initiale erronée est aussi à signaler : le plan de départ décrivait le flux « Cloudflare → Bastion → Nginx », impossible, car un bastion est une passerelle SSH et non un proxy web. La bonne approche est de séparer les deux flux : trafic client via Cloudflare Tunnel, administration via le Bastion.

### Conséquence

L'API est **testée uniquement en local sur le serveur applicatif**. Elle n'est pas accessible publiquement, et les protections Cloudflare (WAF, anti-DDoS) ne sont pas actives.

## Démarche de mise en œuvre

1. **Préparation** : comptes cloud (AWS, Cloudflare), outils locaux (AWS CLI, Terraform, Docker), paire de clés SSH dédiée.
2. **Infrastructure réseau** : VPC, deux sous-réseaux, Internet Gateway, tables de routage, Security Groups.
3. **Compute & Bastion** : bastion (EC2 t2.micro) et instance applicative, durcissement SSH (pas de root, clés uniquement, bannière légale), Fail2Ban.
4. **Stack applicative** : API Node.js et Nginx via Docker Compose, rate limiting, headers de sécurité. L'API n'expose aucun port directement.
5. **IAM** : root protégé, comptes séparés (administrateur, déploiement, audit), rôle IAM attaché aux EC2 pour éviter de stocker des clés.
6. **Stockage & sauvegarde** : bucket S3 (versioning, accès public bloqué, chiffrement), sauvegarde quotidienne par cron.
7. **Supervision** : Prometheus, Grafana, Node Exporter, et CloudWatch pour `auth.log` et `syslog`.
8. **Durcissement Linux** : mises à jour automatiques, UFW restrictif, services inutiles désactivés, paramètres kernel (sysctl), permissions, audit Lynis.
9. **Terraform** : réécriture du réseau (VPC, subnets, Security Groups) et du bastion, avec un état stocké dans S3.

## Statut du projet

| Phase | Description | Statut |
|---|---|---|
| 1 | Préparation & comptes cloud | ✅ Terminé |
| 2 | Infrastructure réseau (VPC) | ✅ Terminé |
| 3 | Compute & bastion host | ✅ Terminé |
| 4 | Stack applicative Docker | ✅ Terminé |
| 5 | IAM & gestion des accès | ✅ Terminé |
| 6 | Stockage & backup S3 | ✅ Terminé |
| 7 | Monitoring & logging | ✅ Terminé |
| 8 | Sécurité & hardening Linux | ✅ Terminé |
| 9 | Terraform | 🟡 Partiel (réseau + bastion ; serveur applicatif et routage à migrer) |
| 10 | Accès sortant (NAT) & Cloudflare Tunnel | ⏳ Non réalisé |
| 11 | Audit de sécurité (AWS Config, Security Hub) | ⏳ Non réalisé |

## Sécurité appliquée

**Réseau** : segmentation public/privé, serveur applicatif sans IP publique, point d'entrée SSH unique restreint à l'IP de l'administrateur, route table privée sans route vers l'Internet Gateway.

**IAM** : root protégé et non utilisé au quotidien, comptes séparés par usage, rôle IAM attaché aux EC2 (aucune clé stockée sur les serveurs).

**Linux** : SSH par clé uniquement, root désactivé, Fail2Ban, UFW en `deny incoming`, sysctl renforcé, permissions restreintes sur les fichiers sensibles, audit Lynis (objectif > 70/100).

**Application** : Nginx masquant sa version, limitation à 10 requêtes/seconde/IP, headers de sécurité. Bucket S3 privé, chiffré et versionné.

## Leçons apprises

- Les sous-réseaux public/privé matérialisent une frontière de confiance plus lisible qu'une simple règle de Security Group.
- Un bastion est une passerelle d'administration SSH, pas un proxy web : le trafic des clients et celui de l'administrateur doivent suivre deux chemins séparés.
- Un sous-réseau privé sans accès Internet complique l'installation de paquets et empêche un tunnel sortant : une solution NAT est nécessaire.
- Les rôles IAM attachés aux EC2 évitent de stocker des identifiants sur les serveurs.
- Terraform documente l'infrastructure par le code, mais il faut en couvrir tout le périmètre pour que la reproductibilité soit réelle.

## Limites et perspectives

- Environnement de démonstration (Free Tier, t2.micro/t3.micro), une seule instance par rôle : pas de haute disponibilité.
- **Prochaines étapes** : instance NAT, Cloudflare Tunnel avec un domaine, test depuis l'extérieur, migration complète vers Terraform, audit AWS Config/Security Hub.

## Utilisation

**Prérequis** : compte AWS, Terraform, AWS CLI configuré.

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

**Lancer l'application (sur le serveur applicatif)**
```bash
cd docker/
docker-compose up -d --build
```

**Tester l'API (en local sur le serveur)**
```bash
curl http://localhost/health
curl -X POST http://localhost/api/payment \
  -H 'Content-Type: application/json' \
  -d '{"amount":100,"currency":"EUR"}'
```

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
