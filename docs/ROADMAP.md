# Roadmap - TriathlonApp

> Planning d'implémentation en 7 phases

---

## Vue d'ensemble

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  PHASE 1        PHASE 2         PHASE 3        PHASE 4                      │
│  Fondations     Auth &          Moteur         Interface                    │
│  Sem 1-2        Onboarding      Programme      Mobile                       │
│                 Sem 3-4         Sem 5-7        Sem 8-10                     │
│  ████████       ████████        ████████████   ████████████                 │
└──────────────────────────────────────────────────────────────────────────────┘
┌──────────────────────────────────────────────────────────────────────────────┐
│  PHASE 5        PHASE 6         PHASE 7                                     │
│  Sync &         Back-office     PSEO &                                      │
│  Recalcul       Sem 13-14       Polish                                      │
│  Sem 11-12                      Sem 15-16                                   │
│  ████████       ████████        ████████                      🚀 LAUNCH    │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Phase 1 : Fondations (Semaines 1-2)

### Objectif
Mettre en place l'infrastructure technique et la structure du projet.

### Livrables

#### Semaine 1

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Setup Monorepo** | Turborepo + pnpm workspace | 🔴 |
| **Config TypeScript** | tsconfig partagé + strict mode | 🔴 |
| **Package shared** | Types, constants, validators | 🔴 |
| **Next.js App** | App Router + Cloudflare adapter | 🔴 |
| **Expo Mobile** | Init Expo managed + NativeWind | 🔴 |

#### Semaine 2

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Cloudflare D1** | Setup DB + wrangler config | 🔴 |
| **Migrations** | Schema initial + seed data | 🔴 |
| **CI/CD** | GitHub Actions + deploy preview | 🟠 |
| **Linting** | ESLint + Prettier config | 🟠 |
| **Dev Environment** | Scripts dev, hot reload | 🔴 |

### Critères de validation
- [ ] `pnpm dev` lance mobile + web en parallèle
- [ ] D1 accessible avec tables créées
- [ ] Deploy preview fonctionnel sur Cloudflare
- [ ] Types partagés entre mobile et web

### Structure créée
```
/triathlon-app
├── apps/mobile/          ✅
├── apps/web/             ✅
├── packages/shared/      ✅
├── packages/training-engine/ (vide)
├── workers/ (vide)
├── docs/                 ✅
├── turbo.json            ✅
└── pnpm-workspace.yaml   ✅
```

---

## Phase 2 : Auth & Onboarding (Semaines 3-4)

### Objectif
Permettre aux utilisateurs de se connecter et configurer leur profil.

### Livrables

#### Semaine 3 - Auth Strava

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **OAuth Flow Web** | /api/auth/strava + callback | 🔴 |
| **OAuth Flow Mobile** | Expo AuthSession + deep link | 🔴 |
| **Token Management** | Stockage sécurisé, refresh | 🔴 |
| **User Creation** | Insert dans D1 après OAuth | 🔴 |
| **Session JWT** | Génération + validation | 🔴 |
| **Auth Context** | Provider React + hooks | 🔴 |

#### Semaine 4 - Onboarding

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Strava Analysis** | Fetch 6 mois, calcul stats | 🔴 |
| **Écran Objectif** | Sélection 70.3 / Ironman | 🔴 |
| **Écran Date** | Calendar picker + validation | 🔴 |
| **Écran Niveau** | 3 options + description | 🔴 |
| **Écran Disponibilité** | Slider heures + jours | 🔴 |
| **Écran Contraintes** | Pool, trainer, injuries | 🟠 |
| **Zones FC** | Import Strava ou calcul | 🔴 |
| **Sauvegarde Profil** | API + D1 insert | 🔴 |

### Critères de validation
- [ ] Login Strava fonctionnel iOS + Android
- [ ] Parcours onboarding complet (7 étapes)
- [ ] Profil athlète sauvegardé en base
- [ ] Zones FC calculées/importées

### API implémentées
- `GET /api/auth/strava`
- `GET /api/auth/strava/callback`
- `POST /api/auth/refresh`
- `GET /api/auth/me`
- `GET /api/onboarding/status`
- `GET /api/onboarding/strava-analysis`
- `POST /api/onboarding/profile`
- `POST /api/onboarding/goal`
- `POST /api/onboarding/availability`
- `POST /api/onboarding/constraints`

---

## Phase 3 : Moteur Programme (Semaines 5-7)

### Objectif
Créer le cœur algorithmique de génération des programmes.

### Livrables

#### Semaine 5 - Templates

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Package training-engine** | Structure du module | 🔴 |
| **Template 70.3** | 16 semaines, 3 niveaux | 🔴 |
| **Template Ironman** | 24 semaines, 3 niveaux | 🔴 |
| **Phase Definition** | Base, Build1, Build2, Peak, Taper | 🔴 |
| **Volume Scaling** | Adaptation selon heures dispo | 🔴 |

