import "bootstrap/dist/css/bootstrap.min.css";
import { Navbar, Nav, Container, Card, Button, Row, Col } from "react-bootstrap";

const appStyle = {
  minHeight: "100vh",
  background: "linear-gradient(135deg, #1e3c72 0%, #2a5298 100%)",
  paddingBottom: "60px",
};

const headingStyle = {
  color: "#ffffff",
  textAlign: "center",
  margin: "50px 0 40px",
  fontWeight: 800,
  letterSpacing: "1.5px",
  textShadow: "0 4px 12px rgba(0,0,0,0.35)",
};

const cardStyle = {
  border: "none",
  borderRadius: "16px",
  overflow: "hidden",
  boxShadow: "0 10px 25px rgba(0,0,0,0.25)",
};

const cards = [
  {
    title: "Discover",
    text: "Explore curated content tailored to your interests and stay ahead of trends.",
    image:
      "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=800&q=80",
    button: "Learn more",
  },
  {
    title: "Build",
    text: "Ship modern web apps faster with reusable components and proven patterns.",
    image:
      "https://images.unsplash.com/photo-1542831371-29b0f74f9713?auto=format&fit=crop&w=800&q=80",
    button: "Get started",
  },
  {
    title: "Share",
    text: "Publish your work and collaborate with a community of passionate developers.",
    image:
      "https://images.unsplash.com/photo-1522071820081-009f0129c71c?auto=format&fit=crop&w=800&q=80",
    button: "Join us",
  },
];

function App() {
  return (
    <>
      <div className="App" style={appStyle}>
        <Navbar bg="dark" variant="dark" expand="lg" className="shadow">
          <Container>
            <Navbar.Brand href="#home">React Checkpoint</Navbar.Brand>
            <Navbar.Toggle aria-controls="basic-navbar-nav" />
            <Navbar.Collapse id="basic-navbar-nav">
              <Nav className="ms-auto">
                <Nav.Link href="#home">Home</Nav.Link>
                <Nav.Link href="#about">About</Nav.Link>
                <Nav.Link href="#contact">Contact</Nav.Link>
              </Nav>
            </Navbar.Collapse>
          </Container>
        </Navbar>

        <Container>
          <h1 style={headingStyle}>Welcome to my React App</h1>

          <Row className="g-4 justify-content-center">
            {cards.map((card, index) => (
              <Col key={index} xs={12} sm={6} lg={4}>
                <Card style={cardStyle}>
                  <Card.Img variant="top" src={card.image} alt={card.title} />
                  <Card.Body>
                    <Card.Title>{card.title}</Card.Title>
                    <Card.Text>{card.text}</Card.Text>
                    <Button variant="primary">{card.button}</Button>
                  </Card.Body>
                </Card>
              </Col>
            ))}
          </Row>
        </Container>
      </div>
    </>
  );
}

export default App;
