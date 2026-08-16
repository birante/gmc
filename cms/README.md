# EduCMS — Educational Content Management System

Full-featured CMS on **Rails 8** with role-based access, posts + drafts +
publishing, categories & tags, comments, media, search, an admin dashboard, and
a headless JSON API — deployable to **Render** on the free tier.

Live URL (once deployed): `https://<your-app>.onrender.com`

## Stack

- **Rails 8.1**, **Ruby 3.4.7**
- **PostgreSQL** (Render Postgres or local)
- **Tailwind CSS v4**, **Hotwire** (Turbo + Stimulus)
- **Devise** — authentication
- **Pundit** — role-based authorization
- **FriendlyId** — human-readable slugs
- **Ransack + Kaminari** — search, filter, pagination

## Local run

```bash
cd cms
bundle install
bin/rails db:setup          # create, migrate, seed
bin/rails server            # http://localhost:3000
```

Seeded users (password: `password123`):

| Email                  | Role   |
| ---------------------- | ------ |
| `admin@educms.local`   | admin  |
| `editor@educms.local`  | editor |
| `author@educms.local`  | author |

## Features

| Feature                                 | Where it lives                                         |
| --------------------------------------- | ------------------------------------------------------ |
| Auth (email + password)                 | Devise — `app/models/user.rb`                          |
| Role-based access (4 roles)             | Enum on User + Pundit policies in `app/policies/`      |
| Post CRUD, draft/published/archived     | `app/controllers/posts_controller.rb`                  |
| Categories (parent/child)               | `app/models/category.rb`                               |
| Tags (comma-separated input on form)    | `posts_controller#assign_tags`                         |
| Comments with moderation                | `app/controllers/comments_controller.rb`               |
| Media table + Active Storage attachment | `app/models/medium.rb`                                 |
| Search + filter                         | Ransack, in `posts#index`                              |
| Pagination                              | Kaminari                                               |
| Reading-time auto-calc                  | `Post#compute_reading_time`                            |
| SEO fields                              | Post columns + edit form                               |
| Dashboard                               | `app/controllers/dashboard_controller.rb`              |
| **Headless JSON API**                   | `/api/v1/posts`, `/api/v1/categories`, `/api/v1/tags`  |
| Health check for Render                 | `GET /up`                                              |

## API

Read-only JSON endpoints (paginated):

```
GET /api/v1/posts               # list
GET /api/v1/posts/:slug         # one post (full content)
GET /api/v1/categories
GET /api/v1/tags
```

## Deploy to Render (free)

`render.yaml` is a Blueprint that provisions Postgres + web service.

1. Push this repo to GitHub (public repo, or connect Render to a private one).
2. Grab your `RAILS_MASTER_KEY`:

   ```bash
   cat config/master.key
   ```

3. render.com → Dashboard → **New** → **Blueprint** → pick the repo.
4. When it prompts, paste `RAILS_MASTER_KEY`. Click **Apply**.
5. First build ~5–8 min. App comes up at `https://educms.onrender.com`.

Free-tier note: the web service sleeps after 15 min idle; first request
takes ~30 s to wake up. Fine for a demo.

## Files of note

```
config/
├── routes.rb                        HTML + JSON API routes
├── database.yml                     uses $DATABASE_URL in production
app/
├── controllers/
│   ├── application_controller.rb    Devise + Pundit wiring
│   ├── pages_controller.rb          home
│   ├── posts_controller.rb          CRUD + Ransack search
│   ├── categories_controller.rb
│   ├── tags_controller.rb
│   ├── comments_controller.rb
│   ├── dashboard_controller.rb
│   └── api/v1/                      JSON API
├── models/                          User Post Category Tag Comment Medium
├── policies/                        Pundit — PostPolicy, CategoryPolicy, CommentPolicy
└── views/                           Tailwind-styled ERB templates
db/
├── migrate/
└── seeds.rb
render.yaml
bin/render-build.sh
```
