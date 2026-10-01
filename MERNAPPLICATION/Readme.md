# 🎟️ EventHub

> 🌐 **Production :** https://eventhub.okemamy.com · 🐳 **Image Docker :** `birantesy/eventhub`

## 1. Titre du projet

**EventHub** — créer, publier et rejoindre des événements en quelques clics.

## 2. Description du projet

EventHub est une plateforme pour créer des événements et s'y inscrire (meetups, ateliers, conférences, soirées associatives). Les organisateurs gèrent souvent leurs inscriptions par WhatsApp ou sur des tableurs. EventHub centralise la publication, les inscriptions et le suivi des places.

### Fonctionnalités

- **Authentification et sessions** : inscription, connexion, déconnexion, profil.
- **CRUD complet des événements** : titre, description, date, lieu, catégorie, nombre de places, image.
- **Inscription / désinscription** à un événement, avec le nombre de places restantes en direct.
- **Tableau de bord** : « mes événements créés » et « mes inscriptions ».
- **Recherche et filtres** par catégorie, par date (à venir ou passés) et par mot-clé.
- **Autorisations** : seul l'organisateur peut modifier ou supprimer son événement.
- **Interface React** avec navigation claire et responsive.

### Stack technique

MongoDB · Express · React (Vite) · Node.js (MERN) · JWT · Docker · Kamal

## 3. Consignes du projet (GOMYCODE)

Create the Front-end of the APP
Create visually appealing UI components using React.js and CSS, ensuring proper navigation and interaction.

2


Back-end Development:
Create routes, controllers, and models to handle CRUD operations, user authentication, and session management.

3


Deployment:
Set up deployment configurations, manage environment variables, and host the application on a cloud platform.

## 4. Architecture

```
MERNAPPLICATION/
├── server/                     # API Express + Mongoose (ES modules)
│   ├── src/
│   │   ├── app.js              # application Express (helmet, cors, rate-limit, routes, SPA)
│   │   ├── index.js            # connexion MongoDB (avec retry), seed auto, listen
│   │   ├── seed.js             # données de démo (2 utilisateurs, 8 événements)
│   │   ├── models/             # User, Event (virtuals seatsLeft, attendeesCount, isPast)
│   │   ├── controllers/        # authController, eventController
│   │   ├── routes/             # /api/auth, /api/events, /api/me
│   │   ├── middleware/         # requireAuth / optionalAuth (JWT), validate, errorHandler
│   │   └── utils/              # config, token, HttpError
│   └── tests/                  # Vitest + supertest + mongodb-memory-server
├── client/                     # React 18 + Vite + React Router
│   └── src/
│       ├── api/client.js       # fetch + jeton Bearer + déconnexion auto sur 401
│       ├── context/            # AuthContext (session, expiration JWT), ToastContext
│       ├── components/         # Navbar, EventCard, SeatsBadge, SeatsMeter, Pagination…
│       ├── pages/              # Événements, Détail, Formulaire, Tableau de bord, Profil, Auth
│       └── __tests__/          # Vitest + Testing Library
├── Dockerfile                  # multi-stage (build client → image Node 22 alpine)
├── config/deploy.yml           # configuration Kamal 2
└── .kamal/secrets              # références aux secrets (aucune valeur en clair)
```

**Points clés**

