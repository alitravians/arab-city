local Constants = {}

-- Game Info
Constants.GAME_NAME = "Arab City"
Constants.VERSION = "1.0.0"

-- Starting Money
Constants.STARTING_CASH = 5000
Constants.DAILY_REWARD = 500
Constants.WELCOME_BONUS = 5000

-- Owner (game creator UserId - auto-admin)
Constants.OWNER_USER_ID = 0 -- Replace with actual owner UserId from Roblox

-- Rank Definitions (GamePass IDs - replace with actual IDs in production)
Constants.RANKS = {
    VIP = {
        order = 1,
        gamePassId = 0, -- Replace with actual GamePass ID
        nameColor = Color3.fromRGB(255, 215, 0),
        dailyBonus = 1000,
        label = "VIP",
        labelAr = "في آي بي",
    },
    Premium = {
        order = 2,
        gamePassId = 0,
        nameColor = Color3.fromRGB(0, 191, 255),
        dailyBonus = 2500,
        label = "Premium",
        labelAr = "بريميوم",
    },
    Elite = {
        order = 3,
        gamePassId = 0,
        nameColor = Color3.fromRGB(148, 0, 211),
        dailyBonus = 5000,
        label = "Elite",
        labelAr = "إيليت",
    },
    Legend = {
        order = 4,
        gamePassId = 0,
        nameColor = Color3.fromRGB(255, 69, 0),
        dailyBonus = 10000,
        label = "Legend",
        labelAr = "ليجند",
    },
}

-- Camera Types
Constants.CAMERAS = {
    Beginner = {
        id = "cam_beginner",
        nameAr = "كاميرا مبتدئ",
        price = 0,
        qualityMultiplier = 1.0,
        viewBoost = 1.0,
        effects = {},
    },
    Professional = {
        id = "cam_professional",
        nameAr = "كاميرا احترافية",
        price = 5000,
        qualityMultiplier = 1.5,
        viewBoost = 2.0,
        effects = { "HDR" },
    },
    Journalist = {
        id = "cam_journalist",
        nameAr = "كاميرا صحفي",
        price = 15000,
        qualityMultiplier = 2.0,
        viewBoost = 3.0,
        effects = { "HDR", "Panorama" },
    },
    VIPCamera = {
        id = "cam_vip",
        nameAr = "كاميرا VIP",
        price = 50000,
        qualityMultiplier = 3.0,
        viewBoost = 5.0,
        effects = { "HDR", "Panorama", "Cinematic", "Filters" },
    },
}

-- Vehicle Categories
Constants.VEHICLE_CATEGORIES = {
    Civilian = { labelAr = "سيارات مدنية" },
    Sport = { labelAr = "سيارات رياضية" },
    Luxury = { labelAr = "سيارات فاخرة" },
    Rare = { labelAr = "سيارات نادرة" },
}

-- Sample Vehicle Data
Constants.VEHICLES = {
    {
        id = "sedan_basic",
        nameAr = "سيدان عادية",
        category = "Civilian",
        price = 3000,
        maxSpeed = 80,
    },
    {
        id = "suv_family",
        nameAr = "جيب عائلي",
        category = "Civilian",
        price = 6000,
        maxSpeed = 90,
    },
    {
        id = "sport_coupe",
        nameAr = "كوبيه رياضية",
        category = "Sport",
        price = 25000,
        maxSpeed = 150,
    },
    {
        id = "supercar",
        nameAr = "سوبر كار",
        category = "Sport",
        price = 75000,
        maxSpeed = 200,
    },
    {
        id = "limo",
        nameAr = "ليموزين",
        category = "Luxury",
        price = 100000,
        maxSpeed = 120,
    },
    {
        id = "gold_car",
        nameAr = "سيارة ذهبية",
        category = "Rare",
        price = 500000,
        maxSpeed = 180,
    },
}

-- Job Definitions
Constants.JOBS = {
    {
        id = "police",
        nameAr = "شرطي",
        salary = 300,
        payInterval = 300, -- seconds
        description = "حماية المدينة والحفاظ على النظام",
    },
    {
        id = "taxi",
        nameAr = "سائق أجرة",
        salary = 200,
        payInterval = 180,
        description = "نقل اللاعبين إلى وجهاتهم",
    },
    {
        id = "photographer",
        nameAr = "مصور",
        salary = 250,
        payInterval = 240,
        description = "التقاط الصور ونشرها على Social Network",
    },
    {
        id = "doctor",
        nameAr = "طبيب",
        salary = 400,
        payInterval = 300,
        description = "علاج اللاعبين في المستشفى",
    },
    {
        id = "firefighter",
        nameAr = "رجل إطفاء",
        salary = 350,
        payInterval = 300,
        description = "إطفاء الحرائق وإنقاذ الأرواح",
    },
    {
        id = "realtor",
        nameAr = "صاحب عقار",
        salary = 500,
        payInterval = 600,
        description = "بيع وشراء العقارات",
    },
    {
        id = "banker",
        nameAr = "موظف بنك",
        salary = 350,
        payInterval = 300,
        description = "إدارة الحسابات المالية",
    },
}

