import { Card, Badge } from "react-bootstrap";

const cardStyle = {
  width: "18rem",
  margin: "20px",
  border: "none",
  borderRadius: "18px",
  overflow: "hidden",
  background: "linear-gradient(160deg, #1e3c72 0%, #2a5298 100%)",
  color: "#ffffff",
  boxShadow: "0 12px 32px rgba(0, 0, 0, 0.35)",
  transition: "transform 0.3s ease",
};

const imageStyle = {
  height: "260px",
  objectFit: "cover",
  borderBottom: "3px solid #ffd700",
};

const numberStyle = {
  position: "absolute",
  top: "12px",
  left: "12px",
  background: "#ffd700",
  color: "#1e3c72",
  width: "48px",
  height: "48px",
  borderRadius: "50%",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  fontWeight: 800,
  fontSize: "1.3rem",
  boxShadow: "0 4px 10px rgba(0,0,0,0.3)",
};

const nameStyle = {
  fontWeight: 700,
  fontSize: "1.3rem",
  marginBottom: "8px",
  letterSpacing: "0.5px",
};

const rowStyle = {
  display: "flex",
  justifyContent: "space-between",
  fontSize: "0.95rem",
  marginBottom: "4px",
  opacity: 0.9,
};

const labelStyle = { fontWeight: 600, color: "#ffd700" };

function Player({ name, team, nationality, jerseyNumber, age, image }) {
  return (
    <Card style={cardStyle}>
      <div style={{ position: "relative" }}>
        <Card.Img variant="top" src={image} alt={name} style={imageStyle} />
        <div style={numberStyle}>{jerseyNumber}</div>
      </div>
      <Card.Body>
        <Card.Title style={nameStyle}>{name}</Card.Title>
        <div style={rowStyle}>
          <span style={labelStyle}>Team</span>
          <span>{team}</span>
        </div>
        <div style={rowStyle}>
          <span style={labelStyle}>Nationality</span>
          <span>{nationality}</span>
        </div>
        <div style={rowStyle}>
          <span style={labelStyle}>Age</span>
          <span>{age}</span>
        </div>
        <Badge
          bg="warning"
          text="dark"
          style={{ marginTop: "10px", fontSize: "0.85rem", padding: "6px 10px" }}
        >
          FIFA OFFICIAL
        </Badge>
      </Card.Body>
    </Card>
  );
}

Player.defaultProps = {
  name: "Unknown Player",
  team: "Free Agent",
  nationality: "Unknown",
  jerseyNumber: 0,
  age: "N/A",
  image:
    "https://via.placeholder.com/300x260.png?text=No+Image",
};

export default Player;
