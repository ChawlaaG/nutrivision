-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES TABLE
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    height_cm NUMERIC,
    current_weight_kg NUMERIC,
    goal_weight_kg NUMERIC,
    birth_date DATE,
    gender TEXT CHECK (gender IN ('male', 'female')),
    activity_level TEXT CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'athlete')),
    dietary_goal TEXT CHECK (dietary_goal IN ('loss', 'maintain', 'gain')),
    calculated_daily_calories INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. DAILY LOGS TABLE
CREATE TABLE daily_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    current_streak_count INTEGER DEFAULT 0,
    total_calories_consumed INTEGER DEFAULT 0,
    logged_weight_today NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, date)
);

-- 3. MEALS TABLE
CREATE TABLE meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    daily_log_id UUID REFERENCES daily_logs(id) ON DELETE CASCADE,
    meal_time TIMESTAMPTZ DEFAULT NOW(),
    photo_storage_path TEXT,
    ai_confidence_score NUMERIC,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. MEAL ITEMS TABLE
CREATE TABLE meal_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    meal_id UUID REFERENCES meals(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    calories INTEGER DEFAULT 0,
    protein_g INTEGER DEFAULT 0,
    carbs_g INTEGER DEFAULT 0,
    fat_g INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_daily_logs_user_date ON daily_logs(user_id, date);
CREATE INDEX idx_meals_daily_log ON meals(daily_log_id);
CREATE INDEX idx_meal_items_meal ON meal_items(meal_id);
