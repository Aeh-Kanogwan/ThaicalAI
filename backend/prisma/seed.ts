import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

// NOTE: This is a curated STARTER set (40+ popular dishes) with realistic
// per-serving values. Per Rqm §4, the full production DB (Top 300-500 items)
// must be built by scraping + cleaning Thai FCD (สถาบันโภชนาการ ม.มหิดล) and
// กรมอนามัย. Values below are per the stated servingSize and rounded for dev.

const prisma = new PrismaClient();

type Seed = {
  nameTh: string;
  nameEn: string;
  keywords: string[];
  calories: number;
  protein: number;
  fat: number;
  carbs: number;
  sodium: number;
  servingSize?: string;
};

const foods: Seed[] = [
  { nameTh: 'ข้าวผัดกะเพราไก่', nameEn: 'Stir-fried Basil Chicken with Rice', keywords: ['กะเพรา', 'กระเพรา', 'ผัดกะเพรา', 'กะเพราไก่', 'basil', 'krapow'], calories: 620, protein: 28, fat: 22, carbs: 78, sodium: 1100 },
  { nameTh: 'ข้าวผัดกะเพราหมูสับ', nameEn: 'Stir-fried Basil Pork with Rice', keywords: ['กะเพราหมู', 'กระเพราหมู', 'หมูสับ', 'basil pork'], calories: 650, protein: 26, fat: 26, carbs: 78, sodium: 1150 },
  { nameTh: 'ไข่ดาว', nameEn: 'Fried Egg', keywords: ['ไข่ดาว', 'ไข่', 'fried egg', 'egg'], calories: 90, protein: 6, fat: 7, carbs: 0.5, sodium: 90, servingSize: '1 ฟอง' },
  { nameTh: 'ต้มยำกุ้ง', nameEn: 'Tom Yum Goong', keywords: ['ต้มยำ', 'ต้มยำกุ้ง', 'tom yum', 'tomyum'], calories: 220, protein: 18, fat: 10, carbs: 12, sodium: 1400, servingSize: '1 ถ้วย' },
  { nameTh: 'ผัดไทยกุ้งสด', nameEn: 'Pad Thai with Shrimp', keywords: ['ผัดไทย', 'ผัดไทยกุ้ง', 'pad thai', 'padthai'], calories: 550, protein: 20, fat: 18, carbs: 76, sodium: 1200 },
  { nameTh: 'ส้มตำไทย', nameEn: 'Green Papaya Salad', keywords: ['ส้มตำ', 'ตำไทย', 'som tam', 'somtam', 'papaya salad'], calories: 130, protein: 4, fat: 3, carbs: 24, sodium: 900, servingSize: '1 จาน' },
  { nameTh: 'ส้มตำปูปลาร้า', nameEn: 'Papaya Salad with Crab and Fermented Fish', keywords: ['ส้มตำปู', 'ปลาร้า', 'ตำปลาร้า', 'som tam pu'], calories: 150, protein: 6, fat: 3, carbs: 26, sodium: 1600 },
  { nameTh: 'ข้าวมันไก่', nameEn: 'Hainanese Chicken Rice', keywords: ['ข้าวมันไก่', 'ไก่ต้ม', 'chicken rice', 'khao man kai'], calories: 590, protein: 26, fat: 20, carbs: 72, sodium: 1000 },
  { nameTh: 'แกงเขียวหวานไก่', nameEn: 'Green Curry with Chicken', keywords: ['แกงเขียวหวาน', 'เขียวหวาน', 'green curry'], calories: 420, protein: 20, fat: 28, carbs: 22, sodium: 1100, servingSize: '1 ถ้วย' },
  { nameTh: 'ก๋วยเตี๋ยวเรือหมู', nameEn: 'Boat Noodles with Pork', keywords: ['ก๋วยเตี๋ยว', 'ก๋วยเตี๋ยวเรือ', 'boat noodle', 'kuaitiao'], calories: 350, protein: 18, fat: 12, carbs: 42, sodium: 1300, servingSize: '1 ชาม' },
  { nameTh: 'ข้าวเหนียวหมูปิ้ง', nameEn: 'Grilled Pork with Sticky Rice', keywords: ['หมูปิ้ง', 'ข้าวเหนียวหมูปิ้ง', 'ข้าวเหนียว', 'moo ping'], calories: 480, protein: 22, fat: 16, carbs: 62, sodium: 800 },
  { nameTh: 'ผัดซีอิ๊วหมู', nameEn: 'Stir-fried Noodles with Soy Sauce', keywords: ['ผัดซีอิ๊ว', 'ซีอิ๊ว', 'pad see ew'], calories: 560, protein: 20, fat: 20, carbs: 74, sodium: 1250 },
  { nameTh: 'ราดหน้าหมู', nameEn: 'Noodles in Gravy with Pork', keywords: ['ราดหน้า', 'rad na', 'radna'], calories: 500, protein: 20, fat: 16, carbs: 70, sodium: 1200 },
  { nameTh: 'ข้าวขาหมู', nameEn: 'Stewed Pork Leg with Rice', keywords: ['ขาหมู', 'ข้าวขาหมู', 'khao kha moo'], calories: 680, protein: 30, fat: 32, carbs: 66, sodium: 1400 },
  { nameTh: 'ข้าวหมูกรอบ', nameEn: 'Crispy Pork with Rice', keywords: ['หมูกรอบ', 'ข้าวหมูกรอบ', 'crispy pork'], calories: 700, protein: 24, fat: 40, carbs: 60, sodium: 1100 },
  { nameTh: 'ข้าวหมูแดง', nameEn: 'Red Barbecued Pork with Rice', keywords: ['หมูแดง', 'ข้าวหมูแดง', 'red pork'], calories: 560, protein: 24, fat: 16, carbs: 74, sodium: 1050 },
  { nameTh: 'ต้มข่าไก่', nameEn: 'Chicken in Coconut Soup', keywords: ['ต้มข่า', 'ต้มข่าไก่', 'tom kha'], calories: 300, protein: 16, fat: 22, carbs: 10, sodium: 1200, servingSize: '1 ถ้วย' },
  { nameTh: 'แกงส้มผักรวม', nameEn: 'Sour Curry with Mixed Vegetables', keywords: ['แกงส้ม', 'kaeng som', 'sour curry'], calories: 180, protein: 12, fat: 5, carbs: 20, sodium: 1300, servingSize: '1 ถ้วย' },
  { nameTh: 'มัสมั่นไก่', nameEn: 'Massaman Curry with Chicken', keywords: ['มัสมั่น', 'massaman'], calories: 460, protein: 22, fat: 28, carbs: 30, sodium: 1000, servingSize: '1 ถ้วย' },
  { nameTh: 'พะแนงหมู', nameEn: 'Panang Curry with Pork', keywords: ['พะแนง', 'panang', 'phanaeng'], calories: 440, protein: 20, fat: 30, carbs: 20, sodium: 1050, servingSize: '1 ถ้วย' },
  { nameTh: 'ไก่ทอด', nameEn: 'Fried Chicken', keywords: ['ไก่ทอด', 'fried chicken', 'gai tod'], calories: 300, protein: 22, fat: 20, carbs: 8, sodium: 600, servingSize: '1 ชิ้น' },
  { nameTh: 'ปลาทอดน้ำปลา', nameEn: 'Deep-fried Fish with Fish Sauce', keywords: ['ปลาทอด', 'fried fish'], calories: 350, protein: 30, fat: 22, carbs: 4, sodium: 900, servingSize: '1 ตัว' },
  { nameTh: 'ยำวุ้นเส้น', nameEn: 'Spicy Glass Noodle Salad', keywords: ['ยำวุ้นเส้น', 'วุ้นเส้น', 'yum woonsen'], calories: 250, protein: 14, fat: 8, carbs: 32, sodium: 1100 },
  { nameTh: 'ลาบหมู', nameEn: 'Spicy Minced Pork Salad', keywords: ['ลาบ', 'ลาบหมู', 'laab', 'larb'], calories: 280, protein: 22, fat: 16, carbs: 8, sodium: 1200 },
  { nameTh: 'น้ำตกหมู', nameEn: 'Spicy Grilled Pork Salad', keywords: ['น้ำตก', 'น้ำตกหมู', 'nam tok'], calories: 300, protein: 24, fat: 18, carbs: 8, sodium: 1150 },
  { nameTh: 'ข้าวผัดหมู', nameEn: 'Pork Fried Rice', keywords: ['ข้าวผัด', 'ข้าวผัดหมู', 'fried rice', 'khao pad'], calories: 560, protein: 20, fat: 18, carbs: 78, sodium: 950 },
  { nameTh: 'ข้าวผัดปู', nameEn: 'Crab Fried Rice', keywords: ['ข้าวผัดปู', 'crab fried rice'], calories: 540, protein: 22, fat: 16, carbs: 76, sodium: 1000 },
  { nameTh: 'ข้าวไข่เจียว', nameEn: 'Thai Omelette with Rice', keywords: ['ไข่เจียว', 'ข้าวไข่เจียว', 'omelette'], calories: 480, protein: 16, fat: 22, carbs: 56, sodium: 700 },
  { nameTh: 'ผัดผักบุ้งไฟแดง', nameEn: 'Stir-fried Morning Glory', keywords: ['ผักบุ้ง', 'ผัดผักบุ้ง', 'morning glory', 'pad pak boong'], calories: 150, protein: 5, fat: 10, carbs: 12, sodium: 900, servingSize: '1 จาน' },
  { nameTh: 'หอยทอด', nameEn: 'Fried Oyster Omelette', keywords: ['หอยทอด', 'oyster omelette', 'hoi tod'], calories: 500, protein: 18, fat: 28, carbs: 44, sodium: 1000 },
  { nameTh: 'ข้าวซอยไก่', nameEn: 'Northern Curry Noodle Soup with Chicken', keywords: ['ข้าวซอย', 'khao soi'], calories: 590, protein: 24, fat: 32, carbs: 52, sodium: 1300, servingSize: '1 ชาม' },
  { nameTh: 'ขนมจีนน้ำยา', nameEn: 'Rice Vermicelli with Fish Curry', keywords: ['ขนมจีน', 'น้ำยา', 'khanom jeen'], calories: 420, protein: 18, fat: 14, carbs: 56, sodium: 1200, servingSize: '1 จาน' },
  { nameTh: 'เย็นตาโฟ', nameEn: 'Pink Seafood Noodle Soup', keywords: ['เย็นตาโฟ', 'yentafo'], calories: 380, protein: 18, fat: 10, carbs: 52, sodium: 1400, servingSize: '1 ชาม' },
  { nameTh: 'บะหมี่หมูแดง', nameEn: 'Egg Noodles with Red Pork', keywords: ['บะหมี่', 'บะหมี่หมูแดง', 'bamee'], calories: 420, protein: 20, fat: 12, carbs: 56, sodium: 1150, servingSize: '1 ชาม' },
  { nameTh: 'ข้าวคลุกกะปิ', nameEn: 'Shrimp Paste Fried Rice', keywords: ['ข้าวคลุกกะปิ', 'กะปิ', 'khao kluk kapi'], calories: 520, protein: 16, fat: 18, carbs: 72, sodium: 1300 },
  { nameTh: 'ไข่พะโล้', nameEn: 'Stewed Egg and Pork in Five-Spice', keywords: ['พะโล้', 'ไข่พะโล้', 'palo'], calories: 380, protein: 20, fat: 22, carbs: 22, sodium: 1250, servingSize: '1 ถ้วย' },
  { nameTh: 'แกงจืดเต้าหู้หมูสับ', nameEn: 'Clear Soup with Tofu and Minced Pork', keywords: ['แกงจืด', 'เต้าหู้', 'clear soup'], calories: 160, protein: 14, fat: 8, carbs: 8, sodium: 900, servingSize: '1 ถ้วย' },
  { nameTh: 'ปอเปี๊ยะทอด', nameEn: 'Fried Spring Rolls', keywords: ['ปอเปี๊ยะ', 'ปอเปี๊ยะทอด', 'spring roll'], calories: 200, protein: 5, fat: 12, carbs: 20, sodium: 400, servingSize: '2 ชิ้น' },
  { nameTh: 'ข้าวเหนียวมะม่วง', nameEn: 'Mango Sticky Rice', keywords: ['ข้าวเหนียวมะม่วง', 'มะม่วง', 'mango sticky rice'], calories: 450, protein: 6, fat: 12, carbs: 82, sodium: 150, servingSize: '1 จาน' },
  { nameTh: 'กล้วยทอด', nameEn: 'Fried Banana', keywords: ['กล้วยทอด', 'fried banana'], calories: 280, protein: 3, fat: 14, carbs: 40, sodium: 100, servingSize: '1 จาน' },
  { nameTh: 'ชาไทยเย็น', nameEn: 'Thai Iced Milk Tea', keywords: ['ชาไทย', 'ชาเย็น', 'thai tea', 'cha yen'], calories: 230, protein: 3, fat: 6, carbs: 42, sodium: 80, servingSize: '1 แก้ว' },
  { nameTh: 'กาแฟเย็น', nameEn: 'Thai Iced Coffee', keywords: ['กาแฟเย็น', 'โอเลี้ยง', 'iced coffee'], calories: 210, protein: 2, fat: 5, carbs: 40, sodium: 60, servingSize: '1 แก้ว' },
  { nameTh: 'น้ำเปล่า', nameEn: 'Plain Water', keywords: ['น้ำเปล่า', 'น้ำ', 'water'], calories: 0, protein: 0, fat: 0, carbs: 0, sodium: 0, servingSize: '1 แก้ว' },
  { nameTh: 'ข้าวสวย', nameEn: 'Steamed Jasmine Rice', keywords: ['ข้าวสวย', 'ข้าว', 'steamed rice', 'rice'], calories: 200, protein: 4, fat: 0.4, carbs: 45, sodium: 2, servingSize: '1 ทัพพี' },
];

