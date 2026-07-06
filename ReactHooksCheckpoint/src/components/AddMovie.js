import React, { useState } from "react";
import { Modal, Button, Form } from "react-bootstrap";

const emptyMovie = { title: "", description: "", posterURL: "", rating: "" };

function AddMovie({ onAdd }) {
  const [show, setShow] = useState(false);
  const [draft, setDraft] = useState(emptyMovie);
  const [error, setError] = useState("");

  const open = () => setShow(true);
  const close = () => {
    setShow(false);
    setDraft(emptyMovie);
    setError("");
  };

  const update = (field) => (e) =>
    setDraft((prev) => ({ ...prev, [field]: e.target.value }));

  const handleSubmit = (e) => {
    e.preventDefault();
    const rating = Number(draft.rating);

    if (!draft.title.trim() || !draft.description.trim() || !draft.posterURL.trim()) {
      setError("Title, description and poster URL are required.");
      return;
    }
    if (Number.isNaN(rating) || rating < 0 || rating > 10) {
      setError("Rating must be a number between 0 and 10.");
      return;
    }

    onAdd({
      title: draft.title.trim(),
      description: draft.description.trim(),
      posterURL: draft.posterURL.trim(),
      rating,
    });
    close();
  };

  return (
    <>
      <Button variant="warning" onClick={open}>
        + Add a movie
      </Button>

      <Modal show={show} onHide={close} centered>
        <Modal.Header closeButton>
          <Modal.Title>Add a new movie</Modal.Title>
        </Modal.Header>
        <Form onSubmit={handleSubmit}>
          <Modal.Body>
            {error && <div className="alert alert-danger py-2">{error}</div>}

            <Form.Group className="mb-3">
              <Form.Label>Title</Form.Label>
              <Form.Control
                type="text"
                value={draft.title}
                onChange={update("title")}
                placeholder="Movie title"
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Description</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                value={draft.description}
                onChange={update("description")}
                placeholder="Short synopsis"
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Poster URL</Form.Label>
              <Form.Control
                type="url"
                value={draft.posterURL}
                onChange={update("posterURL")}
                placeholder="https://…"
              />
            </Form.Group>

            <Form.Group className="mb-3">
              <Form.Label>Rating (0-10)</Form.Label>
              <Form.Control
                type="number"
                min={0}
                max={10}
                step={0.1}
                value={draft.rating}
                onChange={update("rating")}
                placeholder="8.5"
              />
            </Form.Group>
          </Modal.Body>
          <Modal.Footer>
            <Button variant="secondary" onClick={close}>
              Cancel
            </Button>
            <Button type="submit" variant="primary">
              Save
            </Button>
          </Modal.Footer>
        </Form>
      </Modal>
    </>
  );
}

export default AddMovie;
