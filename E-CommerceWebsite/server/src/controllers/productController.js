import { z } from 'zod';
import mongoose from 'mongoose';
import { Product } from '../models/Product.js';
import { HttpError } from '../utils/httpError.js';
import { slugify } from '../utils/slugify.js';

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export const listQuerySchema = z.object({
  search: z.string().trim().max(100).optional(),
  category: z.string().trim().max(60).optional(),
  minPrice: z.coerce.number().int().min(0).optional(),
  maxPrice: z.coerce.number().int().min(0).optional(),
  sort: z.enum(['price_asc', 'price_desc', 'newest', 'rating']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(12)
});

const productBase = {
  name: z.string().trim().min(2, 'au moins 2 caractères').max(120),
  slug: z.string().trim().max(80).optional(),
  description: z.string().max(3000).optional(),
  price: z.coerce.number().int('doit être un entier').min(0, 'doit être positif'),
  category: z.string().trim().min(2, 'requis').max(60),
  imageUrl: z.union([z.string().url('URL invalide'), z.literal('')]).optional(),
  stock: z.coerce.number().int('doit être un entier').min(0, 'doit être positif'),
  rating: z.coerce.number().min(0).max(5).optional()
};

export const productCreateSchema = z.object(productBase);
export const productUpdateSchema = z.object(productBase).partial();

export async function listProducts(req, res) {
  const q = req.validated;
  const filter = {};
  if (q.search) {
    const rx = new RegExp(escapeRegex(q.search), 'i');
    filter.$or = [{ name: rx }, { description: rx }, { category: rx }];
  }
  if (q.category) filter.category = q.category;
  if (q.minPrice !== undefined || q.maxPrice !== undefined) {
    filter.price = {};
    if (q.minPrice !== undefined) filter.price.$gte = q.minPrice;
    if (q.maxPrice !== undefined) filter.price.$lte = q.maxPrice;
  }
  const sortMap = {
    price_asc: { price: 1, _id: 1 },
    price_desc: { price: -1, _id: 1 },
    newest: { createdAt: -1, _id: -1 },
    rating: { rating: -1, _id: 1 }
  };
  const sort = sortMap[q.sort] || sortMap.newest;
  const [items, total] = await Promise.all([
    Product.find(filter).sort(sort).skip((q.page - 1) * q.limit).limit(q.limit),
    Product.countDocuments(filter)
  ]);
  res.json({ items, total, page: q.page, limit: q.limit, pages: Math.max(1, Math.ceil(total / q.limit)) });
}

export async function getProduct(req, res) {
  const { slug } = req.params;
  let product = await Product.findOne({ slug: slug.toLowerCase() });
  if (!product && mongoose.isValidObjectId(slug)) product = await Product.findById(slug);
  if (!product) throw new HttpError(404, 'Produit introuvable');
  res.json(product);
}

export async function listCategories(_req, res) {
  const rows = await Product.aggregate([
    { $group: { _id: '$category', count: { $sum: 1 } } },
    { $sort: { _id: 1 } }
  ]);
  res.json(rows.map((r) => ({ name: r._id, count: r.count })));
}

async function uniqueSlug(base, excludeId) {
  const root = slugify(base) || 'produit';
  let slug = root;
  let i = 2;
  while (await Product.exists({ slug, ...(excludeId ? { _id: { $ne: excludeId } } : {}) })) {
    slug = `${root}-${i++}`;
  }
  return slug;
}

export async function createProduct(req, res) {
  const data = { ...req.body };
  data.slug = await uniqueSlug(data.slug || data.name);
  if (!data.imageUrl) data.imageUrl = `https://picsum.photos/seed/${data.slug}/600/600`;
  const product = await Product.create(data);
  res.status(201).json(product);
}

export async function updateProduct(req, res) {
  if (!mongoose.isValidObjectId(req.params.id)) throw new HttpError(404, 'Produit introuvable');
  const product = await Product.findById(req.params.id);
  if (!product) throw new HttpError(404, 'Produit introuvable');
  const data = { ...req.body };
  if (data.slug) data.slug = await uniqueSlug(data.slug, product._id);
  Object.assign(product, data);
  await product.save();
  res.json(product);
}

export async function deleteProduct(req, res) {
  if (!mongoose.isValidObjectId(req.params.id)) throw new HttpError(404, 'Produit introuvable');
  const product = await Product.findByIdAndDelete(req.params.id);
  if (!product) throw new HttpError(404, 'Produit introuvable');
  res.status(204).end();
}
