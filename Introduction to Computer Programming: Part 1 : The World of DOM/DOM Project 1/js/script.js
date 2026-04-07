document.addEventListener("DOMContentLoaded", () => {
  const totalElement = document.querySelector(".total");
  const productCards = document.querySelectorAll(".list-products > .card-body");

  // Extrait la valeur numerique depuis "100 $".
  function getUnitPrice(card) {
    const priceText = card.querySelector(".unit-price").textContent;
    return parseInt(priceText, 10) || 0;
  }

  function getQuantityElement(card) {
    return card.querySelector(".quantity");
  }

  function getQuantityValue(card) {
    return parseInt(getQuantityElement(card).textContent, 10) || 0;
  }

  // Recalcule le total a partir des cartes encore presentes dans le DOM.
  function updateTotalPrice() {
    let total = 0;

    const activeCards = document.querySelectorAll(".list-products > .card-body");
    activeCards.forEach((card) => {
      const unitPrice = getUnitPrice(card);
      const quantity = getQuantityValue(card);
      total += unitPrice * quantity;
    });

    totalElement.textContent = `${total} $`;
  }

  // Chaque produit gere ses propres interactions (+, -, suppression, like).
  productCards.forEach((card) => {
    const plusButton = card.querySelector(".fa-plus-circle");
    const minusButton = card.querySelector(".fa-minus-circle");
    const deleteButton = card.querySelector(".fa-trash-alt");
    const heartButton = card.querySelector(".fa-heart");
    const quantityElement = getQuantityElement(card);

    plusButton.addEventListener("click", () => {
      const currentQuantity = getQuantityValue(card);
      quantityElement.textContent = currentQuantity + 1;
      updateTotalPrice();
    });

    minusButton.addEventListener("click", () => {
      const currentQuantity = getQuantityValue(card);
      if (currentQuantity > 0) {
        quantityElement.textContent = currentQuantity - 1;
        updateTotalPrice();
      }
    });

    deleteButton.addEventListener("click", () => {
      card.remove();
      updateTotalPrice();
    });

    heartButton.addEventListener("click", () => {
      const isLiked = heartButton.classList.toggle("liked");
      heartButton.style.color = isLiked ? "#e63946" : "black";
    });
  });

  updateTotalPrice();
});
