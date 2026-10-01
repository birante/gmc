# 📚 BookNest

> 🌐 **Production :** https://booknest.okemamy.com · 🐳 **Image Docker :** `birantesy/booknest`

## 1. Titre du projet

**BookNest** — le réseau social des lecteurs pour découvrir, noter et recommander des livres.

## 2. Description du projet

BookNest est un réseau social de lecteurs : on y découvre des livres, on les note et on les recommande aux autres. Il est difficile de trouver de bons livres sans tomber sur des listes de best-sellers génériques. BookNest mise plutôt sur les recommandations de vrais lecteurs que l'on choisit de suivre.

### Fonctionnalités

- **Comptes utilisateurs** : inscription et connexion (mots de passe hachés avec bcrypt, session par JWT), routes protégées.
- **Recherche de livres** par titre, auteur ou genre dans le **catalogue BookNest** (source principale, insensible aux accents), complété par **Open Library** (API publique, sans clé) : les résultats externes s'affichent après ceux du catalogue et peuvent être importés en un clic.
- **Création de livres** : tout lecteur connecté peut ajouter un livre absent du catalogue (titre, auteurs, genres, description, couverture https avec aperçu, ISBN, année, pages) ; les doublons (même titre + auteur) sont détectés et le créateur peut modifier sa fiche.
- **Recommandations** : un formulaire pour recommander un livre avec titre, auteur, description, note sur 5 et avis.
- **Fiche livre** : détails complets et note moyenne, mise à jour en direct quand quelqu'un vote.
- **Interactions** : aimer et commenter les recommandations, suivre d'autres lecteurs.
- **Fil personnalisé** : recommandations des personnes suivies et des genres préférés, classées par pertinence.
- **Interface responsive** (React + CSS), utilisable sur mobile.

### Stack technique

React (Vite) · Node.js / Express · MongoDB (Mongoose) · JWT · Docker · Kamal

## 3. Consignes du projet (GOMYCODE)

Project Setup and Database Configuration

Set up the project directory, install the necessary dependencies, and configure the MongoDB database connection. Create a database schema for storing book recommendations.
User Authentication and Authorization

User Authentication and Authorization
Set up user registration and login functionality, including password hashing and user session management. Create protected routes that require authentication.

Book Search and Recommendation
Integrate external book APIs to provide book search functionality. Implement features that allow users to search for books by title, author, or genre. Provide a form for users to add book recommendations, including details such as title, author, description, and rating.

Book Details and Rating System
Implement a feature that displays detailed information about a selected book, including title, author, description, and average rating. Allow users to rate books and update the average rating dynamically.

User Interaction and Recommendations Feed
Implement features that allow users to interact with other users' recommendations, such as liking, commenting, and following. Create a personalized recommendations feed that displays recommended books based on the user's preferences and interactions.

User Interface and Styling
Enhance the visual appearance of the app through effective UI design and styling. Implement responsive design for optimal viewing on different devices.

Deployment
In this phase, you will deploy the e-commerce website to a production environment and test it thoroughly. You will be responsible for setting up the hosting environment, configuring the server, and ensuring the website runs smoothly.


## 4. Architecture

```
BookRecommendationApp/
├── server/                 # API Express + Mongoose (ES modules)
│   ├── src/
│   │   ├── app.js          # app Express (helmet/CSP, cors, rate-limit, routes, SPA)
│   │   ├── index.js        # connexion MongoDB + listen + seed optionnel
│   │   ├── seed.js         # données de démo (si base vide)
│   │   ├── models/         # User, Book, Recommendation, Comment
│   │   ├── controllers/    # auth, users, books, recommendations, feed
│   │   ├── routes/         # routes /api/* + validation express-validator
│   │   ├── middleware/     # requireAuth / optionalAuth, validation, erreurs JSON
│   │   └── utils/          # client Open Library (fetch natif), normalisation texte/ISBN, sérialisation, config
│   └── tests/              # Vitest + supertest + mongodb-memory-server (fetch mocké)
├── client/                 # React + Vite + React Router, CSS maison responsive
│   └── src/{pages,components,context,api,__tests__}
├── Dockerfile              # multi-stage node:22-alpine
├── config/deploy.yml       # configuration Kamal 2
└── .kamal/secrets          # références aux secrets (aucune valeur en clair)
```

