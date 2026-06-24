--[[
    Arab City v2.0 - Constants
    All game configuration in one place.
]]

local Constants = {}

Constants.VERSION = "2.0.0"
Constants.GAME_NAME = "Arab City"
Constants.DATASTORE_KEY = "ArabCity_PlayerData_v2"
Constants.BAN_STORE_KEY = "ArabCity_Bans_v2"

-- Owner / admin user IDs
Constants.OWNER_USER_IDS = {
    [1] = true, -- placeholder, replace with real owner ID
}

Constants.WELCOME_REWARD = 10000

-- Economy
Constants.CURRENCY_NAME = "Cash"
Constants.START_CASH = 10000
Constants.MAX_CASH = 999999999

-- Jobs
Constants.DEFAULT_JOB = "restaurant_worker"

Constants.JOBS = {
    { id = "restaurant_worker", name = "عامل مطعم", salary = 120, icon = "🍽️" },
    { id = "taxi",       name = "سائق تاكسي",  salary = 150, icon = "🚕" },
    { id = "police",     name = "شرطي",        salary = 200, icon = "👮" },
    { id = "doctor",     name = "طبيب",        salary = 250, icon = "🏥" },
    { id = "firefighter",name = "إطفائي",      salary = 180, icon = "🚒" },
    { id = "mechanic",   name = "ميكانيكي",    salary = 170, icon = "🔧" },
    { id = "chef",       name = "طباخ",        salary = 160, icon = "👨‍🍳" },
    { id = "pilot",      name = "طيار",        salary = 300, icon = "✈️" },
    { id = "photographer",name = "مصور",       salary = 140, icon = "📸" },
}

-- Vehicles
Constants.VEHICLES = {
    { id = "sedan",     name = "سيارة عادية",   price = 5000,   speed = 60  },
    { id = "sport",     name = "سيارة رياضية",  price = 25000,  speed = 100 },
    { id = "suv",       name = "جيب",           price = 15000,  speed = 70  },
    { id = "luxury",    name = "سيارة فاخرة",   price = 50000,  speed = 90  },
    { id = "truck",     name = "شاحنة",         price = 20000,  speed = 50  },
    { id = "motorcycle",name = "دراجة نارية",   price = 8000,   speed = 80  },
    { id = "bus",       name = "باص",           price = 30000,  speed = 55  },
}

-- Properties / Real Estate
Constants.PROPERTIES = {
    { id = "small_house",  name = "بيت صغير",    price = 10000  },
    { id = "apartment",    name = "شقة",         price = 20000  },
    { id = "villa",        name = "فيلا",        price = 50000  },
    { id = "mansion",      name = "قصر",         price = 150000 },
    { id = "penthouse",    name = "بنتهاوس",     price = 100000 },
}

-- Shop items
Constants.SHOP_ITEMS = {
    { id = "camera_basic",   name = "كاميرا عادية",   price = 2000,  category = "tools"    },
    { id = "camera_pro",     name = "كاميرا احترافية", price = 8000,  category = "tools"    },
    { id = "phone",          name = "هاتف",           price = 3000,  category = "tools"    },
    { id = "radio",          name = "راديو",          price = 1500,  category = "tools"    },
    { id = "hat_cap",        name = "قبعة",           price = 500,   category = "clothing" },
    { id = "glasses",        name = "نظارات",         price = 800,   category = "clothing" },
    { id = "backpack",       name = "حقيبة ظهر",      price = 1200,  category = "clothing" },
    { id = "watch_gold",     name = "ساعة ذهبية",     price = 5000,  category = "accessories" },
    { id = "necklace",       name = "قلادة",          price = 3500,  category = "accessories" },
}

-- Redeemable Codes
Constants.CODES = {
    ["ARAB2024"]    = { reward = 1000,  description = "كود ترحيبي" },
    ["CITY500"]     = { reward = 500,   description = "مكافأة المدينة" },
    ["VIP2024"]     = { reward = 2500,  description = "كود VIP" },
    ["WELCOME"]     = { reward = 1500,  description = "أهلاً وسهلاً" },
    ["BOOST"]       = { reward = 3000,  description = "كود بوست" },
}

-- Missions
Constants.MISSIONS = {
    { id = "visit_hospital",  name = "زيارة المستشفى",    reward = 200,  description = "اذهب إلى المستشفى" },
    { id = "visit_bank",      name = "زيارة البنك",       reward = 200,  description = "اذهب إلى البنك" },
    { id = "buy_car",         name = "اشتري سيارة",       reward = 500,  description = "اشتري أول سيارة" },
    { id = "buy_house",       name = "اشتري بيت",         reward = 1000, description = "اشتري أول بيت" },
    { id = "get_job",         name = "احصل على وظيفة",     reward = 300,  description = "تقدم لوظيفة" },
    { id = "earn_10k",        name = "اجمع 10,000$",      reward = 1000, description = "اجمع عشرة آلاف دولار" },
    { id = "visit_mall",      name = "زيارة المول",        reward = 200,  description = "اذهب إلى المول" },
    { id = "take_photo",      name = "التقط صورة",        reward = 300,  description = "التقط صورة بالكاميرا" },
}

