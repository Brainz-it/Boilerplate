# Spécifications Fonctionnelles - TriathlonApp

> Application mobile de génération de programmes d'entraînement triathlon personnalisés

---

## 1. Vision Produit

### 1.1 Problème
Les triathlètes amateurs manquent d'outils accessibles pour créer des programmes d'entraînement personnalisés basés sur leur historique réel et adaptés dynamiquement à leur progression.

### 1.2 Solution
Une application mobile connectée à Strava qui :
- Analyse l'historique d'entraînement de l'utilisateur
- Génère un programme personnalisé vers un objectif (70.3 ou Ironman)
- Recalcule automatiquement chaque semaine selon les séances réalisées

### 1.3 Proposition de valeur
- **Personnalisation** : Programme basé sur les données réelles Strava
- **Adaptabilité** : Ajustement hebdomadaire automatique
- **Simplicité** : Onboarding en 7 micro-étapes, programme clé en main

---

## 2. Personas

### 2.1 Triathlète débutant
- **Profil** : Premier triathlon longue distance
- **Besoin** : Guidance complète, progression sécurisée
- **Crainte** : Se blesser, ne pas être prêt le jour J

### 2.2 Triathlète intermédiaire
- **Profil** : A déjà fait des formats courts, vise plus long
- **Besoin** : Optimiser son temps d'entraînement limité
- **Crainte** : Surentraînement, mauvaise répartition des disciplines

### 2.3 Triathlète confirmé
- **Profil** : Plusieurs longues distances au compteur
- **Besoin** : Programme structuré pour performer
- **Crainte** : Plateau de performance, monotonie

---

## 3. Fonctionnalités MVP

### 3.1 Authentification

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| AUTH-01 | Connexion OAuth Strava | P0 |
| AUTH-02 | Refresh token automatique | P0 |
| AUTH-03 | Déconnexion | P0 |
| AUTH-04 | Gestion session expirée | P1 |

### 3.2 Onboarding

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| ONB-01 | Analyse automatique historique Strava (6 mois) | P0 |
| ONB-02 | Sélection distance objectif (70.3 / Ironman) | P0 |
| ONB-03 | Sélection date événement | P0 |
| ONB-04 | Évaluation niveau expérience | P0 |
| ONB-05 | Configuration disponibilités hebdo | P0 |
| ONB-06 | Saisie contraintes (piscine, home trainer, blessures) | P1 |
| ONB-07 | Objectif chrono optionnel | P2 |

### 3.3 Profil Athlète

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| PRO-01 | Import zones cardiaques Strava | P0 |
| PRO-02 | Calcul zones estimées (220-âge) | P0 |
| PRO-03 | Saisie manuelle FC max | P1 |
| PRO-04 | Calcul/import FTP vélo | P1 |
| PRO-05 | Calcul CSS natation | P2 |

### 3.4 Programme d'entraînement

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| PGM-01 | Génération programme personnalisé | P0 |
| PGM-02 | Vue générale (progression globale) | P0 |
| PGM-03 | Vue semaine détaillée | P0 |
| PGM-04 | Phases périodisation (Base, Build, Peak, Taper) | P0 |
| PGM-05 | Adaptation durée selon date objectif | P0 |
| PGM-06 | Recalcul hebdomadaire automatique | P0 |

### 3.5 Séances

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| SES-01 | Affichage détail séance | P0 |
| SES-02 | Objectif de la séance | P0 |
| SES-03 | Zones cardiaques attendues | P0 |
| SES-04 | Déroulé détaillé (échauffement, corps, retour calme) | P0 |
| SES-05 | Astuces et conseils | P1 |
| SES-06 | Marquer séance terminée | P0 |
| SES-07 | Marquer séance passée (skip) | P1 |
| SES-08 | Association auto avec activité Strava | P1 |

