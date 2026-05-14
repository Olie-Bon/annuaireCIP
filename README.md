# AnnuaireCIP

Application macOS/iOS pour les professionnels de l'insertion professionnelle (CIP) du territoire marseillais.

Développée par **Olivier Bonaldo** dans le cadre d'une formation CIP (Conseiller en Insertion Professionnelle) à Marseille.

## Objectif

Permettre aux CIP et travailleurs sociaux d'accéder rapidement à l'annuaire des structures et services d'insertion du département des Bouches-du-Rhône (13), avec :

- Recherche par nom, adresse, thématique ou public cible
- Visualisation cartographique des structures et services
- Navigation rapide entre structures et leurs services associés
- Consultation des freins à l'emploi avec signaux de repérage, ressources terrain et notes CIP
- Recherche de services data·inclusion filtrés par frein

## Stack technique

- Swift / SwiftUI (macOS + iOS)
- MapKit
- Données : référentiel data·inclusion (structures et services d'insertion)

## Données

L'application s'appuie sur le référentiel open data de l'offre d'insertion sociale et professionnelle fourni par [data·inclusion](https://data.inclusion.gouv.fr), Plateforme de l'inclusion.

L'application interroge l'API data·inclusion (`api.data.inclusion.beta.gouv.fr`) pour disposer de données en temps réel, avec recherche géolocalisée et filtres par thématique et public cible.

## Contexte d'usage

- Utilisateurs cibles : CIP, travailleurs sociaux, conseillers France Travail
- Territoire : Marseille / Bouches-du-Rhône
- Usage : non commercial, outil d'aide à la prescription en entretien

## Architecture

```
AnnuaireCIP/
├── Models/
│   ├── DIStructure.swift       # Structure d'insertion (Codable, CLLocationCoordinate2D)
│   ├── DIService.swift         # Service d'insertion (Codable, CLLocationCoordinate2D)
│   ├── DIReferentiel.swift     # Item de référentiel (value, label, description?)
│   └── Frein.swift             # Frein à l'emploi + RessourceTerrain (corpus CIP)
├── Services/
│   ├── NetworkService.swift    # Client async/await — API data·inclusion (pagination auto + référentiels)
│   ├── MockDataService.swift   # Chargement depuis les JSON bundle (mode hors-ligne)
│   └── FreinsService.swift     # Chargement de freins.json depuis le bundle
├── ViewModels/
│   └── AnnuaireViewModel.swift # @Observable — chargement données + état des filtres actifs
├── Views/
│   ├── FiltresView.swift          # Sidebar inspector filtres (thématiques, publics, modes, frais, sources)
│   ├── StructureDetailView.swift  # Détail d'une structure (coordonnées, horaires, SIRET…)
│   ├── ServiceDetailView.swift    # Détail d'un service (publics, frais, mobilisation…)
│   ├── StructuresMapView.swift    # Carte fusionnée structures + services (MapKit)
│   └── FreinsView.swift           # Liste des freins + détail (signaux, ressources, notes CIP, services DI)
├── ContentView.swift           # TabView : Structures | Services | Carte | Parcours
└── Resources/
    ├── structures-marseille-dev.json
    ├── services-marseille-dev.json
    └── freins.json             # 23 freins à l'emploi (corpus CIP Marseille)
```

## Scripts

### `scripts/update-mock-data.sh`

Met à jour les fichiers JSON de développement (`structures-marseille-dev.json`, `services-marseille-dev.json`) depuis l'API data·inclusion production.

```bash
export DI_API_TOKEN=<token>
bash scripts/update-mock-data.sh
```

Requiert la variable d'environnement `DI_API_TOKEN` (le même token que dans le schéma Xcode). Récupère 50 structures et 50 services du département 13.

### `scripts/convert_freins.py`

Convertit les fiches freins au format Org-mode (`.md`) du corpus CIP en `freins.json` pour le bundle de l'application.

```bash
python3 scripts/convert_freins.py
```

Attend les fichiers `frein-*.md` dans `/Users/olie/Documents/Corpus/`. Extrait automatiquement : titre, description, signaux de repérage, freins associés, ressources terrain, notes CIP. Les champs `thematiques_api` et `publics_api` (slugs data·inclusion) sont à renseigner manuellement dans le JSON généré.

## Avancement

### Modèles
- [x] `DIStructure` — 20 champs mappés depuis l'API data·inclusion (`adresse_certifiee`, `score_qualite`, `doublons` inclus)
- [x] `DIService` — 28 champs mappés (thématiques, publics, frais, modes de mobilisation…)

### Services réseau
- [x] `NetworkService` — appels async/await avec pagination automatique (`/structures`, `/services`, `/search/services`). Chargement parallèle des 5 référentiels data·inclusion (`/api/v1/doc/thematiques`, `/publics`, `/modes-accueil`, `/types`, `/frais`). Token via `DI_API_TOKEN`.
- [x] `MockDataService` — chargement des données réelles depuis le bundle JSON pour le développement hors-API

### Interface
- [x] Liste des structures avec barre de recherche (nom, commune, description)
- [x] Liste des services avec barre de recherche (nom, type, thématique, commune)
- [x] Vue détail structure — sections coordonnées, description, horaires, identification, accessibilité, réseaux
- [x] Vue détail service — sections description, catégorie, publics, frais, accueil, contact, mobilisation
- [x] Carte MapKit fusionnée — Picker segmenté Structures / Services, annotations colorées, callout avec lien vers le détail
- [x] **Filtres avancés** — sidebar inspector (macOS) / sheet (iOS), filtres en temps réel :
  - Services : 16 catégories thématiques, publics cibles, modes d'accueil, types de service, frais
  - Structures : filtre par source de données
  - Fallback automatique sur les valeurs présentes dans les données si l'API référentiel est indisponible
- [x] **Score qualité** — indicateur 4 barres style signal réseau (rouge → orange → jaune → vert) + pourcentage en caption, affiché à côté de la date de mise à jour dans les vues détail
- [x] **Liens cliquables** dans les vues détail — téléphone (`tel:`), email (`mailto:`), site web et liens source (`https://`) s'ouvrent dans l'application système appropriée
- [x] **Tri par score qualité** — `filteredStructures()` et `filteredServices()` retournent les résultats triés par `score_qualite` décroissant ; les fiches sans score apparaissent en bas de liste
- [x] **Services associés** — section en bas de chaque fiche structure listant les services liés, avec icône orange et navigation vers le détail du service
- [x] **Localisation utilisateur sur la carte** — point bleu temps réel via `UserAnnotation()`, bouton de centrage `MapUserLocationButton`

### Onglet Parcours — Freins à l'emploi
- [x] **23 freins** issus du corpus CIP Marseille (fichiers `.md` Org-mode convertis via `convert_freins.py`)
- [x] **Fiche frein** — description, signaux de repérage, freins associés, ressources terrain (nom, description, contact, site), notes CIP
- [x] **Recherche de services data·inclusion** — bouton "Voir les services data·inclusion" dans chaque fiche, filtre par `thematiques_api` et `code_commune` (13055), résultats navigables inline
- [x] **`SearchServiceResult`** — décodage du format `{service, distance?}` de `/api/v1/search/services`, paramètres étendus (`score_qualite_minimum`, `exclure_doublons`, `types`, `modes_accueil`, `frais`, `code_commune`)

### À venir

## Statut

Projet en développement actif — l'application est testée en conditions réelles durant la durée de la formation CIP.

> Mode actuel : **API data·inclusion production**. Requiert la variable d'environnement `DI_API_TOKEN` dans le schéma Xcode (Product > Scheme > Edit Scheme > Run > Environment Variables).
