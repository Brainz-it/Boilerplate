# Stratégie pSEO - TriTrainer

## Vue d'ensemble

Le système pSEO (Programmatic SEO) de TriTrainer génère automatiquement des pages optimisées pour le référencement à partir de données structurées, ciblant les requêtes longue traîne du triathlon.

---

## Architecture des pages

### Structure Pillar/Hub/Cluster

```
🏠 PILLAR PAGE (Page Pilier)
└── /training-plans
    ├── Stats globales (47 programmes, 4 distances, 3 niveaux)
    ├── Liens vers tous les hubs
    └── CTA principal → Générateur

    📦 HUB PAGES (Pages Hub)
    ├── /training-plans/sprint
    ├── /training-plans/olympic
    ├── /training-plans/half-ironman
    └── /training-plans/ironman
        ├── Tableau des phases d'entraînement
        ├── Graphique de volume
        ├── Guides spécifiques
        └── Liens vers clusters

        📄 CLUSTER PAGES (Pages Cluster)
        ├── /training-plans/sprint/debutant
        ├── /training-plans/sprint/intermediaire
        ├── /training-plans/sprint/avance
        └── ... (12 combinaisons distance×niveau)
```

### Maillage interne

```
                    ┌─────────────────────┐
                    │   /training-plans   │ ◄── PILLAR
                    │   (Page centrale)   │
                    └─────────┬───────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
    ┌───────────┐      ┌───────────┐      ┌───────────┐
    │  /sprint  │      │ /olympic  │      │ /ironman  │ ◄── HUBS
    └─────┬─────┘      └─────┬─────┘      └─────┬─────┘
          │                   │                   │
    ┌─────┴─────┐      ┌─────┴─────┐      ┌─────┴─────┐
    │           │      │           │      │           │
    ▼     ▼     ▼      ▼     ▼     ▼      ▼     ▼     ▼
   DEB  INTER  AVA    DEB  INTER  AVA    DEB  INTER  AVA ◄── CLUSTERS
```

**Stratégie de liens :**
- Pillar → Tous les Hubs (4 liens)
- Hub → Pillar + Clusters associés (1 + 3 liens)
- Cluster → Hub parent + Clusters frères + CTA générateur

---

## Clusters actuels (Exploités)

### 1. Cluster GENERATEUR - 28 pages
**URL Pattern:** `/generateur/{distance}-{level}` ou `/generateur/{distance}-{hours}h`

| Type | Combinaisons | Exemple |
|------|--------------|---------|
| Distance × Niveau | 5 × 3 = 15 | `/generateur/sprint-debutant` |
| Distance × Temps | Variable = 13 | `/generateur/olympic-5h` |

**Keywords ciblés :**
- "programme triathlon sprint débutant"
- "plan ironman 10h semaine"
- "entrainement half ironman intermédiaire"

**Volume estimé :** 500-2000 recherches/mois par page

---

### 2. Cluster COMPETITION - 10 pages
**URL Pattern:** `/competition/{race-slug}`

| Course | Distance | Localisation |
|--------|----------|--------------|
| Ironman Nice | Full | Nice, France |
| Ironman 70.3 Aix | Half | Aix-en-Provence |
| Ironman 70.3 Vichy | Half | Vichy |
| Triathlon Paris | Olympic | Paris |
| Triathlon Deauville | Olympic | Deauville |
| Triathlon Alpe d'Huez | Olympic | Alpe d'Huez |
| Embrunman | Full | Embrun |
| Triathlon La Baule | Sprint | La Baule |
| Ironman Hawaii | Full | Kona, USA |
| Challenge Roth | Full | Roth, Allemagne |

**Keywords ciblés :**
- "préparation ironman nice"
- "programme triathlon alpe d'huez"
- "entrainement embrunman"

**Volume estimé :** 1000-5000 recherches/mois (saisonnalité forte)

---

### 3. Cluster PROFIL - 5 pages
**URL Pattern:** `/profil/{profile-slug}`

| Profil | Description |
|--------|-------------|
| Homme 25-35 ans | Capacité récupération optimale |
| Femme 25-35 ans | Adaptation cycle menstruel |
| Master +40 ans | Récupération allongée |
| Parent actif | Optimisation temps limité |
| Cadre/Entrepreneur | Emploi du temps chargé |

**Keywords ciblés :**
- "triathlon master 40 ans"
- "entrainement triathlon parent"
- "programme triathlon femme"

**Volume estimé :** 200-800 recherches/mois par page

---

### 4. Cluster PROGRAMME - 4 pages
**URL Pattern:** `/programme/{weakness-slug}`

| Faiblesse | Discipline | Focus |
|-----------|------------|-------|
| Natation faible | Natation | Technique + endurance |
| Vélo faible | Cyclisme | Puissance + FTP |
| Course faible | Course | Progression sans blessure |
| Transitions lentes | Multi | Optimisation T1/T2 |

**Keywords ciblés :**
- "améliorer natation triathlon"
- "progresser vélo triathlon"
- "transitions rapides triathlon"

**Volume estimé :** 300-1000 recherches/mois par page

