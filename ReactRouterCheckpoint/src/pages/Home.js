import React from "react";
import { Container } from "react-bootstrap";
import MovieList from "../components/MovieList";
import Filter from "../components/Filter";
import AddMovie from "../components/AddMovie";

function Home({
  movies,
  titleQuery,
  minRating,
  onTitleChange,
  onRatingChange,
  onAdd,
}) {
  return (
    <Container className="py-5">
      <div className="d-flex justify-content-between align-items-center mb-4">
        <h1 className="text-light mb-0">My Movie Collection</h1>
        <AddMovie onAdd={onAdd} />
      </div>

      <Filter
        titleQuery={titleQuery}
        minRating={minRating}
        onTitleChange={onTitleChange}
        onRatingChange={onRatingChange}
      />

      <MovieList movies={movies} />
    </Container>
  );
}

export default Home;
