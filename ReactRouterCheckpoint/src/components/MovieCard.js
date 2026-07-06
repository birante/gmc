import React from "react";
import { Card } from "react-bootstrap";
import { Link } from "react-router-dom";

function MovieCard({ movie }) {
  return (
    <Link
      to={`/movies/${movie.id}`}
      className="text-decoration-none text-reset"
    >
      <Card className="movie-card h-100">
        <Card.Img variant="top" src={movie.posterURL} alt={movie.title} />
        <Card.Body>
          <Card.Title className="d-flex justify-content-between align-items-start">
            <span>{movie.title}</span>
            <span className="rating-star">★ {movie.rating}</span>
          </Card.Title>
          <Card.Text className="text-truncate-3">{movie.description}</Card.Text>
        </Card.Body>
      </Card>
    </Link>
  );
}

export default MovieCard;
