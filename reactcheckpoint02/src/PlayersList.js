import Player from "./Player";
import players from "./players";

const listStyle = {
  display: "flex",
  flexWrap: "wrap",
  justifyContent: "center",
  padding: "40px 20px",
};

const titleStyle = {
  textAlign: "center",
  color: "#ffffff",
  fontSize: "2.4rem",
  fontWeight: 800,
  letterSpacing: "2px",
  textTransform: "uppercase",
  marginTop: "30px",
  textShadow: "0 4px 12px rgba(0,0,0,0.4)",
};

function PlayersList() {
  return (
    <>
      <h1 style={titleStyle}>FIFA Player Cards</h1>
      <div style={listStyle}>
        {players.map((player) => (
          <Player key={player.id} {...player} />
        ))}
      </div>
    </>
  );
}

export default PlayersList;
