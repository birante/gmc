# Next.js Portfolio Checkpoint

A portfolio website built with **Next.js 16 (App Router)** and **TypeScript**.
Showcases skills, projects, and contact info across four routes with server-
rendered pages and CSS Modules for styling.

## Features

- Four pages with file-based routing (`/`, `/about`, `/projects`, `/contact`)
- Shared layout with a sticky navbar and footer
- Server-Side Rendering — the Projects page is an `async` server component
  that awaits data before rendering
- Styling with **CSS Modules** (one `*.module.css` file per component/page)
- Images with the Next.js `<Image>` component (auto optimization, lazy load,
  responsive sizing)
- A client-side contact form (`"use client"`) with controlled inputs and
  submission feedback
- Per-page `<title>` and `<meta>` via the Metadata API

## Project structure

```text
CheckpointNextjsPortfolio/
├── app/
│   ├── layout.tsx              # root layout (navbar + footer)
│   ├── page.tsx                # /            — Home
│   ├── page.module.css
│   ├── globals.css
│   ├── about/
│   │   ├── page.tsx            # /about
│   │   └── about.module.css
│   ├── projects/
│   │   ├── page.tsx            # /projects    — async, SSR
│   │   └── projects.module.css
│   └── contact/
│       ├── page.tsx            # /contact
│       ├── ContactForm.tsx     # "use client" — form logic
│       └── contact.module.css
├── components/
│   ├── Navbar.tsx              # shared top-nav (Link-based)
│   ├── Navbar.module.css
│   ├── ProjectCard.tsx         # reusable project card + <Image>
│   └── ProjectCard.module.css
├── lib/
│   └── projects.ts             # server-side data fetcher (async)
└── public/images/              # SVG placeholder images
```

## Getting started

```bash
npm install
npm run dev
```

Runs at [http://localhost:3000](http://localhost:3000).

## Building & type-checking

```bash
npm run build
npm start           # runs the production build
```

`next build` type-checks the whole project; a green build means no TS
errors and no ESLint issues.

## How each checkpoint requirement is met

| Requirement | Where |
|---|---|
| **Multiple pages** | `app/page.tsx`, `app/about/page.tsx`, `app/projects/page.tsx`, `app/contact/page.tsx` |
| **File-based routing** | Each folder under `app/` becomes a route automatically |
| **CSS styling** | CSS Modules (`*.module.css`) scoped per component/page + a small `globals.css` |
| **Images with `next/image`** | Avatar on Home, project screenshots on `ProjectCard` |
| **Server-Side Rendering** | `app/projects/page.tsx` is an `async` server component that awaits `getProjects()` |
| **Components folder** | `components/Navbar.tsx`, `components/ProjectCard.tsx` |

## Deploying

The easiest way to deploy is with **Vercel** (made by the Next.js team):

1. Push this folder to a GitHub repo.
2. Go to <https://vercel.com/new>, import the repo, and click **Deploy**.
3. Vercel auto-detects Next.js and runs `next build` — no configuration
   needed.

Alternatively:

- **Netlify** — supports Next.js via the official runtime.
- **Self-hosted** — `npm run build && npm start` on any Node.js server
  (port 3000).

## Resources

- [Next.js Docs](https://nextjs.org/docs)
- [App Router](https://nextjs.org/docs/app)
- [next/image](https://nextjs.org/docs/app/api-reference/components/image)
