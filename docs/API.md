# Documentation API - TriathlonApp

> API REST Next.js déployée sur Cloudflare Pages

---

## Base URL

```
Production: https://api.triathlon-app.com
Development: http://localhost:3000
```

---

## Authentification

### Tokens

L'API utilise deux types d'authentification :

| Type | Usage | Header |
|------|-------|--------|
| **User Token** | App mobile | `Authorization: Bearer <jwt_token>` |
| **Admin Session** | Back-office | Cookie `admin_session` |

### JWT Structure (User)

```json
{
  "sub": "user_id",
  "strava_id": "123456",
  "exp": 1234567890,
  "iat": 1234567890
}
```

---

## Endpoints

### Auth

#### `GET /api/auth/strava`

Initie le flow OAuth Strava.

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `redirect_uri` | string | Yes | URI de callback (mobile deep link) |
| `state` | string | No | State pour CSRF protection |

**Response:** Redirect vers Strava OAuth

---

#### `GET /api/auth/strava/callback`

Callback OAuth Strava.

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `code` | string | Yes | Code OAuth Strava |
| `state` | string | No | State CSRF |

**Response:**
```json
{
  "success": true,
  "user": {
    "id": "usr_abc123",
    "strava_id": "123456",
    "first_name": "John",
    "last_name": "Doe",
    "profile_picture": "https://...",
    "onboarding_completed": false
  },
  "token": "eyJhbG...",
  "is_new_user": true
}
```

**Errors:**
| Code | Message |
|------|---------|
| 400 | `invalid_code` - Code OAuth invalide |
| 500 | `strava_error` - Erreur API Strava |

---

#### `POST /api/auth/refresh`

Rafraîchit le token Strava expiré.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "token": "eyJhbG...",
  "expires_at": 1234567890
}
```

---

#### `POST /api/auth/logout`

Déconnecte l'utilisateur.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true
}
```

---

#### `GET /api/auth/me`

Récupère l'utilisateur courant.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "user": {
    "id": "usr_abc123",
    "strava_id": "123456",
    "email": "john@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "profile_picture": "https://...",
    "onboarding_completed": true
  },
  "profile": {
    "experience_level": "intermediate",
    "weekly_hours_available": 12,
    "fc_max": 185,
    "ftp": 250
  }
}
```

---

### Onboarding

#### `GET /api/onboarding/status`

État de l'onboarding utilisateur.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "completed": false,
  "current_step": 3,
  "steps": {
    "strava_analysis": { "completed": true, "data": {...} },
    "goal": { "completed": true },
    "level": { "completed": true },
    "availability": { "completed": false },
    "constraints": { "completed": false },
    "target_time": { "completed": false }
  }
}
```

---

#### `GET /api/onboarding/strava-analysis`

Analyse les 6 derniers mois d'activités Strava.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "analysis": {
    "period": {
      "start": "2024-07-01",
      "end": "2025-01-01"
    },
    "totals": {
      "activities": 156,
      "hours": 245.5
    },
    "by_sport": {
      "swim": {
        "count": 42,
        "distance_m": 84000,
        "duration_min": 2520,
        "avg_pace_100m": 108
      },
      "bike": {
        "count": 58,
        "distance_km": 2450,
        "duration_min": 5800,
        "avg_speed_kmh": 25.4,
        "avg_power_w": 195
      },
      "run": {
        "count": 56,
        "distance_km": 485,
        "duration_min": 2640,
        "avg_pace_min_km": 5.45
      }
    },
    "weekly_avg": {
      "hours": 9.4,
      "sessions": 6
    },
    "zones_detected": {
      "hr_zones": [...],
      "source": "strava"
    },
    "estimated_level": "intermediate"
  }
}
```

---

#### `POST /api/onboarding/profile`

Sauvegarde le profil athlète.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "birth_year": 1990,
  "gender": "M",
  "weight_kg": 75,
  "experience_level": "intermediate",
  "triathlon_count": 3,
  "longest_distance": "olympic"
}
```

**Response:**
```json
{
  "success": true,
  "profile_id": "prof_xyz789"
}
```

---

#### `POST /api/onboarding/goal`

