import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom';
import { api } from '../api/client.js';
import BookCover from '../components/BookCover.jsx';
import GenrePicker from '../components/GenrePicker.jsx';
import { isValidIsbn, splitList } from '../utils.js';

const EMPTY = { title: '', authors: [], genres: [], description: '', coverUrl: '', isbn: '', publishedDate: '', pageCount: '' };

function fromBook(b) {
  return {
    title: b.title || '',
    authors: b.authors || [],
    genres: b.genres || [],
    description: b.description || '',
    coverUrl: b.coverUrl || '',
    isbn: b.isbn || '',
    publishedDate: b.publishedDate || '',
    pageCount: b.pageCount ? String(b.pageCount) : '',
  };
}

/** Saisie des auteurs sous forme de « chips » (Entrée ou virgule pour valider). */
function AuthorsInput({ value, onChange, draft, setDraft }) {
  const add = (text) => {
    const next = [...value];
    for (const a of splitList(text)) if (!next.some((x) => x.toLowerCase() === a.toLowerCase())) next.push(a);
    onChange(next);
    setDraft('');
  };
  return (
    <div className="field">
      <label htmlFor="book-authors" className="label">
        Auteur(s) <span className="muted small">(Entrée ou virgule pour ajouter)</span>
      </label>
      <div className="chip-input">
        {value.map((a) => (
          <span key={a} className="chip chip--on">
            {a}
            <button type="button" className="chip__remove" aria-label={`Retirer ${a}`} onClick={() => onChange(value.filter((x) => x !== a))}>
              ×
            </button>
          </span>
        ))}
        <input
          id="book-authors"
          value={draft}
          placeholder={value.length ? 'Autre auteur…' : 'Ex. Fatou Diome'}
          onChange={(e) => {
            const v = e.target.value;
            if (/[,;]/.test(v)) add(v);
            else setDraft(v);
          }}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              if (draft.trim()) add(draft);
            } else if (e.key === 'Backspace' && !draft && value.length) {
              onChange(value.slice(0, -1));
            }
          }}
          onBlur={() => draft.trim() && add(draft)}
        />
      </div>
    </div>
  );
}

export function validateBookForm(f) {
  const errors = {};
  if (!f.title.trim()) errors.title = 'Le titre est requis.';
  if (f.coverUrl.trim() && !/^https:\/\/\S+$/i.test(f.coverUrl.trim())) errors.coverUrl = "L'URL de couverture doit commencer par https://";
  if (f.isbn.trim() && !isValidIsbn(f.isbn)) errors.isbn = 'ISBN invalide : 10 ou 13 chiffres (tirets autorisés).';
  if (f.publishedDate.trim()) {
    const y = Number(f.publishedDate);
    if (!/^\d{1,4}$/.test(f.publishedDate.trim()) || y > new Date().getFullYear() + 1) errors.publishedDate = 'Année invalide.';
  }
  if (f.pageCount !== '' && !(Number.isInteger(Number(f.pageCount)) && Number(f.pageCount) > 0 && Number(f.pageCount) <= 20000)) errors.pageCount = 'Nombre de pages invalide.';
  return errors;
}

