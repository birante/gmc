import "bootstrap/dist/css/bootstrap.min.css";
import "./App.css";
import PlayersList from "./PlayersList";

const appStyle = {
  minHeight: "100vh",
  background:
    "linear-gradient(135deg, #0f2027 0%, #203a43 50%, #2c5364 100%)",
  paddingBottom: "40px",
};

function App() {
  return (
    <div style={appStyle}>
      <PlayersList />
    </div>
  );
}

export default App;
