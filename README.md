# AnnuaireCIP

Application macOS/iOS pour les professionnels de l'insertion professionnelle (CIP) du territoire marseillais.

Développée par **Olivier Bonaldo** dans le cadre d'une formation CIP (Conseiller en Insertion Professionnelle) à Marseille.

## Objectif

Permettre aux CIP et travailleurs sociaux d'accéder rapidement à l'annuaire des structures et services d'insertion du département des Bouches-du-Rhône (13), avec :

- Recherche par nom, adresse, thématique ou public cible
- Visualisation cartographique des structures et services
- Navigation rapide entre structures et leurs services associés

## Stack technique

- Swift / SwiftUI (macOS + iOS)
- MapKit
- Données : référentiel data·inclusion (structures et services d'insertion)

## Données

L'application s'appuie sur le référentiel open data de l'offre d'insertion sociale et professionnelle fourni par [data·inclusion](https://data.inclusion.gouv.fr), Plateforme de l'inclusion.

L'objectif est d'intégrer l'API data·inclusion pour disposer de données en temps réel, filtrées sur le département 13.

## Contexte d'usage

- Utilisateurs cibles : CIP, travailleurs sociaux, conseillers France Travail
- Territoire : Marseille / Bouches-du-Rhône
- Usage : non commercial, outil d'aide à la prescription en entretien

## Architecture

```
AnnuaireCIP/
├── Models/
│   ├── DIStructure.swift       # Structure d'insertion (Codable, CLLocationCoordinate2D)
│   └── DIService.swift         # Service d'insertion (Codable, CLLocationCoordinate2D)
├── Services/
│   ├── NetworkService.swift    # Client async/await — API data·inclusion (pagination auto)
│   └── MockDataService.swift   # Chargement depuis les JSON bundle (mode hors-ligne)
├── ViewModels/
│   └── AnnuaireViewModel.swift # @Observable — orchestre le chargement des données
├── Views/
│   ├── StructureDetailView.swift  # Détail d'une structure (coordonnées, horaires, SIRET…)
│   ├── ServiceDetailView.swift    # Détail d'un service (publics, frais, mobilisation…)
│   └── StructuresMapView.swift    # Carte fusionnée structures + services (MapKit)
├── ContentView.swift           # TabView : Structures | Services | Carte
└── Resources/
    ├── structures-marseille-dev.json
    └── services-marseille-dev.json
```

## Avancement

### Modèles
- [x] `DIStructure` — 20 champs mappés depuis l'API data·inclusion (`adresse_certifiee`, `score_qualite`, `doublons` inclus)
- [x] `DIService` — 28 champs mappés (thématiques, publics, frais, modes de mobilisation…)

### Services réseau
- [x] `NetworkService` — appels async/await avec pagination automatique (endpoint `/structures` et `/services`, filtre `code_departement=13`)
- [x] `MockDataService` — chargement des données réelles depuis le bundle JSON pour le développement hors-API

### Interface
- [x] Liste des structures avec barre de recherche (nom, commune, description)
- [x] Liste des services avec barre de recherche (nom, type, thématique, commune)
- [x] Vue détail structure — sections coordonnées, description, horaires, identification, accessibilité, réseaux
- [x] Vue détail service — sections description, catégorie, publics, frais, accueil, contact, mobilisation
- [x] Carte MapKit fusionnée — Picker segmenté Structures / Services, annotations colorées, callout avec lien vers le détail

### En cours / À venir
- [ ] Accès à l'API data·inclusion staging (token en attente)
- [ ] Filtres avancés (thématique, public, commune)
- [ ] Lien structure → liste de ses services
- [ ] Localisation de l'utilisateur sur la carte

## Statut

Projet en développement actif — l'application est testée en conditions réelles durant la durée de la formation CIP.

> Mode actuel : **données mock** (JSON bundle). Basculer vers l'API réelle en remplaçant `MockDataService` par `NetworkService` dans `AnnuaireViewModel`.
