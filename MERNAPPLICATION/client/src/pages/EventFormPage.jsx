import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { api } from '../api/client.js';
import { useToast } from '../context/ToastContext.jsx';
import Spinner from '../components/Spinner.jsx';
import EventImage from '../components/EventImage.jsx';
import { CATEGORIES, toLocalInput } from '../utils/format.js';

const EMPTY = {
  title: '',
  description: '',
  date: '',
  location: '',
  category: 'Tech',
  capacity: 30,
  imageUrl: '',
};

export function validateEvent(form) {
  const errors = {};
  if (form.title.trim().length < 3) errors.title = 'Le titre doit contenir au moins 3 caractères.';
  if (form.description.trim().length < 10) errors.description = 'La description doit contenir au moins 10 caractères.';
  if (!form.date || Number.isNaN(new Date(form.date).getTime())) errors.date = 'Choisissez une date valide.';
  if (form.location.trim().length < 2) errors.location = 'Le lieu est requis.';
  if (!Number.isInteger(Number(form.capacity)) || Number(form.capacity) < 1) errors.capacity = 'Au moins 1 place.';
  if (form.imageUrl && !/^https?:\/\/.+/i.test(form.imageUrl)) errors.imageUrl = "L'URL doit commencer par http(s)://";
  return errors;
}

export default function EventFormPage() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const navigate = useNavigate();
  const { showToast } = useToast();
  const [form, setForm] = useState(EMPTY);
  const [errors, setErrors] = useState({});
  const [serverError, setServerError] = useState('');
  const [loading, setLoading] = useState(isEdit);
  const [saving, setSaving] = useState(false);
  const [attendeesCount, setAttendeesCount] = useState(0);

  useEffect(() => {
    if (!isEdit) return;
    api
      .getEvent(id)
      .then(({ event }) => {
        if (!event.isOrganizer) {
          showToast("Seul l'organisateur peut modifier cet événement.", 'error');
          navigate(`/events/${id}`, { replace: true });
          return;
        }
        setAttendeesCount(event.attendeesCount);
        setForm({
          title: event.title,
          description: event.description,
          date: toLocalInput(event.date),
          location: event.location,
          category: event.category,
          capacity: event.capacity,
          imageUrl: event.imageUrl || '',
        });
      })
      .catch((err) => setServerError(err.message))
      .finally(() => setLoading(false));
  }, [id, isEdit, navigate, showToast]);

  const onChange = (e) => {
    const { name, value } = e.target;
    setForm((f) => ({ ...f, [name]: value }));
    setErrors((errs) => ({ ...errs, [name]: undefined }));
  };

  const onSubmit = async (e) => {
    e.preventDefault();
    const errs = validateEvent(form);
    if (isEdit && Number(form.capacity) < attendeesCount) {
      errs.capacity = `Il y a déjà ${attendeesCount} inscrit(s).`;
    }
    setErrors(errs);
    if (Object.keys(errs).length) return;
    setSaving(true);
    setServerError('');
    const payload = {
      ...form,
      title: form.title.trim(),
      description: form.description.trim(),
      location: form.location.trim(),
      capacity: Number(form.capacity),
      date: new Date(form.date).toISOString(),
    };
    try {
      const { event } = isEdit ? await api.updateEvent(id, payload) : await api.createEvent(payload);
      showToast(isEdit ? 'Événement mis à jour.' : 'Événement publié 🎉');
      navigate(`/events/${event.id}`);
    } catch (err) {
      setServerError(err.message);
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <Spinner />;

  const field = (name) => ({ name, id: name, value: form[name], onChange, 'aria-invalid': Boolean(errors[name]) });

  return (
    <section className="container section narrow">
      <Link to={isEdit ? `/events/${id}` : '/'} className="back-link">← Retour</Link>
      <h1 className="page-title">{isEdit ? "Modifier l'événement" : 'Créer un événement'}</h1>
      <p className="muted">Renseignez les informations : elles seront visibles par tous les visiteurs.</p>

      <form className="card form-grid" onSubmit={onSubmit} noValidate>
        {serverError && <div className="alert alert-error span-2">{serverError}</div>}

        <div className="field span-2">
          <label htmlFor="title">Titre *</label>
          <input type="text" placeholder="Ex. Meetup JavaScript Dakar" {...field('title')} />
          {errors.title && <p className="field-error">{errors.title}</p>}
        </div>

        <div className="field span-2">
          <label htmlFor="description">Description *</label>
          <textarea rows={6} placeholder="Programme, intervenants, public visé…" {...field('description')} />
          {errors.description && <p className="field-error">{errors.description}</p>}
        </div>

        <div className="field">
          <label htmlFor="date">Date et heure *</label>
          <input type="datetime-local" {...field('date')} />
          {errors.date && <p className="field-error">{errors.date}</p>}
        </div>

        <div className="field">
          <label htmlFor="location">Lieu *</label>
          <input type="text" placeholder="Ex. Impact Hub, Dakar" {...field('location')} />
          {errors.location && <p className="field-error">{errors.location}</p>}
        </div>

        <div className="field">
          <label htmlFor="category">Catégorie</label>
          <select {...field('category')}>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        </div>

        <div className="field">
          <label htmlFor="capacity">Nombre de places *</label>
          <input type="number" min={Math.max(1, attendeesCount)} step={1} {...field('capacity')} />
          {errors.capacity && <p className="field-error">{errors.capacity}</p>}
        </div>

        <div className="field span-2">
          <label htmlFor="imageUrl">Image (URL)</label>
          <input type="url" placeholder="https://picsum.photos/seed/mon-event/800/400" {...field('imageUrl')} />
          {errors.imageUrl && <p className="field-error">{errors.imageUrl}</p>}
          {form.imageUrl && !errors.imageUrl && (
            <EventImage key={form.imageUrl} src={form.imageUrl} alt="Aperçu" category={form.category} className="preview" />
          )}
        </div>

        <div className="form-actions span-2">
          <Link to={isEdit ? `/events/${id}` : '/'} className="btn btn-ghost">Annuler</Link>
          <button type="submit" className="btn btn-primary" disabled={saving}>
            {saving ? 'Enregistrement…' : isEdit ? 'Enregistrer' : "Publier l'événement"}
          </button>
        </div>
      </form>
    </section>
  );
}