#### Semaine 6 - Séances Types

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Session Templates Swim** | 5 types (tech, endo, inter, css, ow) | 🔴 |
| **Session Templates Bike** | 6 types | 🔴 |
| **Session Templates Run** | 6 types | 🔴 |
| **Session Templates Brick** | 3 types | 🔴 |
| **Zone Calculator** | FC, Power, Pace zones | 🔴 |
| **Workout Structure** | JSON format warmup/main/cooldown | 🔴 |

#### Semaine 7 - Générateur

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Program Generator** | Algorithme principal | 🔴 |
| **Week Builder** | Génération des semaines | 🔴 |
| **Session Assigner** | Attribution des séances | 🔴 |
| **Personalization** | Ajustement selon profil | 🔴 |
| **API Complete** | POST /api/onboarding/complete | 🔴 |
| **Tests Unitaires** | Coverage moteur > 80% | 🟠 |

### Critères de validation
- [ ] Programme 70.3 généré correctement
- [ ] Programme Ironman généré correctement
- [ ] Séances avec détails complets (zones, tips)
- [ ] Volumes adaptés selon disponibilités

### Module training-engine
```
/packages/training-engine
├── /templates
│   ├── half-ironman.ts
│   └── ironman.ts
├── /sessions
│   ├── swim.ts
│   ├── bike.ts
│   ├── run.ts
│   └── brick.ts
├── /zones
│   ├── heart-rate.ts
│   ├── power.ts
│   └── pace.ts
├── /rules
│   └── adjustment.ts
├── /generator
│   ├── program.ts
│   ├── week.ts
│   └── session.ts
└── index.ts
```

---

## Phase 4 : Interface Mobile (Semaines 8-10)

### Objectif
Développer l'expérience utilisateur complète sur mobile.

### Livrables

#### Semaine 8 - Navigation & Structure

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Navigation Setup** | Expo Router / React Navigation | 🔴 |
| **Tab Navigator** | Home, Programme, Profil | 🔴 |
| **Design System** | NativeWind tokens, composants base | 🔴 |
| **Écran Home** | Séances du jour, stats | 🔴 |
| **Loading States** | Skeletons, spinners | 🟠 |

#### Semaine 9 - Programme

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Vue Overview** | Progression, phases, stats | 🔴 |
| **Vue Semaine** | Liste séances, statuts | 🔴 |
| **Navigation Semaines** | Swipe ou picker | 🔴 |
| **Phase Indicator** | Timeline visuelle | 🟠 |
| **Stats Cards** | Volumes, compliance | 🟠 |

#### Semaine 10 - Séances

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Écran Détail Séance** | Full design | 🔴 |
| **Zones FC Display** | Visuel par phase | 🔴 |
| **Workout Structure** | Échauffement, corps, retour | 🔴 |
| **Tips Display** | Liste conseils | 🔴 |
| **Mark Complete** | Action + confirmation | 🔴 |
| **Skip Session** | Modal raison | 🟠 |
| **Pull to Refresh** | Sync data | 🟠 |

### Critères de validation
- [ ] Navigation fluide entre tous les écrans
- [ ] Programme affiché correctement
- [ ] Séances détaillées avec zones
- [ ] Actions complète/skip fonctionnelles
- [ ] UX testée sur iOS et Android