### 3.6 Synchronisation Strava

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| STR-01 | Webhook temps réel nouvelles activités | P0 |
| STR-02 | Sync batch hebdomadaire | P0 |
| STR-03 | Comparaison prévu vs réalisé | P0 |
| STR-04 | Calcul taux de compliance | P1 |
| STR-05 | Détection surcharge/sous-charge | P1 |

### 3.7 Notifications

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| NOT-01 | Programme mis à jour (hebdo) | P0 |
| NOT-02 | Rappel séance du jour | P1 |
| NOT-03 | Alerte surcharge détectée | P1 |
| NOT-04 | Félicitations objectif atteint | P2 |
| NOT-05 | Configuration préférences notifications | P1 |

### 3.8 Back-office Admin

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| ADM-01 | Authentification admin (email/password) | P0 |
| ADM-02 | CRUD templates programmes | P0 |
| ADM-03 | CRUD séances types | P0 |
| ADM-04 | Visualisation utilisateurs | P1 |
| ADM-05 | Gestion jobs/workers | P0 |
| ADM-06 | Consultation audit logs | P0 |
| ADM-07 | Exécution manuelle jobs | P1 |

### 3.9 PSEO (Programmatic SEO)

| ID | Fonctionnalité | Priorité |
|----|----------------|----------|
| SEO-01 | Pages distances (70.3, Ironman) | P1 |
| SEO-02 | Pages types de séances | P2 |
| SEO-03 | Pages phases d'entraînement | P2 |
| SEO-04 | Génération automatique via Worker | P1 |

---

## 4. Règles métier

### 4.1 Génération de programme

```
ENTRÉES:
- distance_type: '70.3' | 'ironman'
- event_date: Date
- experience_level: 'beginner' | 'intermediate' | 'advanced'
- weekly_hours: number
- strava_history: Activity[]

RÈGLES:
1. Calcul nombre de semaines = (event_date - today) / 7
2. Sélection template selon distance + niveau
3. Ajustement phases selon durée disponible:
   - < 12 sem: Compression phases Build
   - 12-20 sem: Template standard
   - > 20 sem: Extension phase Base
4. Scaling volume selon weekly_hours
5. Personnalisation zones selon profil
```

### 4.2 Recalcul hebdomadaire

```
DÉCLENCHEUR: Lundi 6h00 (CRON) ou webhook Strava

ÉTAPES:
1. Récupérer activités semaine S-1
2. Calculer volumes réalisés (swim/bike/run)
3. Comparer avec volumes planifiés
4. Calculer compliance_rate

DÉCISIONS:
- compliance >= 90%: Maintenir progression normale
- compliance 70-89%: Ajustement léger semaine S+1
- compliance 50-69%: Réduction intensité, maintien volume
- compliance < 50%: Reset semaine, investigation cause

ACTIONS:
- Mettre à jour program_weeks.actual_*
- Régénérer sessions semaine S+1 si ajustement
- Créer notification utilisateur
- Logger dans audit_logs
```

### 4.3 Calcul zones cardiaques

```
PRIORITÉ:
1. Zones importées Strava (si disponibles)
2. Calcul depuis FC max manuelle
3. Estimation FC max = 220 - âge

ZONES (% FC max):
- Z1 (Récupération): 50-60%
- Z2 (Endurance): 60-70%
- Z3 (Tempo): 70-80%
- Z4 (Seuil): 80-90%
- Z5 (VO2max): 90-100%
```

### 4.4 Association activité Strava

```
CRITÈRES MATCHING:
- Date activité = Date séance planifiée (+/- 1 jour)
- Type sport correspond
- Durée dans range acceptable (±30%)

ACTIONS SI MATCH:
- Lier strava_activity_id à session
- Mettre session.status = 'completed'
- Calculer écarts (durée, distance, FC)
- Mettre à jour actual_* de la semaine
```

---

## 5. Parcours utilisateur

### 5.1 Première connexion

