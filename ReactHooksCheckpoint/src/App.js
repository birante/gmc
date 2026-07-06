import React, { useState, useMemo } from "react";
import { Container } from "react-bootstrap";
import MovieList from "./components/MovieList";
import Filter from "./components/Filter";
import AddMovie from "./components/AddMovie";

const initialMovies = [
  {
    id: 1,
    title: "Inception",
    description:
      "A thief who steals corporate secrets through dream-sharing technology is given the inverse task of planting an idea.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/9gk7adHYeDvHkCSEqAvQNLV5Uge.jpg",
    rating: 8.8,
  },
  {
    id: 2,
    title: "Interstellar",
    description:
      "A team of explorers travels through a wormhole in space in an attempt to ensure humanity's survival.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg",
    rating: 8.7,
  },
  {
    id: 3,
    title: "The Dark Knight",
    description:
      "Batman raises the stakes in his war on crime with the help of Lt. Jim Gordon and DA Harvey Dent.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/qJ2tW6WMUDux911r6m7haRef0WH.jpg",
    rating: 9.0,
  },
  {
    id: 4,
    title: "Parasite",
    description:
      "Greed and class discrimination threaten the newly formed symbiotic relationship between two families.",
    posterURL:
      "https://image.tmdb.org/t/p/w500/7IiTTgloJzvGI1TAYymCfbfl3vT.jpg",
    rating: 8.5,
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
    <Container className="py-5">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h1 className="text-light mb-0">My Movie Collection</h1>
        <AddMovie onAdd={addMovie} />
      </div>

      <Filter
        titleQuery={titleQuery}
        minRating={minRating}
        onTitleChange={setTitleQuery}
        onRatingChange={setMinRating}
      />

      <MovieList movies={filteredMovies} />
    </Container>
  );
}

export default App;
