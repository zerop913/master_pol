CREATE TABLE partner_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE partners (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    partner_type_id INTEGER REFERENCES partner_types(id),
    director VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200),
    inn VARCHAR(20),
    rating INTEGER CHECK (rating >= 0),
    logo_path VARCHAR(255)
);

CREATE TABLE product_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    coefficient DECIMAL(5, 2) NOT NULL
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    article VARCHAR(50) NOT NULL,
    product_type_id INTEGER REFERENCES product_types(id),
    min_price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE sales (
    id SERIAL PRIMARY KEY,
    partner_id INTEGER REFERENCES partners(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    sale_date DATE NOT NULL
);

CREATE TABLE material_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    defect_percentage DECIMAL(5, 2) NOT NULL
);

-- Функция для расчета скидки партнера
CREATE OR REPLACE FUNCTION calculate_partner_discount(p_partner_id INTEGER)
RETURNS DECIMAL AS $$
DECLARE
    total_quantity INTEGER;
    discount_percent DECIMAL;
BEGIN
    -- Получаем общее количество проданной продукции партнером
    SELECT COALESCE(SUM(quantity), 0) INTO total_quantity
    FROM sales
    WHERE partner_id = p_partner_id;
    
    -- Рассчитываем скидку на основе общего количества
    IF total_quantity < 10000 THEN
        discount_percent := 0;
    ELSIF total_quantity >= 10000 AND total_quantity < 50000 THEN
        discount_percent := 5;
    ELSIF total_quantity >= 50000 AND total_quantity < 300000 THEN
        discount_percent := 10;
    ELSE
        discount_percent := 15;
    END IF;
    
    RETURN discount_percent;
END;
$$ LANGUAGE plpgsql;

-- Функция для расчета необходимого количества материала
CREATE OR REPLACE FUNCTION calculate_material_amount(
    product_type_id INTEGER,
    material_type_id INTEGER,
    product_quantity INTEGER,
    param1 DECIMAL,
    param2 DECIMAL
)
RETURNS INTEGER AS $$
DECLARE
    coefficient DECIMAL;
    defect_percentage DECIMAL;
    material_amount DECIMAL;
BEGIN
    -- Проверяем корректность входных данных
    IF product_quantity <= 0 OR param1 <= 0 OR param2 <= 0 THEN
        RETURN -1;
    END IF;
    
    -- Получаем коэффициент типа продукции
    SELECT coefficient INTO coefficient
    FROM product_types
    WHERE id = product_type_id;
    
    -- Получаем процент брака материала
    SELECT defect_percentage INTO defect_percentage
    FROM material_types
    WHERE id = material_type_id;
    
    -- Если не найдены данные, возвращаем -1
    IF coefficient IS NULL OR defect_percentage IS NULL THEN
        RETURN -1;
    END IF;
    
    -- Рассчитываем количество материала с учетом брака
    material_amount := param1 * param2 * coefficient * product_quantity;
    material_amount := material_amount * (1 + defect_percentage / 100);
    
    -- Округляем до целого числа (в большую сторону)
    RETURN CEILING(material_amount);
END;
$$ LANGUAGE plpgsql;