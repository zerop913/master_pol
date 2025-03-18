--
-- PostgreSQL database dump
--

-- Dumped from database version 16.2
-- Dumped by pg_dump version 16.0

-- Started on 2025-03-18 13:09:07

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 239 (class 1255 OID 16465)
-- Name: calculate_material_amount(integer, integer, integer, numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_material_amount(product_type_id integer, material_type_id integer, product_quantity integer, param1 numeric, param2 numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.calculate_material_amount(product_type_id integer, material_type_id integer, product_quantity integer, param1 numeric, param2 numeric) OWNER TO postgres;

--
-- TOC entry 227 (class 1255 OID 16464)
-- Name: calculate_partner_discount(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_partner_discount(p_partner_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.calculate_partner_discount(p_partner_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 226 (class 1259 OID 16458)
-- Name: material_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.material_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    defect_percentage numeric(5,2) NOT NULL
);


ALTER TABLE public.material_types OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16457)
-- Name: material_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.material_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.material_types_id_seq OWNER TO postgres;

--
-- TOC entry 4844 (class 0 OID 0)
-- Dependencies: 225
-- Name: material_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.material_types_id_seq OWNED BY public.material_types.id;


--
-- TOC entry 216 (class 1259 OID 16400)
-- Name: partner_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partner_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.partner_types OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16399)
-- Name: partner_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partner_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.partner_types_id_seq OWNER TO postgres;

--
-- TOC entry 4845 (class 0 OID 0)
-- Dependencies: 215
-- Name: partner_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partner_types_id_seq OWNED BY public.partner_types.id;


--
-- TOC entry 218 (class 1259 OID 16407)
-- Name: partners; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.partners (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    partner_type_id integer,
    director character varying(100) NOT NULL,
    email character varying(100),
    phone character varying(20),
    address character varying(200),
    inn character varying(20),
    rating integer,
    logo_path character varying(255),
    CONSTRAINT partners_rating_check CHECK ((rating >= 0))
);


ALTER TABLE public.partners OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16406)
-- Name: partners_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.partners_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.partners_id_seq OWNER TO postgres;

--
-- TOC entry 4846 (class 0 OID 0)
-- Dependencies: 217
-- Name: partners_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.partners_id_seq OWNED BY public.partners.id;


--
-- TOC entry 220 (class 1259 OID 16422)
-- Name: product_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    coefficient numeric(5,2) NOT NULL
);


ALTER TABLE public.product_types OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16421)
-- Name: product_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.product_types_id_seq OWNER TO postgres;

--
-- TOC entry 4847 (class 0 OID 0)
-- Dependencies: 219
-- Name: product_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_types_id_seq OWNED BY public.product_types.id;


--
-- TOC entry 222 (class 1259 OID 16429)
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    article character varying(50) NOT NULL,
    product_type_id integer,
    min_price numeric(10,2) NOT NULL
);


ALTER TABLE public.products OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16428)
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO postgres;

--
-- TOC entry 4848 (class 0 OID 0)
-- Dependencies: 221
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- TOC entry 224 (class 1259 OID 16441)
-- Name: sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sales (
    id integer NOT NULL,
    partner_id integer,
    product_id integer,
    quantity integer NOT NULL,
    sale_date date NOT NULL
);


ALTER TABLE public.sales OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16440)
-- Name: sales_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sales_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sales_id_seq OWNER TO postgres;

--
-- TOC entry 4849 (class 0 OID 0)
-- Dependencies: 223
-- Name: sales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sales_id_seq OWNED BY public.sales.id;


--
-- TOC entry 4666 (class 2604 OID 16461)
-- Name: material_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_types ALTER COLUMN id SET DEFAULT nextval('public.material_types_id_seq'::regclass);


--
-- TOC entry 4661 (class 2604 OID 16403)
-- Name: partner_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_types ALTER COLUMN id SET DEFAULT nextval('public.partner_types_id_seq'::regclass);


--
-- TOC entry 4662 (class 2604 OID 16410)
-- Name: partners id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partners ALTER COLUMN id SET DEFAULT nextval('public.partners_id_seq'::regclass);


--
-- TOC entry 4663 (class 2604 OID 16425)
-- Name: product_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_types ALTER COLUMN id SET DEFAULT nextval('public.product_types_id_seq'::regclass);


