import { fileURLToPath } from 'node:url';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import { User } from './models/User.js';
import { Task } from './models/Task.js';

const DAY = 24 * 60 * 60 * 1000;
const inDays = (n) => new Date(Date.now() + n * DAY);

export const DEMO_EMAIL = 'demo@taskflow.sn';

export async function seedDemo({ force = false } = {}) {
  if (!force && (await User.estimatedDocumentCount()) > 0) return false;
  if (force) {
    const existing = await User.findOne({ email: DEMO_EMAIL });
    if (existing) {
      await Task.deleteMany({ owner: existing._id });
      await existing.deleteOne();
    }
  }
  const user = await User.create({
    name: 'Compte Démo',
    email: DEMO_EMAIL,
    passwordHash: await bcrypt.hash('password123', 10),
  });
  const tasks = [
    { title: 'Préparer la présentation du projet', description: 'Slides pour la soutenance GOMYCODE : architecture MERN et démo.', deadline: inDays(3), priority: 'high', status: 'in_progress' },
    { title: 'Corriger le bug de connexion', description: 'Le jeton expiré ne redirige pas vers la page de connexion.', deadline: inDays(-2), priority: 'high', status: 'todo' },
    { title: 'Rédiger la documentation API', description: 'Décrire tous les endpoints dans le Readme.', deadline: inDays(7), priority: 'medium', status: 'todo' },
    { title: 'Faire les courses', description: 'Riz, poisson, légumes et fruits pour la semaine.', deadline: inDays(1), priority: 'low', status: 'todo' },
    { title: 'Réviser les hooks React', description: 'useEffect, useMemo, useCallback et hooks personnalisés.', deadline: inDays(-5), priority: 'medium', status: 'in_progress' },
    { title: 'Configurer le déploiement Kamal', description: 'deploy.yml, secrets et accessoire MongoDB.', deadline: inDays(-1), priority: 'high', status: 'done' },
    { title: 'Appeler le service client', description: 'Demander le suivi de la commande internet.', deadline: null, priority: 'low', status: 'done' },
    { title: 'Écrire les tests d’intégration', description: 'Supertest + mongodb-memory-server pour les routes des tâches.', deadline: inDays(10), priority: 'medium', status: 'todo' },
  ];
  for (const t of tasks) {
    // save() pour déclencher les hooks (priorityRank, completedAt)
    await new Task({ ...t, owner: user._id }).save();
  }
  return true;
}

// Exécution directe : node src/seed.js
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/taskflow';
  await mongoose.connect(uri);
  await seedDemo({ force: true });
  console.log(`Seed terminé : ${DEMO_EMAIL} / password123`);
  await mongoose.disconnect();
}
