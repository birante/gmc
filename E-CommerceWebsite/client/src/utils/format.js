const nf = new Intl.NumberFormat('fr-FR');

export const formatPrice = (value) => `${nf.format(Math.round(Number(value) || 0)).replace(/ | /g, ' ')} FCFA`;

export const formatDate = (iso) =>
  new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' });

export const STATUS_LABELS = {
  pending: 'En attente',
  paid: 'Payée',
  shipped: 'Expédiée',
  delivered: 'Livrée',
  cancelled: 'Annulée'
};

export const STATUS_FLOW = ['pending', 'paid', 'shipped', 'delivered'];
