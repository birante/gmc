import { screen, fireEvent } from '@testing-library/react';
import Header from '../components/Header.jsx';
import ProductCard from '../components/ProductCard.jsx';
import Cart from '../pages/Cart.jsx';
import { renderWithProviders, sampleProduct } from './helpers.jsx';

describe('Panier', () => {
  it('ajoute au panier depuis la carte produit et met à jour le compteur du header', () => {
    renderWithProviders(<><Header /><ProductCard product={sampleProduct} /></>);
    expect(screen.getByTestId('cart-count')).toHaveTextContent('0');
    const btn = screen.getByRole('button', { name: /ajouter robe wax/i });
    fireEvent.click(btn);
    fireEvent.click(btn);
    expect(screen.getByTestId('cart-count')).toHaveTextContent('2');
    const saved = JSON.parse(localStorage.getItem('boutik_cart'));
    expect(saved).toEqual([expect.objectContaining({ id: 'p1', quantity: 2 })]);
  });

  it('ne dépasse pas le stock disponible', () => {
    renderWithProviders(<><Header /><ProductCard product={sampleProduct} /></>);
    const btn = screen.getByRole('button', { name: /ajouter robe wax/i });
    for (let i = 0; i < 6; i++) fireEvent.click(btn);
    expect(screen.getByTestId('cart-count')).toHaveTextContent('3');
  });

  it('désactive le bouton pour un produit épuisé', () => {
    renderWithProviders(<ProductCard product={{ ...sampleProduct, stock: 0 }} />);
    expect(screen.getByRole('button', { name: /ajouter robe wax/i })).toBeDisabled();
  });

  it('restaure le panier depuis localStorage, change les quantités et calcule le total', () => {
    localStorage.setItem('boutik_cart', JSON.stringify([
      { ...sampleProduct, quantity: 1 },
      { id: 'p2', slug: 'miel', name: 'Miel', price: 6000, stock: 10, imageUrl: '', quantity: 2 }
    ]));
    renderWithProviders(<><Header /><Cart /></>);
    expect(screen.getByTestId('cart-count')).toHaveTextContent('3');
    expect(screen.getAllByText('30 500 FCFA').length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole('button', { name: /augmenter robe wax/i }));
    expect(screen.getAllByText('49 000 FCFA').length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole('button', { name: /retirer miel/i }));
    expect(screen.queryByText('Miel')).not.toBeInTheDocument();
    expect(screen.getByTestId('cart-count')).toHaveTextContent('2');

    fireEvent.click(screen.getByRole('button', { name: /vider le panier/i }));
    expect(screen.getByText(/votre panier est vide/i)).toBeInTheDocument();
  });
});
