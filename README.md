# AnnuaireCIP

Application macOS/iOS pour les professionnels de l'insertion professionnelle (CIP) du territoire marseillais.

Développée par **Olivier Bonaldo** dans le cadre d'un stage de formation CIP (Conseiller en Insertion Professionnelle) à Marseille.

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

## Statut

Projet en développement actif — version initiale testée en structure d'insertion (APCARS, Marseille) prévue juin 2026.
