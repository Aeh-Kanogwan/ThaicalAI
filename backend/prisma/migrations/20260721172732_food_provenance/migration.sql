-- AlterTable
ALTER TABLE "foods" ADD COLUMN     "importedAt" TIMESTAMP(3),
ADD COLUMN     "source" TEXT,
ADD COLUMN     "sourceRef" TEXT,
ADD COLUMN     "sourceUrl" TEXT;
