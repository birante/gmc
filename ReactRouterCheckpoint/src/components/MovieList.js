import React from "react";
import { Row, Col } from "react-bootstrap";
import MovieCard from "./MovieCard";

function MovieList({ movies }) {
  if (movies.length === 0) {
    return (
      <p className="text-center text-light opacity-75 my-5">
        No movies match your filters. Try loosening the search or add a new one.
      </p>
    );
  }

  return (
    <Row className="g-4">
      {movies.map((movie) => (
        <Col key={movie.id} xs={12} sm={6} md={4} lg={3}>
          <MovieCard movie={movie} />
        </Col>
      ))}
    </Row>
  );
}

export default MovieList;
