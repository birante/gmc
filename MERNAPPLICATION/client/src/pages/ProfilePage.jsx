import { useState } from 'react';
import { useAuth } from '../context/AuthContext.jsx';
import { useToast } from '../context/ToastContext.jsx';
import { initials } from '../utils/format.js';

export default function ProfilePage() {
  const { user, updateProfile } = useAuth();
  const { showToast } = useToast();
  const [form, setForm] = useState({ name: user.name, email: user.email, bio: user.bio || '' });
  const [pwd, setPwd] = useState({ currentPassword: '', newPassword: '' });
  const [error, setError] = useState('');
  const [pwdError, setPwdError] = useState('');
  const [saving, setSaving] = useState(false);

  const saveProfile = async (e) => {
    e.preventDefault();
    if (form.name.trim().length < 2) return setError('Le nom doit contenir au moins 2 caractères.');
    setSaving(true);
    setError('');
    try {
      await updateProfile({ name: form.name.trim(), email: form.email, bio: form.bio });
      showToast('Profil mis à jour.');
    } catch (err) {
      setError(err.message);
    } finally {
      setSaving(false);
    }
    return undefined;
  };

  const savePassword = async (e) => {
    e.preventDefault();
    if (pwd.newPassword.length < 6) return setPwdError('Le nouveau mot de passe doit contenir au moins 6 caractères.');
    setPwdError('');
    try {
      await updateProfile(pwd);
      setPwd({ currentPassword: '', newPassword: '' });
      showToast('Mot de passe modifié.');
    } catch (err) {
      setPwdError(err.message);
    }
    return undefined;
  };

  return (
    <section className="container section narrow">
      <div className="profile-head">
        <span className="avatar avatar-lg">{initials(user.name)}</span>
        <div>
          <h1 className="page-title">{user.name}</h1>
          <p className="muted">
            Membre depuis {new Date(user.createdAt).toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })}
          </p>
        </div>
      </div>

      <form className="card form-grid" onSubmit={saveProfile} noValidate>
        <h2 className="span-2 section-title">Informations du profil</h2>
        {error && <div className="alert alert-error span-2">{error}</div>}
        <div className="field">
          <label htmlFor="name">Nom</label>
          <input id="name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </div>
        <div className="field">
          <label htmlFor="email">E-mail</label>
          <input id="email" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
        </div>
        <div className="field span-2">
          <label htmlFor="bio">Bio</label>
          <textarea
            id="bio"
            rows={4}
            maxLength={500}
            placeholder="Présentez-vous en quelques mots…"
            value={form.bio}
            onChange={(e) => setForm({ ...form, bio: e.target.value })}
          />
          <p className="muted small">{form.bio.length}/500</p>
        </div>
        <div className="form-actions span-2">
          <button type="submit" className="btn btn-primary" disabled={saving}>
            {saving ? 'Enregistrement…' : 'Enregistrer'}
          </button>
        </div>
      </form>

      <form className="card form-grid" onSubmit={savePassword} noValidate>
        <h2 className="span-2 section-title">Changer de mot de passe</h2>
        {pwdError && <div className="alert alert-error span-2">{pwdError}</div>}
        <div className="field">
          <label htmlFor="currentPassword">Mot de passe actuel</label>
          <input
            id="currentPassword"
            type="password"
            autoComplete="current-password"
            value={pwd.currentPassword}
            onChange={(e) => setPwd({ ...pwd, currentPassword: e.target.value })}
          />
        </div>
        <div className="field">
          <label htmlFor="newPassword">Nouveau mot de passe</label>
          <input
            id="newPassword"
            type="password"
            autoComplete="new-password"
            value={pwd.newPassword}
            onChange={(e) => setPwd({ ...pwd, newPassword: e.target.value })}
          />
        </div>
        <div className="form-actions span-2">
          <button type="submit" className="btn btn-ghost">Mettre à jour le mot de passe</button>
        </div>
      </form>
    </section>
  );
}