--
-- TOC entry 4664 (class 2604 OID 16432)
-- Name: products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- TOC entry 4665 (class 2604 OID 16444)
-- Name: sales id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales ALTER COLUMN id SET DEFAULT nextval('public.sales_id_seq'::regclass);


--
-- TOC entry 4838 (class 0 OID 16458)
-- Dependencies: 226
-- Data for Name: material_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.material_types (id, name, defect_percentage) VALUES (1, 'Тип материала 1', 0.10);
INSERT INTO public.material_types (id, name, defect_percentage) VALUES (2, 'Тип материала 2', 0.95);
INSERT INTO public.material_types (id, name, defect_percentage) VALUES (3, 'Тип материала 3', 0.28);
INSERT INTO public.material_types (id, name, defect_percentage) VALUES (4, 'Тип материала 4', 0.55);
INSERT INTO public.material_types (id, name, defect_percentage) VALUES (5, 'Тип материала 5', 0.34);


--
-- TOC entry 4828 (class 0 OID 16400)
-- Dependencies: 216
-- Data for Name: partner_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.partner_types (id, name) VALUES (1, 'ЗАО');
INSERT INTO public.partner_types (id, name) VALUES (2, 'ООО');
INSERT INTO public.partner_types (id, name) VALUES (3, 'ПАО');
INSERT INTO public.partner_types (id, name) VALUES (4, 'ОАО');


--
-- TOC entry 4830 (class 0 OID 16407)
-- Dependencies: 218
-- Data for Name: partners; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.partners (id, name, partner_type_id, director, email, phone, address, inn, rating, logo_path) VALUES (1, 'База Строитель', 1, 'Иванова Александра Ивановна', 'aleksandraivanova@ml.ru', '493 123 45 67', '652050, Кемеровская область, город Юрга, ул. Лесная, 15', '2222455179', 7, NULL);
INSERT INTO public.partners (id, name, partner_type_id, director, email, phone, address, inn, rating, logo_path) VALUES (2, 'Паркет 29', 2, 'Петров Василий Петрович', 'vppetrov@vl.ru', '987 123 56 78', '164500, Архангельская область, город Северодвинск, ул. Строителей, 18', '3333888520', 7, NULL);
INSERT INTO public.partners (id, name, partner_type_id, director, email, phone, address, inn, rating, logo_path) VALUES (3, 'Стройсервис', 3, 'Соловьев Андрей Николаевич', 'ansolovev@st.ru', '812 223 32 00', '188910, Ленинградская область, город Приморск, ул. Парковая, 21', '4440391035', 7, NULL);
INSERT INTO public.partners (id, name, partner_type_id, director, email, phone, address, inn, rating, logo_path) VALUES (4, 'Ремонт и отделка', 4, 'Воробьева Екатерина Валерьевна', 'ekaterina.vorobeva@ml.ru', '444 222 33 11', '143960, Московская область, город Реутов, ул. Свободы, 51', '1111520857', 5, NULL);
INSERT INTO public.partners (id, name, partner_type_id, director, email, phone, address, inn, rating, logo_path) VALUES (5, 'МонтажПро', 1, 'Степанов Степан Сергеевич', 'stepanov@stepan.ru', '912 888 33 33', '309500, Белгородская область, город Старый Оскол, ул. Рабочая, 122', '5552431140', 10, NULL);


--
-- TOC entry 4832 (class 0 OID 16422)
-- Dependencies: 220
-- Data for Name: product_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.product_types (id, name, coefficient) VALUES (1, 'Ламинат', 2.35);
INSERT INTO public.product_types (id, name, coefficient) VALUES (2, 'Массивная доска', 5.15);
INSERT INTO public.product_types (id, name, coefficient) VALUES (3, 'Паркетная доска', 4.34);
INSERT INTO public.product_types (id, name, coefficient) VALUES (4, 'Пробковое покрытие', 1.50);