**Modèles**
- `User` : username, email, passwordHash (bcryptjs), bio, favoriteGenres[], following[], followers[].
- `Book` : title, authors[], genres[], description, coverUrl, isbn, publishedDate, pageCount, source (`booknest` \| `openlibrary`), externalId (optionnel, unique, ex. `ol:/works/OL45804W`), addedBy, ratings[{user, value 1-5}], averageRating, ratingsCount.
- `Recommendation` : user, book, review, rating, likes[], createdAt.
- `Comment` : recommendation, user, text.

**Recherche** (`GET /api/books/search`) : l'application fonctionne entièrement avec son propre catalogue (50 livres de démo au premier démarrage).
1. **Catalogue BookNest d'abord** : regex insensible à la casse et aux accents (`senghor`, `etranger`…) ; en mode *titre*, les correspondances dans le titre passent avant celles trouvées dans la description.
2. **Open Library ensuite** (facultatif, `EXTERNAL_BOOK_SEARCH=true` par défaut, `false` pour couper) : `search.json?title=|author=|subject=`, User-Agent `BookNest/1.0`, délai max 5 s. Les résultats sont dédupliqués (par `externalId` puis titre + auteur normalisés) et ajoutés après les résultats locaux. Chaque résultat porte un champ `source` (`booknest` ou `openlibrary`) ; la réponse indique `externalAvailable` : en cas d'échec (réseau, 429…), seuls les résultats locaux sont renvoyés, sans erreur.
3. Un résultat Open Library n'a pas d'`id` local : `POST /api/books` avec son `externalId` l'importe (idempotent). Si seul l'`externalId` est fourni, l'œuvre et ses auteurs sont récupérés sur Open Library (400 si injoignable).

**Création de livres** (`/livres/nouveau`, lien dans la navigation, la bibliothèque et la recherche sans résultat) : formulaire complet, validation côté client et serveur (titre requis, URL de couverture https, ISBN-10/13 avec clé de contrôle, année, pages). Doublon (même titre + auteur, accents ignorés) → `200` avec le livre existant ; sinon `201` et redirection vers la fiche. Le créateur (`addedBy`) peut modifier sa fiche (`PUT /api/books/:id`, bouton « Modifier ») ; sans couverture, une couverture est générée.

