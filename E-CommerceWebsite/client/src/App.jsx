import { Routes, Route } from 'react-router-dom';
import Header from './components/Header.jsx';
import Footer from './components/Footer.jsx';
import ProtectedRoute from './components/ProtectedRoute.jsx';
import ScrollToTop from './components/ScrollToTop.jsx';
import Home from './pages/Home.jsx';
import Catalog from './pages/Catalog.jsx';
import ProductDetail from './pages/ProductDetail.jsx';
import Cart from './pages/Cart.jsx';
import Checkout from './pages/Checkout.jsx';
import Login from './pages/Login.jsx';
import Register from './pages/Register.jsx';
import Orders from './pages/Orders.jsx';
import OrderDetail from './pages/OrderDetail.jsx';
import AdminProducts from './pages/admin/AdminProducts.jsx';
import AdminOrders from './pages/admin/AdminOrders.jsx';
import NotFound from './pages/NotFound.jsx';

export default function App() {
  return (
    <div className="app">
      <ScrollToTop />
      <Header />
      <main className="main">
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/produits" element={<Catalog />} />
          <Route path="/produits/:slug" element={<ProductDetail />} />
          <Route path="/panier" element={<Cart />} />
          <Route path="/connexion" element={<Login />} />
          <Route path="/inscription" element={<Register />} />
          <Route path="/commande" element={<ProtectedRoute><Checkout /></ProtectedRoute>} />
          <Route path="/mes-commandes" element={<ProtectedRoute><Orders /></ProtectedRoute>} />
          <Route path="/mes-commandes/:id" element={<ProtectedRoute><OrderDetail /></ProtectedRoute>} />
          <Route path="/admin" element={<ProtectedRoute admin><AdminProducts /></ProtectedRoute>} />
          <Route path="/admin/commandes" element={<ProtectedRoute admin><AdminOrders /></ProtectedRoute>} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </main>
      <Footer />
    </div>
  );
}
