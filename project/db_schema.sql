--
-- PostgreSQL database dump
--

\restrict tqeYjdXPEEz8ieOyfOMd8e3dmZKMyzXqPyabH1sfZlgc8xk33ZwZc1bnfpSWh8a

-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO autoshop;

--
-- Name: inventory; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.inventory (
    id integer NOT NULL,
    product_id integer NOT NULL,
    store_id integer NOT NULL,
    quantity integer,
    status character varying(20),
    updated_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.inventory OWNER TO autoshop;

--
-- Name: inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.inventory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_id_seq OWNER TO autoshop;

--
-- Name: inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.inventory_id_seq OWNED BY public.inventory.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.products (
    id integer NOT NULL,
    sku character varying(100) NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    category character varying(100),
    brand character varying(100),
    vehicle_brand character varying(50),
    vehicle_model character varying(50),
    engine_type character varying(50),
    engine_volume double precision,
    year_from integer,
    year_to integer,
    purchase_price double precision NOT NULL,
    selling_price double precision NOT NULL,
    quantity integer,
    min_quantity integer,
    vin_codes text,
    is_active boolean,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone
);


ALTER TABLE public.products OWNER TO autoshop;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.products_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.products_id_seq OWNER TO autoshop;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: stores; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.stores (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    address character varying,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.stores OWNER TO autoshop;

--
-- Name: stores_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.stores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stores_id_seq OWNER TO autoshop;

--
-- Name: stores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.stores_id_seq OWNED BY public.stores.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying,
    hashed_password character varying,
    is_active boolean
);


ALTER TABLE public.users OWNER TO autoshop;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO autoshop;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.vehicles (
    id integer NOT NULL,
    vin character varying(17),
    make character varying(100),
    model character varying(100),
    year integer,
    engine_code character varying(20),
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.vehicles OWNER TO autoshop;

--
-- Name: vehicles_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.vehicles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicles_id_seq OWNER TO autoshop;

--
-- Name: vehicles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.vehicles_id_seq OWNED BY public.vehicles.id;


--
-- Name: inventory id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.inventory ALTER COLUMN id SET DEFAULT nextval('public.inventory_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: stores id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.stores ALTER COLUMN id SET DEFAULT nextval('public.stores_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: vehicles id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.vehicles ALTER COLUMN id SET DEFAULT nextval('public.vehicles_id_seq'::regclass);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: ix_inventory_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_inventory_id ON public.inventory USING btree (id);


--
-- Name: ix_products_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_products_id ON public.products USING btree (id);


--
-- Name: ix_products_sku; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE UNIQUE INDEX ix_products_sku ON public.products USING btree (sku);


--
-- Name: ix_stores_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_stores_id ON public.stores USING btree (id);


--
-- Name: ix_stores_name; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE UNIQUE INDEX ix_stores_name ON public.stores USING btree (name);


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: ix_users_username; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE UNIQUE INDEX ix_users_username ON public.users USING btree (username);


--
-- Name: ix_vehicles_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_vehicles_id ON public.vehicles USING btree (id);


--
-- Name: ix_vehicles_vin; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE UNIQUE INDEX ix_vehicles_vin ON public.vehicles USING btree (vin);


--
-- Name: inventory inventory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: inventory inventory_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_store_id_fkey FOREIGN KEY (store_id) REFERENCES public.stores(id);


--
-- PostgreSQL database dump complete
--

\unrestrict tqeYjdXPEEz8ieOyfOMd8e3dmZKMyzXqPyabH1sfZlgc8xk33ZwZc1bnfpSWh8a