**Notes** : un vote par utilisateur et par livre, modifiable ; la moyenne est recalculée à chaque vote (la note d'une recommandation compte comme vote). La fiche livre se rafraîchit toutes les 15 s pour refléter les votes des autres lecteurs.

**Fil personnalisé** (`GET /api/feed`) : les recommandations récentes des autres lecteurs sont classées par un score = récence (10 pts, demi-vie 3 jours) + likes (2 pts/like) + commentaires (0,5 pt) + personne suivie (+8) + genre favori (+5) + livre bien noté (+1). Chaque élément indique la raison (`following`, `genre`, `popular`, `discover`).

## 5. Lancer en local

Prérequis : Node 22, MongoDB local (ou `docker run -d -p 27017:27017 mongo:7`).

```bash
cp .env.example .env          # facultatif : valeurs par défaut utilisables en dev
npm install                   # installe racine + server + client
SEED_ON_START=true npm run dev  # API sur :3000, client Vite sur :5173 (proxy /api)
```

Ou remplir la base manuellement : `npm run seed`.

**Comptes de démo** (seed) — mot de passe `password123` :
`amina@booknest.app`, `lucas@booknest.app`, `sofia@booknest.app`.

Production locale : `npm run build && NODE_ENV=production JWT_SECRET=xxx npm start` (l'API sert `client/dist`).

## 6. Tests

```bash
npm test            # tests serveur puis client
npm --prefix server test   # 34 tests d'intégration (auth, recherche locale + Open Library mockée, import, création/modification de livres, notes, recommandations, likes, commentaires, follow, profil, fil, seed, 400/401/403/404/409)
npm --prefix client test   # 16 tests de composants (StarRating, BookCover, RecommendationCard, LoginPage, SearchPage, BookFormPage)
```

Les tests serveur utilisent `mongodb-memory-server` ; `fetch` est systématiquement mocké (aucun appel réseau réel à Open Library).

## 7. Déploiement (Kamal)

```bash
# Secrets communs aux 5 apps, stockés hors du dépôt (lus par .kamal/secrets) :
#   ~/.config/okemamy/registry_token   token Docker Hub (birantesy)
#   ~/.config/okemamy/jwt_secret       secret JWT partagé
kamal setup        # première fois : proxy, accessoire mongo, app
kamal deploy       # déploiements suivants
```

- Image `birantesy/booknest` (build amd64), service sur `https://booknest.okemamy.com` (SSL via kamal-proxy).
- Healthcheck : `GET /up` (200 `OK`, 503 si MongoDB non connecté).
- MongoDB 7 en accessoire `booknest-mongo`, non exposé publiquement (réseau docker `kamal`), données dans `data:/data/db`.
- `SEED_ON_START=true` : les données de démo ne sont insérées que si la base est vide.
- Aucune clé d'API externe n'est nécessaire. Pour couper la recherche Open Library : `EXTERNAL_BOOK_SEARCH: "false"` dans `env.clear`.


> **Registry** : si `~/.config/okemamy/registry_token` existe, Kamal pousse l'image sur Docker Hub (`birantesy/<app>`) ; sinon il utilise son registry local (`localhost:5555`, tunnel SSH vers le serveur, aucun identifiant). Kamal ≥ 2.8 requis (testé avec 2.12). Le build React se fait en natif (`--platform=$BUILDPLATFORM`) car esbuild plante sous émulation amd64.

## 8. API

| Méthode | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/up` | – | Healthcheck (200 OK / 503) |
| POST | `/api/auth/register` | – | Inscription `{username, email, password, favoriteGenres?}` → `{token, user}` |
| POST | `/api/auth/login` | – | Connexion `{email, password}` → `{token, user}` |
| GET | `/api/auth/me` | ✔ | Utilisateur courant |
| GET | `/api/books/search?q=&type=title\|author\|genre` | – | Catalogue BookNest puis Open Library (dédupliqué) → `{results[{source…}], localCount, externalCount, externalAvailable}` |
| GET | `/api/books?q=&genre=&sort=popular\|rating\|recent` | – | Livres de la bibliothèque locale |
| GET | `/api/books/genres` | – | Genres présents |
| POST | `/api/books` | ✔ | Crée un livre `{title, authors, genres, description, coverUrl, isbn, publishedDate, pageCount}` ou importe `{externalId, …}` → 201, ou 200 + livre existant si doublon |
| PUT | `/api/books/:id` | ✔ créateur | Modifie la fiche (403 pour les autres, 409 si doublon) |
| GET | `/api/books/:id` | – | Fiche livre + recommandations |
| POST | `/api/books/:id/rate` | ✔ | Note `{value: 1-5}` (un vote par utilisateur, modifiable) |
| GET | `/api/recommendations?user=&book=&page=` | – | Liste des recommandations |
| POST | `/api/recommendations` | ✔ | Crée `{bookId \| book:{externalId \| title, authors, description, genres…}, rating, review}` |
| GET | `/api/recommendations/:id` | – | Détail + commentaires |
| PATCH | `/api/recommendations/:id` | ✔ auteur | Modifie avis/note (403 sinon) |
| DELETE | `/api/recommendations/:id` | ✔ auteur | Supprime (403 sinon) |
| POST / DELETE | `/api/recommendations/:id/like` | ✔ | Aimer / ne plus aimer |
| GET | `/api/recommendations/:id/comments` | – | Commentaires |
| POST | `/api/recommendations/:id/comments` | ✔ | Ajoute un commentaire `{text}` |
| DELETE | `/api/comments/:id` | ✔ auteur | Supprime (auteur du commentaire ou de la recommandation) |
| GET | `/api/feed?page=` | ✔ | Fil personnalisé trié par score |
| GET | `/api/users?q=` | – | Lecteurs |
| GET | `/api/users/:username` | – | Profil + recommandations |
| PATCH | `/api/users/me` | ✔ | Modifie bio / genres favoris |
| POST / DELETE | `/api/users/:id/follow` | ✔ | Suivre / ne plus suivre |

Erreurs : JSON `{ "error": "..." }` (400 validation, 401 non authentifié, 403 interdit, 404 introuvable, 409 doublon).
