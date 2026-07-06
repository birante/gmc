import React from "react";
import { Form, Row, Col } from "react-bootstrap";

function Filter({ titleQuery, minRating, onTitleChange, onRatingChange }) {
  return (
    <Form className="mb-4">
      <Row className="g-3">
        <Col xs={12} md={8}>
          <Form.Label className="text-light">Search by title</Form.Label>
          <Form.Control
            type="text"
            placeholder="e.g. Inception"
            value={titleQuery}
            onChange={(e) => onTitleChange(e.target.value)}
          />
        </Col>
        <Col xs={12} md={4}>
          <Form.Label className="text-light">
            Minimum rating: <strong>{minRating}</strong>
          </Form.Label>
          <Form.Range
            min={0}
            max={10}
            step={0.5}
            value={minRating}
            onChange={(e) => onRatingChange(Number(e.target.value))}
          />
        </Col>
      </Row>
    </Form>
  );
}

export default Filter;
