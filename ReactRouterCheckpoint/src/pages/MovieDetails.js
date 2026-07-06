import React from "react";
import { useParams, useNavigate, Link } from "react-router-dom";
import { Container, Button, Row, Col } from "react-bootstrap";

function MovieDetails({ movies }) {
  const { id } = useParams();
  const navigate = useNavigate();
  const movie = movies.find((m) => String(m.id) === id);

  if (!movie) {
    return (
      <Container className="py-5 text-center text-light">
        <h2>Movie not found</h2>
        <Link to="/" className="btn btn-warning mt-3">
          ← Back to home
        </Link>
      </Container>
    );
  }

  return (
    <Container className="py-5 text-light">
      <Button
        variant="warning"
        className="mb-4"
        onClick={() => navigate(-1)}
      >
        ← Back to home
      </Button>

      <Row className="g-4">
        <Col xs={12} md={4}>
          <img
            src={movie.posterURL}
            alt={movie.title}
            className="img-fluid rounded shadow"
          />
        </Col>
        <Col xs={12} md={8}>
          <h1 className="mb-2">{movie.title}</h1>
          <p className="rating-star mb-3">★ {movie.rating} / 10</p>
          <p>{movie.description}</p>
        </Col>
      </Row>

      <h3 className="mt-5 mb-3">Trailer</h3>
      <div className="ratio ratio-16x9 shadow rounded overflow-hidden">
        <iframe
          src={movie.trailerLink}
          title={`${movie.title} trailer`}
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
          allowFullScreen
        />
      </div>
    </Container>
  );
}

export default MovieDetails;
