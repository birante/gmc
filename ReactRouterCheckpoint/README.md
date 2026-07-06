# React Router Checkpoint — Movie App with Routing

Extends the previous Movie App with `react-router-dom`:

- The home page lists movies and lets you filter/add them.
- Clicking a movie card navigates to `/movies/:id`, which shows the full
  description and the embedded trailer.
- A **Back to home** button on the details page returns to the list.

Every movie now carries a `trailerLink` (embed URL) in addition to `title`,
`description`, `posterURL`, and `rating`.

## Getting started

```bash
npm install
npm start
```

The app runs at [http://localhost:3000](http://localhost:3000).
