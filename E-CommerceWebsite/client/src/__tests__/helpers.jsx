import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '../context/AuthContext.jsx';
import { CartProvider } from '../context/CartContext.jsx';

export function renderWithProviders(ui, { route = '/' } = {}) {
  return render(
    <MemoryRouter initialEntries={[route]} future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <AuthProvider>
        <CartProvider>{ui}</CartProvider>
      </AuthProvider>
    </MemoryRouter>
  );
}

export const sampleProduct = {
  id: 'p1',
  slug: 'robe-wax',
  name: 'Robe wax',
  price: 18500,
  category: 'Mode',
  stock: 3,
  rating: 4.5,
  imageUrl: 'https://picsum.photos/seed/robe-wax/600/600'
};

export function mockFetch(handler) {
  return vi.spyOn(globalThis, 'fetch').mockImplementation(async (url, opts) => {
    const { status = 200, body } = (await handler(String(url), opts)) || {};
    return new Response(JSON.stringify(body ?? {}), { status, headers: { 'Content-Type': 'application/json' } });
  });
}
