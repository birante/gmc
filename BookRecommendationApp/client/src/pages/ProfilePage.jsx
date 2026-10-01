import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api } from '../api/client.js';
import FollowButton from '../components/FollowButton.jsx';
import GenrePicker from '../components/GenrePicker.jsx';
import RecommendationCard from '../components/RecommendationCard.jsx';
import { useAuth } from '../context/AuthContext.jsx';

export default function ProfilePage() {
  const { username } = useParams();
  const { user: me, setUser } = useAuth();
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState(false);
  const [bio, setBio] = useState('');
  const [genres, setGenres] = useState([]);
  const [tab, setTab] = useState('recs');

  useEffect(() => {
    setData(null);
    setError('');
    api
      .profile(username)
      .then((d) => {
        setData(d);
        setBio(d.user.bio || '');
        setGenres(d.user.favoriteGenres || []);
      })
      .catch((e) => setError(e.message));
  }, [username, me?.id]);

  async function save(e) {
    e.preventDefault();
    const { user } = await api.updateMe({ bio, favoriteGenres: genres });
    setUser(user);
    setData((d) => ({ ...d, user: { ...d.user, bio: user.bio, favoriteGenres: user.favoriteGenres } }));
    setEditing(false);
  }

  if (error) return <div className="empty empty--page"><p className="error">{error}</p><Link to="/lecteurs">Voir les lecteurs</Link></div>;
  if (!data) return <div className="loader" aria-label="Chargement" />;
  const { user, recommendations } = data;

  return (
    <>
      <section className="profile-head">
        <span className="avatar avatar--xl" aria-hidden="true">{user.username[0].toUpperCase()}</span>
        <div className="profile-head__info">
          <h1>{user.username}</h1>
          <p className="profile-stats">
            <button className="linklike" onClick={() => setTab('recs')}><strong>{recommendations.length}</strong> recommandation{recommendations.length > 1 ? 's' : ''}</button>
            <button className="linklike" onClick={() => setTab('followers')}><strong data-testid="followers-count">{user.followersCount}</strong> abonné{user.followersCount > 1 ? 's' : ''}</button>
            <button className="linklike" onClick={() => setTab('following')}><strong>{user.followingCount}</strong> abonnement{user.followingCount > 1 ? 's' : ''}</button>
          </p>
          {!editing && (
            <>
              {user.bio ? <p className="bio">{user.bio}</p> : user.isMe && <p className="muted">Ajoutez une bio pour vous présenter.</p>}
              {user.favoriteGenres?.length > 0 && <p className="tags">{user.favoriteGenres.map((g) => <span key={g} className="tag">{g}</span>)}</p>}
            </>
          )}
          {editing && (
            <form className="form" onSubmit={save}>
              <label>
                Bio
                <textarea rows={3} value={bio} onChange={(e) => setBio(e.target.value)} maxLength={500} />
              </label>
              <GenrePicker value={genres} onChange={setGenres} />
              <div className="row">
                <button className="btn btn--primary btn--sm">Enregistrer</button>
                <button type="button" className="btn btn--ghost btn--sm" onClick={() => setEditing(false)}>Annuler</button>
              </div>
            </form>
          )}
        </div>
        <div className="profile-head__actions">
          {user.isMe ? (
            !editing && <button className="btn btn--ghost" onClick={() => setEditing(true)}>Modifier le profil</button>
          ) : (
            <FollowButton
              key={user.id}
              userId={user.id}
              initialFollowing={user.isFollowing}
              onChange={(res) =>
                setData((d) => ({
                  ...d,
                  user: {
                    ...d.user,
                    followersCount: res.followersCount,
                    isFollowing: res.following,
                    followers: res.following ? [...d.user.followers, { id: me.id, username: me.username }] : d.user.followers.filter((f) => f.id !== me.id),
                  },
                }))
              }
            />
          )}
        </div>
      </section>

      <div className="tabs" role="tablist">
        <button role="tab" aria-selected={tab === 'recs'} onClick={() => setTab('recs')}>Recommandations</button>
        <button role="tab" aria-selected={tab === 'followers'} onClick={() => setTab('followers')}>Abonnés</button>
        <button role="tab" aria-selected={tab === 'following'} onClick={() => setTab('following')}>Abonnements</button>
      </div>

      {tab === 'recs' && (
        <div className="stack">
          {recommendations.length === 0 && <p className="empty">Aucune recommandation pour l'instant.</p>}
          {recommendations.map((r) => (
            <RecommendationCard key={r.id} rec={r} onDelete={(id) => setData((d) => ({ ...d, recommendations: d.recommendations.filter((x) => x.id !== id) }))} />
          ))}
        </div>
      )}
      {tab !== 'recs' && (
        <ul className="people">
          {(tab === 'followers' ? user.followers : user.following).map((p) => (
            <li key={p.id}>
              <Link to={`/lecteurs/${p.username}`}>
                <span className="avatar avatar--sm" aria-hidden="true">{p.username[0].toUpperCase()}</span> {p.username}
              </Link>
            </li>
          ))}
          {(tab === 'followers' ? user.followers : user.following).length === 0 && <p className="empty">Personne pour l'instant.</p>}
        </ul>
      )}
    </>
  );
}
