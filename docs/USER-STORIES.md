# User Stories - TriathlonApp

> Stories organisées par epic et priorité

---

## Légende

**Priorité:**
- 🔴 P0 - MVP critique
- 🟠 P1 - MVP important
- 🟡 P2 - Post-MVP

**Estimation (Story Points):**
- XS: 1 | S: 2 | M: 3 | L: 5 | XL: 8

---

## Epic 1: Authentification

### US-AUTH-01 🔴 [M]
**En tant qu'** utilisateur
**Je veux** me connecter avec mon compte Strava
**Afin de** accéder à l'application avec mes données d'entraînement

**Critères d'acceptation:**
- [ ] Bouton "Se connecter avec Strava" sur l'écran d'accueil
- [ ] Redirection vers OAuth Strava
- [ ] Récupération du token après autorisation
- [ ] Création du compte utilisateur si première connexion
- [ ] Stockage sécurisé des tokens

**Notes techniques:**
- OAuth 2.0 flow avec PKCE pour mobile
- Stocker tokens dans SecureStore (Expo)

---

### US-AUTH-02 🔴 [S]
**En tant qu'** utilisateur connecté
**Je veux** que ma session reste active
**Afin de** ne pas avoir à me reconnecter à chaque ouverture

**Critères d'acceptation:**
- [ ] Session persiste entre les fermetures d'app
- [ ] Refresh automatique du token Strava si expiré
- [ ] Déconnexion automatique si refresh échoue

---

### US-AUTH-03 🟠 [XS]
**En tant qu'** utilisateur
**Je veux** pouvoir me déconnecter
**Afin de** sécuriser mon compte sur un appareil partagé

**Critères d'acceptation:**
- [ ] Option déconnexion dans les paramètres
- [ ] Suppression des tokens locaux
- [ ] Retour à l'écran de connexion

---

## Epic 2: Onboarding

### US-ONB-01 🔴 [L]
**En tant que** nouvel utilisateur
**Je veux** que l'app analyse automatiquement mon historique Strava
**Afin de** personnaliser mon programme selon mon niveau actuel

**Critères d'acceptation:**
- [ ] Écran de chargement avec animation
- [ ] Récupération des 6 derniers mois d'activités
- [ ] Calcul des volumes par sport (natation, vélo, course)
- [ ] Affichage progressif des stats découvertes
- [ ] Détection du niveau estimé (débutant/intermédiaire/avancé)

**Notes techniques:**
- Pagination API Strava (200 activités max par requête)
- Cache des données analysées

---

### US-ONB-02 🔴 [S]
**En tant que** nouvel utilisateur
**Je veux** sélectionner mon objectif (70.3 ou Ironman)
**Afin de** recevoir un programme adapté à cette distance

**Critères d'acceptation:**
- [ ] Écran avec 2 cartes cliquables (70.3 / Ironman)
- [ ] Description courte de chaque format
- [ ] Indication du volume d'entraînement type
- [ ] Sélection visuelle claire

---

### US-ONB-03 🔴 [S]
**En tant que** nouvel utilisateur
**Je veux** indiquer la date de mon événement
**Afin que** le programme soit calé sur cette échéance

**Critères d'acceptation:**
- [ ] Calendrier de sélection de date
- [ ] Validation: date > aujourd'hui + 8 semaines
- [ ] Affichage du nombre de semaines de préparation
- [ ] Warning si délai trop court pour la distance

---

### US-ONB-04 🔴 [S]
**En tant que** nouvel utilisateur
**Je veux** indiquer mon niveau d'expérience
**Afin que** le programme soit adapté à mon vécu

**Critères d'acceptation:**
- [ ] 3 options: Découverte / Expérimenté / Compétiteur
- [ ] Description de chaque niveau
- [ ] Pré-sélection basée sur l'analyse Strava

---

### US-ONB-05 🔴 [S]
**En tant que** nouvel utilisateur
**Je veux** indiquer mes disponibilités hebdomadaires
**Afin que** le programme respecte mon emploi du temps

**Critères d'acceptation:**
- [ ] Slider pour le nombre d'heures (5h-20h)
- [ ] Sélection des jours impossibles
- [ ] Choix du jour préféré pour la sortie longue

---

### US-ONB-06 🟠 [M]
**En tant que** nouvel utilisateur
**Je veux** indiquer mes contraintes (piscine, équipement)
**Afin que** le programme soit réaliste

**Critères d'acceptation:**
- [ ] Toggle accès piscine + créneaux si oui
- [ ] Toggle home trainer disponible
- [ ] Champ texte optionnel pour blessures/limitations

---

