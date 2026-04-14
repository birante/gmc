class Product {
	constructor(id, name, price) {
		this.id = id;
		this.name = name;
		this.price = price;
	}
}

class ShoppingCartItem {
	constructor(product, quantity = 1) {
		this.product = product;
		this.quantity = quantity;
	}

	// Calcule le total pour cet article (prix unitaire x quantite)
	getTotalPrice() {
		return this.product.price * this.quantity;
	}
}

class ShoppingCart {
	constructor() {
		this.items = [];
	}

	// Retourne le nombre total d'articles (somme des quantites)
	getTotalItems() {
		return this.items.reduce((total, item) => total + item.quantity, 0);
	}

	addItem(product, quantity = 1) {
		const existingItem = this.items.find((item) => item.product.id === product.id);

		if (existingItem) {
			existingItem.quantity += quantity;
		} else {
			this.items.push(new ShoppingCartItem(product, quantity));
		}
	}

	// Si quantity est fourni, on reduit la quantite; sinon on retire completement l'article
	removeItem(productId, quantity = null) {
		const itemIndex = this.items.findIndex((item) => item.product.id === productId);

		if (itemIndex === -1) {
			console.log(`Produit avec id ${productId} introuvable dans le panier.`);
			return;
		}

		if (quantity === null || this.items[itemIndex].quantity <= quantity) {
			this.items.splice(itemIndex, 1);
		} else {
			this.items[itemIndex].quantity -= quantity;
		}
	}

	getCartTotal() {
		return this.items.reduce((total, item) => total + item.getTotalPrice(), 0);
	}

	displayCartItems() {
		console.log("\n--- PANIER ---");

		if (this.items.length === 0) {
			console.log("Le panier est vide.");
			return;
		}

		this.items.forEach((item) => {
			console.log(
				`${item.product.name} | Prix: ${item.product.price.toFixed(2)} | Quantite: ${item.quantity} | Total: ${item
					.getTotalPrice()
					.toFixed(2)}`
			);
		});

		console.log(`Total articles: ${this.getTotalItems()}`);
		console.log(`Montant total: ${this.getCartTotal().toFixed(2)}`);
	}
}

// ------------------ TESTS DU CHECKPOINT ------------------

// 1) Creer des produits
const product1 = new Product(1, "Laptop", 1200);
const product2 = new Product(2, "Souris", 25.5);
const product3 = new Product(3, "Clavier", 75);

// 2) Creer un panier
const cart = new ShoppingCart();

// 3) Ajouter des articles
cart.addItem(product1, 1);
cart.addItem(product2, 2);
cart.addItem(product3, 1);
cart.addItem(product2, 1); // Test d'augmentation de quantite sur un produit existant

// 4) Afficher le panier
console.log("Etat du panier apres ajouts:");
cart.displayCartItems();

// 5) Supprimer un article (partiellement)
cart.removeItem(2, 2); // Retire 2 souris sur la quantite existante
console.log("\nEtat du panier apres suppression partielle de l'article id=2:");
cart.displayCartItems();

// 6) Supprimer un article (completement)
cart.removeItem(1); // Retire le laptop completement
console.log("\nEtat du panier apres suppression complete de l'article id=1:");
cart.displayCartItems();
