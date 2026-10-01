# 💬 Waxtaan

> 🌐 **Production :** https://waxtaan.okemamy.com · 🐳 **Image Docker :** `birantesy/waxtaan`

## 1. Titre du projet

**Waxtaan** (« discuter » en wolof) — messagerie instantanée par salons de discussion.

## 2. Description du projet

Waxtaan est une messagerie instantanée organisée en salons de discussion. Elle permet à une équipe, une classe ou une communauté de discuter en temps réel autour de thèmes, sans dépendre d'une application tierce.

### Fonctionnalités

- **Authentification JWT** : inscription, connexion et déconnexion, middleware qui protège les routes REST et les connexions Socket.IO.
- **Salons** : créer, lister, rejoindre et quitter un salon ; la liste des membres présents est stockée et mise à jour.
- **Messagerie temps réel** avec Socket.IO : envoi et réception instantanés, et historique conservé dans MongoDB.
- **Indicateurs** : horodatage des messages, avatar et nom de l'auteur, utilisateurs en ligne, « X est en train d'écrire… ».
- **Interface type messagerie** : salons à gauche, conversation à droite, adaptée au mobile.

### Stack technique

React (Vite) · Node.js / Express · Socket.IO · MongoDB (Mongoose) · JWT · Docker · Kamal

## 3. Consignes du projet (GOMYCODE)

Project Setup and Database Configuration
- Create a new project directory. - Set up the backend using Node.js and Express.js. - Install the necessary dependencies, such as Express.js, Mongoose, and Socket.IO. - Configure the MongoDB database connection and create models for chat messages and user data.

2


User Authentication
Create routes for user registration, login, and logout. Implement user authentication using JWT (JSON Web Tokens) for secure user sessions. Set up client-side forms for user registration and login using React.js. Implement authentication middleware to protect routes and validate user sessions.

3


Chat Room Creation and Management
Create routes for creating, joining, and leaving chat rooms. Implement backend logic to handle chat room creation, joining, and leaving. Create a form on the client-side to create new chat rooms. Display a list of available chat rooms for users to join. Implement functionality to join and leave chat rooms. Store and update the list of users present in each chat room.

4


Real-Time Messaging
Implement real-time messaging using Socket.IO for instant message updates. Create a message model in the database and implement the necessary backend logic. Develop a messaging interface on the client-side to send and receive messages. Display messages in real-time to users within the chat room. Implement features such as message timestamps and user indicators.

5


User Interface and Styling
Design and develop a user interface for the chat application using React.js. Apply CSS styling to improve the visual appeal and usability of the application. Implement responsive design to ensure the application is mobile-friendly.

6


Deployment
In this final step, you will deploy the React application to a hosting platform of your choice. This will make the application accessible to users online and allow for real-world testing and usage.

## 4. Architecture

```
Real-timeChatApplication/
├── package.json            # scripts racine : dev, build, test, start, seed
├── Dockerfile              # multi-stage node:22-alpine (build client → image finale USER node)
├── config/deploy.yml       # configuration Kamal 2 (service waxtaan + accessoire mongo)
├── .kamal/secrets          # références aux variables d'environnement (aucun secret en clair)
├── server/                 # Express 5 + Mongoose + Socket.IO (ES modules)
│   ├── src/
│   │   ├── app.js          # app Express (helmet, cors, morgan, /up, /api, statique + fallback SPA)
│   │   ├── server.js       # createServer() : app + http.Server + Socket.IO (sans listen)
│   │   ├── index.js        # connexion MongoDB, seed éventuel, listen(PORT)
│   │   ├── sockets/        # attachSockets() (auth JWT du handshake, événements) + présence en mémoire
│   │   ├── models/         # User, Room, Message
│   │   ├── controllers/    # auth, salons, historique paginé
│   │   ├── routes/ middleware/ utils/
│   │   └── seed.js         # données de démo (SEED_ON_START=true ou npm run seed)
│   └── tests/              # Vitest + supertest + mongodb-memory-server + socket.io-client
└── client/                 # React 19 + Vite + React Router + socket.io-client
    └── src/
        ├── context/        # AuthContext (JWT), SocketContext (io() même origine)
        ├── pages/          # Connexion, Inscription, Messagerie
        ├── components/     # RoomList, MessageList, MessageInput, TypingIndicator, OnlineUsers, Avatar…
        └── __tests__/      # Vitest + Testing Library
```

**Temps réel.** Le serveur Socket.IO est attaché au serveur HTTP d'Express (même port, chemin `/socket.io`). La connexion exige `handshake.auth.token` (JWT valide), sinon elle est refusée (`connect_error: "Non authentifié"`). Le client se connecte avec `io()` sur la même origine : en développement via le proxy Vite (`ws: true`), en production directement derrière kamal-proxy (WebSocket supporté). Le fallback SPA ignore `/api`, `/up` et `/socket.io`.