### Écrans implémentés
- Splash / Auth
- Onboarding (7 étapes)
- Home (aujourd'hui)
- Programme Overview
- Semaine détaillée
- Séance détaillée
- Profil / Paramètres

---

## Phase 5 : Sync & Recalcul (Semaines 11-12)

### Objectif
Synchroniser avec Strava et adapter les programmes automatiquement.

### Livrables

#### Semaine 11 - Strava Integration

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Webhook Setup** | Subscription Strava | 🔴 |
| **Webhook Handler** | /api/webhook/strava | 🔴 |
| **Activity Sync** | Import données activité | 🔴 |
| **Activity Matching** | Association avec séance | 🔴 |
| **Queue Processing** | Cloudflare Queues | 🔴 |
| **Sync Manual** | API trigger sync | 🟠 |

#### Semaine 12 - Recalcul

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Worker Recalc** | Job CRON hebdo | 🔴 |
| **Compliance Calc** | Prévu vs réalisé | 🔴 |
| **Adjustment Rules** | Logique adaptation | 🔴 |
| **Week Regeneration** | Modifier S+1 si besoin | 🔴 |
| **Expo Notifications** | Setup + permissions | 🔴 |
| **Notif Program Update** | Push après recalcul | 🔴 |
| **Notif Daily Reminder** | Rappel séance | 🟠 |

### Critères de validation
- [ ] Webhook Strava reçoit les events
- [ ] Activités synchronisées automatiquement
- [ ] Match séance/activité fonctionnel
- [ ] Recalcul hebdo modifie le programme
- [ ] Notifications push reçues

### Workers créés
```
/workers
├── /strava-sync
│   └── index.ts
├── /recalc-weekly
│   └── index.ts
└── /notifications
    └── index.ts
```

---

## Phase 6 : Back-office (Semaines 13-14)

### Objectif
Interface d'administration pour gérer l'application.

### Livrables

#### Semaine 13 - Auth & Structure

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Login Admin** | Email/password + session | 🔴 |
| **Layout Admin** | Sidebar, header | 🔴 |
| **Dashboard** | Stats overview | 🟠 |
| **Users List** | Table paginée | 🟠 |
| **User Detail** | Profile + programme | 🟡 |

#### Semaine 14 - Gestion

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Templates CRUD** | Liste + form création | 🔴 |
| **Sessions CRUD** | Bibliothèque séances | 🔴 |
| **Jobs Management** | Liste, toggle, run | 🔴 |
| **Audit Logs** | Consultation + filtres | 🔴 |
| **Export CSV** | Logs, users | 🟡 |

### Critères de validation
- [ ] Login admin sécurisé
- [ ] CRUD templates fonctionnel
- [ ] CRUD séances fonctionnel
- [ ] Jobs gérables depuis l'UI
- [ ] Audit logs consultables

### Routes admin
```
/admin
├── /login
├── /dashboard
├── /users
│   └── /[id]
├── /templates
│   ├── /new
│   └── /[id]/edit
├── /sessions
│   ├── /new
│   └── /[id]/edit
├── /jobs
└── /logs
```

---

## Phase 7 : PSEO & Polish (Semaines 15-16)

### Objectif
Finaliser l'application pour le lancement.

### Livrables

#### Semaine 15 - PSEO

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Page Distance 70.3** | SEO optimisé | 🟠 |
| **Page Distance Ironman** | SEO optimisé | 🟠 |
| **PSEO Generator Worker** | Auto-génération | 🟠 |
| **Sitemap** | XML auto-généré | 🟠 |
| **Meta Tags** | OG, Twitter cards | 🟠 |

#### Semaine 16 - Polish & Launch

| Tâche | Détail | Priorité |
|-------|--------|----------|
| **Error Handling** | Sentry setup | 🔴 |
| **Performance Audit** | Lighthouse, bundle | 🟠 |
| **Security Audit** | Headers, CORS, rate limit | 🔴 |
| **E2E Tests** | Parcours critiques | 🟠 |
| **App Store Assets** | Screenshots, description | 🔴 |
| **Documentation** | README, API docs | 🟠 |
| **Deploy Production** | Config finale | 🔴 |
| **Monitoring** | Logs, alertes | 🟠 |

### Critères de validation
- [ ] Pages PSEO indexables
- [ ] Score Lighthouse > 90
- [ ] Tests E2E passent
- [ ] Déploiement prod stable
- [ ] Monitoring en place

---

## Résumé des dépendances

```
Phase 1 ─────┐
             ├──▶ Phase 2 ────▶ Phase 3 ────▶ Phase 4
             │         │              │              │
             │         │              │              ▼
             │         │              └─────▶ Phase 5
             │         │                           │
             │         └───────────────────────────┼──▶ Phase 6
             │                                     │         │
             └─────────────────────────────────────┴─────────┴──▶ Phase 7
```

---

## Risques identifiés

| Risque | Impact | Probabilité | Mitigation |
|--------|--------|-------------|------------|
| Limites API Strava | Haut | Moyen | Cache agressif, batch sync |
| Complexité génération programme | Haut | Faible | Templates bien définis |
| Performance D1 | Moyen | Faible | Index optimisés, pagination |
| Rejection App Store | Moyen | Moyen | Guidelines Apple, beta TestFlight |
| Complexité recalcul | Moyen | Moyen | Règles simples au départ |

---

## KPIs par phase

| Phase | Métrique | Cible |
|-------|----------|-------|
| 1 | Dev environment stable | ✓ |
| 2 | Onboarding completion | > 80% |
| 3 | Temps génération programme | < 10s |
| 4 | Crash-free sessions | > 99% |
| 5 | Sync success rate | > 95% |
| 6 | Admin actions/jour | Baseline |
| 7 | Lighthouse score | > 90 |

---

## Post-MVP Roadmap

### V1.1 (M+1)
- Support Garmin Connect
- Formats Sprint et Olympique
- Amélioration matching activités

### V1.2 (M+2)
- Intégration calendrier
- Statistiques avancées
- Comparaison athlètes similaires

### V2.0 (M+4)
- Coaching IA conversationnel
- Plans nutrition
- Marketplace coaches

---

## Ressources nécessaires

### Équipe
- 1 Fullstack Developer (lead)
- 1 Mobile Developer (React Native)
- 0.5 Designer (UI/UX)

### Comptes & Services
- Strava API (app enregistrée)
- Cloudflare (Pages, D1, Workers, Queues)
- Expo (EAS Build)
- Apple Developer ($99/an)
- Google Play Developer ($25 one-time)
- Sentry (error tracking)
- GitHub (repo + Actions)

### Coûts estimés
| Service | Coût mensuel |
|---------|--------------|
| Cloudflare | $5-50 (selon usage) |
| Expo EAS | $0-99 |
| Sentry | $0-26 |
| Apple Developer | $8 (annualisé) |
| **Total** | ~$50-150/mois |