Définit l'objectif principal.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "event_name": "Ironman Nice 2025",
  "event_date": "2025-09-14",
  "distance_type": "ironman",
  "target_time": null,
  "event_location": "Nice, France",
  "event_url": "https://www.ironman.com/im-nice"
}
```

**Response:**
```json
{
  "success": true,
  "goal_id": "goal_abc123",
  "weeks_until_event": 24,
  "recommended_template": "tpl_im_int_24"
}
```

**Validation:**
- `event_date` doit être > aujourd'hui + 8 semaines
- `distance_type` doit être `70.3` ou `ironman`

---

#### `POST /api/onboarding/availability`

Configure les disponibilités.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "weekly_hours": 14,
  "unavailable_days": [0, 3],
  "preferred_long_day": 6
}
```

**Response:**
```json
{
  "success": true
}
```

---

#### `POST /api/onboarding/constraints`

Configure les contraintes.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "pool_access": true,
  "pool_schedule": {
    "monday": ["12:00-13:30", "19:00-21:00"],
    "wednesday": ["12:00-13:30"],
    "saturday": ["08:00-12:00"]
  },
  "home_trainer": true,
  "outdoor_bike_only": false,
  "injuries_notes": "Tendinite cheville droite en 2023, guérie"
}
```

**Response:**
```json
{
  "success": true
}
```

---

#### `POST /api/onboarding/complete`

Finalise l'onboarding et génère le programme.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "target_time": 39600,
  "fc_max_manual": null,
  "ftp_manual": null
}
```

**Response:**
```json
{
  "success": true,
  "program": {
    "id": "prog_xyz789",
    "goal_id": "goal_abc123",
    "template_id": "tpl_im_int_24",
    "start_date": "2025-01-20",
    "end_date": "2025-09-14",
    "total_weeks": 24,
    "phases": [
      { "name": "Base", "weeks": "1-6", "start": "2025-01-20" },
      { "name": "Build 1", "weeks": "7-12", "start": "2025-03-03" },
      { "name": "Build 2", "weeks": "13-18", "start": "2025-04-14" },
      { "name": "Peak", "weeks": "19-22", "start": "2025-05-26" },
      { "name": "Taper", "weeks": "23-24", "start": "2025-06-23" }
    ]
  }
}
```

---

### Programme

#### `GET /api/program/current`

Récupère le programme actif.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "program": {
    "id": "prog_xyz789",
    "status": "active",
    "goal": {
      "event_name": "Ironman Nice 2025",
      "event_date": "2025-09-14",
      "distance_type": "ironman",
      "days_remaining": 145
    },
    "progress": {
      "current_week": 8,
      "total_weeks": 24,
      "current_phase": "Build 1",
      "completion_pct": 33.3
    },
    "stats": {
      "total_swim_m": 42000,
      "total_bike_km": 1200,
      "total_run_km": 240,
      "total_hours": 98.5,
      "avg_compliance": 87.5
    }
  }
}
```

---

#### `GET /api/program/:id`

Détail d'un programme.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "program": {
    "id": "prog_xyz789",
    "goal": {...},
    "template": {...},
    "start_date": "2025-01-20",
    "end_date": "2025-09-14",
    "total_weeks": 24,
    "current_week": 8,
    "status": "active",
    "phases": [...],
    "weekly_hours_target": 16,
    "last_recalc_at": "2025-03-10T06:00:00Z"
  }
}
```

---

#### `GET /api/program/:id/overview`

Vue d'ensemble du programme (toutes les semaines).

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "overview": {
    "program_id": "prog_xyz789",
    "weeks": [
      {
        "week_number": 1,
        "phase": "Base",
        "status": "completed",
        "planned_hours": 12,
        "actual_hours": 11.5,
        "compliance_rate": 95.8,
        "sessions_completed": 7,
        "sessions_total": 7
      },
      {
        "week_number": 2,
        "phase": "Base",
        "status": "completed",
        "planned_hours": 12,
        "actual_hours": 10.2,
        "compliance_rate": 85.0,
        "sessions_completed": 6,
        "sessions_total": 7
      },
      // ... autres semaines
      {
        "week_number": 8,
        "phase": "Build 1",
        "status": "current",
        "planned_hours": 16,
        "actual_hours": 8.5,
        "compliance_rate": null,
        "sessions_completed": 4,
        "sessions_total": 8
      }
    ],
    "totals": {
      "planned_hours": 384,
      "actual_hours": 98.5,
      "avg_compliance": 87.5
    }
  }
}
```

---

#### `GET /api/program/:id/week/:num`

Détail d'une semaine.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "week": {
    "id": "week_abc123",
    "program_id": "prog_xyz789",
    "week_number": 8,
    "phase": "Build 1",
    "status": "current",
    "start_date": "2025-03-10",
    "end_date": "2025-03-16",
    "planned": {
      "hours": 16,
      "swim_m": 7500,
      "bike_km": 180,
      "run_km": 45
    },
    "actual": {
      "hours": 8.5,
      "swim_m": 4500,
      "bike_km": 95,
      "run_km": 22
    },
    "sessions": [
      {
        "id": "sess_001",
        "day_of_week": 1,
        "scheduled_date": "2025-03-10",
        "sport": "swim",
        "title": "Natation technique",
        "duration_planned": 60,
        "status": "completed",
        "actual_duration": 55
      },
      // ... autres séances
    ],
    "compliance_rate": 53.1,
    "recalc_notes": null
  }
}
```

