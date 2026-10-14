# 🎬 Watchlist — Votre Cinémathèque Personnelle

Une application mobile moderne, fluide et élégante conçue avec Flutter pour suivre, organiser et découvrir vos films préférés, alimentée par l'API TMDB.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Android](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://android.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![TMDB API](https://img.shields.io/badge/API-TMDB_v3-01b4e4)](https://www.themoviedb.org)

---

## 📲 Téléchargement & Installation de l'APK

Vous souhaitez installer l'application sur votre smartphone Android ? C'est direct et 100% gratuit !

### 👉 [**Cliquez ici pour télécharger la dernière version (.APK)**](https://github.com/Ibanm/Watchlist/releases/latest)

#### 📝 Guide d'installation rapide (Android) :
1. **Téléchargez** le fichier `app-release.apk` depuis la page des **[Releases](https://github.com/Ibanm/Watchlist/releases/latest)**.
2. **Ouvrez le fichier téléchargé** sur votre téléphone.
3. Si Android affiche une alerte de sécurité :
   - Cliquez sur **Paramètres**.
   - Activez l'option **"Autoriser cette source"** (ou *Installer des applications inconnues*).
4. Cliquez sur **Installer** puis sur **Ouvrir**.
5. C'est prêt ! Profitez de votre cinémathèque ! 🎉

---

## ✨ Fonctionnalités Principales

- 🎬 **Clap de Cinéma Interactif** : En-tête animé stylisé rappelant les plateaux de tournage.
- 🔍 **Recherche TMDB en Temps Réel** : Explorez des millions de films avec affiches HD, résumés, genres, durées réelles et castings.
- 📋 **Organisation Intuitive** :
  - 🍿 *À voir absolument* (Watchlist)
  - ✅ *Films vus* (Historique & avis)
  - 🗑️ *Gestion facile & suppression*
- 🎨 **Design Sombre Premium** : Interface épurée conçue pour le confort visuel avec badges modernes et affiches fluides.
- 💾 **100% Hors-Ligne & Local** : Vos données restent stockées sur votre appareil en toute sécurité.
- 🔐 **Respect de la Vie Privée & BYOK (Bring Your Own Key)** :
  - Aucune collecte de données personnelles ni publicité.
  - Clé TMDB personnalisable et masquée dans les Paramètres.

---

## 🛠️ Pour les Développeurs (Contribuer / Compiler)

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x ou supérieur)
- Android Studio ou VS Code avec extension Flutter
- Une clé API gratuite [The Movie Database (TMDB)](https://www.themoviedb.org)

### Installation locale

1. **Cloner le projet :**
   ```bash
   git clone https://github.com/Ibanm/Watchlist.git
   cd Watchlist
   ```

2. **Installer les dépendances :**
   ```bash
   flutter pub get
   ```

3. **Lancer l'application :**
   - Avec votre clé TMDB injectée au lancement :
     ```bash
     flutter run --dart-define=TMDB_API_KEY=votre_cle_tmdb_ici
     ```
   - Ou sans clé (vous pourrez la saisir directement dans l'écran *Paramètres* de l'app) :
     ```bash
     flutter run
     ```

### Génération de l'APK Release

Pour compiler un APK autonome prêt pour votre téléphone :
```bash
flutter build apk --release --dart-define=TMDB_API_KEY=votre_cle_tmdb_ici
```
Le fichier généré sera disponible dans `build/app/outputs/flutter-apk/app-release.apk`.

---

## ⚖️ Mentions Légales & Attribution TMDB

<p align="left">
  <img src="https://www.themoviedb.org/assets/2/v4/logos/v2/blue_short-8e7b30f73a4020692ccca4c88bafe5dcb6f8a62a4c6bc55cd9ba82bb2cd95f6c.svg" width="130" alt="TMDB Logo"/>
</p>

> *Ce produit utilise l'API TMDB mais n'est ni certifié ni approuvé par The Movie Database (TMDB).*
>
> *This product uses the TMDB API but is not endorsed or certified by TMDB.*

---

## 📄 Licence
Ce projet est distribué sous licence [MIT](LICENSE). Libre d'utilisation pour des projets personnels ou éducatifs.
