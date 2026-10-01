import { fileURLToPath } from 'node:url';
import mongoose from 'mongoose';
import { User } from './models/User.js';
import { Event } from './models/Event.js';

const DAY = 24 * 60 * 60 * 1000;
const at = (days, hour = 18) => {
  const d = new Date(Date.now() + days * DAY);
  d.setHours(hour, 0, 0, 0);
  return d;
};
const img = (seed) => `https://picsum.photos/seed/${seed}/800/400`;

export const DEMO_PASSWORD = 'password123';

export async function seedDatabase() {
  const aminata = new User({
    name: 'Aminata Diop',
    email: 'aminata@eventhub.dev',
    bio: 'Développeuse full-stack et organisatrice de meetups tech à Dakar.',
  });
  await aminata.setPassword(DEMO_PASSWORD);
  const moussa = new User({
    name: 'Moussa Ndiaye',
    email: 'moussa@eventhub.dev',
    bio: 'Animateur associatif, passionné de culture et de sport.',
  });
  await moussa.setPassword(DEMO_PASSWORD);
  await Promise.all([aminata.save(), moussa.save()]);

  const events = [
    {
      title: 'Meetup JavaScript Dakar',
      description: "Une soirée autour de l'écosystème JavaScript : React 19, Node.js 22 et retours d'expérience de la communauté. Pizza et networking offerts !",
      date: at(5, 18), location: 'Impact Hub, Dakar', category: 'Tech', capacity: 60,
      imageUrl: img('jsmeetup'), organizer: aminata._id, attendees: [moussa._id],
    },
    {
      title: 'Atelier : déployer une app MERN avec Docker',
      description: 'Atelier pratique de 3 heures : conteneuriser une application MERN, la publier sur un registre et la déployer avec Kamal. Apportez votre ordinateur.',
      date: at(12, 9), location: 'GOMYCODE, Dakar Plateau', category: 'Atelier', capacity: 20,
      imageUrl: img('dockerlab'), organizer: aminata._id, attendees: [],
    },
    {
      title: "Conférence : l'IA au service de la santé",
      description: "Chercheurs et startups présentent leurs travaux sur l'intelligence artificielle appliquée au diagnostic et à la surveillance épidémiologique.",
      date: at(20, 10), location: 'Université Cheikh Anta Diop', category: 'Conférence', capacity: 200,
      imageUrl: img('aihealth'), organizer: aminata._id, attendees: [moussa._id],
    },
    {
      title: 'Festival des musiques urbaines',
      description: 'Concerts live, open mic et exposition de street art. Une journée pour célébrer la scène urbaine sénégalaise.',
      date: at(9, 16), location: 'Place du Souvenir Africain', category: 'Culture', capacity: 500,
      imageUrl: img('urbanfest'), organizer: moussa._id, attendees: [aminata._id],
    },
    {
      title: 'Tournoi de football inter-associations',
      description: 'Tournoi à 7 ouvert à toutes les associations du quartier. Inscriptions par équipe, ambiance conviviale garantie.',
      date: at(15, 8), location: 'Stade Iba Mar Diop', category: 'Sport', capacity: 3,
      imageUrl: img('football'), organizer: moussa._id, attendees: [aminata._id],
    },
    {
      title: 'Journée de nettoyage de la plage',
      description: 'Rejoignez les bénévoles pour une matinée de nettoyage de la plage de Yoff. Gants et sacs fournis, petit-déjeuner offert.',
      date: at(3, 8), location: 'Plage de Yoff', category: 'Associatif', capacity: 40,
      imageUrl: img('beachclean'), organizer: moussa._id, attendees: [],
    },
    {
      title: 'Hackathon Open Data',
      description: 'Un week-end pour créer des applications à partir des données publiques. Prix pour les trois meilleures équipes.',
      date: at(-10, 9), location: 'Dakar Digital Hub', category: 'Tech', capacity: 80,
      imageUrl: img('hackathon'), organizer: aminata._id, attendees: [moussa._id],
    },
    {
      title: 'Soirée cinéma en plein air',
      description: 'Projection de courts-métrages de jeunes réalisateurs africains, suivie d’un débat avec les équipes de tournage.',
      date: at(-25, 20), location: 'Institut Français, Dakar', category: 'Culture', capacity: 120,
      imageUrl: img('cinema'), organizer: moussa._id, attendees: [aminata._id],
    },
  ];
  await Event.insertMany(events);
  return { users: 2, events: events.length };
}

/** Seed uniquement si la base est vide. */
export async function seedIfEmpty() {
  const [users, events] = await Promise.all([User.estimatedDocumentCount(), Event.estimatedDocumentCount()]);
  if (users > 0 || events > 0) return null;
  const result = await seedDatabase();
  console.log(`[seed] ${result.users} utilisateurs et ${result.events} événements créés (mot de passe : ${DEMO_PASSWORD})`);
  return result;
}

// Exécution directe : `node src/seed.js` (réinitialise la base)
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/eventhub';
  await mongoose.connect(uri);
  await Promise.all([User.deleteMany({}), Event.deleteMany({})]);
  const result = await seedDatabase();
  console.log('[seed] terminé', result);
  await mongoose.disconnect();
}
