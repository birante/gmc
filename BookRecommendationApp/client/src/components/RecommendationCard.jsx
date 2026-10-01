import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { api } from '../api/client.js';
import { useAuth } from '../context/AuthContext.jsx';
import { authorsLabel, REASON_LABELS, timeAgo } from '../utils.js';
import BookCover from './BookCover.jsx';
import CommentThread from './CommentThread.jsx';
import StarRating from './StarRating.jsx';

export default function RecommendationCard({ rec, showBook = true, onDelete, defaultOpenComments = false }) {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [liked, setLiked] = useState(rec.likedByMe);
  const [likes, setLikes] = useState(rec.likesCount);
  const [commentsCount, setCommentsCount] = useState(rec.commentsCount);
  const [showComments, setShowComments] = useState(defaultOpenComments);
  const [busy, setBusy] = useState(false);
  const isMine = user && rec.user?.id === user.id;

  async function toggleLike() {
    if (!user) return navigate('/connexion');
    setBusy(true);
    const prev = { liked, likes };
    setLiked(!liked);
    setLikes(likes + (liked ? -1 : 1));
    try {
      const res = liked ? await api.unlike(rec.id) : await api.like(rec.id);
      setLiked(res.liked);
      setLikes(res.likesCount);
    } catch {
      setLiked(prev.liked);
      setLikes(prev.likes);
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!window.confirm('Supprimer cette recommandation ?')) return;
    await api.deleteRecommendation(rec.id);
    onDelete?.(rec.id);
  }

  return (
    <article className="rec-card">
      {showBook && rec.book && (
        <Link to={`/livres/${rec.book.id}`} className="rec-card__cover" aria-label={`Voir ${rec.book.title}`}>
          <BookCover book={rec.book} size="sm" />
        </Link>
      )}
      <div className="rec-card__body">
        <header className="rec-card__head">
          <Link to={`/lecteurs/${rec.user?.username}`} className="rec-card__user">
            <span className="avatar avatar--sm" aria-hidden="true">{rec.user?.username?.[0]?.toUpperCase()}</span>
            <span className="strong">{rec.user?.username}</span>
          </Link>
          <span className="muted small">recommande · {timeAgo(rec.createdAt)}</span>
          {rec.reasons?.length > 0 && (
            <span className="badges">
              {rec.reasons.map((r) => (
                <span key={r} className={`badge badge--${r}`}>{REASON_LABELS[r] || r}</span>
              ))}
            </span>
          )}
        </header>
        {showBook && rec.book && (
          <h3 className="rec-card__title">
            <Link to={`/livres/${rec.book.id}`}>{rec.book.title}</Link>
            <span className="muted rec-card__authors"> — {authorsLabel(rec.book.authors)}</span>
          </h3>
        )}
        <StarRating value={rec.rating} size="sm" label="Note du lecteur" />
        <blockquote className="rec-card__review">{rec.review}</blockquote>
        <footer className="rec-card__actions">
          <button className={`action ${liked ? 'action--on' : ''}`} onClick={toggleLike} disabled={busy} aria-pressed={liked} aria-label={liked ? "Je n'aime plus" : "J'aime"}>
            <span aria-hidden="true">{liked ? '♥' : '♡'}</span> <span data-testid="likes-count">{likes}</span>
          </button>
          <button className="action" onClick={() => setShowComments((s) => !s)} aria-expanded={showComments}>
            <span aria-hidden="true">💬</span> {commentsCount} commentaire{commentsCount > 1 ? 's' : ''}
          </button>
          <Link to={`/recommandations/${rec.id}`} className="action">Ouvrir</Link>
          {isMine && (
            <button className="action action--danger" onClick={remove}>Supprimer</button>
          )}
        </footer>
        {showComments && <CommentThread recommendationId={rec.id} recommendationOwnerId={rec.user?.id} onCountChange={setCommentsCount} />}
      </div>
    </article>
  );
}
