# Ikigabo - Gestion de Patrimoine Personnel

Application mobile de gestion de patrimoine personnel complète et professionnelle, 100% offline.

## Fonctionnalités Principales

### Dashboard Complet

- Vue d'ensemble du patrimoine total (actifs et passifs)
- Graphiques animés de l'activité hebdomadaire
- Liste des transactions récentes
- Statistiques des entrées/sorties

### Gestion des Sources d'Argent

- Argent en poche
- Comptes bancaires multiples
- Caisses personnelles
- Biens convertibles (bétail, récoltes, etc.)
- Dettes données et reçues
- Sources personnalisées illimitées

### Gestion Avancée des Banques

- Banques gratuites ou payantes
- Calcul automatique des frais
- Frais mensuels ou annuels
- Montant fixe ou pourcentage
- Déduction automatique programmée

### Transactions Complètes

- **Entrées**: Salaire, Vente, Don, Dette reçue, etc.
- **Sorties**: Achats, Retraits, Dons, Dettes données, etc.
- Catégories personnalisables
- Historique complet avec recherche

### Gestion des Biens & Actifs

- Bétail (chèvres, porcs, etc.)
- Récoltes agricoles
- Terrains
- Véhicules
- Équipements
- Bijoux

### Gestion des Dettes

- Dettes données (créances)
- Dettes reçues (passifs)
- Suivi des paiements partiels
- Calcul automatique des montants restants

### Sécurité Renforcée

- Code PIN obligatoire au démarrage
- Support biométrique (empreinte)
- Mot de passe optionnel
- Verrouillage automatique

### Multilingue

- Kirundi (pur)
- Français
- English
- Kiswahili

### UI/UX Professionnelle

- Dark mode magnifique
- Animations fluides
- Transitions professionnelles
- Responsive 100%

## Technologies Utilisées

- **Flutter** - Framework UI
- **Isar Database** - Base de données offline
- **Riverpod** - State Management
- **fl_chart** - Graphiques
- **flutter_animate** - Animations

## Installation

### Prérequis

- Flutter SDK (≥ 3.10.0)
- Dart SDK (≥ 3.10.0)

### Étapes

1. **Installer les dépendances**

```bash
flutter pub get
```

2. **Générer les fichiers Isar**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

3. **Lancer l'application**

```bash
flutter run
```

## Structure du Projet

```
lib/
├── core/           # Constantes, thèmes, utils
├── data/           # Modèles, services
├── domain/         # Entités, repositories
├── presentation/   # Screens, widgets, providers
└── l10n/          # Traductions
```

## Captures d'écran

L'application utilise un design moderne dark mode avec :

- Dashboard avec graphiques
- Écran PIN sécurisé
- Navigation fluide
- Animations professionnelles

## Support & Contact

**Développeur**: Niyondiko Joffre  
**Email**: niyondikojoffreasjubu@gmail.com  
**Téléphone**: +257 68 49 73 72 | +257 61 89 59 40  

**Offrir un café**: Contactez-nous aux numéros ci-dessus pour soutenir le développement de l'application.

---

**Développé avec passion pour la gestion de patrimoine personnel au Burundi**
