import product from "./product";

function Image() {
  return (
    <img
      src={product.image}
      alt={product.name}
      className="product-image"
    />
  );
}

export default Image;
