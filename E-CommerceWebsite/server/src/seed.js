import mongoose from 'mongoose';
import { fileURLToPath } from 'node:url';
import { config } from './config.js';
import { Product } from './models/Product.js';
import { User } from './models/User.js';
import { slugify } from './utils/slugify.js';

const raw = [
  ['Boubou brodé homme', 'Mode', 35000, 'Grand boubou en bazin riche, broderies faites main à Dakar. Coupe ample et élégante pour les cérémonies.', 12, 4.7],
  ['Robe wax Ndeye', 'Mode', 18500, 'Robe mi-longue en tissu wax 100 % coton, motifs colorés, ceinture assortie.', 20, 4.5],
  ['Sandales en cuir artisanales', 'Mode', 12000, 'Sandales en cuir véritable tannées et cousues à la main par des artisans de Ngaye Mékhé.', 30, 4.3],
  ['Sac cabas en raphia', 'Mode', 9500, 'Sac tressé en raphia naturel, anses en cuir, idéal pour le marché ou la plage.', 25, 4.2],
  ['Smartphone Tecno Spark 20', 'Électronique', 95000, 'Écran 6,6", 128 Go de stockage, double SIM, batterie 5000 mAh longue durée.', 8, 4.1],
  ['Écouteurs sans fil Pro', 'Électronique', 15000, 'Écouteurs Bluetooth 5.3 avec boîtier de charge, réduction de bruit et 24 h d\'autonomie.', 40, 4.0],
  ['Enceinte Bluetooth portable', 'Électronique', 22000, 'Son puissant 20 W, étanche IPX6, autonomie 12 h, parfaite pour les sorties.', 15, 4.4],
  ['Power bank 20 000 mAh', 'Électronique', 13500, 'Batterie externe charge rapide, 2 ports USB + USB-C, affichage LED du niveau.', 35, 4.6],
  ['Café Touba moulu 500 g', 'Épicerie', 3500, 'Café traditionnel parfumé au djar (poivre de Guinée), torréfié artisanalement.', 100, 4.8],
  ['Bissap séché 1 kg', 'Épicerie', 2500, 'Fleurs d\'hibiscus séchées pour préparer le jus de bissap maison.', 80, 4.6],
  ['Miel de Casamance 500 g', 'Épicerie', 6000, 'Miel pur et naturel récolté dans les forêts de Casamance.', 45, 4.9],
  ['Huile d\'arachide artisanale 1 L', 'Épicerie', 2000, 'Huile d\'arachide pressée à froid, goût authentique du Saloum.', 60, 4.3],
  ['Panier tressé décoratif', 'Maison', 8000, 'Panier coloré tressé à la main, idéal pour le rangement ou la décoration.', 18, 4.5],
  ['Coussin en bogolan', 'Maison', 7500, 'Housse de coussin 45×45 cm en bogolan teint aux pigments naturels.', 22, 4.4],
  ['Théière marocaine inox', 'Maison', 11000, 'Théière traditionnelle pour l\'attaya, inox de qualité, 1 L.', 14, 4.7],
  ['Beurre de karité bio 250 g', 'Beauté', 4500, 'Beurre de karité pur non raffiné, nourrit la peau et les cheveux.', 50, 4.8],
  ['Savon noir naturel', 'Beauté', 1500, 'Savon noir à l\'huile d\'olive et au karité, exfoliant doux pour tout le corps.', 70, 4.2]
];

export const demoProducts = raw.map(([name, category, price, description, stock, rating]) => {
  const slug = slugify(name);
  return {
    name,
    slug,
    category,
    price,
    description,
    stock,
    rating,
    imageUrl: `https://picsum.photos/seed/${slug}/600/600`
  };
});

async function ensureUser(email, name, password, role) {
  if (await User.exists({ email })) return;
  await User.create({ email, name, role, passwordHash: await User.hashPassword(password) });
}

export async function seedIfEmpty({ log = true } = {}) {
  await ensureUser('admin@boutik.sn', 'Admin Boutik', config.adminPassword, 'admin');
  await ensureUser('demo@boutik.sn', 'Client Démo', 'password123', 'client');
  const count = await Product.estimatedDocumentCount();
  if (count > 0) {
    if (log) console.log(`Seed ignoré : ${count} produits déjà présents`);
    return false;
  }
  await Product.insertMany(demoProducts);
  if (log) console.log(`Seed : ${demoProducts.length} produits insérés`);
  return true;
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  mongoose
    .connect(config.mongoUri)
    .then(() => seedIfEmpty())
    .then(() => mongoose.disconnect())
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
