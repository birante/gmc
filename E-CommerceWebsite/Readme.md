# 🛍️ Boutik

> 🌐 **Production :** https://boutik.okemamy.com · 🐳 **Image Docker :** `birantesy/boutik`

## 1. Titre du projet

**Boutik** — une boutique en ligne simple et complète pour les petits commerçants.

## 2. Description du projet

Boutik est une boutique en ligne complète. Les petits commerçants ont souvent besoin d'une vitrine simple pour vendre en ligne sans passer par des plateformes coûteuses. Boutik offre un catalogue, un panier, des commandes et un espace d'administration.

### Fonctionnalités

- **Catalogue** : liste des produits avec recherche, filtres par catégorie et prix, tri, et une page détail par produit.
- **Panier** persistant (ajouter, retirer, changer les quantités, calcul du total).
- **Authentification** : inscription et connexion par JWT, avec deux rôles (`client` et `admin`).
- **Commandes** : validation du panier avec adresse de livraison, historique des commandes, suivi du statut (en attente, payée, expédiée, livrée).
- **Paiement simulé** (pas de vrai paiement, adapté à un projet pédagogique).
- **Espace admin** : gestion des produits (CRUD, stock) et des commandes (changement de statut).
- **Design responsive** : en-tête, navigation et pied de page soignés.

### Stack technique

React (Vite, React Router) · Node.js / Express · MongoDB (Mongoose) · JWT · Docker · Kamal

## 3. Consignes du projet (GOMYCODE)

Front-end Development : User Interface Design
In this phase, you will design the user interface for the e-commerce website using ReactJS. You will be responsible for creating the website's layout, navigation, and styling. The design should be visually appealing, easy to navigate, and responsive on all devices.

Back-end Development : Server-side Development
In this phase, you will develop the server-side functionality of the e-commerce website using Node.js and Express. You will create the API endpoints for user authentication, product management, and order processing.

Deployment
In this phase, you will deploy the e-commerce website to a production environment and test it thoroughly. You will be responsible for setting up the hosting environment, configuring the server, and ensuring the website runs smoothly.

Pitch your work
Provide a brief overview of the presentation phase, including its purpose and significance. Explain that this is an opportunity to showcase the project's objectives, outcomes, and findings.

## 4. Architecture

```
E-CommerceWebsite/
├── package.json          # scripts racine : dev, build, test, start, seed
├── Dockerfile            # multi-stage (build client Vite -> image Node 22 alpine)
├── config/deploy.yml     # configuration Kamal 2 (service boutik + accessoire mongo)
├── .kamal/secrets        # références aux secrets (aucune valeur en clair)
├── server/               # API Express + Mongoose (ES modules)
│   ├── src/
│   │   ├── app.js        # app Express (helmet, cors, morgan, routes, statique SPA)
│   │   ├── index.js      # connexion MongoDB + listen + seed auto (SEED_ON_START)
│   │   ├── seed.js       # 17 produits de démo, admin et client démo
│   │   ├── models/       # User, Product, Order
│   │   ├── controllers/  # auth, produits, commandes
│   │   ├── routes/       # /api/auth, /api/products, /api/orders
│   │   ├── middleware/   # requireAuth, requireAdmin, validation zod, erreurs JSON
│   │   └── utils/
│   └── tests/            # Vitest + supertest + mongodb-memory-server
└── client/               # React 18 + Vite + React Router
    └── src/
        ├── context/      # AuthContext (JWT), CartContext (panier persistant localStorage)
        ├── components/   # Header (compteur panier), Footer, ProductCard, …
        ├── pages/        # Accueil, Catalogue, Détail, Panier, Commande, Mes commandes, Admin
        └── __tests__/    # Vitest + Testing Library
```

Points clés :

- **Prix en FCFA (entiers)**. Lors de la création d'une commande, le serveur **ignore les prix envoyés** par le client et recalcule prix unitaires et total depuis la base.
- **Pas de survente** : chaque ligne est réservée par une mise à jour atomique conditionnelle `findOneAndUpdate({ _id, stock: { $gte: qty } }, { $inc: { stock: -qty } })`. Si une ligne échoue, les lignes déjà réservées sont restituées et l'API renvoie `400`.
- **Panier côté client** (Context + localStorage), **resynchronisé au checkout** avec les prix et stocks réels du serveur.
- **Paiement simulé** : `POST /api/orders/:id/pay` passe la commande à `paid` et génère une référence `PAY-…`.
- L'annulation d'une commande par l'admin restitue le stock.
- En production, Express sert `client/dist` et renvoie `index.html` pour toute route non `/api` (SPA).
- Sécurité : helmet (CSP avec `img-src 'self' https: data:`), bcryptjs, JWT, rate limit sur `/api/auth`, validation zod, `trust proxy`.

## 5. Lancer en local

Prérequis : Node.js 22, MongoDB (local ou Docker : `docker run -d -p 27017:27017 mongo:7`).

