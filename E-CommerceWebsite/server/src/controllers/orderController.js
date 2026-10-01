import { z } from 'zod';
import crypto from 'node:crypto';
import mongoose from 'mongoose';
import { Order, ORDER_STATUSES } from '../models/Order.js';
import { Product } from '../models/Product.js';
import { HttpError } from '../utils/httpError.js';

const objectId = z.string().refine((v) => mongoose.isValidObjectId(v), 'identifiant invalide');

export const createOrderSchema = z.object({
  items: z
    .array(z.object({ product: objectId, quantity: z.coerce.number().int().min(1).max(100) }))
    .min(1, 'le panier est vide')
    .max(50),
  shippingAddress: z.object({
    fullName: z.string().trim().min(2, 'requis').max(100),
    address: z.string().trim().min(3, 'requis').max(200),
    city: z.string().trim().min(2, 'requis').max(80),
    phone: z.string().trim().min(6, 'numéro invalide').max(30)
  })
});

export const statusSchema = z.object({ status: z.enum(ORDER_STATUSES) });

/** Restaure le stock de lignes déjà décrémentées. */
async function restock(lines) {
  await Promise.all(
    lines.map((l) => Product.updateOne({ _id: l.product }, { $inc: { stock: l.quantity } }))
  );
}

export async function createOrder(req, res) {
  // Fusionne les doublons du panier
  const merged = new Map();
  for (const { product, quantity } of req.body.items) {
    merged.set(product, (merged.get(product) || 0) + quantity);
  }

  const reserved = [];
  const items = [];
  try {
    for (const [productId, quantity] of merged) {
      // Décrément atomique conditionnel : aucune survente possible
      const product = await Product.findOneAndUpdate(
        { _id: productId, stock: { $gte: quantity } },
        { $inc: { stock: -quantity } },
        { new: true }
      );
      if (!product) {
        const exists = await Product.findById(productId).select('name stock');
        if (!exists) throw new HttpError(400, 'Un produit du panier n\'existe plus');
        throw new HttpError(
          400,
          `Stock insuffisant pour « ${exists.name} » (disponible : ${exists.stock})`
        );
      }
      reserved.push({ product: product._id, quantity });
      items.push({ product: product._id, name: product.name, price: product.price, quantity });
    }

    const total = items.reduce((sum, i) => sum + i.price * i.quantity, 0);
    const order = await Order.create({
      user: req.user._id,
      items,
      shippingAddress: req.body.shippingAddress,
      total
    });
    res.status(201).json(order);
  } catch (err) {
    await restock(reserved);
    throw err;
  }
}

async function findOrderFor(req) {
  if (!mongoose.isValidObjectId(req.params.id)) throw new HttpError(404, 'Commande introuvable');
  const order = await Order.findById(req.params.id);
  if (!order) throw new HttpError(404, 'Commande introuvable');
  if (req.user.role !== 'admin' && !order.user.equals(req.user._id)) {
    throw new HttpError(404, 'Commande introuvable');
  }
  return order;
}

export async function getOrder(req, res) {
  res.json(await findOrderFor(req));
}

export async function myOrders(req, res) {
  const orders = await Order.find({ user: req.user._id }).sort({ createdAt: -1 });
  res.json(orders);
}

export async function payOrder(req, res) {
  const order = await findOrderFor(req);
  if (!order.user.equals(req.user._id)) throw new HttpError(403, 'Seul le client peut payer sa commande');
  if (order.status !== 'pending') throw new HttpError(400, 'Cette commande ne peut plus être payée');
  order.status = 'paid';
  order.paymentRef = `PAY-${Date.now().toString(36).toUpperCase()}-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
  await order.save();
  res.json(order);
}

export async function allOrders(req, res) {
  const filter = {};
  if (req.query.status && ORDER_STATUSES.includes(req.query.status)) filter.status = req.query.status;
  const orders = await Order.find(filter).sort({ createdAt: -1 }).populate('user', 'name email');
  res.json(orders);
}

export async function updateStatus(req, res) {
  const order = await findOrderFor(req);
  const { status } = req.body;
  if (status === 'cancelled' && order.status !== 'cancelled') {
    await restock(order.items);
  } else if (order.status === 'cancelled' && status !== 'cancelled') {
    throw new HttpError(400, 'Une commande annulée ne peut pas être réactivée');
  }
  order.status = status;
  await order.save();
  await order.populate('user', 'name email');
  res.json(order);
}