---

#### `POST /api/program/:id/recalculate`

Force le recalcul du programme.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "success": true,
  "recalculation": {
    "triggered_at": "2025-03-10T14:30:00Z",
    "status": "completed",
    "changes": {
      "weeks_modified": [9, 10],
      "sessions_added": 2,
      "sessions_removed": 1,
      "volume_adjustment": -5
    }
  }
}
```

---

### Séances

#### `GET /api/sessions/today`

Séances du jour.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "date": "2025-03-12",
  "sessions": [
    {
      "id": "sess_003",
      "sport": "run",
      "session_type": "intervals",
      "title": "Course - Intervalles",
      "duration_planned": 50,
      "status": "pending",
      "objective": "Développer la VMA",
      "summary": "6x1000m avec récup 2min"
    }
  ]
}
```

---

#### `GET /api/sessions/week`

Séances de la semaine courante.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `week_id` | string | No | ID semaine spécifique (défaut: courante) |

**Response:**
```json
{
  "week": {
    "number": 8,
    "phase": "Build 1",
    "start_date": "2025-03-10",
    "end_date": "2025-03-16"
  },
  "sessions": [
    {
      "id": "sess_001",
      "day_of_week": 1,
      "date": "2025-03-10",
      "sport": "swim",
      "title": "Natation technique",
      "duration_planned": 60,
      "status": "completed"
    },
    // ... autres séances
  ],
  "stats": {
    "completed": 4,
    "pending": 3,
    "skipped": 1
  }
}
```

---

#### `GET /api/sessions/:id`

Détail complet d'une séance.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "session": {
    "id": "sess_003",
    "sport": "run",
    "session_type": "intervals",
    "title": "Course - Intervalles VMA",
    "scheduled_date": "2025-03-12",
    "status": "pending",

    "objective": "Développer la vitesse maximale aérobie (VMA) et améliorer la capacité à maintenir des efforts intenses.",

    "duration_planned": 50,
    "distance_planned": 8000,

    "hr_zones": {
      "warmup": { "zone": 2, "hr_range": [130, 145] },
      "intervals": { "zone": 5, "hr_range": [175, 185] },
      "recovery": { "zone": 1, "hr_range": [100, 130] },
      "cooldown": { "zone": 1, "hr_range": [100, 130] }
    },

    "workout_details": {
      "warmup": {
        "duration": 15,
        "description": "Footing léger progressif",
        "hr_zone": 2
      },
      "main": [
        {
          "type": "interval_set",
          "reps": 6,
          "work": {
            "distance": 1000,
            "duration": null,
            "pace_target": "3:45-3:55/km",
            "hr_zone": 5,
            "description": "1000m à 95-100% VMA"
          },
          "rest": {
            "duration": 120,
            "type": "jog",
            "description": "Récup trot léger 2min"
          }
        }
      ],
      "cooldown": {
        "duration": 10,
        "description": "Retour calme + étirements",
        "hr_zone": 1
      }
    },

    "tips": [
      "Commence les premiers intervalles de manière contrôlée, tu peux accélérer sur les derniers",
      "Si tu sens que tu ne tiens pas l'allure, réduis à 5 répétitions",
      "Hydrate-toi bien avant la séance"
    ],

    "strava_activity": null,
    "actual_duration": null,
    "actual_distance": null,
    "completed_at": null
  }
}
```

---

#### `PATCH /api/sessions/:id/complete`

Marque une séance comme terminée.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "perceived_effort": 7,
  "notes": "Bonnes sensations, derniers intervalles difficiles",
  "strava_activity_id": "12345678"
}
```

