// Animation globale pour tous les boutons "Ajouter au panier"

// Fonction d'animation pour les boutons d'ajout au panier
function animateAddToCart(button) {
  if (!button) return;
  
  // Ajouter une classe d'animation
  button.classList.add('animate-pulse-once');
  
  // S'assurer que le bouton a position relative et overflow hidden
  if (window.getComputedStyle(button).position === 'static') {
    button.style.position = 'relative';
  }
  button.style.overflow = 'hidden';
  
  // Créer un effet de vague/ripple
  const ripple = document.createElement('span');
  ripple.className = 'ripple-effect';
  
  button.appendChild(ripple);
  
  // Retirer l'animation après un court délai
  setTimeout(() => {
    button.classList.remove('animate-pulse-once');
    if (ripple.parentNode) {
      ripple.parentNode.removeChild(ripple);
    }
  }, 600);
}

// Fonction pour détecter si un bouton/formulaire est un bouton d'ajout au panier
function isAddToCartButton(element) {
  // Vérifier si c'est un formulaire qui poste vers cart_items
  if (element.tagName === 'FORM') {
    const action = element.getAttribute('action') || '';
    return action.includes('/cart_items') || action.includes('cart_items');
  }
  
  // Vérifier si c'est un bouton dans un formulaire d'ajout au panier
  if (element.tagName === 'BUTTON' || element.tagName === 'INPUT') {
    const form = element.closest('form');
    if (form) {
      const action = form.getAttribute('action') || '';
      if (action.includes('/cart_items') || action.includes('cart_items')) {
        return true;
      }
    }
    
    // Vérifier le texte ou l'aria-label
    const text = (element.textContent || '').toLowerCase();
    const ariaLabel = (element.getAttribute('aria-label') || '').toLowerCase();
    return text.includes('ajouter au panier') || ariaLabel.includes('ajouter au panier') || 
           element.id === 'addToCartBtn';
  }
  
  return false;
}

// Utiliser la délégation d'événements pour capturer tous les clics sur les boutons d'ajout au panier
// Variable pour éviter les listeners dupliqués
let addToCartHandlerAttached = false;

function handleAddToCartClick(e) {
  let target = e.target;
  
  // Remonter jusqu'à trouver le bouton submit ou le formulaire
  while (target && target !== document.body) {
    if (target.tagName === 'BUTTON' || target.tagName === 'INPUT') {
      if (isAddToCartButton(target)) {
        animateAddToCart(target);
        break;
      }
    } else if (target.tagName === 'FORM' && isAddToCartButton(target)) {
      const submitBtn = target.querySelector('button[type="submit"], input[type="submit"]');
      if (submitBtn) {
        animateAddToCart(submitBtn);
      }
      break;
    }
    target = target.parentElement;
  }
}

// Fonction pour initialiser l'event listener (une seule fois)
function setupAddToCartAnimations() {
  // Ne pas ajouter plusieurs fois le même listener
  if (!addToCartHandlerAttached) {
    // Utiliser event delegation sur document pour capturer tous les clics
    document.addEventListener('click', handleAddToCartClick, true); // Utiliser capture phase
    addToCartHandlerAttached = true;
  }
}

// Initialiser au chargement
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', setupAddToCartAnimations);
} else {
  setupAddToCartAnimations();
}

// Réinitialiser après chaque navigation Turbo (mais ne pas dupliquer le listener)
document.addEventListener('turbo:load', function() {
  // Le listener est déjà attaché, pas besoin de le re-attacher
  // Mais on peut vérifier qu'il est toujours actif
  if (!addToCartHandlerAttached) {
    setupAddToCartAnimations();
  }
});

document.addEventListener('turbo:render', function() {
  if (!addToCartHandlerAttached) {
    setupAddToCartAnimations();
  }
});