```bash
cp .env.example .env          # puis adapter si besoin
npm install                   # installe aussi server/ et client/ (postinstall)
npm run seed                  # (optionnel) données de démo
npm run dev                   # API sur :3000, front Vite sur :5173 (proxy /api)
```

Production locale : `npm run build && NODE_ENV=production JWT_SECRET=xxx npm start` puis http://localhost:3000.

Variables d'environnement : `PORT`, `MONGODB_URI`, `JWT_SECRET` (obligatoire en production), `SEED_ON_START` (`true` = seed si la collection produits est vide), `ADMIN_PASSWORD` (défaut `admin12345`).

Comptes de démo (seed) :

| Rôle   | Email             | Mot de passe                    |
|--------|-------------------|---------------------------------|
| Admin  | admin@boutik.sn   | `ADMIN_PASSWORD` (défaut `admin12345`) |
| Client | demo@boutik.sn    | password123                     |

## 6. Tests

```bash
npm test                      # serveur puis client
npm --prefix server test      # 28 tests d'intégration (auth, catalogue, commandes, stock, admin, 401/403/404)
npm --prefix client test      # 12 tests composants (panier, header, catalogue, connexion, routes protégées)
```

Les tests serveur utilisent `mongodb-memory-server` : aucune base externe n'est nécessaire.

## 7. Déploiement (Kamal)

```bash
# Secrets communs aux 5 apps, stockés hors du dépôt (lus par .kamal/secrets) :
#   ~/.config/okemamy/registry_token   token Docker Hub (birantesy)
#   ~/.config/okemamy/jwt_secret       secret JWT partagé
#   ~/.config/okemamy/boutik_admin_password  mot de passe admin@boutik.sn en production
kamal setup                            # 1re fois : installe docker, kamal-proxy, l'accessoire mongo et l'app
kamal deploy                           # déploiements suivants
kamal app logs -f                      # logs
```

- Image `birantesy/boutik` construite en `amd64`, servie derrière kamal-proxy avec TLS automatique sur `boutik.okemamy.com`.
- Healthcheck : `GET /up` (200 `OK`, 503 si MongoDB est déconnecté).
- MongoDB tourne comme accessoire `boutik-mongo` (volume `data:/data/db`), non exposé publiquement, joignable sur le réseau docker `kamal`.
- `SEED_ON_START=true` peuple le catalogue au premier démarrage uniquement.


> **Registry** : si `~/.config/okemamy/registry_token` existe, Kamal pousse l'image sur Docker Hub (`birantesy/<app>`) ; sinon il utilise son registry local (`localhost:5555`, tunnel SSH vers le serveur, aucun identifiant). Kamal ≥ 2.8 requis (testé avec 2.12). Le build React se fait en natif (`--platform=$BUILDPLATFORM`) car esbuild plante sous émulation amd64.

## 8. API

Toutes les réponses d'erreur ont la forme `{ "error": "message" }`. Authentification : en-tête `Authorization: Bearer <token>`.

| Méthode | Endpoint | Accès | Description |
|---------|----------|-------|-------------|
| GET | `/up` | public | Healthcheck (200 `OK` / 503) |
| POST | `/api/auth/register` | public | Inscription `{name, email, password}` → `{token, user}` (rôle `client`) |
| POST | `/api/auth/login` | public | Connexion `{email, password}` → `{token, user}` |
| GET | `/api/auth/me` | connecté | Profil de l'utilisateur courant |
| GET | `/api/products` | public | Liste : `search`, `category`, `minPrice`, `maxPrice`, `sort` (`price_asc`, `price_desc`, `newest`, `rating`), `page`, `limit` → `{items, total, page, limit, pages}` |
| GET | `/api/products/:slug` | public | Détail d'un produit (slug ou id) |
| GET | `/api/categories` | public | Catégories avec nombre de produits `[{name, count}]` |
| POST | `/api/products` | admin | Créer un produit (slug et image générés si absents) |
| PUT | `/api/products/:id` | admin | Modifier un produit (prix, stock, …) |
| DELETE | `/api/products/:id` | admin | Supprimer un produit (204) |
| POST | `/api/orders` | connecté | Créer une commande `{items:[{product, quantity}], shippingAddress:{fullName, address, city, phone}}` ; prix/total recalculés, stock décrémenté atomiquement, 400 si stock insuffisant |
| GET | `/api/orders/mine` | connecté | Historique des commandes de l'utilisateur |
| GET | `/api/orders/:id` | propriétaire / admin | Détail d'une commande (404 si elle appartient à un autre client) |
| POST | `/api/orders/:id/pay` | propriétaire | Paiement simulé : `pending` → `paid` + `paymentRef` |
| GET | `/api/orders` | admin | Toutes les commandes (filtre optionnel `?status=`) |
| PATCH | `/api/orders/:id/status` | admin | Changer le statut `{status}` (`pending`, `paid`, `shipped`, `delivered`, `cancelled`) ; l'annulation restitue le stock |
