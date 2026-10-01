import { describe, it, expect, beforeAll, afterAll, beforeEach } from 'vitest';
import { startDb, stopDb, clearDb, api, registerUser, auth } from './setup.js';
import { Task } from '../src/models/Task.js';
import { User } from '../src/models/User.js';
import { seedDemo } from '../src/seed.js';

beforeAll(startDb);
afterAll(stopDb);

const DAY = 86400000;
let token;

beforeEach(async () => {
  await clearDb();
  ({ token } = await registerUser());
});

const create = (body, t = token) => api().post('/api/tasks').set(auth(t)).send(body);

describe('Tâches — CRUD', () => {
  it('exige une authentification (401)', async () => {
    expect((await api().get('/api/tasks')).status).toBe(401);
    expect((await api().post('/api/tasks').send({ title: 'x' })).status).toBe(401);
    expect((await api().get('/api/tasks/stats')).status).toBe(401);
  });

  it('crée une tâche avec les valeurs par défaut', async () => {
    const res = await create({ title: 'Ma tâche', description: 'Desc', deadline: new Date(Date.now() + DAY).toISOString() });
    expect(res.status).toBe(201);
    expect(res.body.task).toMatchObject({ title: 'Ma tâche', priority: 'medium', status: 'todo', completedAt: null, overdue: false });
    expect(res.body.task.id).toBeTruthy();
    expect(res.body.task.priorityRank).toBeUndefined();
  });

  it('valide la création (titre requis, priorité/statut/échéance valides)', async () => {
    expect((await create({ description: 'sans titre' })).status).toBe(400);
    expect((await create({ title: '   ' })).status).toBe(400);
    expect((await create({ title: 'x', priority: 'urgent' })).status).toBe(400);
    expect((await create({ title: 'x', status: 'archived' })).status).toBe(400);
    expect((await create({ title: 'x', deadline: 'pas une date' })).status).toBe(400);
  });

  it('lit, modifie et supprime une tâche', async () => {
    const { body } = await create({ title: 'A modifier' });
    const id = body.task.id;
    const got = await api().get(`/api/tasks/${id}`).set(auth(token));
    expect(got.status).toBe(200);
    expect(got.body.task.title).toBe('A modifier');

    const upd = await api().put(`/api/tasks/${id}`).set(auth(token)).send({ title: 'Modifiée', priority: 'high', deadline: null });
    expect(upd.status).toBe(200);
    expect(upd.body.task).toMatchObject({ title: 'Modifiée', priority: 'high', deadline: null });

    expect((await api().put(`/api/tasks/${id}`).set(auth(token)).send({ title: '' })).status).toBe(400);

    const del = await api().delete(`/api/tasks/${id}`).set(auth(token));
    expect(del.status).toBe(204);
    expect((await api().get(`/api/tasks/${id}`).set(auth(token))).status).toBe(404);
  });

  it('renvoie 404 pour un identifiant invalide ou inexistant', async () => {
    expect((await api().get('/api/tasks/nimportequoi').set(auth(token))).status).toBe(404);
    expect((await api().get('/api/tasks/507f1f77bcf86cd799439011').set(auth(token))).status).toBe(404);
  });

  it('PATCH /status change le statut et gère completedAt', async () => {
    const { body } = await create({ title: 'Statut' });
    const id = body.task.id;
    const done = await api().patch(`/api/tasks/${id}/status`).set(auth(token)).send({ status: 'done' });
    expect(done.status).toBe(200);
    expect(done.body.task.status).toBe('done');
    expect(done.body.task.completedAt).toBeTruthy();

    const back = await api().patch(`/api/tasks/${id}/status`).set(auth(token)).send({ status: 'in_progress' });
    expect(back.body.task.status).toBe('in_progress');
    expect(back.body.task.completedAt).toBeNull();

    expect((await api().patch(`/api/tasks/${id}/status`).set(auth(token)).send({ status: 'nope' })).status).toBe(400);
  });

  it('PUT avec status=done remplit aussi completedAt', async () => {
    const { body } = await create({ title: 'Via PUT' });
    const res = await api().put(`/api/tasks/${body.task.id}`).set(auth(token)).send({ status: 'done' });
    expect(res.body.task.completedAt).toBeTruthy();
  });

  it('marque une tâche en retard (overdue)', async () => {
    const res = await create({ title: 'En retard', deadline: new Date(Date.now() - DAY).toISOString() });
    expect(res.body.task.overdue).toBe(true);
    const done = await api().patch(`/api/tasks/${res.body.task.id}/status`).set(auth(token)).send({ status: 'done' });
    expect(done.body.task.overdue).toBe(false);
  });
});

describe('Tâches — isolation entre utilisateurs', () => {
  it('un utilisateur ne voit ni ne modifie jamais les tâches d’un autre (404)', async () => {
    const other = await registerUser();
    const { body } = await create({ title: 'Secret de A' });
    const id = body.task.id;
    const t2 = other.token;

    const list = await api().get('/api/tasks').set(auth(t2));
    expect(list.body.tasks).toHaveLength(0);
    const search = await api().get('/api/tasks?search=Secret').set(auth(t2));
    expect(search.body.tasks).toHaveLength(0);

    expect((await api().get(`/api/tasks/${id}`).set(auth(t2))).status).toBe(404);
    expect((await api().put(`/api/tasks/${id}`).set(auth(t2)).send({ title: 'Piraté' })).status).toBe(404);
    expect((await api().patch(`/api/tasks/${id}/status`).set(auth(t2)).send({ status: 'done' })).status).toBe(404);
    expect((await api().delete(`/api/tasks/${id}`).set(auth(t2))).status).toBe(404);

    const stats = await api().get('/api/tasks/stats').set(auth(t2));
    expect(stats.body.total).toBe(0);

    const intact = await Task.findById(id);
    expect(intact.title).toBe('Secret de A');
    expect(intact.status).toBe('todo');
  });

  it('ignore un champ owner fourni par le client', async () => {
    const other = await registerUser();
    const res = await create({ title: 'Injection', owner: other.user.id });
    expect(res.status).toBe(201);
    expect((await api().get('/api/tasks').set(auth(other.token))).body.tasks).toHaveLength(0);
    expect((await api().get('/api/tasks').set(auth(token))).body.tasks).toHaveLength(1);
  });
});