**Response:**
```json
{
  "success": true,
  "session": {
    "id": "sess_003",
    "status": "completed",
    "completed_at": "2025-03-12T18:30:00Z",
    "actual_duration": 52,
    "actual_distance": 8200,
    "actual_avg_hr": 158,
    "strava_activity_id": "12345678"
  },
  "week_stats": {
    "completed": 5,
    "pending": 2,
    "compliance_rate": 71.4
  }
}
```

---

#### `PATCH /api/sessions/:id/skip`

Marque une séance comme passée.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "reason": "fatigue",
  "notes": "Grosse fatigue accumulée, besoin de repos"
}
```

**Response:**
```json
{
  "success": true,
  "session": {
    "id": "sess_003",
    "status": "skipped",
    "skip_reason": "fatigue"
  },
  "adjustment_triggered": true
}
```

---

#### `POST /api/sessions/:id/feedback`

Ajoute un feedback sur une séance.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "perceived_effort": 8,
  "feeling": "hard",
  "notes": "Séance plus difficile que prévu",
  "pain_reported": false
}
```

**Response:**
```json
{
  "success": true
}
```

---

### Strava

#### `POST /api/strava/sync`

Déclenche une synchronisation manuelle.

**Headers:** `Authorization: Bearer <token>`

**Body:**
```json
{
  "since": "2025-03-01"
}
```

**Response:**
```json
{
  "success": true,
  "sync": {
    "activities_fetched": 12,
    "activities_new": 8,
    "activities_updated": 4,
    "sessions_matched": 6
  }
}
```

---

#### `GET /api/strava/activities`

Liste les activités Strava synchronisées.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `sport` | string | No | Filtrer par sport |
| `since` | string | No | Date début (ISO) |
| `until` | string | No | Date fin (ISO) |
| `matched` | boolean | No | Filtrer matchées/non matchées |
| `limit` | number | No | Limite (défaut: 50) |
| `offset` | number | No | Offset pagination |

**Response:**
```json
{
  "activities": [
    {
      "id": "act_001",
      "strava_id": "12345678",
      "sport_type": "Run",
      "name": "Sortie course du matin",
      "start_date": "2025-03-12T07:30:00Z",
      "distance": 8200,
      "moving_time": 2520,
      "average_heartrate": 158,
      "matched_session_id": "sess_003"
    }
  ],
  "pagination": {
    "total": 156,
    "limit": 50,
    "offset": 0,
    "has_more": true
  }
}
```

---

#### `GET /api/strava/stats`

Statistiques globales Strava.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
| Param | Type | Required | Description |
|-------|------|----------|-------------|
| `period` | string | No | `week`, `month`, `year`, `all` (défaut: month) |

**Response:**
```json
{
  "period": "month",
  "stats": {
    "totals": {
      "activities": 24,
      "hours": 32.5,
      "distance_km": 420
    },
    "by_sport": {
      "swim": { "count": 8, "distance_m": 16000, "hours": 8 },
      "bike": { "count": 8, "distance_km": 320, "hours": 14 },
      "run": { "count": 8, "distance_km": 84, "hours": 10.5 }
    },
    "trends": {
      "vs_previous_period": {
        "hours": +12.5,
        "activities": +4
      }
    }
  }
}
```

---

### Webhook

#### `GET /api/webhook/strava`

Validation du webhook Strava (subscription verification).

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `hub.mode` | string | `subscribe` |
| `hub.challenge` | string | Challenge à retourner |
| `hub.verify_token` | string | Token de vérification |

**Response:**
```json
{
  "hub.challenge": "challenge_value"
}
```

---

#### `POST /api/webhook/strava`

Réception des événements Strava.

**Body (Strava):**
```json
{
  "aspect_type": "create",
  "event_time": 1234567890,
  "object_id": 12345678,
  "object_type": "activity",
  "owner_id": 123456,
  "subscription_id": 123456
}
```

**Response:**
```json
{
  "received": true
}
```

---

### Admin

#### `POST /api/admin/auth/login`

Login administrateur.

**Body:**
```json
{
  "email": "admin@triathlon-app.com",
  "password": "..."
}
```

**Response:**
```json
{
  "success": true,
  "admin": {
    "id": "adm_001",
    "email": "admin@triathlon-app.com",
    "name": "Admin",
    "role": "super_admin"
  }
}
```

Sets cookie `admin_session`.

---

#### `GET /api/admin/users`

Liste des utilisateurs.

**Headers:** Cookie `admin_session`

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `search` | string | Recherche nom/email |
| `status` | string | `active`, `inactive` |
| `limit` | number | Limite |
| `offset` | number | Offset |

