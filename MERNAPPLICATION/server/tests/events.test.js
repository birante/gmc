import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import {
  startDb, stopDb, clearDb, api, createUser, createEvent, eventPayload, pastDate, futureDate,
} from './helpers.js';

beforeAll(startDb);
afterAll(stopDb);
beforeEach(clearDb);

describe('CRUD des événements', () => {
  it('exige une authentification pour créer (401)', async () => {
    const res = await api().post('/api/events').send(eventPayload());
    expect(res.status).toBe(401);
  });

  it('crée un événement avec seatsLeft', async () => {
    const { auth, user } = await createUser();
    const res = await api().post('/api/events').set(auth).send(eventPayload({ capacity: 10 }));
    expect(res.status).toBe(201);
    expect(res.body.event.seatsLeft).toBe(10);
    expect(res.body.event.attendeesCount).toBe(0);
    expect(res.body.event.organizer.name).toBe(user.name);
    expect(res.body.event.isOrganizer).toBe(true);
    expect(res.body.event.attendees).toBeUndefined();
  });

  it('valide les données (400)', async () => {
    const { auth } = await createUser();
    const res = await api().post('/api/events').set(auth).send(eventPayload({ category: 'Inconnue', capacity: 0 }));
    expect(res.status).toBe(400);
  });

  it('lit un événement ; 404 si inexistant ou id invalide', async () => {
    const { auth } = await createUser();
    const ev = await createEvent(auth);
    const ok = await api().get(`/api/events/${ev.id}`);
    expect(ok.status).toBe(200);
    expect(ok.body.event.title).toBe('Meetup React');
    expect((await api().get('/api/events/64b7f0f0f0f0f0f0f0f0f0f0')).status).toBe(404);
    expect((await api().get('/api/events/pas-un-id')).status).toBe(404);
  });

  it("seul l'organisateur peut modifier ou supprimer (403)", async () => {
    const owner = await createUser();
    const other = await createUser();
    const ev = await createEvent(owner.auth);

    const put403 = await api().put(`/api/events/${ev.id}`).set(other.auth).send({ title: 'Piraté !' });
    expect(put403.status).toBe(403);
    const del403 = await api().delete(`/api/events/${ev.id}`).set(other.auth);
    expect(del403.status).toBe(403);
    expect((await api().put(`/api/events/${ev.id}`).send({ title: 'x' })).status).toBe(401);

    const put = await api().put(`/api/events/${ev.id}`).set(owner.auth).send({ title: 'Meetup React 19', capacity: 5 });
    expect(put.status).toBe(200);
    expect(put.body.event.title).toBe('Meetup React 19');
    expect(put.body.event.seatsLeft).toBe(5);

    const del = await api().delete(`/api/events/${ev.id}`).set(owner.auth);
    expect(del.status).toBe(204);
    expect((await api().get(`/api/events/${ev.id}`)).status).toBe(404);
    expect((await api().delete(`/api/events/${ev.id}`).set(owner.auth)).status).toBe(404);
  });

  it("refuse une capacité inférieure au nombre d'inscrits", async () => {
    const owner = await createUser();
    const a = await createUser();
    const b = await createUser();
    const ev = await createEvent(owner.auth, { capacity: 3 });
    await api().post(`/api/events/${ev.id}/register`).set(a.auth);
    await api().post(`/api/events/${ev.id}/register`).set(b.auth);
    const res = await api().put(`/api/events/${ev.id}`).set(owner.auth).send({ capacity: 1 });
    expect(res.status).toBe(400);
  });
});

describe('Recherche, filtres et pagination', () => {
  beforeEach(async () => {
    const { auth } = await createUser();
    await createEvent(auth, { title: 'Atelier Docker', category: 'Atelier', date: futureDate(3) });
    await createEvent(auth, { title: 'Concert de jazz', category: 'Culture', location: 'Saint-Louis', date: futureDate(10) });
    await createEvent(auth, { title: 'Hackathon passé', category: 'Tech', date: pastDate(5) });
    await createEvent(auth, { title: 'Conférence IA', category: 'Conférence', date: futureDate(1) });
  });

  it('liste tout, triés par date', async () => {
    const res = await api().get('/api/events');
    expect(res.status).toBe(200);
    expect(res.body.total).toBe(4);
    expect(res.body.events[0].title).toBe('Hackathon passé');
  });

  it('filtre par mot-clé (titre, description, lieu)', async () => {
    const res = await api().get('/api/events?search=docker');
    expect(res.body.events.map((e) => e.title)).toEqual(['Atelier Docker']);
    const byLoc = await api().get('/api/events?search=saint-louis');
    expect(byLoc.body.total).toBe(1);
  });

  it('filtre par catégorie', async () => {
    const res = await api().get('/api/events?category=Culture');
    expect(res.body.total).toBe(1);
    expect((await api().get('/api/events?category=Nope')).status).toBe(400);
  });

  it('filtre à venir / passés', async () => {
    const up = await api().get('/api/events?when=upcoming');
    expect(up.body.total).toBe(3);
    expect(up.body.events[0].title).toBe('Conférence IA');
    const past = await api().get('/api/events?when=past');
    expect(past.body.events.map((e) => e.title)).toEqual(['Hackathon passé']);
    expect(past.body.events[0].isPast).toBe(true);
  });

  it('pagine les résultats', async () => {
    const res = await api().get('/api/events?page=2&limit=3');
    expect(res.body.page).toBe(2);
    expect(res.body.totalPages).toBe(2);
    expect(res.body.events).toHaveLength(1);
  });

  it('liste les catégories', async () => {
    const res = await api().get('/api/events/categories');
    expect(res.body.categories).toContain('Conférence');
  });
});