/** Création (/livres/nouveau) ou modification (/livres/:id/modifier) d'un livre du catalogue. */
export default function BookFormPage() {
  const { id } = useParams();
  const editing = Boolean(id);
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const [form, setForm] = useState(() => ({
    ...EMPTY,
    title: params.get('titre') || '',
    authors: params.get('auteur') ? splitList(params.get('auteur')) : [],
    genres: params.get('genre') ? [params.get('genre')] : [],
  }));
  const [authorDraft, setAuthorDraft] = useState('');
  const [errors, setErrors] = useState({});
  const [error, setError] = useState('');
  const [existing, setExisting] = useState(null);
  const [busy, setBusy] = useState(false);
  const [loading, setLoading] = useState(editing);

  useEffect(() => {
    if (!editing) return;
    api
      .book(id)
      .then(({ book }) => {
        if (!book.canEdit) setError('Seul le lecteur qui a ajouté ce livre peut le modifier.');
        setForm(fromBook(book));
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [editing, id]);

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function submit(e) {
    e.preventDefault();
    setError('');
    setExisting(null);
    const authors = authorDraft.trim() ? [...form.authors, ...splitList(authorDraft)] : form.authors;
    const data = { ...form, authors };
    const errs = validateBookForm(data);
    setErrors(errs);
    if (Object.keys(errs).length) return;
    const payload = {
      title: data.title.trim(),
      authors,
      genres: data.genres,
      description: data.description.trim(),
      coverUrl: data.coverUrl.trim(),
      isbn: data.isbn.trim(),
      publishedDate: data.publishedDate.trim(),
      pageCount: data.pageCount === '' ? null : Number(data.pageCount),
    };
    setBusy(true);
    try {
      if (editing) {
        await api.updateBook(id, payload);
        navigate(`/livres/${id}`);
      } else {
        const res = await api.createBook(payload);
        if (res.created === false) setExisting(res.book);
        else navigate(`/livres/${res.book.id}`, { state: { flash: 'Livre ajouté au catalogue, merci !' } });
      }
    } catch (err) {
      setError(err.message);
    } finally {
      setBusy(false);
    }
  }

  if (loading) return <div className="loader" aria-label="Chargement" />;
  const preview = { title: form.title || 'Titre du livre', authors: form.authors, coverUrl: /^https:\/\/\S+$/i.test(form.coverUrl.trim()) ? form.coverUrl.trim() : '' };

  return (
    <div className="narrow narrow--wide">
      <div className="page-head">
        <h1>{editing ? 'Modifier le livre' : 'Ajouter un livre'}</h1>
        <p className="muted">
          {editing
            ? 'Complétez ou corrigez la fiche de ce livre.'
            : "Un livre manque au catalogue ? Créez sa fiche : il pourra ensuite être noté et recommandé par tous les lecteurs."}
        </p>
      </div>

      <form className="form panel book-form" onSubmit={submit} noValidate>
        <div className="book-form__grid">
          <div className="book-form__fields">
            <label>
              Titre *
              <input value={form.title} onChange={set('title')} maxLength={300} aria-invalid={Boolean(errors.title)} required />
              {errors.title && <span className="field-error">{errors.title}</span>}
            </label>
            <AuthorsInput value={form.authors} onChange={(authors) => setForm({ ...form, authors })} draft={authorDraft} setDraft={setAuthorDraft} />
            <GenrePicker label="Genres" value={form.genres} onChange={(genres) => setForm({ ...form, genres })} />
            <label>
              Description
              <textarea rows={5} value={form.description} onChange={set('description')} maxLength={5000} placeholder="De quoi parle ce livre ?" />
            </label>
            <label>
              URL de la couverture <span className="muted small">(https, facultatif)</span>
              <input type="url" value={form.coverUrl} onChange={set('coverUrl')} placeholder="https://…" aria-invalid={Boolean(errors.coverUrl)} />
              {errors.coverUrl && <span className="field-error">{errors.coverUrl}</span>}
            </label>
            <div className="form-row form-row--3">
              <label>
                ISBN
                <input value={form.isbn} onChange={set('isbn')} inputMode="numeric" placeholder="978…" aria-invalid={Boolean(errors.isbn)} />
                {errors.isbn && <span className="field-error">{errors.isbn}</span>}
              </label>
              <label>
                Année
                <input value={form.publishedDate} onChange={set('publishedDate')} inputMode="numeric" placeholder="2021" maxLength={4} aria-invalid={Boolean(errors.publishedDate)} />
                {errors.publishedDate && <span className="field-error">{errors.publishedDate}</span>}
              </label>
              <label>
                Pages
                <input type="number" min="1" value={form.pageCount} onChange={set('pageCount')} aria-invalid={Boolean(errors.pageCount)} />
                {errors.pageCount && <span className="field-error">{errors.pageCount}</span>}
              </label>
            </div>
          </div>
          <aside className="book-form__preview" aria-label="Aperçu de la couverture">
            <BookCover key={preview.coverUrl} book={preview} size="lg" />
            <p className="muted small">{preview.coverUrl ? 'Aperçu de la couverture' : 'Sans URL, une couverture est générée automatiquement.'}</p>
          </aside>
        </div>

        {existing && (
          <div className="notice" role="status">
            Ce livre existe déjà dans le catalogue : <strong>{existing.title}</strong>.{' '}
            <Link to={`/livres/${existing.id}`}>Voir sa fiche</Link>
          </div>
        )}
        {error && <p className="error" role="alert">{error}</p>}
        <div className="row">
          <button className="btn btn--primary" disabled={busy}>
            {busy ? 'Enregistrement…' : editing ? 'Enregistrer les modifications' : 'Ajouter le livre'}
          </button>
          <Link to={editing ? `/livres/${id}` : '/bibliotheque'} className="btn btn--ghost">Annuler</Link>
        </div>
      </form>
    </div>
  );
}
