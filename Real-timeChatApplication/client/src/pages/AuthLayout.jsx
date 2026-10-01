export default function AuthLayout({ title, subtitle, children }) {
  return (
    <div className="auth-page">
      <div className="auth-hero" aria-hidden="true">
        <div className="brand brand-lg"><span className="brand-logo">W</span> Waxtaan</div>
        <p>Discutez en temps réel avec votre équipe, votre classe ou votre communauté, salon par salon.</p>
        <ul className="hero-bubbles">
          <li>Na nga def ? 👋</li>
          <li className="me">Maa ngi fi rekk ! On se retrouve dans #Tech ?</li>
          <li>Awa est en train d'écrire…</li>
        </ul>
      </div>
      <div className="auth-card">
        <h1>{title}</h1>
        {subtitle && <p className="muted">{subtitle}</p>}
        {children}
      </div>
    </div>
  );
}
