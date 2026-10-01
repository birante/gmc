import mongoose from 'mongoose';

export const PRIORITIES = ['low', 'medium', 'high'];
export const STATUSES = ['todo', 'in_progress', 'done'];
export const PRIORITY_RANK = { low: 1, medium: 2, high: 3 };

const taskSchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true, trim: true, maxlength: 200 },
    description: { type: String, trim: true, default: '', maxlength: 5000 },
    deadline: { type: Date, default: null },
    priority: { type: String, enum: PRIORITIES, default: 'medium' },
    priorityRank: { type: Number, default: PRIORITY_RANK.medium },
    status: { type: String, enum: STATUSES, default: 'todo' },
    completedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

taskSchema.index({ owner: 1, status: 1 });
taskSchema.index({ owner: 1, deadline: 1 });

// Maintient le rang de priorité (tri logique high > medium > low) et la date de complétion
taskSchema.pre('save', function syncDerived(next) {
  this.priorityRank = PRIORITY_RANK[this.priority] || PRIORITY_RANK.medium;
  if (this.isModified('status')) {
    if (this.status === 'done') {
      if (!this.completedAt) this.completedAt = new Date();
    } else {
      this.completedAt = null;
    }
  }
  next();
});

taskSchema.virtual('overdue').get(function overdue() {
  return Boolean(this.deadline && this.status !== 'done' && this.deadline.getTime() < Date.now());
});

taskSchema.set('toJSON', {
  virtuals: true,
  transform: (_doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    delete ret.priorityRank;
    return ret;
  },
});

export const Task = mongoose.model('Task', taskSchema);