- **Sessions** : JWT (`JWT_EXPIRES_IN`, 7 jours par défaut) stocké dans `localStorage`. Au rechargement, `GET /api/auth/me` restaure la session. Le client planifie une déconnexion à l'expiration du jeton et toute réponse `401` déconnecte automatiquement l'utilisateur.
- **Inscriptions atomiques** : `findOneAndUpdate` avec la condition `$size(attendees) < capacity` et `attendees != user` ; il n'y a donc jamais de surréservation, même en cas d'inscriptions concurrentes (testé). L'API renvoie `409` si l'événement est complet, passé, si l'utilisateur est déjà inscrit ou s'il en est l'organisateur.
- **Places en direct** : chaque réponse contient `seatsLeft` ; la page de détail se rafraîchit toutes les 10 s.
- **Autorisations** : seul l'organisateur peut faire `PUT`/`DELETE` (`403` sinon) et voir la liste des participants.
- **Production** : Express sert `client/dist` avec un fallback SPA ; `GET /up` sert de healthcheck pour kamal-proxy (`503` tant que MongoDB n'est pas connecté). La CSP helmet autorise `img-src https: data:`.

## 5. Lancer en local

Prérequis : Node.js 22 et MongoDB (local ou `docker run -d -p 27017:27017 mongo:7`).

```bash
cp .env.example server/.env        # facultatif : valeurs par défaut utilisées sinon
npm run install:all                # installe racine + server + client
SEED_ON_START=true npm run dev     # API sur :3000, client Vite sur http://localhost:5173
```

Pour réinitialiser les données de démo : `npm run seed`.

**Comptes de démo** (seed) : `aminata@eventhub.dev` et `moussa@eventhub.dev`, mot de passe `password123`.

| Variable        | Défaut                                  | Rôle                                      |
|-----------------|-----------------------------------------|-------------------------------------------|
| `PORT`          | `3000`                                  | port HTTP                                 |
| `MONGODB_URI`   | `mongodb://localhost:27017/eventhub`    | base MongoDB                              |
| `JWT_SECRET`    | `dev-secret-change-me` (obligatoire en prod) | signature des jetons                 |
| `JWT_EXPIRES_IN`| `7d`                                    | durée de validité de la session           |
| `SEED_ON_START` | `false`                                 | `true` : données de démo si la base est vide |

Build de production local : `npm run build && NODE_ENV=production JWT_SECRET=secret npm start` puis http://localhost:3000.

## 6. Tests

```bash
npm test            # tests serveur puis client
npm --prefix server test
npm --prefix client test
```

- **Serveur** (31 tests, MongoDB en mémoire) : inscription/connexion, `/api/auth/me` (jeton absent, invalide, expiré), mise à jour du profil et du mot de passe, CRUD des événements, validation, `401/403/404`, recherche/filtres/pagination, inscriptions (doublon, complet, concurrence, événement passé, organisateur), tableau de bord, seed, CSP.
- **Client** (11 tests) : `SeatsBadge`, `EventCard`, `Navbar` (visiteur / connecté), `LoginPage` (succès et erreur), client API (jeton Bearer, déconnexion auto sur 401).

## 7. Déploiement (Kamal)

L'application est déployée sur `https://eventhub.okemamy.com` avec [Kamal 2](https://kamal-deploy.org) : l'image `birantesy/eventhub` (build `amd64`) tourne derrière kamal-proxy (SSL Let's Encrypt), et MongoDB 7 est un *accessory* privé, joignable uniquement sur le réseau Docker `kamal` sous le nom `eventhub-mongo`.

```bash
# Secrets communs aux 5 apps, stockés hors du dépôt (lus par .kamal/secrets) :
#   ~/.config/okemamy/registry_token   token Docker Hub (birantesy)
#   ~/.config/okemamy/jwt_secret       secret JWT partagé

kamal setup                 # premier déploiement (proxy + accessory mongo + app)
kamal deploy                # déploiements suivants
kamal app logs -f           # journaux
kamal accessory boot mongo  # (re)démarrer MongoDB si besoin
```

Les secrets ne sont jamais versionnés : `.kamal/secrets` ne contient que des références aux variables d'environnement. Le seed de démo est activé (`SEED_ON_START=true`) et ne s'exécute que si la base est vide.

Test de l'image en local :

```bash
docker network create eventhub-net
docker run -d --name eventhub-mongo-test --network eventhub-net mongo:7
docker build -t eventhub:test .
docker run -d --name eventhub-app-test --network eventhub-net -p 4103:3000 \
  -e NODE_ENV=production -e JWT_SECRET=test -e SEED_ON_START=true \
  -e MONGODB_URI=mongodb://eventhub-mongo-test:27017/eventhub eventhub:test
curl http://localhost:4103/up   # OK
```


> **Registry** : si `~/.config/okemamy/registry_token` existe, Kamal pousse l'image sur Docker Hub (`birantesy/<app>`) ; sinon il utilise son registry local (`localhost:5555`, tunnel SSH vers le serveur, aucun identifiant). Kamal ≥ 2.8 requis (testé avec 2.12). Le build React se fait en natif (`--platform=$BUILDPLATFORM`) car esbuild plante sous émulation amd64.

## 8. API

Toutes les réponses sont en JSON ; les erreurs ont la forme `{ "error": "message" }`. Les routes 🔒 exigent l'en-tête `Authorization: Bearer <token>`.

| Méthode | Route | Auth | Description |
|---|---|---|---|
| GET | `/up` | — | Healthcheck (`200 OK`, `503` si MongoDB indisponible) |
| POST | `/api/auth/register` | — | Inscription `{name, email, password}` → `{token, user}` |
| POST | `/api/auth/login` | — | Connexion `{email, password}` → `{token, user}` |
| POST | `/api/auth/logout` | — | Déconnexion (sans état, le client supprime le jeton) → `204` |
| GET | `/api/auth/me` | 🔒 | Profil courant (restauration de session) |
| PUT | `/api/auth/me` | 🔒 | Modifier `name`, `email`, `bio`, ou le mot de passe (`currentPassword`, `newPassword`) |
| GET | `/api/events` | optionnelle | Liste paginée : `?search=&category=&when=upcoming\|past&page=&limit=` → `{events, page, total, totalPages}` |
| GET | `/api/events/categories` | — | Catégories disponibles |
| GET | `/api/events/:id` | optionnelle | Détail (avec `participants` pour l'organisateur) |
| POST | `/api/events` | 🔒 | Créer `{title, description, date, location, category, capacity, imageUrl}` |
| PUT | `/api/events/:id` | 🔒 organisateur | Modifier (`403` sinon ; capacité ≥ nombre d'inscrits) |
| DELETE | `/api/events/:id` | 🔒 organisateur | Supprimer (`403` sinon) → `204` |
| POST | `/api/events/:id/register` | 🔒 | S'inscrire (`409` si complet, passé, déjà inscrit ou organisateur) |
| DELETE | `/api/events/:id/register` | 🔒 | Se désinscrire (`409` si non inscrit) |
| GET | `/api/me/events` | 🔒 | Mes événements créés |
| GET | `/api/me/registrations` | 🔒 | Mes inscriptions |

Chaque événement renvoyé contient `seatsLeft`, `attendeesCount`, `isPast`, `isRegistered`, `isOrganizer` et `organizer {name, bio}`.
