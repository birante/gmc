import React, { Component } from "react";
import { Container, Card, Button, Badge } from "react-bootstrap";

const pageStyle = {
  minHeight: "100vh",
  background: "linear-gradient(135deg, #1e3c72 0%, #2a5298 100%)",
  padding: "60px 0",
};

const headingStyle = {
  color: "#ffffff",
  textAlign: "center",
  marginBottom: "30px",
  fontWeight: 800,
  letterSpacing: "1px",
  textShadow: "0 4px 12px rgba(0,0,0,0.35)",
};

const timerStyle = {
  color: "#ffffff",
  textAlign: "center",
  marginBottom: "30px",
  fontSize: "1rem",
  opacity: 0.9,
};

const cardStyle = {
  border: "none",
  borderRadius: "16px",
  overflow: "hidden",
  boxShadow: "0 10px 25px rgba(0,0,0,0.25)",
  maxWidth: "480px",
  margin: "0 auto",
};

class App extends Component {
  constructor(props) {
    super(props);
    this.state = {
      person: {
        fullName: "Ada Lovelace",
        bio:
          "Mathematician and writer, chiefly known for her work on Charles Babbage's proposed mechanical general-purpose computer, the Analytical Engine.",
        imgSrc:
          "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTpG9hPAi6d9dBKaEPJkNFxrkhUeEWg5hF1saffGMGBYt7q-kfm9vpfHTTbE0i1620qOT-V52hNOjmO6yfsjlUtKX-y4e956hROaQ25C-Y0-Q&s=10",
        profession: "Mathematician & First Computer Programmer",
      },
      show: false,
      mountedAt: Date.now(),
      elapsed: 0,
    };
  }

  componentDidMount() {
    this.timerId = setInterval(() => {
      this.setState({ elapsed: Math.floor((Date.now() - this.state.mountedAt) / 1000) });
    }, 1000);
  }

  componentWillUnmount() {
    clearInterval(this.timerId);
  }

  toggleShow = () => {
    this.setState((prev) => ({ show: !prev.show }));
  };

  render() {
    const { person, show, elapsed } = this.state;

    return (
      <div style={pageStyle}>
        <Container>
          <h1 style={headingStyle}>React State Checkpoint</h1>
          <p style={timerStyle}>
            <Badge bg="light" text="dark">
              Mounted {elapsed} second{elapsed === 1 ? "" : "s"} ago
            </Badge>
          </p>

          <div className="text-center mb-4">
            <Button variant="light" onClick={this.toggleShow}>
              {show ? "Hide profile" : "Show profile"}
            </Button>
          </div>

          {show && (
            <Card style={cardStyle}>
              <Card.Img variant="top" src={person.imgSrc} alt={person.fullName} />
              <Card.Body>
                <Card.Title>{person.fullName}</Card.Title>
                <Card.Subtitle className="mb-2 text-muted">
                  {person.profession}
                </Card.Subtitle>
                <Card.Text>{person.bio}</Card.Text>
              </Card.Body>
            </Card>
          )}
        </Container>
      </div>
    );
  }
}

export default App;
