import mongoose from 'mongoose';

export const CATEGORIES = ['Tech', 'Atelier', 'Conférence', 'Culture', 'Sport', 'Associatif', 'Autre'];

const eventSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true, maxlength: 120 },
    description: { type: String, required: true, trim: true, maxlength: 5000 },
    date: { type: Date, required: true, index: true },
    location: { type: String, required: true, trim: true, maxlength: 200 },
    category: { type: String, enum: CATEGORIES, default: 'Autre', index: true },
    capacity: { type: Number, required: true, min: 1, max: 100000 },
    imageUrl: { type: String, default: '' },
    organizer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    attendees: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true, toJSON: { virtuals: true }, toObject: { virtuals: true } }
);

eventSchema.index({ attendees: 1 });

eventSchema.virtual('attendeesCount').get(function attendeesCount() {
  return (this.attendees || []).length;
});

eventSchema.virtual('seatsLeft').get(function seatsLeft() {
  return Math.max(0, this.capacity - (this.attendees || []).length);
});

eventSchema.virtual('isPast').get(function isPast() {
  return this.date ? this.date.getTime() < Date.now() : false;
});

eventSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: (_doc, ret) => {
    delete ret.id;
    ret.id = ret._id;
    return ret;
  },
});

export const Event = mongoose.model('Event', eventSchema);