---

## Clusters potentiels (Non exploités)

### 5. Cluster SIMULATEUR (À créer)
**URL Pattern:** `/simulateur/{type}`

| Page | Fonctionnalité | Potentiel |
|------|----------------|-----------|
| `/simulateur/temps-course` | Estimateur temps selon profil | ⭐⭐⭐⭐⭐ |
| `/simulateur/zones-entrainement` | Calculateur zones FC/puissance | ⭐⭐⭐⭐ |
| `/simulateur/nutrition` | Besoins caloriques course | ⭐⭐⭐⭐ |
| `/simulateur/allure-natation` | Prédicteur temps natation | ⭐⭐⭐ |

**Potentiel SEO :** 5000+ recherches/mois combinées
**Lead potential :** TRÈS ÉLEVÉ (outil interactif)

---

### 6. Cluster OBJECTIF (À créer)
**URL Pattern:** `/objectif/{goal-type}`

| Page | Description |
|------|-------------|
| `/objectif/finir-premier-triathlon` | Guide completion |
| `/objectif/sub-3h-olympic` | Objectif temps spécifique |
| `/objectif/qualification-nice` | Guide qualification |
| `/objectif/perte-poids` | Triathlon pour maigrir |

**Potentiel SEO :** 3000+ recherches/mois
**Pages estimées :** 10-15 pages

---

### 7. Cluster ÉQUIPEMENT (À créer)
**URL Pattern:** `/equipement/{category}`

| Page | Contenu |
|------|---------|
| `/equipement/combinaison-triathlon` | Guide achat combinaison |
| `/equipement/velo-triathlon-budget` | Vélos par budget |
| `/equipement/chaussures-course` | Chaussures transition |
| `/equipement/montre-triathlon` | Comparatif montres GPS |

**Potentiel SEO :** 10000+ recherches/mois
**Monétisation :** Affiliation Amazon/Décathlon

---

### 8. Cluster NUTRITION (À créer)
**URL Pattern:** `/nutrition/{topic}`

| Page | Contenu |
|------|---------|
| `/nutrition/avant-course` | Repas J-1 et petit-déjeuner |
| `/nutrition/pendant-ironman` | Stratégie ravitaillement |
| `/nutrition/recuperation` | Post-course nutrition |
| `/nutrition/hydratation` | Électrolytes et boissons |

**Potentiel SEO :** 5000+ recherches/mois

---

## Générateur de programme + Lead PDF

### Flux utilisateur

```
┌─────────────────────────────────────────────────────────────┐
│  ÉTAPE 1: Découverte via pSEO                               │
│  └── User arrive sur /training-plans/olympic/debutant       │
│      via recherche "programme triathlon olympic débutant"   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ÉTAPE 2: Engagement avec CTA                               │
│  └── Bouton "GÉNÉRER MON PROGRAMME PERSONNALISÉ"            │
│      visible dans Hero + Footer                             │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ÉTAPE 3: Formulaire multi-étapes                           │
│  ├── Distance cible                                         │
│  ├── Niveau actuel                                          │
│  ├── Heures disponibles/semaine                             │
│  ├── Date de course                                         │
│  ├── Objectif (finir, temps, performance)                   │
│  └── Points faibles                                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ÉTAPE 4: Capture Lead (EMAIL WALL)                         │
│  └── "Entrez votre email pour recevoir votre programme"     │
│      ├── Email (obligatoire)                                │
│      ├── Prénom (optionnel)                                 │
│      └── ☑️ Accepter newsletter conseils triathlon          │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ÉTAPE 5: Génération + Envoi                                │
│  ├── Génération PDF personnalisé (AI ou template)           │
│  ├── Envoi email avec PDF attaché                           │
│  ├── Redirection page merci + preview programme             │
│  └── Séquence email nurturing (J+1, J+3, J+7)               │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  ÉTAPE 6: Conversion Premium                                │
│  └── Email J+7: "Passez à la version complète"              │
│      ├── Suivi connecté Strava                              │
│      ├── Ajustements automatiques                           │
│      ├── Coach virtuel AI                                   │
│      └── Communauté premium                                 │
└─────────────────────────────────────────────────────────────┘
```

### Contenu du PDF généré

```
📄 PROGRAMME TRIATHLON PERSONNALISÉ
├── Page 1: Résumé et objectifs
│   ├── Distance: Olympic (1500m/40km/10km)
│   ├── Niveau: Débutant
│   ├── Durée: 12 semaines
│   └── Volume: 5-8h/semaine
│
├── Page 2-3: Planning semaine type
│   ├── Lundi: Repos
│   ├── Mardi: Natation technique 45min
│   ├── Mercredi: Course EF 40min
│   ├── Jeudi: Vélo intervalles 1h
│   ├── Vendredi: Natation endurance 45min
│   ├── Samedi: Brick vélo-course 1h30
│   └── Dimanche: Sortie longue vélo 2h
│
├── Page 4-7: Programme 12 semaines détaillé
│   ├── Phase 1 (S1-4): Base aérobique
│   ├── Phase 2 (S5-8): Développement
│   ├── Phase 3 (S9-11): Spécifique
│   └── Phase 4 (S12): Affûtage
│
├── Page 8: Zones d'entraînement
│   ├── FC: Z1-Z5 avec vos valeurs
│   ├── Natation: Allures CSS
│   └── Vélo: Zones FTP
│
├── Page 9: Conseils nutrition
│   ├── Avant l'entraînement
│   ├── Pendant (longues séances)
│   └── Récupération
│
└── Page 10: CTA Premium
    ├── QR code app mobile
    ├── Offre -20% premier mois
    └── Lien inscription premium
```