-- Mission Templates
Constants.MISSIONS = {
    {
        id = "take_photos",
        nameAr = "التقاط 5 صور",
        description = "التقط 5 صور باستخدام الكاميرا",
        target = 5,
        trackKey = "photosTaken",
        reward = 1000,
    },
    {
        id = "sell_house",
        nameAr = "بيع منزل",
        description = "قم ببيع منزل واحد على الأقل",
        target = 1,
        trackKey = "housesSold",
        reward = 5000,
    },
    {
        id = "buy_car",
        nameAr = "شراء سيارة",
        description = "اشترِ أي سيارة من المعرض",
        target = 1,
        trackKey = "carsBought",
        reward = 2000,
    },
    {
        id = "visit_landmark",
        nameAr = "زيارة مكان مميز",
        description = "قم بزيارة أي معلم في المدينة",
        target = 1,
        trackKey = "landmarksVisited",
        reward = 500,
    },
    {
        id = "earn_money",
        nameAr = "جمع 10,000 عملة",
        description = "اجمع 10,000 عملة من أي مصدر",
        target = 10000,
        trackKey = "totalEarned",
        reward = 3000,
    },
}

-- Achievement Definitions
Constants.ACHIEVEMENTS = {
    {
        id = "first_house",
        nameAr = "أول منزل",
        description = "اشترِ أول منزل لك",
        icon = "rbxassetid://0",
        trackKey = "housesBought",
        target = 1,
        reward = 2000,
    },
    {
        id = "first_car",
        nameAr = "أول سيارة",
        description = "اشترِ أول سيارة لك",
        icon = "rbxassetid://0",
        trackKey = "carsBought",
        target = 1,
        reward = 1000,
    },
    {
        id = "followers_1000",
        nameAr = "أول 1000 متابع",
        description = "احصل على 1000 متابع في Social Network",
        icon = "rbxassetid://0",
        trackKey = "followers",
        target = 1000,
        reward = 10000,
    },
    {
        id = "millionaire",
        nameAr = "أول مليون",
        description = "اجمع 1,000,000 عملة",
        icon = "rbxassetid://0",
        trackKey = "totalEarned",
        target = 1000000,
        reward = 50000,
    },
}

-- Map Locations
Constants.MAP_LOCATIONS = {
    { id = "residential",  nameAr = "أحياء سكنية",  icon = "🏘️" },
    { id = "airport",      nameAr = "مطار",         icon = "✈️" },
    { id = "beach",        nameAr = "شاطئ",         icon = "🏖️" },
    { id = "mall",         nameAr = "مركز تجاري",   icon = "🏬" },
    { id = "bank",         nameAr = "بنك",          icon = "🏦" },
    { id = "hospital",     nameAr = "مستشفى",       icon = "🏥" },
    { id = "police_hq",    nameAr = "مركز شرطة",   icon = "🚔" },
    { id = "vip_zone",     nameAr = "منطقة VIP",    icon = "⭐" },
    { id = "owner_palace", nameAr = "قصر الأونر",   icon = "👑" },
}

-- Loading Screen Tips
Constants.LOADING_TIPS = {
    "التقط صورًا وانشرها على Social Network لزيادة شهرتك!",
    "اشترِ منزلاً وعرضه للبيع لتحقيق أرباح كبيرة!",
    "انضم إلى وظيفة لكسب دخل ثابت.",
    "ارفع مستوى كاميرتك للحصول على مشاهدات أكثر.",
    "استخدم الأكواد للحصول على مكافآت مجانية!",
    "زُر المركز التجاري لشراء أفضل السيارات.",
    "أصحاب الرتب يحصلون على مكافآت يومية إضافية!",
    "اقفز من الطائرة واختر مكان هبوطك بعناية!",
    "تابع اللاعبين الآخرين على Social Network لبناء شبكتك.",
    "أكمل المهمات اليومية للحصول على جوائز خاصة!",
}

-- Parachute settings
Constants.PLANE_ALTITUDE = 500
Constants.PLANE_SPEED = 80
Constants.PARACHUTE_FALL_SPEED = 30
Constants.PARACHUTE_DRIFT_SPEED = 50

-- Weather types
Constants.WEATHER_TYPES = {
    "Clear",    -- صافي
    "Rain",     -- أمطار
    "Fog",      -- ضباب
}

-- Day cycle duration in seconds (full day = 20 minutes)
Constants.DAY_CYCLE_DURATION = 1200

-- (OWNER_USER_ID already defined at top of file)