### US-ONB-07 🟡 [S]
**En tant que** nouvel utilisateur
**Je veux** pouvoir définir un objectif de temps
**Afin que** l'intensité du programme soit ajustée

**Critères d'acceptation:**
- [ ] Option "Juste finir" vs "Objectif temps"
- [ ] Saisie du temps cible si objectif temps
- [ ] Validation cohérence temps/niveau

---

### US-ONB-08 🔴 [XL]
**En tant que** nouvel utilisateur
**Je veux** que l'app génère mon programme personnalisé
**Afin de** commencer mon entraînement

**Critères d'acceptation:**
- [ ] Animation de génération
- [ ] Programme créé avec toutes les semaines
- [ ] Séances détaillées pour chaque jour
- [ ] Affichage récapitulatif avant validation
- [ ] Bouton "Commencer l'entraînement"

---

## Epic 3: Programme d'entraînement

### US-PGM-01 🔴 [M]
**En tant qu'** utilisateur
**Je veux** voir une vue d'ensemble de mon programme
**Afin de** comprendre ma progression globale

**Critères d'acceptation:**
- [ ] Affichage de l'objectif (event + date)
- [ ] Barre de progression (semaine actuelle / total)
- [ ] Indication de la phase actuelle
- [ ] Stats cumulées (km nagés/pédalés/courus)
- [ ] Jours restants avant l'événement

---

### US-PGM-02 🔴 [M]
**En tant qu'** utilisateur
**Je veux** voir le détail de chaque semaine
**Afin de** planifier mon entraînement

**Critères d'acceptation:**
- [ ] Liste des séances jour par jour
- [ ] Icône sport + titre + durée pour chaque séance
- [ ] Statut de chaque séance (fait/à faire/passé)
- [ ] Volume total de la semaine (heures, km par sport)
- [ ] Navigation entre les semaines

---

### US-PGM-03 🔴 [S]
**En tant qu'** utilisateur
**Je veux** accéder rapidement aux séances du jour
**Afin de** savoir ce que je dois faire maintenant

**Critères d'acceptation:**
- [ ] Widget "Aujourd'hui" en haut de l'écran
- [ ] Séance(s) du jour en surbrillance
- [ ] Accès direct au détail en un tap

---

### US-PGM-04 🟠 [M]
**En tant qu'** utilisateur
**Je veux** voir les phases de mon programme
**Afin de** comprendre la logique de préparation

**Critères d'acceptation:**
- [ ] Timeline visuelle des phases
- [ ] Phase actuelle mise en évidence
- [ ] Description de chaque phase au tap
- [ ] Dates de début/fin de chaque phase

---

## Epic 4: Séances

### US-SES-01 🔴 [L]
**En tant qu'** utilisateur
**Je veux** voir le détail complet d'une séance
**Afin de** savoir exactement quoi faire

**Critères d'acceptation:**
- [ ] Titre et type de séance
- [ ] Durée et distance prévues
- [ ] Objectif pédagogique expliqué
- [ ] Zones cardiaques attendues avec valeurs personnalisées
- [ ] Déroulé détaillé (échauffement, corps, retour calme)
- [ ] Conseils et astuces

---

### US-SES-02 🔴 [S]
**En tant qu'** utilisateur
**Je veux** voir les zones cardiaques attendues
**Afin de** m'entraîner à la bonne intensité

**Critères d'acceptation:**
- [ ] Affichage des zones FC pour chaque phase
- [ ] Valeurs en BPM personnalisées
- [ ] Code couleur par zone (Z1 vert → Z5 rouge)
- [ ] Pourcentage de temps par zone

---

### US-SES-03 🔴 [S]
**En tant qu'** utilisateur
**Je veux** marquer une séance comme terminée
**Afin de** suivre ma progression

**Critères d'acceptation:**
- [ ] Bouton "Marquer comme faite"
- [ ] Séance passe en statut "completed"
- [ ] Mise à jour des stats semaine
- [ ] Animation de confirmation

---

### US-SES-04 🟠 [S]
**En tant qu'** utilisateur
**Je veux** pouvoir passer une séance
**Afin de** signaler que je ne l'ai pas faite

**Critères d'acceptation:**
- [ ] Option "Passer cette séance"
- [ ] Sélection du motif (fatigue, blessure, autre)
- [ ] Séance marquée comme "skipped"
- [ ] Impact sur le taux de compliance

---

### US-SES-05 🟠 [M]
**En tant qu'** utilisateur
**Je veux** que mes activités Strava soient associées aux séances
**Afin de** ne pas saisir manuellement