describe('Inscriptions', () => {
  it('inscrit, refuse le doublon (409), puis désinscrit', async () => {
    const owner = await createUser();
    const guest = await createUser();
    const ev = await createEvent(owner.auth, { capacity: 2 });

    expect((await api().post(`/api/events/${ev.id}/register`)).status).toBe(401);

    const reg = await api().post(`/api/events/${ev.id}/register`).set(guest.auth);
    expect(reg.status).toBe(200);
    expect(reg.body.event.seatsLeft).toBe(1);
    expect(reg.body.event.isRegistered).toBe(true);

    const dup = await api().post(`/api/events/${ev.id}/register`).set(guest.auth);
    expect(dup.status).toBe(409);
    expect(dup.body.error).toMatch(/déjà inscrit/);

    const unreg = await api().delete(`/api/events/${ev.id}/register`).set(guest.auth);
    expect(unreg.status).toBe(200);
    expect(unreg.body.event.seatsLeft).toBe(2);
    expect(unreg.body.event.isRegistered).toBe(false);

    const unreg2 = await api().delete(`/api/events/${ev.id}/register`).set(guest.auth);
    expect(unreg2.status).toBe(409);
  });

  it('refuse quand l’événement est complet (409)', async () => {
    const owner = await createUser();
    const a = await createUser();
    const b = await createUser();
    const ev = await createEvent(owner.auth, { capacity: 1 });
    expect((await api().post(`/api/events/${ev.id}/register`).set(a.auth)).status).toBe(200);
    const full = await api().post(`/api/events/${ev.id}/register`).set(b.auth);
    expect(full.status).toBe(409);
    expect(full.body.error).toMatch(/complet/);
  });

  it('reste cohérent avec des inscriptions concurrentes', async () => {
    const owner = await createUser();
    const users = await Promise.all(Array.from({ length: 6 }, () => createUser()));
    const ev = await createEvent(owner.auth, { capacity: 3 });
    const results = await Promise.all(
      users.map((u) => api().post(`/api/events/${ev.id}/register`).set(u.auth))
    );
    expect(results.filter((r) => r.status === 200)).toHaveLength(3);
    expect(results.filter((r) => r.status === 409)).toHaveLength(3);
    const detail = await api().get(`/api/events/${ev.id}`);
    expect(detail.body.event.seatsLeft).toBe(0);
    expect(detail.body.event.attendeesCount).toBe(3);
  });

  it("l'organisateur ne peut pas s'inscrire et on ne peut pas s'inscrire à un événement passé", async () => {
    const owner = await createUser();
    const guest = await createUser();
    const ev = await createEvent(owner.auth);
    expect((await api().post(`/api/events/${ev.id}/register`).set(owner.auth)).status).toBe(409);
    const past = await createEvent(owner.auth, { date: pastDate(2) });
    const res = await api().post(`/api/events/${past.id}/register`).set(guest.auth);
    expect(res.status).toBe(409);
    expect(res.body.error).toMatch(/passé/);
  });

  it('404 pour un événement inexistant', async () => {
    const guest = await createUser();
    const res = await api().post('/api/events/64b7f0f0f0f0f0f0f0f0f0f0/register').set(guest.auth);
    expect(res.status).toBe(404);
  });

  it("l'organisateur voit la liste des participants, pas les autres", async () => {
    const owner = await createUser();
    const guest = await createUser({ name: 'Fatou Sall' });
    const ev = await createEvent(owner.auth);
    await api().post(`/api/events/${ev.id}/register`).set(guest.auth);
    const asOwner = await api().get(`/api/events/${ev.id}`).set(owner.auth);
    expect(asOwner.body.event.participants.map((p) => p.name)).toEqual(['Fatou Sall']);
    const asGuest = await api().get(`/api/events/${ev.id}`).set(guest.auth);
    expect(asGuest.body.event.participants).toBeUndefined();
    expect(asGuest.body.event.isRegistered).toBe(true);
  });
});

describe('Tableau de bord', () => {
  it('GET /api/me/events et /api/me/registrations', async () => {
    const alice = await createUser();
    const bob = await createUser();
    const e1 = await createEvent(alice.auth, { title: 'Événement Alice' });
    await createEvent(bob.auth, { title: 'Événement Bob' });
    await api().post(`/api/events/${e1.id}/register`).set(bob.auth);

    const mine = await api().get('/api/me/events').set(alice.auth);
    expect(mine.status).toBe(200);
    expect(mine.body.events.map((e) => e.title)).toEqual(['Événement Alice']);

    const regs = await api().get('/api/me/registrations').set(bob.auth);
    expect(regs.body.events.map((e) => e.title)).toEqual(['Événement Alice']);

    expect((await api().get('/api/me/events')).status).toBe(401);
    expect((await api().get('/api/me/registrations')).status).toBe(401);
  });
});