-- Badge Definitions (replace id=0 with actual Badge IDs from Creator Hub)
Constants.BADGES = {
    { id = 0, name = "welcome",     nameAr = "مرحباً بك!",    description = "انضم إلى Arab City لأول مرة",    trigger = "firstJoin" },
    { id = 0, name = "first_house", nameAr = "أول منزل",      description = "اشترِ أول منزل لك",             trigger = "housesBought",     target = 1 },
    { id = 0, name = "first_car",   nameAr = "أول سيارة",     description = "اشترِ أول سيارة لك",            trigger = "carsBought",       target = 1 },
    { id = 0, name = "photographer",nameAr = "مصور محترف",    description = "التقط 50 صورة",                  trigger = "photosTaken",      target = 50 },
    { id = 0, name = "famous",      nameAr = "مشهور",         description = "احصل على 1000 متابع",            trigger = "followers",        target = 1000 },
    { id = 0, name = "millionaire", nameAr = "مليونير",       description = "اجمع 1,000,000$",                trigger = "totalEarned",      target = 1000000 },
    { id = 0, name = "explorer",    nameAr = "مستكشف",        description = "زُر جميع المعالم",               trigger = "landmarksVisited", target = 9 },
    { id = 0, name = "worker",      nameAr = "عامل مجتهد",   description = "أكمل 10 مهمات",                  trigger = "completedMissions",target = 10 },
}

-- Game Pass Definitions (replace id=0 with actual GamePass IDs from Creator Hub)
Constants.GAME_PASSES = {
    {
        id = 0, name = "VIP", nameAr = "في آي بي",
        description = "لون اسم خاص + دخل يومي إضافي 1,000$ + دخول منطقة VIP",
        price = 299,
        benefits = { "nameColor", "dailyBonus", "vipAccess" },
    },
    {
        id = 0, name = "Premium", nameAr = "بريميوم",
        description = "كل مزايا VIP + سيارات حصرية + دخل يومي 2,500$",
        price = 599,
        benefits = { "nameColor", "dailyBonus", "vipAccess", "premiumCars" },
    },
    {
        id = 0, name = "Elite", nameAr = "إيليت",
        description = "كل مزايا بريميوم + شارة مميزة + دخل يومي 5,000$",
        price = 999,
        benefits = { "nameColor", "dailyBonus", "vipAccess", "premiumCars", "eliteBadge" },
    },
    {
        id = 0, name = "Legend", nameAr = "ليجند",
        description = "جميع المزايا + تأثيرات دخول خاصة + دخل يومي 10,000$",
        price = 1999,
        benefits = { "nameColor", "dailyBonus", "vipAccess", "premiumCars", "eliteBadge", "legendEffects" },
    },
    {
        id = 0, name = "DoubleMoney", nameAr = "مضاعف الأموال",
        description = "احصل على ضعف الأموال من جميع المصادر",
        price = 499,
        benefits = { "doubleMoney" },
    },
    {
        id = 0, name = "ExtraSpeed", nameAr = "سرعة إضافية",
        description = "سرعة مشي أعلى بـ 50%",
        price = 199,
        benefits = { "extraSpeed" },
    },
    {
        id = 0, name = "RadioDJ", nameAr = "منسق الأغاني",
        description = "شغّل موسيقى في سيارتك",
        price = 149,
        benefits = { "carRadio" },
    },
}

-- Building interaction types
Constants.BUILDING_ACTIONS = {
    Hospital      = { nameAr = "مستشفى",            icon = "🏥", prompt = "علاج",     action = "heal" },
    Bank          = { nameAr = "البنك",             icon = "🏦", prompt = "رصيدك",    action = "bank" },
    Mall          = { nameAr = "المركز التجاري",    icon = "🏬", prompt = "تسوّق",    action = "shop" },
    PoliceStation = { nameAr = "مركز الشرطة",       icon = "🚔", prompt = "انضم",     action = "job_police" },
    FireStation   = { nameAr = "مركز الإطفاء",      icon = "🚒", prompt = "انضم",     action = "job_firefighter" },
    CarDealership = { nameAr = "معرض السيارات",      icon = "🚗", prompt = "شراء سيارة", action = "vehicles" },
    VIPLounge     = { nameAr = "منطقة VIP",          icon = "⭐", prompt = "دخول VIP", action = "vip" },
    Airport       = { nameAr = "المطار",             icon = "✈️", prompt = "سفر",      action = "airport" },
}

-- XP / Leveling System
Constants.XP_BASE = 100
Constants.XP_MULTIPLIER = 1.5
Constants.MAX_LEVEL = 50
Constants.XP_REWARDS = {
    mission_complete = 50,
    photo_taken = 10,
    house_bought = 100,
    car_bought = 75,
    landmark_visited = 25,
    job_payment = 15,
    daily_login = 30,
    trade_complete = 40,
}