```
┌─────────────────────────────────────────────────────────────┐
│  1. ÉCRAN ACCUEIL                                           │
│     [Se connecter avec Strava]                              │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  2. OAUTH STRAVA                                            │
│     Autorisation accès données                              │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  3. ANALYSE EN COURS                                        │
│     "On analyse tes 6 derniers mois..."                     │
│     [Spinner + stats qui s'affichent progressivement]       │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  4. TON OBJECTIF                                            │
│     "Quel est ton prochain défi ?"                          │
│     [Half Ironman 70.3]  [Ironman]                          │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  5. DATE ÉVÉNEMENT                                          │
│     "Quand a lieu ton triathlon ?"                          │
│     [Calendrier picker]                                     │
│     → Validation: date > today + 8 semaines                 │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  6. TON NIVEAU                                              │
│     "C'est ton premier triathlon longue distance ?"         │
│     [Oui, découverte] [Déjà fait] [Compétiteur]            │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  7. DISPONIBILITÉ                                           │
│     "Combien d'heures par semaine ?"                        │
│     [Slider: 5h - 20h]                                      │
│     "Jours impossibles ?" [Multi-select jours]              │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  8. CONTRAINTES                                             │
│     "Accès piscine ?" [Oui/Non] + créneaux si oui           │
│     "Home trainer ?" [Oui/Non]                              │
│     "Blessures ?" [Textarea optionnel]                      │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  9. GÉNÉRATION                                              │
│     "On prépare ton programme..."                           │
│     [Animation génération]                                  │
│                        ↓                                    │
├─────────────────────────────────────────────────────────────┤
│  10. PROGRAMME PRÊT                                         │
│      "Voici ton plan sur X semaines !"                      │
│      [Vue générale du programme]                            │
│      [Commencer →]                                          │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 Usage quotidien

```
┌─────────────────────────────────────────────────────────────┐
│  ÉCRAN PRINCIPAL (Aujourd'hui)                              │
│                                                             │
│  📅 Mercredi 15 Janvier                                     │
│  Semaine 8/20 - Phase Build 1                               │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  🏃 Course - Intervalles                            │    │
│  │  50 min | 8 km                                      │    │
│  │  [Voir détail]                                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Cette semaine:                                             │
│  ✅ Lun - Natation technique                                │
│  ✅ Mar - Vélo tempo                                        │
│  🔵 Mer - Course intervalles ← Aujourd'hui                  │
│  ○  Jeu - Natation endurance                                │
│  ○  Ven - Repos                                             │
│  ○  Sam - Brick                                             │
│  ○  Dim - Sortie longue vélo                                │
│                                                             │
│  [📊 Vue programme complet]                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Templates d'entraînement

### 6.1 Half Ironman 70.3

| Phase | Semaines | Focus | Volume hebdo |
|-------|----------|-------|--------------|
| **Base** | 1-4 | Endurance aérobie, technique | 8-10h |
| **Build 1** | 5-8 | Volume progressif | 10-12h |
| **Build 2** | 9-12 | Intensité spécifique | 12-14h |
| **Peak** | 13-14 | Séances race pace, briques | 10-12h |
| **Taper** | 15-16 | Affûtage | 6-8h |

**Répartition type semaine Build:**
- Natation: 3x (technique, intervalles, endurance)
- Vélo: 3x (tempo, force, sortie longue)
- Course: 3x (intervalles, tempo, sortie longue)
- Brick: 1x (samedi)
- Repos: 1x

### 6.2 Ironman

| Phase | Semaines | Focus | Volume hebdo |
|-------|----------|-------|--------------|
| **Base** | 1-6 | Fondation aérobie | 10-12h |
| **Build 1** | 7-12 | Développement volume | 14-16h |
| **Build 2** | 13-18 | Spécificité Ironman | 16-20h |
| **Peak** | 19-22 | Simulation race, briques longues | 14-16h |
| **Taper** | 23-24 | Récupération, affûtage | 8-10h |

**Répartition type semaine Peak:**
- Natation: 3-4x (dont 1x eau libre si possible)
- Vélo: 3x (dont sortie 4-5h)
- Course: 3x (dont sortie 2h+)
- Brick longue: 1x (vélo 3h + run 1h)
- Repos: 1x

---

## 7. Types de séances

### 7.1 Natation

| Code | Nom | Durée | Objectif |
|------|-----|-------|----------|
| SWIM_TECH | Technique | 45-60' | Améliorer l'efficacité du mouvement |
| SWIM_ENDO | Endurance | 60-75' | Développer l'aérobie, régularité |
| SWIM_INTER | Intervalles | 60' | Travailler le seuil, vitesse |
| SWIM_CSS | Critical Swim Speed | 60' | Déterminer/améliorer allure seuil |
| SWIM_OW | Eau libre | Variable | Navigation, drafting, adaptation |

### 7.2 Vélo

| Code | Nom | Durée | Objectif |
|------|-----|-------|----------|
| BIKE_ENDO | Endurance | 1h30-3h | Base aérobie, économie |
| BIKE_TEMPO | Tempo/Sweet Spot | 1h-1h30 | Seuil, endurance puissance |
| BIKE_VO2 | VO2max | 1h | Capacité aérobie max |
| BIKE_FORCE | Force | 1h | Force musculaire spécifique |
| BIKE_LONG | Sortie longue | 3h-5h | Endurance longue distance |
| BIKE_RECUP | Récupération | 45'-1h | Récupération active |

### 7.3 Course à pied

| Code | Nom | Durée | Objectif |
|------|-----|-------|----------|
| RUN_ENDO | Endurance | 45'-1h15 | Base aérobie |
| RUN_TEMPO | Tempo | 45'-1h | Allure semi-marathon |
| RUN_INTER | Intervalles | 50'-1h | VMA, vitesse |
| RUN_LONG | Sortie longue | 1h30-2h30 | Endurance spécifique |
| RUN_RECUP | Récupération | 30'-40' | Régénération |
| RUN_PROG | Progressive | 1h | Montée en intensité |

### 7.4 Combinés

| Code | Nom | Durée | Objectif |
|------|-----|-------|----------|
| BRICK_SHORT | Enchaînement court | 1h30 | Adaptation transition |
| BRICK_LONG | Enchaînement long | 3h-4h | Simulation course |
| BRICK_RUN | Focus run post-vélo | 2h | Course sur jambes fatiguées |

---

## 8. Contraintes techniques

### 8.1 Performance
- Temps de chargement initial < 3s
- Génération programme < 10s
- Sync Strava < 5s par activité

### 8.2 Limites Strava API
- Rate limit: 100 requêtes / 15 min, 1000 / jour
- Webhook: 1 subscription par app
- Données historiques: 6 mois par défaut

### 8.3 Stockage D1
- Taille max DB: 500MB (free), 10GB (paid)
- Requêtes: 5M reads/jour, 100K writes/jour (free)

### 8.4 Notifications Expo
- Push tokens expirent après 1 an d'inactivité
- Limite: 600 notifications/minute

---

## 9. Métriques de succès

### 9.1 Acquisition
- Nombre d'inscriptions
- Taux de complétion onboarding
- Source d'acquisition (PSEO, referral, etc.)

### 9.2 Engagement
- DAU / WAU / MAU
- Taux de compliance hebdomadaire
- Nombre de séances marquées terminées

### 9.3 Rétention
- Rétention J7, J30, J90
- Churn rate
- Durée moyenne d'utilisation

### 9.4 Satisfaction
- NPS
- Taux d'objectifs atteints (arrivée à l'événement)
- Feedback utilisateur

---

## 10. Évolutions futures (post-MVP)

### V1.1
- Support Garmin Connect
- Formats Sprint et Olympique
- Partage social du programme

### V1.2
- Intégration calendrier (Google, Apple)
- Analyse détaillée performances
- Comparaison avec athlètes similaires

### V2.0
- Coaching IA conversationnel
- Plans nutrition
- Marketplace coaches humains
