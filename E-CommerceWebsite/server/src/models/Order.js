import mongoose from 'mongoose';

export const ORDER_STATUSES = ['pending', 'paid', 'shipped', 'delivered', 'cancelled'];

const itemSchema = new mongoose.Schema(
  {
    product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product', required: true },
    name: { type: String, required: true },
    price: { type: Number, required: true },
    quantity: { type: Number, required: true, min: 1 }
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    items: { type: [itemSchema], validate: (v) => v.length > 0 },
    shippingAddress: {
      fullName: { type: String, required: true },
      address: { type: String, required: true },
      city: { type: String, required: true },
      phone: { type: String, required: true }
    },
    total: { type: Number, required: true },
    status: { type: String, enum: ORDER_STATUSES, default: 'pending' },
    paymentRef: { type: String, default: null }
  },
  { timestamps: true }
);

orderSchema.set('toJSON', {
  versionKey: false,
  transform: (_doc, ret) => {
    ret.id = ret._id;
    return ret;
  }
});

export const Order = mongoose.model('Order', orderSchema);