---

## Potentiel trafic et leads

### Estimation trafic organique

| Cluster | Pages | Recherches/mois/page | Trafic estimé |
|---------|-------|---------------------|---------------|
| Générateur | 28 | 500-2000 | 14,000-56,000 |
| Compétition | 10 | 1000-5000 | 10,000-50,000 |
| Profil | 5 | 200-800 | 1,000-4,000 |
| Programme | 4 | 300-1000 | 1,200-4,000 |
| **TOTAL actuel** | **47** | - | **26,200-114,000** |

### Potentiel avec clusters additionnels

| Cluster | Pages estimées | Trafic additionnel |
|---------|----------------|-------------------|
| Simulateur | 4-6 | 5,000-15,000 |
| Objectif | 10-15 | 3,000-10,000 |
| Équipement | 15-20 | 10,000-30,000 |
| Nutrition | 8-12 | 5,000-15,000 |
| **TOTAL potentiel** | **85-100** | **49,200-184,000** |

### Conversion leads

```
Trafic mensuel:     50,000 visiteurs (estimation conservatrice)
Taux clic CTA:      5-10%
Visiteurs formulaire: 2,500-5,000
Taux completion:    30-50%
LEADS MENSUELS:     750-2,500

Conversion premium: 2-5%
CLIENTS PREMIUM:    15-125/mois
Revenue (10€/mois): 150€-1,250€ MRR initial
```

---

## Roadmap recommandée

### Phase 1 - Optimisation (Semaines 1-2)
- [ ] Ajouter schéma JSON-LD (Article, FAQPage, HowTo)
- [ ] Implémenter FAQ dynamique sur chaque cluster
- [ ] Optimiser Core Web Vitals
- [ ] Soumettre sitemap à Google/Bing

### Phase 2 - Générateur PDF (Semaines 3-4)
- [ ] Créer composant formulaire multi-étapes
- [ ] Intégrer Resend pour emails transactionnels
- [ ] Développer template PDF (react-pdf ou puppeteer)
- [ ] Page de remerciement + preview
- [ ] Séquence email nurturing (3 emails)

### Phase 3 - Expansion clusters (Semaines 5-8)
- [ ] Cluster Simulateur (4 pages outils)
- [ ] Cluster Objectif (10 pages)
- [ ] Intégration calculateurs interactifs

### Phase 4 - Monétisation (Semaines 9-12)
- [ ] Cluster Équipement avec liens affiliation
- [ ] Cluster Nutrition avec partenariats
- [ ] A/B testing CTAs
- [ ] Optimisation conversion funnel

---

## Stack technique pSEO

```
src/
├── app/(pseo)/
│   ├── [...slug]/page.tsx        # Catch-all dynamique
│   ├── layout.tsx                # Layout brutalist
│   └── training-plans/
│       ├── page.tsx              # Pillar page
│       ├── [distance]/
│       │   ├── page.tsx          # Hub pages
│       │   └── [level]/
│       │       └── page.tsx      # Cluster pages
│
├── components/brutal/
│   ├── BrutalHero.tsx
│   ├── BrutalCard.tsx
│   ├── BrutalFAQ.tsx
│   ├── BrutalTable.tsx
│   └── BrutalStats.tsx
│
├── lib/pseo/
│   └── seed-data.ts              # Données + générateur pages
│
└── lib/db/schema/
    └── pseo.ts                   # Tables DB pour rollout
```

---

## Métriques de succès

| Métrique | Objectif M1 | Objectif M3 | Objectif M6 |
|----------|-------------|-------------|-------------|
| Pages indexées | 47 | 60 | 100 |
| Trafic organique | 5,000 | 20,000 | 50,000 |
| Leads/mois | 100 | 500 | 1,500 |
| Conversion premium | 1% | 2% | 3% |
| MRR | 100€ | 500€ | 2,000€ |

---

## Conclusion

Le système pSEO de TriTrainer est conçu pour capturer le trafic longue traîne du triathlon francophone. Avec 47 pages actuellement déployées et un potentiel de 100+ pages, l'objectif est de devenir la référence pour les programmes d'entraînement triathlon personnalisés en France.

**Avantages compétitifs :**
1. Design brutalist différenciant (mémorable)
2. Génération automatique scalable
3. Maillage interne optimisé SEO
4. Funnel lead magnet (PDF gratuit)
5. Données structurées complètes

**Prochaine priorité :** Implémenter le générateur PDF avec capture email pour convertir le trafic en leads qualifiés.