function Constants.getXPForLevel(level: number): number
    return math.floor(Constants.XP_BASE * (Constants.XP_MULTIPLIER ^ (level - 1)))
end

-- Pet System
Constants.PET_TYPES = {
    { id = "cat",      nameAr = "قطة",       price = 2000,  speed = 1.0, icon = "🐱" },
    { id = "dog",      nameAr = "كلب",       price = 2500,  speed = 1.2, icon = "🐕" },
    { id = "parrot",   nameAr = "ببغاء",     price = 5000,  speed = 0.8, icon = "🦜" },
    { id = "falcon",   nameAr = "صقر",       price = 15000, speed = 1.5, icon = "🦅" },
    { id = "horse",    nameAr = "حصان",      price = 30000, speed = 2.0, icon = "🐎" },
    { id = "dragon",   nameAr = "تنين",      price = 100000,speed = 2.5, icon = "🐉" },
}

-- Daily Challenges
Constants.DAILY_CHALLENGES = {
    { id = "dc_walk",       nameAr = "امشِ 500 متر",       target = 500,  reward = 300,  trackKey = "walkDistance" },
    { id = "dc_photos",     nameAr = "التقط 3 صور",         target = 3,    reward = 500,  trackKey = "dailyPhotos" },
    { id = "dc_chat",       nameAr = "أرسل 10 رسائل",       target = 10,   reward = 200,  trackKey = "dailyMessages" },
    { id = "dc_visit",      nameAr = "زُر 3 معالم",         target = 3,    reward = 400,  trackKey = "dailyVisits" },
    { id = "dc_earn",       nameAr = "اكسب 1,000$",         target = 1000, reward = 600,  trackKey = "dailyEarnings" },
}

-- Leaderboard Categories
Constants.LEADERBOARD_CATEGORIES = {
    { id = "richest",   nameAr = "الأغنياء",   key = "cash",           icon = "💰" },
    { id = "famous",    nameAr = "المشاهير",   key = "fame",           icon = "⭐" },
    { id = "level",     nameAr = "المستويات",  key = "level",          icon = "🏆" },
    { id = "workers",   nameAr = "المجتهدين",  key = "totalEarned",    icon = "💼" },
}

-- Tutorial Steps
Constants.TUTORIAL_STEPS = {
    { id = "welcome",   titleAr = "مرحباً بك!",       descAr = "مرحباً بك في Arab City! هذا دليلك السريع.", icon = "👋" },
    { id = "hud",       titleAr = "واجهة اللعبة",     descAr = "شريط علوي: أكواد، متجر، حقيبة، هاتف، خريطة، مهمات.", icon = "🎮" },
    { id = "jobs",      titleAr = "الوظائف",          descAr = "روح مركز الشرطة أو الإطفاء عشان تشتغل وتكسب فلوس.", icon = "💼" },
    { id = "houses",    titleAr = "العقارات",         descAr = "اشترِ بيت من لوحات البيع الذهبية في الحي السكني.", icon = "🏠" },
    { id = "cars",      titleAr = "السيارات",         descAr = "اشترِ سيارة من المتجر واستدعيها من نقاط السيارات.", icon = "🚗" },
    { id = "social",    titleAr = "التواصل",          descAr = "استخدم الهاتف للتصوير والنشر على Social Network.", icon = "📱" },
    { id = "missions",  titleAr = "المهمات",          descAr = "أكمل المهمات اليومية للحصول على مكافآت إضافية!", icon = "📋" },
    { id = "done",      titleAr = "جاهز!",            descAr = "أنت جاهز لاستكشاف المدينة! استمتع!", icon = "🎉" },
}

-- Traffic / NPC settings
Constants.TRAFFIC_CAR_COUNT = 12
Constants.TRAFFIC_SPEED_MIN = 25
Constants.TRAFFIC_SPEED_MAX = 45

-- UI Colors (Midnight Blue Neon Theme)
Constants.COLORS = {
    Primary = Color3.fromRGB(5, 10, 28),
    Secondary = Color3.fromRGB(12, 20, 42),
    Accent = Color3.fromRGB(0, 180, 255),
    Gold = Color3.fromRGB(255, 215, 0),
    Success = Color3.fromRGB(0, 200, 130),
    Danger = Color3.fromRGB(255, 59, 80),
    Text = Color3.fromRGB(220, 230, 245),
    TextDim = Color3.fromRGB(140, 160, 190),
    Background = Color3.fromRGB(2, 5, 18),
    CardBg = Color3.fromRGB(10, 18, 38),
    NeonCyan = Color3.fromRGB(0, 230, 255),
    NeonPink = Color3.fromRGB(255, 0, 120),
    MoonGlow = Color3.fromRGB(100, 150, 220),
    WindowAmber = Color3.fromRGB(200, 170, 80),
}

return Constants