--
-- TOC entry 4834 (class 0 OID 16429)
-- Dependencies: 222
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.products (id, name, article, product_type_id, min_price) VALUES (1, 'Паркетная доска Ясень темный однополосная 14 мм', '8758385', 3, 4456.90);
INSERT INTO public.products (id, name, article, product_type_id, min_price) VALUES (2, 'Инженерная доска Дуб Французская елка однополосная 12 мм', '8858958', 3, 7330.99);
INSERT INTO public.products (id, name, article, product_type_id, min_price) VALUES (3, 'Ламинат Дуб дымчато-белый 33 класс 12 мм', '7750282', 1, 1799.33);
INSERT INTO public.products (id, name, article, product_type_id, min_price) VALUES (4, 'Ламинат Дуб серый 32 класс 8 мм с фаской', '7028748', 1, 3890.41);
INSERT INTO public.products (id, name, article, product_type_id, min_price) VALUES (5, 'Пробковое напольное клеевое покрытие 32 класс 4 мм', '5012543', 4, 5450.59);


--
-- TOC entry 4836 (class 0 OID 16441)
-- Dependencies: 224
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (1, 1, 1, 15500, '2023-03-23');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (2, 1, 3, 12350, '2023-12-18');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (3, 1, 4, 37400, '2024-06-07');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (4, 2, 2, 35000, '2022-12-02');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (5, 2, 5, 1250, '2023-05-17');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (6, 2, 3, 1000, '2024-06-07');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (7, 2, 1, 7550, '2024-07-01');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (8, 3, 1, 7250, '2023-01-22');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (9, 3, 2, 2500, '2024-07-05');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (10, 4, 4, 59050, '2023-03-20');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (11, 4, 3, 37200, '2024-03-12');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (12, 4, 5, 4500, '2024-05-14');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (13, 5, 3, 50000, '2023-09-19');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (14, 5, 4, 670000, '2023-11-10');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (15, 5, 1, 35000, '2024-04-15');
INSERT INTO public.sales (id, partner_id, product_id, quantity, sale_date) VALUES (16, 5, 2, 25000, '2024-06-12');


--
-- TOC entry 4850 (class 0 OID 0)
-- Dependencies: 225
-- Name: material_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.material_types_id_seq', 5, true);


--
-- TOC entry 4851 (class 0 OID 0)
-- Dependencies: 215
-- Name: partner_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.partner_types_id_seq', 4, true);


--
-- TOC entry 4852 (class 0 OID 0)
-- Dependencies: 217
-- Name: partners_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.partners_id_seq', 5, true);


--
-- TOC entry 4853 (class 0 OID 0)
-- Dependencies: 219
-- Name: product_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_types_id_seq', 4, true);


--
-- TOC entry 4854 (class 0 OID 0)
-- Dependencies: 221
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.products_id_seq', 5, true);


--
-- TOC entry 4855 (class 0 OID 0)
-- Dependencies: 223
-- Name: sales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sales_id_seq', 16, true);


--
-- TOC entry 4679 (class 2606 OID 16463)
-- Name: material_types material_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.material_types
    ADD CONSTRAINT material_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4669 (class 2606 OID 16405)
-- Name: partner_types partner_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partner_types
    ADD CONSTRAINT partner_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4671 (class 2606 OID 16415)
-- Name: partners partners_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_pkey PRIMARY KEY (id);


--
-- TOC entry 4673 (class 2606 OID 16427)
-- Name: product_types product_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_types
    ADD CONSTRAINT product_types_pkey PRIMARY KEY (id);


--
-- TOC entry 4675 (class 2606 OID 16434)
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- TOC entry 4677 (class 2606 OID 16446)
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- TOC entry 4680 (class 2606 OID 16416)
-- Name: partners partners_partner_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.partners
    ADD CONSTRAINT partners_partner_type_id_fkey FOREIGN KEY (partner_type_id) REFERENCES public.partner_types(id);


--
-- TOC entry 4681 (class 2606 OID 16435)
-- Name: products products_product_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_product_type_id_fkey FOREIGN KEY (product_type_id) REFERENCES public.product_types(id);


--
-- TOC entry 4682 (class 2606 OID 16447)
-- Name: sales sales_partner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_partner_id_fkey FOREIGN KEY (partner_id) REFERENCES public.partners(id);


--
-- TOC entry 4683 (class 2606 OID 16452)
-- Name: sales sales_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


-- Completed on 2025-03-18 13:09:07

--
-- PostgreSQL database dump complete
--