-- Game Passes (IDs are placeholders — set real IDs in Roblox dashboard)
Constants.GAME_PASSES = {
    { id = "vip",         name = "VIP",           price = 99,   multiplier = 1.5 },
    { id = "premium",     name = "Premium",       price = 199,  multiplier = 2.0 },
    { id = "elite",       name = "Elite",         price = 499,  multiplier = 2.5 },
    { id = "legend",      name = "Legend",        price = 999,  multiplier = 3.0 },
    { id = "double_cash", name = "مضاعفة الفلوس", price = 149,  multiplier = 2.0 },
    { id = "speed",       name = "سرعة إضافية",   price = 49,   multiplier = 1.0 },
    { id = "radio_dj",    name = "Radio DJ",      price = 79,   multiplier = 1.0 },
}

-- XP / Leveling
Constants.XP_PER_LEVEL = 1000
Constants.MAX_LEVEL = 100
Constants.XP_SOURCES = {
    job_complete = 50,
    mission_complete = 100,
    purchase = 10,
    daily_login = 200,
    chat_message = 5,
}

-- Pets
Constants.PETS = {
    { id = "cat",    name = "قطة",    price = 3000,  speed = 16 },
    { id = "dog",    name = "كلب",    price = 3000,  speed = 18 },
    { id = "bird",   name = "طائر",   price = 2000,  speed = 20 },
    { id = "rabbit", name = "أرنب",   price = 2500,  speed = 14 },
    { id = "turtle", name = "سلحفاة", price = 1500,  speed = 10 },
}

-- Daily Challenges
Constants.DAILY_CHALLENGES = {
    { id = "earn_1k",      name = "اكسب 1,000$",       reward = 500,  target = 1000  },
    { id = "drive_60s",    name = "قُد سيارة 60 ثانية", reward = 300,  target = 60    },
    { id = "chat_10",      name = "أرسل 10 رسائل",      reward = 200,  target = 10    },
    { id = "visit_3",      name = "زُر 3 أماكن",        reward = 400,  target = 3     },
}

-- Map / Building positions (city layout)
Constants.BUILDINGS = {
    { id = "hospital",   name = "المستشفى",      position = { 120, 0,  80}, size = {40, 25, 30} },
    { id = "bank",       name = "البنك",         position = {-120, 0,  80}, size = {35, 20, 25} },
    { id = "mall",       name = "المول",         position = { 0,   0, 160}, size = {50, 22, 40} },
    { id = "police",     name = "مركز الشرطة",   position = { 120, 0, -80}, size = {35, 18, 30} },
    { id = "fire",       name = "الإطفاء",       position = {-120, 0, -80}, size = {35, 18, 30} },
    { id = "airport",    name = "المطار",        position = { 0,   0,-200}, size = {80, 15, 50} },
    { id = "dealership", name = "معرض السيارات",  position = {-200, 0,   0}, size = {45, 15, 35} },
    { id = "restaurant", name = "المطعم",        position = { 200, 0,   0}, size = {25, 12, 20} },
    { id = "house_1",    name = "بيت 1",         position = { 60,  0, -40}, size = {20, 10, 18} },
    { id = "house_2",    name = "بيت 2",         position = {-60,  0, -40}, size = {20, 10, 18} },
    { id = "house_3",    name = "بيت 3",         position = { 60,  0,  40}, size = {20, 10, 18} },
    { id = "apartment_1",name = "شقة 1",         position = {-60,  0,  40}, size = {22, 30, 20} },
    { id = "apartment_2",name = "شقة 2",         position = { 180, 0,  40}, size = {22, 30, 20} },
    { id = "gas_station", name = "محطة وقود",     position = {-200, 0, 100}, size = {30, 8,  25} },
}

-- Street layout (start, end pairs for road segments)
Constants.STREETS = {
    { from = {-300, 0.05, 0},   to = {300, 0.05, 0},   width = 14 },  -- main east-west
    { from = {0, 0.05, -300},   to = {0, 0.05, 300},   width = 14 },  -- main north-south
    { from = {-300, 0.05, 80},  to = {300, 0.05, 80},  width = 10 },  -- secondary east-west
    { from = {-300, 0.05, -80}, to = {300, 0.05, -80}, width = 10 },  -- secondary east-west south
    { from = {120, 0.05, -300}, to = {120, 0.05, 300}, width = 10 },  -- secondary north-south east
    { from = {-120, 0.05,-300}, to = {-120, 0.05,300}, width = 10 },  -- secondary north-south west
}

-- NPC Traffic waypoints (loop paths for AI cars)
Constants.TRAFFIC_PATHS = {
    {
        { 280, 2, 5},  { 0, 2, 5},   {-280, 2, 5},  {-280, 2, 85},
        { 0, 2, 85},   { 280, 2, 85}, { 280, 2, 5},
    },
    {
        {-280, 2, -5}, { 0, 2, -5},  { 280, 2, -5}, { 280, 2, -85},
        { 0, 2, -85},  {-280, 2,-85},{-280, 2, -5},
    },
}

-- Admin
Constants.BAN_DURATIONS = {
    temporary_15m = 900,
    temporary_1h  = 3600,
    temporary_24h = 86400,
    permanent     = -1,
}

-- UI
Constants.UI_COLORS = {
    primary    = Color3.fromRGB(30, 50, 80),
    secondary  = Color3.fromRGB(45, 70, 110),
    accent     = Color3.fromRGB(0, 170, 255),
    success    = Color3.fromRGB(0, 200, 80),
    danger     = Color3.fromRGB(220, 50, 50),
    warning    = Color3.fromRGB(255, 180, 0),
    text       = Color3.fromRGB(255, 255, 255),
    textDim    = Color3.fromRGB(180, 180, 200),
    background = Color3.fromRGB(20, 25, 35),
    card       = Color3.fromRGB(30, 38, 55),
}

return Constants
