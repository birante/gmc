export default function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-inner">
        <span>🎟️ EventHub — créer, publier et rejoindre des événements.</span>
        <span>Projet MERN · GOMYCODE · {new Date().getFullYear()}</span>
      </div>
    </footer>
  );
}