**Critères d'acceptation:**
- [ ] Détection automatique d'un match (date + sport + durée)
- [ ] Proposition d'association à l'utilisateur
- [ ] Import des données réelles (durée, distance, FC)
- [ ] Marquage automatique comme complétée

---

### US-SES-06 🟡 [S]
**En tant qu'** utilisateur
**Je veux** voir mes performances vs le prévu
**Afin de** évaluer ma séance

**Critères d'acceptation:**
- [ ] Comparaison durée prévue vs réelle
- [ ] Comparaison distance prévue vs réelle
- [ ] Comparaison FC cible vs réelle
- [ ] Indication si séance "réussie" ou non

---

## Epic 5: Synchronisation Strava

### US-STR-01 🔴 [L]
**En tant qu'** utilisateur
**Je veux** que mes nouvelles activités soient synchronisées automatiquement
**Afin de** que mon suivi soit à jour

**Critères d'acceptation:**
- [ ] Webhook Strava configuré
- [ ] Réception des events "activity.create"
- [ ] Import des données de l'activité
- [ ] Tentative de match avec séance planifiée
- [ ] Notification si nouvelle activité détectée

---

### US-STR-02 🔴 [M]
**En tant que** système
**Je veux** recalculer les programmes chaque semaine
**Afin de** adapter le plan selon les séances réalisées

**Critères d'acceptation:**
- [ ] Job CRON lundi 6h
- [ ] Comparaison prévu vs réalisé semaine passée
- [ ] Calcul du taux de compliance
- [ ] Ajustement semaine suivante si écart significatif
- [ ] Notification utilisateur des changements

---

### US-STR-03 🟠 [S]
**En tant qu'** utilisateur
**Je veux** pouvoir déclencher une synchronisation manuelle
**Afin de** forcer la mise à jour si besoin

**Critères d'acceptation:**
- [ ] Pull-to-refresh sur l'écran programme
- [ ] Bouton sync dans les paramètres
- [ ] Indicateur de dernière synchronisation

---

## Epic 6: Notifications

### US-NOT-01 🔴 [M]
**En tant qu'** utilisateur
**Je veux** recevoir une notification quand mon programme est mis à jour
**Afin de** être informé des changements

**Critères d'acceptation:**
- [ ] Push notification après recalcul hebdo
- [ ] Résumé des modifications
- [ ] Deep link vers le programme

---

### US-NOT-02 🟠 [M]
**En tant qu'** utilisateur
**Je veux** recevoir un rappel pour ma séance du jour
**Afin de** ne pas l'oublier

**Critères d'acceptation:**
- [ ] Notification le matin (heure configurable)
- [ ] Titre de la séance + durée
- [ ] Deep link vers le détail

---

### US-NOT-03 🟠 [S]
**En tant qu'** utilisateur
**Je veux** être alerté en cas de surcharge détectée
**Afin de** prévenir le surentraînement

**Critères d'acceptation:**
- [ ] Notification si volume > 120% du prévu
- [ ] Conseil de repos ou allègement
- [ ] Option de réduire la semaine suivante

---

### US-NOT-04 🟡 [S]
**En tant qu'** utilisateur
**Je veux** recevoir des encouragements
**Afin de** rester motivé

**Critères d'acceptation:**
- [ ] Notification quand un objectif est atteint
- [ ] Félicitations quand compliance > 90%
- [ ] Messages motivationnels configurables

---

### US-NOT-05 🟠 [S]
**En tant qu'** utilisateur
**Je veux** configurer mes préférences de notifications
**Afin de** ne recevoir que ce qui m'intéresse

**Critères d'acceptation:**
- [ ] Toggle par type de notification
- [ ] Choix de l'heure des rappels
- [ ] Option "Ne pas déranger" certains jours

---

## Epic 7: Back-office Admin

### US-ADM-01 🔴 [M]
**En tant qu'** administrateur
**Je veux** me connecter au back-office
**Afin de** gérer l'application

**Critères d'acceptation:**
- [ ] Page de login email/password
- [ ] Session sécurisée avec cookie httpOnly
- [ ] Expiration de session après inactivité
- [ ] Logout

---

### US-ADM-02 🔴 [L]
**En tant qu'** administrateur
**Je veux** gérer les templates de programmes
**Afin de** créer et modifier les plans d'entraînement

**Critères d'acceptation:**
- [ ] Liste des templates existants
- [ ] Création d'un nouveau template
- [ ] Modification d'un template
- [ ] Activation/désactivation
- [ ] Visualisation des phases et semaines types

---

### US-ADM-03 🔴 [L]
**En tant qu'** administrateur
**Je veux** gérer la bibliothèque de séances types
**Afin de** enrichir les programmes

