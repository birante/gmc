# API Checkpoint — React + Axios + JSONPlaceholder

React app that fetches a list of users from
[`jsonplaceholder.typicode.com/users`](https://jsonplaceholder.typicode.com/users)
with **axios** inside a **`useEffect`** hook, stores them in
**`listOfUser`** via `useState`, and maps them into cards on screen.

## Run

```bash
npm install
npm run dev        # opens http://localhost:5173
npm run build      # production bundle in dist/
npm run preview    # serve the built bundle
```

Requires Node.js **≥ 18**.

## Tooling note — Vite instead of Create React App

`create-react-app` was officially deprecated by the React team in 2023; the
React docs now recommend **Vite** (or a framework like Next.js) for new
apps. This checkpoint uses Vite for that reason — starts a dev server in
under a second, replaces webpack.

The brief asks for a file named `UserList.js`. Vite by default only treats
`.jsx` / `.tsx` files as JSX. To honour the exact filename requested, the
included [`vite.config.js`](./vite.config.js) tells the plugin + esbuild
to also treat `.js` files as JSX. All React components in this repo
therefore live in `.js` files, as the brief requires.

## Files

```
index.html            -- Vite entry point, mounts <App /> into #root
vite.config.js        -- Vite + React plugin, .js-as-JSX loader override
src/
├── main.js           -- createRoot() + <StrictMode><App /></StrictMode>
├── App.js            -- app shell (header + <UserList />)
├── UserList.js       -- <-- the requested file: axios + useEffect + useState + .map
└── styles.css        -- responsive card grid, dark-scheme aware
```

## What `UserList.js` does

```js
const [listOfUser, setListOfUser] = useState([]);

useEffect(() => {
  const controller = new AbortController();
  axios
    .get("https://jsonplaceholder.typicode.com/users", { signal: controller.signal })
    .then(response => setListOfUser(response.data))
    .catch(err => { if (!axios.isCancel(err)) setError(err.message); })
    .finally(() => setLoading(false));
  return () => controller.abort();
}, []);
```

- The **empty dependency array** `[]` makes the fetch happen once on
  mount.
- **`AbortController` cleanup** cancels the request if the component
  unmounts before the response arrives — matters in React 18 StrictMode,
  where components mount → unmount → mount in dev to surface effect bugs.
- `listOfUser.map(user => …)` renders one `<li class="user-card">` per
  user, with a monogram avatar (built from the initials), and a
  definition list of email / phone / company / website / city.
- Two additional states (`loading`, `error`) keep the UI honest: a
  status banner is shown until the request has settled.

## Styling

Pure CSS in `src/styles.css`:

- **Responsive card grid** — `grid-template-columns: repeat(auto-fill, minmax(320px, 1fr))`.
  Below 480 px each card takes the full width.
- **Monogram avatars** — a CSS gradient circle showing the initials.
- **Dark scheme** — picked up automatically via
  `@media (prefers-color-scheme: dark)`.
- **Hover** — cards lift 2 px and gain a soft shadow.

## Requirements checklist

- [x] React app created (Vite, the modern replacement for CRA)
- [x] `UserList.js` file in `src/`
- [x] `axios` installed (declared in `package.json`)
- [x] Fetch inside a `useEffect` hook
- [x] Data stored in `listOfUser` state via `useState`
- [x] `.map(...)` used to render the list
- [x] Styled — responsive grid, dark-scheme support, hover interaction