| Événement (client → serveur) | Charge utile | Effet |
|---|---|---|
| `room:join` | `{ roomId }` + ack | Abonne le socket au salon (membres seulement), met à jour la présence |
| `room:leave` | `{ roomId }` + ack | Désabonne le socket du salon |
| `message:send` | `{ roomId, text }` + ack | Valide (1–2000 caractères, membre), persiste dans MongoDB, diffuse `message:new` |
| `typing:start` / `typing:stop` | `{ roomId }` | Relaye `typing` aux autres membres connectés |

| Événement (serveur → client) | Charge utile |
|---|---|
| `message:new` | `{ id, room, text, createdAt, user: { id, username, avatarColor } }` |
| `typing` | `{ roomId, user, isTyping }` |
| `room:users` | `{ roomId, users: [...] }` — utilisateurs en ligne dans le salon |
| `room:created` / `room:members` | `{ room }` — nouveau salon / liste des membres mise à jour |

La déconnexion côté client supprime le jeton et ferme le socket.

## 5. Lancer en local

Prérequis : Node.js 22 et MongoDB (local ou `docker run -d -p 27017:27017 mongo:7`).

```bash
cp .env.example .env          # puis adapter si besoin (copier aussi dans server/ ou exporter les variables)
npm install                   # installe racine + server + client (postinstall)
npm run seed                  # facultatif : salons Général / Tech / Détente + comptes démo
npm run dev                   # API sur http://localhost:3000, client sur http://localhost:5173
```

Comptes de démo (seed) : `awa@waxtaan.sn` et `moussa@waxtaan.sn`, mot de passe `password123`.

Mode production local : `npm run build && NODE_ENV=production JWT_SECRET=… npm start` puis http://localhost:3000.

## 6. Tests

```bash
npm test                      # server (Vitest) puis client (Vitest)
```

- **Serveur** : tests REST d'intégration (supertest + mongodb-memory-server) — inscription, connexion, `/me`, salons (création, doublons, rejoindre/quitter), historique paginé, codes 400/401/403/404/409, seed — et tests **Socket.IO réels** (serveur sur port éphémère + `socket.io-client`) : refus sans jeton / jeton invalide, présence `room:users`, envoi/réception d'un message entre deux clients avec persistance, validation, `typing`, `room:leave`.
- **Client** : Vitest + Testing Library — formatage, Avatar, MessageItem, MessageInput, TypingIndicator, RoomList, OnlineUsers, page de connexion, page de messagerie (socket simulé).

## 7. Déploiement (Kamal)

L'image `birantesy/waxtaan` est construite pour `amd64` et déployée sur `142.93.114.9`, derrière kamal-proxy en HTTPS (`waxtaan.okemamy.com`, healthcheck `GET /up`). MongoDB 7 tourne en accessoire privé (`waxtaan-mongo`, réseau docker `kamal`, sans port publié).

```bash
# Secrets communs aux 5 apps, stockés hors du dépôt (lus par .kamal/secrets) :
#   ~/.config/okemamy/registry_token   token Docker Hub (birantesy)
#   ~/.config/okemamy/jwt_secret       secret JWT partagé
kamal accessory boot mongo            # première fois
kamal setup                           # première fois (ensuite : kamal deploy)
```

Variables : `NODE_ENV=production`, `PORT=3000`, `MONGODB_URI=mongodb://waxtaan-mongo:27017/waxtaan`, `SEED_ON_START=true` (seed uniquement si la base est vide), secret `JWT_SECRET`.


> **Registry** : si `~/.config/okemamy/registry_token` existe, Kamal pousse l'image sur Docker Hub (`birantesy/<app>`) ; sinon il utilise son registry local (`localhost:5555`, tunnel SSH vers le serveur, aucun identifiant). Kamal ≥ 2.8 requis (testé avec 2.12). Le build React se fait en natif (`--platform=$BUILDPLATFORM`) car esbuild plante sous émulation amd64.

## 8. API

Toutes les routes `/api/rooms` exigent `Authorization: Bearer <token>`. Erreurs au format `{ "error": "…" }`.

| Méthode | Route | Description | Réponses |
|---|---|---|---|
| GET | `/up` | Healthcheck (503 si MongoDB indisponible) | 200 `OK` |
| POST | `/api/auth/register` | `{ username, email, password }` → `{ token, user }` | 201, 400, 409 |
| POST | `/api/auth/login` | `{ email, password }` → `{ token, user }` | 200, 400, 401 |
| GET | `/api/auth/me` | Utilisateur courant | 200, 401 |
| POST | `/api/auth/logout` | Déconnexion (JWT sans état, le client oublie le jeton) | 204, 401 |
| GET | `/api/rooms` | Liste des salons (`members`, `memberCount`, `isMember`) | 200, 401 |
| POST | `/api/rooms` | `{ name, description? }` — le créateur devient membre | 201, 400, 401, 409 |
| POST | `/api/rooms/:id/join` | Rejoindre un salon | 200, 401, 404 |
| POST | `/api/rooms/:id/leave` | Quitter un salon | 200, 400, 401, 404 |
| GET | `/api/rooms/:id/messages?before=<ISO>&limit=<1-100>` | Historique paginé (ordre chronologique, `hasMore`) — membres seulement | 200, 400, 401, 403, 404 |
