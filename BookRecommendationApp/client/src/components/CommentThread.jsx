import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api/client.js';
import { useAuth } from '../context/AuthContext.jsx';
import { timeAgo } from '../utils.js';

export default function CommentThread({ recommendationId, recommendationOwnerId, initialComments, onCountChange }) {
  const { user } = useAuth();
  const [comments, setComments] = useState(initialComments || null);
  const [text, setText] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (initialComments) return;
    api.comments(recommendationId).then((d) => setComments(d.comments)).catch((e) => setError(e.message));
  }, [recommendationId, initialComments]);

  async function submit(e) {
    e.preventDefault();
    if (!text.trim()) return;
    setBusy(true);
    setError('');
    try {
      const { comment } = await api.addComment(recommendationId, text.trim());
      const next = [...(comments || []), comment];
      setComments(next);
      onCountChange?.(next.length);
      setText('');
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(id) {
    await api.deleteComment(id);
    const next = comments.filter((c) => c.id !== id);
    setComments(next);
    onCountChange?.(next.length);
  }

  return (
    <div className="comments">
      {comments === null && !error && <p className="muted small">Chargement des commentaires…</p>}
      {comments?.length === 0 && <p className="muted small">Aucun commentaire pour l'instant. Lancez la discussion !</p>}
      <ul>
        {comments?.map((c) => (
          <li key={c.id} className="comment">
            <span className="avatar avatar--sm" aria-hidden="true">{c.user?.username?.[0]?.toUpperCase()}</span>
            <div className="comment__body">
              <p>
                <Link to={`/lecteurs/${c.user?.username}`} className="strong">{c.user?.username}</Link>{' '}
                <span className="muted small">{timeAgo(c.createdAt)}</span>
              </p>
              <p>{c.text}</p>
            </div>
            {user && (user.id === c.user?.id || user.id === recommendationOwnerId) && (
              <button className="icon-btn" aria-label="Supprimer le commentaire" onClick={() => remove(c.id)}>×</button>
            )}
          </li>
        ))}
      </ul>
      {error && <p className="error small">{error}</p>}
      {user ? (
        <form className="comment-form" onSubmit={submit}>
          <input value={text} onChange={(e) => setText(e.target.value)} placeholder="Écrire un commentaire…" aria-label="Votre commentaire" maxLength={1000} />
          <button className="btn btn--primary btn--sm" disabled={busy || !text.trim()}>Publier</button>
        </form>
      ) : (
        <p className="small"><Link to="/connexion">Connectez-vous</Link> pour commenter.</p>
      )}
    </div>
  );
}