**Response:**
```json
{
  "users": [
    {
      "id": "usr_001",
      "strava_id": "123456",
      "email": "john@example.com",
      "first_name": "John",
      "last_name": "Doe",
      "onboarding_completed": true,
      "created_at": "2025-01-15T10:00:00Z",
      "active_program": {
        "id": "prog_001",
        "distance_type": "ironman",
        "event_date": "2025-09-14"
      }
    }
  ],
  "pagination": {
    "total": 156,
    "limit": 20,
    "offset": 0
  }
}
```

---

#### `GET /api/admin/templates`

Liste des templates.

**Headers:** Cookie `admin_session`

**Response:**
```json
{
  "templates": [
    {
      "id": "tpl_001",
      "name": "Ironman 24 semaines - Intermédiaire",
      "slug": "ironman-24-weeks-intermediate",
      "distance_type": "ironman",
      "experience_level": "intermediate",
      "duration_weeks": 24,
      "is_active": true,
      "usage_count": 45
    }
  ]
}
```

---

#### `POST /api/admin/templates`

Crée un nouveau template.

**Headers:** Cookie `admin_session`

**Body:**
```json
{
  "name": "Half Ironman 12 semaines - Débutant",
  "distance_type": "70.3",
  "experience_level": "beginner",
  "duration_weeks": 12,
  "weekly_hours_min": 8,
  "weekly_hours_max": 12,
  "description": "...",
  "phases": [...],
  "week_templates": {...}
}
```

**Response:**
```json
{
  "success": true,
  "template": {
    "id": "tpl_new",
    "slug": "half-ironman-12-weeks-beginner"
  }
}
```

---

#### `GET /api/admin/jobs`

Liste des jobs configurés.

**Headers:** Cookie `admin_session`

**Response:**
```json
{
  "jobs": [
    {
      "id": "job_001",
      "name": "Recalcul hebdomadaire",
      "worker_name": "recalc-weekly",
      "cron_expression": "0 6 * * 1",
      "is_active": true,
      "last_run_at": "2025-03-10T06:00:00Z",
      "last_run_status": "success",
      "last_run_duration_ms": 4523,
      "stats": {
        "total_runs": 10,
        "successful_runs": 9,
        "failed_runs": 1
      }
    }
  ]
}
```

---

#### `POST /api/admin/jobs/:id/run`

Exécute un job manuellement.

**Headers:** Cookie `admin_session`

**Response:**
```json
{
  "success": true,
  "execution": {
    "id": "exec_001",
    "status": "queued",
    "queued_at": "2025-03-12T14:30:00Z"
  }
}
```

---

#### `GET /api/admin/audit-logs`

Consultation des logs d'audit.

**Headers:** Cookie `admin_session`

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| `event_type` | string | Filtrer par type |
| `entity_type` | string | Filtrer par entité |
| `actor_type` | string | Filtrer par acteur |
| `since` | string | Date début |
| `until` | string | Date fin |
| `limit` | number | Limite |

**Response:**
```json
{
  "logs": [
    {
      "id": "log_001",
      "timestamp": "2025-03-12T10:30:00Z",
      "event_type": "program.generated",
      "entity_type": "program",
      "entity_id": "prog_001",
      "actor_type": "system",
      "actor_id": null,
      "trigger_worker": "recalc-weekly",
      "worker_status": "completed"
    }
  ],
  "pagination": {
    "total": 1250,
    "limit": 50,
    "offset": 0
  }
}
```

---

## Codes d'erreur

| Code HTTP | Error Code | Description |
|-----------|------------|-------------|
| 400 | `validation_error` | Données invalides |
| 401 | `unauthorized` | Token manquant ou invalide |
| 403 | `forbidden` | Accès non autorisé |
| 404 | `not_found` | Ressource non trouvée |
| 409 | `conflict` | Conflit (ex: programme déjà existant) |
| 429 | `rate_limited` | Trop de requêtes |
| 500 | `internal_error` | Erreur serveur |
| 502 | `strava_error` | Erreur API Strava |

**Format erreur:**
```json
{
  "error": {
    "code": "validation_error",
    "message": "Invalid event_date",
    "details": {
      "field": "event_date",
      "reason": "must_be_future"
    }
  }
}
```

---

## Rate Limiting

| Endpoint | Limite |
|----------|--------|
| Auth | 10 req/min |
| API générale | 100 req/min |
| Webhook | 1000 req/min |
| Admin | 200 req/min |

Headers de réponse :
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1234567890
```
