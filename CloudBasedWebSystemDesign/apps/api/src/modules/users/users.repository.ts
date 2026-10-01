import type { Prisma, PrismaClient } from '@prisma/client';

const publicUserSelect = {
  id: true,
  email: true,
  name: true,
  role: true,
  active: true,
  clinicId: true,
  createdAt: true,
  clinic: { select: { id: true, name: true, code: true } },
} satisfies Prisma.UserSelect;

export type PublicUser = Prisma.UserGetPayload<{ select: typeof publicUserSelect }>;

export class UsersRepository {
  constructor(private readonly db: PrismaClient) {}

  findByEmail(email: string) {
    return this.db.user.findUnique({ where: { email: email.toLowerCase() } });
  }

  findById(id: string): Promise<PublicUser | null> {
    return this.db.user.findUnique({ where: { id }, select: publicUserSelect });
  }

  list(): Promise<PublicUser[]> {
    return this.db.user.findMany({ select: publicUserSelect, orderBy: { createdAt: 'asc' } });
  }

  create(data: Prisma.UserUncheckedCreateInput): Promise<PublicUser> {
    return this.db.user.create({ data: { ...data, email: data.email.toLowerCase() }, select: publicUserSelect });
  }

  update(id: string, data: Prisma.UserUncheckedUpdateInput): Promise<PublicUser> {
    return this.db.user.update({ where: { id }, data, select: publicUserSelect });
  }
}