**Critères d'acceptation:**
- [ ] Liste des séances par sport
- [ ] Création d'une nouvelle séance type
- [ ] Modification d'une séance existante
- [ ] Définition des zones, durées, structures
- [ ] Tags et catégorisation

---

### US-ADM-04 🟠 [M]
**En tant qu'** administrateur
**Je veux** voir la liste des utilisateurs
**Afin de** suivre l'adoption

**Critères d'acceptation:**
- [ ] Liste paginée des utilisateurs
- [ ] Recherche par nom/email
- [ ] Affichage du statut onboarding
- [ ] Lien vers le programme actif

---

### US-ADM-05 🔴 [M]
**En tant qu'** administrateur
**Je veux** gérer les jobs/workers
**Afin de** contrôler les tâches automatiques

**Critères d'acceptation:**
- [ ] Liste des jobs configurés
- [ ] Activation/désactivation
- [ ] Modification du CRON
- [ ] Exécution manuelle
- [ ] Historique des exécutions

---

### US-ADM-06 🔴 [M]
**En tant qu'** administrateur
**Je veux** consulter les logs d'audit
**Afin de** comprendre ce qui se passe

**Critères d'acceptation:**
- [ ] Liste des événements avec filtres
- [ ] Détail de chaque événement
- [ ] Filtrage par type, entité, acteur
- [ ] Export CSV

---

## Epic 8: PSEO

### US-SEO-01 🟠 [L]
**En tant que** système
**Je veux** générer des pages SEO pour chaque distance
**Afin d'** acquérir du trafic organique

**Critères d'acceptation:**
- [ ] Page /triathlon/half-ironman
- [ ] Page /triathlon/ironman
- [ ] Contenu structuré et optimisé SEO
- [ ] Métadonnées (title, description, OG)
- [ ] Call-to-action vers l'app

---

### US-SEO-02 🟡 [M]
**En tant que** système
**Je veux** générer des pages pour les types de séances
**Afin d'** éduquer les visiteurs

**Critères d'acceptation:**
- [ ] Pages /seance/natation-intervalles, etc.
- [ ] Explication de chaque type de séance
- [ ] Bénéfices et structure type
- [ ] Liens internes vers autres séances

---

### US-SEO-03 🟡 [L]
**En tant qu'** administrateur
**Je veux** que les pages PSEO soient générées automatiquement
**Afin de** ne pas les maintenir manuellement

**Critères d'acceptation:**
- [ ] Worker de génération
- [ ] Déclenchement hebdomadaire ou à la demande
- [ ] Gestion des versions
- [ ] Publication/dépublication

---

## Epic 9: Profil & Paramètres

### US-PRO-01 🟠 [M]
**En tant qu'** utilisateur
**Je veux** voir et modifier mes zones cardiaques
**Afin de** personnaliser mes cibles

**Critères d'acceptation:**
- [ ] Affichage des 5 zones avec valeurs
- [ ] Source (Strava/calculé/manuel)
- [ ] Modification de la FC max
- [ ] Recalcul automatique des zones

---

### US-PRO-02 🟡 [S]
**En tant qu'** utilisateur
**Je veux** modifier mes disponibilités
**Afin de** adapter mon programme si ma situation change

**Critères d'acceptation:**
- [ ] Accès aux paramètres de disponibilité
- [ ] Modification des heures/jours
- [ ] Confirmation de recalcul du programme

---

### US-PRO-03 🟡 [S]
**En tant qu'** utilisateur
**Je veux** changer mon objectif
**Afin de** m'adapter si mes plans changent

**Critères d'acceptation:**
- [ ] Modification de la date d'événement
- [ ] Changement de distance
- [ ] Avertissement de régénération programme
- [ ] Conservation de l'historique

---

## Récapitulatif par priorité

### 🔴 P0 - MVP (32 stories)

| Epic | Stories | Points |
|------|---------|--------|
| Auth | 2 | 5 |
| Onboarding | 7 | 23 |
| Programme | 3 | 8 |
| Séances | 3 | 9 |
| Strava Sync | 2 | 8 |
| Notifications | 1 | 3 |
| Back-office | 5 | 16 |
| **Total** | **23** | **72** |

### 🟠 P1 (12 stories, ~35 points)

### 🟡 P2 (8 stories, ~20 points)

---

## Definition of Done

- [ ] Code implémenté et fonctionnel
- [ ] Tests unitaires passent
- [ ] Code review effectuée
- [ ] Documentation mise à jour si nécessaire
- [ ] Testé sur iOS et Android (mobile)
- [ ] Responsive testé (web)
- [ ] Pas de régression détectée
- [ ] Déployé en staging
- [ ] Validé par le PO
