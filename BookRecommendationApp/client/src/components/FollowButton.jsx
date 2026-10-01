import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../api/client.js';
import { useAuth } from '../context/AuthContext.jsx';

export default function FollowButton({ userId, initialFollowing, onChange, small }) {
  const { user, setUser } = useAuth();
  const navigate = useNavigate();
  const [following, setFollowing] = useState(initialFollowing);
  const [busy, setBusy] = useState(false);

  if (user && user.id === userId) return null;

  async function toggle() {
    if (!user) return navigate('/connexion');
    setBusy(true);
    try {
      const res = following ? await api.unfollow(userId) : await api.follow(userId);
      setFollowing(res.following);
      setUser((u) =>
        u && {
          ...u,
          following: res.following ? [...new Set([...(u.following || []), userId])] : (u.following || []).filter((id) => id !== userId),
        }
      );
      onChange?.(res);
    } finally {
      setBusy(false);
    }
  }

  return (
    <button className={`btn ${following ? 'btn--ghost' : 'btn--primary'} ${small ? 'btn--sm' : ''}`} onClick={toggle} disabled={busy} aria-pressed={following}>
      {following ? 'Suivi ✓' : 'Suivre'}
    </button>
  );
}
