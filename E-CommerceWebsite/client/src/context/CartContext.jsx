import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';

const CART_KEY = 'boutik_cart';
const CartContext = createContext(null);

function loadCart() {
  try {
    const raw = JSON.parse(localStorage.getItem(CART_KEY) || '[]');
    return Array.isArray(raw) ? raw.filter((i) => i && i.id && i.quantity > 0) : [];
  } catch {
    return [];
  }
}

const toItem = (p) => ({
  id: p.id || p._id,
  slug: p.slug,
  name: p.name,
  price: p.price,
  imageUrl: p.imageUrl,
  stock: p.stock
});

export function CartProvider({ children }) {
  const [items, setItems] = useState(loadCart);

  useEffect(() => {
    try { localStorage.setItem(CART_KEY, JSON.stringify(items)); } catch { /* ignore */ }
  }, [items]);

  const addItem = useCallback((product, quantity = 1) => {
    setItems((prev) => {
      const item = toItem(product);
      const existing = prev.find((i) => i.id === item.id);
      const max = item.stock ?? Infinity;
      if (existing) {
        return prev.map((i) => (i.id === item.id ? { ...i, ...item, quantity: Math.min(i.quantity + quantity, max) } : i));
      }
      return [...prev, { ...item, quantity: Math.min(quantity, max) }].filter((i) => i.quantity > 0);
    });
  }, []);

  const updateQuantity = useCallback((id, quantity) => {
    setItems((prev) =>
      prev
        .map((i) => (i.id === id ? { ...i, quantity: Math.max(0, Math.min(quantity, i.stock ?? Infinity)) } : i))
        .filter((i) => i.quantity > 0)
    );
  }, []);

  const removeItem = useCallback((id) => setItems((prev) => prev.filter((i) => i.id !== id)), []);
  const clear = useCallback(() => setItems([]), []);

  /** Met à jour prix/stock à partir des données serveur (synchronisation au checkout). */
  const syncWith = useCallback((freshProducts) => {
    const byId = new Map(freshProducts.filter(Boolean).map((p) => [p.id || p._id, p]));
    setItems((prev) =>
      prev
        .filter((i) => byId.has(i.id))
        .map((i) => {
          const p = byId.get(i.id);
          return { ...i, ...toItem(p), quantity: Math.min(i.quantity, p.stock) };
        })
        .filter((i) => i.quantity > 0)
    );
  }, []);

  const value = useMemo(() => {
    const count = items.reduce((s, i) => s + i.quantity, 0);
    const total = items.reduce((s, i) => s + i.quantity * i.price, 0);
    return { items, count, total, addItem, updateQuantity, removeItem, clear, syncWith };
  }, [items, addItem, updateQuantity, removeItem, clear, syncWith]);

  return <CartContext.Provider value={value}>{children}</CartContext.Provider>;
}

export const useCart = () => useContext(CartContext);