async function main() {
  console.log(`Seeding ${foods.length} foods...`);
  // Idempotent-ish: wipe existing foods then insert. Safe for dev seed.
  await prisma.food.deleteMany({});
  for (const f of foods) {
    await prisma.food.create({
      data: {
        nameTh: f.nameTh,
        nameEn: f.nameEn,
        keywords: f.keywords,
        calories: f.calories,
        protein: f.protein,
        fat: f.fat,
        carbs: f.carbs,
        sodium: f.sodium,
        servingSize: f.servingSize ?? '1 จาน',
        isVerified: true,
      },
    });
  }
  console.log(`Seeded ${foods.length} foods.`);

  // Test user with a filled profile.
  const email = 'test@calthai.app';
  const passwordHash = await bcrypt.hash('Test@12345', 10);
  const user = await prisma.user.upsert({
    where: { email },
    update: { passwordHash, name: 'Test User', tier: 'free' },
    create: { email, passwordHash, name: 'Test User', tier: 'free' },
  });
  await prisma.profile.upsert({
    where: { userId: user.id },
    update: {
      sex: 'male',
      age: 30,
      heightCm: 175,
      weightKg: 70,
      activityLevel: 'moderate',
      goal: 'maintain',
    },
    create: {
      userId: user.id,
      sex: 'male',
      age: 30,
      heightCm: 175,
      weightKg: 70,
      activityLevel: 'moderate',
      goal: 'maintain',
    },
  });
  console.log(`Seeded test user: ${email} / Test@12345`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
