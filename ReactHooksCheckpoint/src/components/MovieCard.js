import React from "react";
import { Card } from "react-bootstrap";

function MovieCard({ movie }) {
  return (
    <Card className="movie-card">
      <Card.Img variant="top" src={movie.posterURL} alt={movie.title} />
      <Card.Body>
        <Card.Title className="d-flex justify-content-between align-items-start">
          <span>{movie.title}</span>
          <span className="rating-star">★ {movie.rating}</span>
        </Card.Title>
        <Card.Text>{movie.description}</Card.Text>
      </Card.Body>
    </Card>
  );
}

export default MovieCard;
