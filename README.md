# SecureCloud Lab 🔐

![Infrastructure](https://img.shields.io/badge/Infrastructure-Deployed-green)
![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20S3%20%7C%20IAM%20%7C%20CloudWatch-orange)
![Terraform](https://img.shields.io/badge/IaC-Terraform-purple)
![Docker](https://img.shields.io/badge/Container-Docker-blue)

## Contexte métier

PayFlow est une startup SaaS de paiement B2B en phase de lancement sur le marché africain. Ce projet simule le déploiement d'une infrastructure cloud production-grade pour héberger son API de paiement avec traçabilité complète, zéro exposition inutile et gestion fine des accès.

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

## Stack technique

| Catégorie | Technologies |
|---|---|
| Cloud | AWS (EC2, S3, IAM, CloudWatch, VPC) |
| IaC | Terraform |
| Conteneurs | Docker, Docker Compose |
| Reverse Proxy | Nginx |
| Monitoring | Prometheus, Grafana, Node Exporter, CloudWatch |
| Sécurité | Fail2Ban, UFW, Lynis, AWS IAM |
| OS | Ubuntu 22.04 LTS |

## Phases du projet

| Phase | Description | Statut |
|---|---|---|
| Phase 1 | Préparation & Comptes Cloud | ✅ Terminé |
| Phase 2 | Infrastructure Réseau VPC | ✅ Terminé |
| Phase 3 | Compute & Bastion Host | ✅ Terminé |
| Phase 4 | Application Stack Docker | ✅ Terminé |
| Phase 5 | IAM & Gestion des Accès | ✅ Terminé |
| Phase 6 | Stockage & Backup S3 | ✅ Terminé |
| Phase 7 | Monitoring & Logging | ✅ Terminé |
| Phase 8 | Sécurité & Hardening Linux | ✅ Terminé |
| Phase 9 | Automation avec Terraform | ✅ Terminé |

## Setup

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

## Architecture Sécurité

### Zero Trust Network
- Bastion Host comme seul point d'entrée SSH
- Serveur App dans subnet privé jamais accessible directement depuis Internet
- Security Groups avec principe du moindre privilège

### IAM
- Compte Root protégé jamais utilisé au quotidien
- Utilisateurs séparés : admin, deployer, auditor
- Rôle IAM attaché aux EC2 pas de clés stockées sur les serveurs

### Hardening Linux
- SSH : clés uniquement, root désactivé, Fail2Ban actif
- UFW : ports minimum ouverts
- Lynis Hardening Index : > 70/100
- sysctl : protection SYN flood, ICMP, source routing

## Lessons Learned

- La séparation réseau via subnets public/privé est plus robuste qu'un simple Security Group
- Les IAM Roles sur EC2 évitent de stocker des credentials sur les serveurs
- Le subnet privé sans accès Internet nécessite un NAT Gateway ou une solution alternative pour installer des paquets
- Terraform permet de documenter l'infrastructure comme du code reproductible en une commande

## Adaptation Oracle Cloud

Le document original prévoyait Oracle Cloud Always Free pour le serveur applicatif. Suite à des contraintes de carte bancaire, le serveur App a été déployé sur une deuxième instance EC2 t3.micro dans le subnet privé. Toutes les compétences techniques sont identiques seul le fournisseur cloud change.

## Portfolio

[senghorvl.vlsenghor97.workers.dev](https://senghorvl.vlsenghor97.workers.dev)

## Auteur

**Senghor Padraic VLAVONOU**  
Licence en Sécurité Informatique IFRI, Bénin  
Junior Cloud / DevOps / Security Engineer
