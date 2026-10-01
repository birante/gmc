import mongoose from 'mongoose';

const productSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 120 },
    slug: { type: String, required: true, unique: true, lowercase: true, trim: true },
    description: { type: String, default: '', maxlength: 3000 },
    price: {
      type: Number,
      required: true,
      min: 0,
      validate: { validator: Number.isInteger, message: 'Le prix doit être un entier (FCFA)' }
    },
    category: { type: String, required: true, trim: true, index: true },
    imageUrl: { type: String, default: '' },
    stock: { type: Number, required: true, min: 0, default: 0 },
    rating: { type: Number, min: 0, max: 5, default: 0 }
  },
  { timestamps: true }
);

productSchema.index({ name: 'text', description: 'text' });

productSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: (_doc, ret) => {
    ret.id = ret._id;
    return ret;
  }
});

export const Product = mongoose.model('Product', productSchema);
