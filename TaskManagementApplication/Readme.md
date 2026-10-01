# ✅ TaskFlow

> 🌐 **Production :** https://taskflow.okemamy.com · 🐳 **Image Docker :** `birantesy/taskflow`

## 1. Titre du projet

**TaskFlow** — organiser ses tâches, respecter ses échéances, suivre sa progression.

## 2. Description du projet

TaskFlow est un gestionnaire de tâches personnel. Il aide chacun à organiser son travail : créer des tâches, fixer des échéances, définir des priorités et suivre sa progression. Chaque utilisateur a sa propre liste, privée et sécurisée.

### Fonctionnalités

- **Inscription et connexion** par JWT ; chaque tâche est liée à son propriétaire, et l'API vérifie qu'on n'accède qu'à ses propres tâches.
- **Créer une tâche** : titre, description, échéance, priorité (basse, moyenne, haute) et statut (à faire, en cours, terminée).
- **Modifier et supprimer** des tâches ; on peut aussi changer le statut en un clic.
- **Filtres** par statut, et **recherche** par titre ou description.
- **Tri** par échéance, priorité ou date de création.
- **Indicateurs** : tâches en retard mises en évidence, barre de progression (part des tâches terminées).
- **Interface intuitive et responsive.**

### Stack technique

MongoDB · Express · React (Vite) · Node.js (MERN) · JWT · Docker · Kamal

## 3. Consignes du projet (GOMYCODE)

Project Setup and Backend Configuration
Project Idea: Task Management Application Brief: You have been assigned to develop a task management application using the MERN stack (MongoDB, Express.js, React, Node.js). The application should allow users to create, update, and delete tasks, set task deadlines, and track their progress. Users should be able to sign up, log in, and have their own personalized task lists. The application should provide an intuitive user interface and a seamless user experience. Guideline Instructor: Throughout the project, the student must use the MERN stack for the development of the application. The student should pay attention to proper authentication and authorization mechanisms, data management, and seamless user experience. The application should be well-designed, responsive, and scalable. Step 1: Project Setup and Backend Configuration Description: In this step, you will set up the project structure and configure the backend using Node.js, Express.js, and MongoDB. You will create the necessary folders, install the required dependencies, and establish a connection to the MongoDB database. Additionally, you will define the basic routes and API endpoints for task management.

2


User Authentication and Authorization
In this step, you will implement user authentication and authorization functionalities to allow users to sign up, log in, and access their personalized task lists. Users should be able to securely register their accounts, log in with their credentials, and have their tasks associated with their accounts. You will implement token-based authentication and secure the API endpoints.

3


Task Creation and Listing
In this step, you will implement the functionality to create tasks and display the list of tasks for each user. Users should be able to add new tasks with a title, description, and deadline. The tasks should be listed in a user-friendly interface, showing relevant information such as task title, status, and deadline.

4


Task Update and Deletion
In this step, you will enhance the task management application by implementing the functionality to update and delete tasks. Users should be able to edit task details such as title, description, and deadline. They should also be able to delete tasks from their task lists. The changes should be reflected in the database and the user interface.

5


Task Filtering and Sorting
In this step, you will add filtering and sorting options to the task management application. Users should be able to filter tasks based on their status (completed, in progress) or search for tasks by title or description. Additionally, users should have the option to sort tasks based on different criteria such as deadline or priority.

6


Deployment and Finalization
In this final step, you will prepare the task management application for deployment and finalize the project. You will set up the production environment, configure any necessary settings, and deploy the application to a web server or cloud hosting platform. Additionally, you will conduct a final round of testing to ensure the deployed application functions correctly.

## 4. Architecture

```
TaskManagementApplication/
├── package.json          # scripts racine : dev, build, test, start, install:all
├── Dockerfile            # multi-stage : build du client puis image Node 22 alpine (USER node)
├── config/deploy.yml     # configuration Kamal 2 (service taskflow + accessoire MongoDB)
├── .kamal/secrets        # références aux variables d'environnement (aucun secret en clair)
├── server/               # API Express + Mongoose (ES modules)
│   ├── src/app.js        # application Express (helmet, cors, rate-limit, /up, /api, SPA)
│   ├── src/index.js      # connexion MongoDB + listen + seed automatique (SEED_ON_START)
│   ├── src/seed.js       # compte démo + 8 tâches
│   ├── src/models/       # User, Task (index sur owner, owner+status, owner+deadline)
│   ├── src/controllers/  # auth, tâches (CRUD, statut, filtres, tri, stats)
│   ├── src/routes/       # routes + validation express-validator
│   ├── src/middleware/   # requireAuth (JWT Bearer), validate, gestion d'erreurs JSON
│   └── tests/            # Vitest + supertest + mongodb-memory-server
└── client/               # React 18 + Vite + React Router, CSS maison responsive (FR)
    └── src/
        ├── pages/        # AuthPage (connexion/inscription), Dashboard
        ├── components/   # StatsPanel, Toolbar, TaskCard, TaskForm, Modal, Header
        ├── context/      # AuthContext (jeton JWT en localStorage)
        ├── api/          # client fetch
        └── __tests__/    # Vitest + Testing Library
```

