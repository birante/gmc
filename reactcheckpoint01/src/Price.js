import product from "./product";

function Price() {
  return (
    <p className="product-price">
      ${product.price.toFixed(2)}
    </p>
  );
}

export default Price;
