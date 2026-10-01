import { Link } from 'react-router-dom';

export default function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-grid">
        <div>
          <div className="logo logo-light"><span className="logo-mark" aria-hidden="true">B</span>Boutik</div>
          <p>La vitrine en ligne simple et abordable des petits commerçants.</p>
        </div>
        <div>
          <h4>Boutique</h4>
          <ul>
            <li><Link to="/produits">Catalogue</Link></li>
            <li><Link to="/panier">Panier</Link></li>
            <li><Link to="/mes-commandes">Mes commandes</Link></li>
          </ul>
        </div>
        <div>
          <h4>Aide</h4>
          <ul>
            <li>Livraison 24–72 h</li>
            <li>Retours sous 7 jours</li>
            <li>Paiement simulé (projet pédagogique)</li>
          </ul>
        </div>
        <div>
          <h4>Contact</h4>
          <ul>
            <li>Dakar, Sénégal</li>
            <li>contact@boutik.sn</li>
            <li>+221 77 000 00 00</li>
          </ul>
        </div>
      </div>
      <div className="footer-bottom">© {new Date().getFullYear()} Boutik · Projet GOMYCODE</div>
    </footer>
  );
}