describe('Tâches — filtres, recherche et tri', () => {
  beforeEach(async () => {
    await create({ title: 'Acheter du pain', description: 'Boulangerie', priority: 'low', status: 'todo', deadline: new Date(Date.now() + 5 * DAY).toISOString() });
    await create({ title: 'Rapport mensuel', description: 'Envoyer au MANAGER', priority: 'high', status: 'in_progress', deadline: new Date(Date.now() + 1 * DAY).toISOString() });
    await create({ title: 'Sport', description: 'Course (5km) + étirements', priority: 'medium', status: 'done', deadline: new Date(Date.now() + 3 * DAY).toISOString() });
    await create({ title: 'Lire un livre', priority: 'high', status: 'todo' });
  });

  const list = (qs) => api().get(`/api/tasks${qs}`).set(auth(token));

  it('filtre par statut', async () => {
    const res = await list('?status=todo');
    expect(res.body.tasks.map((t) => t.title).sort()).toEqual(['Acheter du pain', 'Lire un livre']);
    expect((await list('?status=done')).body.tasks).toHaveLength(1);
    expect((await list('?status=invalide')).status).toBe(400);
  });

  it('recherche insensible à la casse dans titre et description', async () => {
    expect((await list('?search=RAPPORT')).body.tasks.map((t) => t.title)).toEqual(['Rapport mensuel']);
    expect((await list('?search=manager')).body.tasks.map((t) => t.title)).toEqual(['Rapport mensuel']);
    expect((await list('?search=boulangerie&status=todo')).body.tasks).toHaveLength(1);
  });

  it('échappe les caractères spéciaux des regex', async () => {
    const res = await list(`?search=${encodeURIComponent('(5km)')}`);
    expect(res.status).toBe(200);
    expect(res.body.tasks.map((t) => t.title)).toEqual(['Sport']);
    const star = await list(`?search=${encodeURIComponent('.*')}`);
    expect(star.body.tasks).toHaveLength(0);
  });

  it('trie par priorité de façon logique (high > medium > low)', async () => {
    const desc = (await list('?sort=-priority')).body.tasks.map((t) => t.priority);
    expect(desc).toEqual(['high', 'high', 'medium', 'low']);
    const asc = (await list('?sort=priority')).body.tasks.map((t) => t.priority);
    expect(asc).toEqual(['low', 'medium', 'high', 'high']);
  });

  it('trie par échéance (sans échéance en dernier)', async () => {
    const asc = (await list('?sort=deadline')).body.tasks.map((t) => t.title);
    expect(asc).toEqual(['Rapport mensuel', 'Sport', 'Acheter du pain', 'Lire un livre']);
    const desc = (await list('?sort=-deadline')).body.tasks.map((t) => t.title);
    expect(desc).toEqual(['Acheter du pain', 'Sport', 'Rapport mensuel', 'Lire un livre']);
  });

  it('trie par date de création', async () => {
    const asc = (await list('?sort=createdAt')).body.tasks.map((t) => t.title);
    expect(asc[0]).toBe('Acheter du pain');
    const desc = (await list('?sort=-createdAt')).body.tasks.map((t) => t.title);
    expect(desc[0]).toBe('Lire un livre');
    expect((await list('?sort=title')).status).toBe(400);
  });
});

describe('Tâches — statistiques', () => {
  it('calcule total, répartition, retards et % terminé', async () => {
    await create({ title: 'a', status: 'done' });
    await create({ title: 'b', status: 'in_progress', deadline: new Date(Date.now() - DAY).toISOString() });
    await create({ title: 'c', status: 'todo', deadline: new Date(Date.now() - 2 * DAY).toISOString() });
    await create({ title: 'd', status: 'done', deadline: new Date(Date.now() - DAY).toISOString() });
    const res = await api().get('/api/tasks/stats').set(auth(token));
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ total: 4, byStatus: { todo: 1, in_progress: 1, done: 2 }, overdue: 2, completionRate: 50 });
  });

  it('renvoie des zéros sans tâche', async () => {
    const res = await api().get('/api/tasks/stats').set(auth(token));
    expect(res.body).toEqual({ total: 0, byStatus: { todo: 0, in_progress: 0, done: 0 }, overdue: 0, completionRate: 0 });
  });
});

describe('Seed de démo', () => {
  it('crée le compte démo et ses tâches uniquement si la base est vide', async () => {
    expect(await seedDemo()).toBe(false); // un utilisateur existe déjà
    await clearDb();
    expect(await seedDemo()).toBe(true);
    const demo = await User.findOne({ email: 'demo@taskflow.sn' });
    expect(demo).toBeTruthy();
    expect(await Task.countDocuments({ owner: demo._id })).toBe(8);
    const login = await api().post('/api/auth/login').send({ email: 'demo@taskflow.sn', password: 'password123' });
    expect(login.status).toBe(200);
  });
});
