import "bootstrap/dist/css/bootstrap.min.css";
import "./App.css";
import { Card, Button, Badge } from "react-bootstrap";
import Name from "./Name";
import Price from "./Price";
import Description from "./Description";
import ProductImage from "./Image";

const firstName = "Birante";
const userAvatar =
  "https://api.dicebear.com/7.x/avataaars/svg?seed=Birante&backgroundColor=ffd5dc";

function App() {
  return (
    <div className="App">
      <div className="page-background">
        <Card className="product-card shadow-lg">
          <div className="image-wrapper">
            <ProductImage />
            <Badge bg="danger" className="sale-badge">
              -20% TODAY
            </Badge>
          </div>
          <Card.Body className="text-center">
            <Name />
            <Price />
            <Description />
            <Button variant="dark" size="lg" className="buy-btn">
              Add to Cart
            </Button>
          </Card.Body>
        </Card>

        <div className="greeting-box">
          {firstName ? (
            <>
              <img
                src={userAvatar}
                alt={`${firstName} avatar`}
                className="user-avatar"
              />
              <h3 className="greeting">Hello, {firstName}!</h3>
            </>
          ) : (
            <h3 className="greeting">Hello, there!</h3>
          )}
        </div>
      </div>
    </div>
  );
}

export default App;
