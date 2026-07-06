import React, { useState, useMemo } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "./pages/Home";
import MovieDetails from "./pages/MovieDetails";

const initialMovies = [
  {
    id: 1,
    title: "Inception",
    description:
      "A thief who steals corporate secrets through the use of dream-sharing technology is given the inverse task of planting an idea into the mind of a C.E.O., but his tragic past may doom the project and his team to disaster.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
    rating: 8.8,
    trailerLink: "https://www.youtube.com/embed/YoHD9XEInc0",
  },
  {
    id: 2,
    title: "Interstellar",
    description:
      "When Earth becomes uninhabitable in the future, a farmer and ex-NASA pilot is tasked to pilot a spacecraft, along with a team of researchers, to find a new planet for humans.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
    rating: 8.7,
    trailerLink: "https://www.youtube.com/embed/zSWdZVtXT7E",
  },
  {
    id: 3,
    title: "The Dark Knight",
    description:
      "When the menace known as the Joker wreaks havoc and chaos on the people of Gotham, Batman, James Gordon and Harvey Dent must work together to put an end to the madness.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
    rating: 9.0,
    trailerLink: "https://www.youtube.com/embed/EXeTwQWrcwY",
  },
  {
    id: 4,
    title: "Parasite",
    description:
      "Greed and class discrimination threaten the newly formed symbiotic relationship between the wealthy Park family and the destitute Kim clan.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
    rating: 8.5,
    trailerLink: "https://www.youtube.com/embed/5xH0HfJHsaY",
  },
];

function App() {
  const [movies, setMovies] = useState(initialMovies);
  const [titleQuery, setTitleQuery] = useState("");
  const [minRating, setMinRating] = useState(0);

  const addMovie = (movie) => {
    setMovies((prev) => [...prev, { id: Date.now(), ...movie }]);
  };

  const filteredMovies = useMemo(() => {
    const q = titleQuery.trim().toLowerCase();
    return movies.filter(
      (m) =>
        (q === "" || m.title.toLowerCase().includes(q)) && m.rating >= minRating
    );
  }, [movies, titleQuery, minRating]);

  return (
    <BrowserRouter>
      <Routes>
        <Route
          path="/"
          element={
            <Home
              movies={filteredMovies}
              titleQuery={titleQuery}
              minRating={minRating}
              onTitleChange={setTitleQuery}
              onRatingChange={setMinRating}
              onAdd={addMovie}
            />
          }
        />
        <Route path="/movies/:id" element={<MovieDetails movies={movies} />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