Points clés :
- **Isolation stricte** : toutes les requêtes sur les tâches filtrent sur `owner = utilisateur connecté` ; la tâche d'un autre utilisateur renvoie **404** (on ne révèle pas son existence). Un champ `owner` envoyé par le client est ignoré.
- **Tri par priorité logique** (haute > moyenne > basse) grâce à un champ interne `priorityRank` maintenu par un hook Mongoose. Pour le tri par échéance, les tâches sans échéance passent en dernier.
- **Recherche** insensible à la casse sur titre et description, avec échappement des caractères spéciaux des regex.
- `completedAt` est renseigné automatiquement au passage à « terminée » et remis à `null` sinon ; le champ virtuel `overdue` signale les tâches en retard.
- En production, Express sert `client/dist` et renvoie `index.html` pour toute route hors `/api` et `/up`.

## 5. Lancer en local

Prérequis : Node 22, MongoDB local (ou `docker run -d -p 27017:27017 mongo:7`).

```bash
cp .env.example .env          # puis adapter si besoin (le serveur lit les variables d'environnement)
npm run install:all           # installe racine + server + client
SEED_ON_START=true npm run dev  # API sur :3000, client Vite sur http://localhost:5173 (proxy /api)
```

Compte de démo (créé si la base est vide avec `SEED_ON_START=true`, ou via `npm run seed`) :
**demo@taskflow.sn / password123**

Production locale : `npm run build && NODE_ENV=production JWT_SECRET=xxx npm start` puis http://localhost:3000.

| Variable | Défaut | Rôle |
|---|---|---|
| `PORT` | `3000` | Port HTTP |
| `MONGODB_URI` | `mongodb://localhost:27017/taskflow` | Base MongoDB |
| `JWT_SECRET` | (obligatoire en production) | Signature des jetons |
| `JWT_EXPIRES_IN` | `7d` | Durée de validité du jeton |
| `SEED_ON_START` | `false` | Crée le compte démo si la base est vide |

## 6. Tests

```bash
npm test     # tests serveur puis client
```

- **Serveur** (28 tests, Vitest + supertest + mongodb-memory-server) : healthcheck, inscription/connexion/me, validation, 401 sans jeton, CRUD complet, changement de statut et `completedAt`, tâches en retard, **isolation entre utilisateurs (404)**, filtres, recherche insensible à la casse et échappement regex, tri (priorité logique, échéance, création), statistiques, seed.
- **Client** (14 tests, Vitest + Testing Library) : carte de tâche (retard en rouge, actions en un clic), formulaire (validation, édition), panneau de statistiques, tableau de bord (chargement, onglets, tri, PATCH statut, création via modale).

## 7. Déploiement (Kamal)

L'application est déployée sur `https://taskflow.okemamy.com` avec Kamal 2 (`config/deploy.yml`) : image `birantesy/taskflow` (build amd64), kamal-proxy avec SSL et healthcheck sur `/up`, MongoDB 7 en accessoire privé (`taskflow-mongo` sur le réseau docker `kamal`, sans port exposé).

```bash
# Secrets communs aux 5 apps, stockés hors du dépôt (lus par .kamal/secrets) :
#   ~/.config/okemamy/registry_token   token Docker Hub (birantesy)
#   ~/.config/okemamy/jwt_secret       secret JWT partagé
kamal setup        # première fois (installe docker, proxy, accessoire mongo, app)
kamal deploy       # déploiements suivants
kamal app logs     # journaux
```

Test local de l'image :

```bash
docker network create taskflow-net
docker run -d --name taskflow-mongo-test --network taskflow-net mongo:7
docker build -t taskflow:test .
docker run -d --name taskflow-app-test --network taskflow-net -p 4105:3000 \
  -e NODE_ENV=production -e JWT_SECRET=test -e SEED_ON_START=true \
  -e MONGODB_URI=mongodb://taskflow-mongo-test:27017/taskflow taskflow:test
curl http://localhost:4105/up   # OK
```


> **Registry** : si `~/.config/okemamy/registry_token` existe, Kamal pousse l'image sur Docker Hub (`birantesy/<app>`) ; sinon il utilise son registry local (`localhost:5555`, tunnel SSH vers le serveur, aucun identifiant). Kamal ≥ 2.8 requis (testé avec 2.12). Le build React se fait en natif (`--platform=$BUILDPLATFORM`) car esbuild plante sous émulation amd64.

## 8. API

Toutes les routes `/api/tasks` exigent l'en-tête `Authorization: Bearer <jeton>`. Les erreurs sont renvoyées au format `{ "error": "..." }`.

| Méthode | Route | Description |
|---|---|---|
| GET | `/up` | Healthcheck (200 `OK`, 503 si MongoDB déconnectée) |
| POST | `/api/auth/register` | Inscription `{ name, email, password }` → `{ token, user }` |
| POST | `/api/auth/login` | Connexion `{ email, password }` → `{ token, user }` |
| GET | `/api/auth/me` | Utilisateur courant |
| GET | `/api/tasks` | Liste des tâches de l'utilisateur. Query : `status=todo\|in_progress\|done`, `search=texte`, `sort=deadline\|-deadline\|priority\|-priority\|createdAt\|-createdAt` (défaut `-createdAt`) |
| GET | `/api/tasks/stats` | `{ total, byStatus: { todo, in_progress, done }, overdue, completionRate }` |
| POST | `/api/tasks` | Créer `{ title*, description, deadline, priority: low\|medium\|high, status }` |
| GET | `/api/tasks/:id` | Détail d'une tâche (404 si elle n'appartient pas à l'utilisateur) |
| PUT | `/api/tasks/:id` | Modifier (champs partiels acceptés) |
| PATCH | `/api/tasks/:id/status` | Changer uniquement le statut `{ status }` |
| DELETE | `/api/tasks/:id` | Supprimer (204) |
