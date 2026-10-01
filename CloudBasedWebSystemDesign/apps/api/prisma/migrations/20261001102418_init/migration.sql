-- CreateEnum
CREATE TYPE "Role" AS ENUM ('ADMIN', 'CLINICIAN');

-- CreateEnum
CREATE TYPE "Sex" AS ENUM ('F', 'M');

-- CreateTable
CREATE TABLE "Clinic" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "region" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Clinic_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'CLINICIAN',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "clinicId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Patient" (
    "id" TEXT NOT NULL,
    "referenceCode" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "sex" "Sex" NOT NULL,
    "dateOfBirth" DATE NOT NULL,
    "guardianName" TEXT NOT NULL,
    "guardianPhone" TEXT NOT NULL,
    "address" TEXT,
    "clinicId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Patient_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vaccine" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "antigen" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "doseNumber" INTEGER NOT NULL,
    "recommendedAgeDays" INTEGER NOT NULL,
    "description" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "Vaccine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Immunization" (
    "id" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "vaccineId" TEXT NOT NULL,
    "scheduledDate" DATE NOT NULL,
    "administeredDate" DATE,
    "administeredById" TEXT,
    "lotNumber" TEXT,
    "notes" TEXT,
    "reminderSentAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Immunization_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Clinic_code_key" ON "Clinic"("code");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_clinicId_idx" ON "User"("clinicId");

-- CreateIndex
CREATE UNIQUE INDEX "Patient_referenceCode_key" ON "Patient"("referenceCode");

-- CreateIndex
CREATE INDEX "Patient_clinicId_lastName_idx" ON "Patient"("clinicId", "lastName");

-- CreateIndex
CREATE UNIQUE INDEX "Vaccine_code_key" ON "Vaccine"("code");

-- CreateIndex
CREATE INDEX "Immunization_scheduledDate_administeredDate_idx" ON "Immunization"("scheduledDate", "administeredDate");

-- CreateIndex
CREATE UNIQUE INDEX "Immunization_patientId_vaccineId_key" ON "Immunization"("patientId", "vaccineId");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "Clinic"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Patient" ADD CONSTRAINT "Patient_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "Clinic"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Immunization" ADD CONSTRAINT "Immunization_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "Patient"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Immunization" ADD CONSTRAINT "Immunization_vaccineId_fkey" FOREIGN KEY ("vaccineId") REFERENCES "Vaccine"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Immunization" ADD CONSTRAINT "Immunization_administeredById_fkey" FOREIGN KEY ("administeredById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
