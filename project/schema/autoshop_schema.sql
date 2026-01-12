--
-- PostgreSQL database dump
--

\restrict cK7hNOdDpi24U24AHYQs2KQjCsxaHe6ci76reWm1pfuVVlVGDbGQjU3xGSoRxqu

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

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


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
-- Name: current_inventory; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.current_inventory (
    id integer NOT NULL,
    product_id integer NOT NULL,
    store_id integer NOT NULL,
    quantity integer DEFAULT 0 NOT NULL,
    reserved integer DEFAULT 0 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.current_inventory OWNER TO autoshop;

--
-- Name: current_inventory_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.current_inventory_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.current_inventory_id_seq OWNER TO autoshop;

--
-- Name: current_inventory_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.current_inventory_id_seq OWNED BY public.current_inventory.id;


--
-- Name: inventory; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.inventory (
    id integer NOT NULL,
    product_id integer NOT NULL,
    change_type character varying(20) NOT NULL,
    quantity integer NOT NULL,
    previous_quantity integer,
    new_quantity integer,
    document_number character varying(100),
    document_date timestamp without time zone,
    reason character varying(255),
    store_id integer,
    created_at timestamp with time zone DEFAULT now(),
    created_by character varying(100)
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
-- Name: movements; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.movements (
    id integer NOT NULL,
    product_id integer NOT NULL,
    store_id integer NOT NULL,
    movement_type character varying(20) NOT NULL,
    quantity integer NOT NULL,
    related_document text,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.movements OWNER TO autoshop;

--
-- Name: movements_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.movements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movements_id_seq OWNER TO autoshop;

--
-- Name: movements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.movements_id_seq OWNED BY public.movements.id;


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
-- Name: stock_snapshots; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.stock_snapshots (
    id integer NOT NULL,
    product_id integer NOT NULL,
    store_id integer NOT NULL,
    quantity integer NOT NULL,
    taken_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.stock_snapshots OWNER TO autoshop;

--
-- Name: stock_snapshots_id_seq; Type: SEQUENCE; Schema: public; Owner: autoshop
--

CREATE SEQUENCE public.stock_snapshots_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.stock_snapshots_id_seq OWNER TO autoshop;

--
-- Name: stock_snapshots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: autoshop
--

ALTER SEQUENCE public.stock_snapshots_id_seq OWNED BY public.stock_snapshots.id;


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: autoshop
--

CREATE TABLE public.vehicles (
    id integer NOT NULL,
    brand character varying(100) NOT NULL,
    model character varying(100) NOT NULL,
    year integer,
    engine_model character varying(100),
    engine_volume double precision,
    engine_power integer,
    fuel_type character varying(50),
    category character varying(50),
    vin character varying(17),
    registration_number character varying(20),
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone,
    is_active boolean DEFAULT true NOT NULL
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
-- Name: current_inventory id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.current_inventory ALTER COLUMN id SET DEFAULT nextval('public.current_inventory_id_seq'::regclass);


--
-- Name: inventory id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.inventory ALTER COLUMN id SET DEFAULT nextval('public.inventory_id_seq'::regclass);


--
-- Name: movements id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.movements ALTER COLUMN id SET DEFAULT nextval('public.movements_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: stock_snapshots id; Type: DEFAULT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.stock_snapshots ALTER COLUMN id SET DEFAULT nextval('public.stock_snapshots_id_seq'::regclass);


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
-- Name: current_inventory current_inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.current_inventory
    ADD CONSTRAINT current_inventory_pkey PRIMARY KEY (id);


--
-- Name: inventory inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_pkey PRIMARY KEY (id);


--
-- Name: movements movements_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.movements
    ADD CONSTRAINT movements_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: stock_snapshots stock_snapshots_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.stock_snapshots
    ADD CONSTRAINT stock_snapshots_pkey PRIMARY KEY (id);


--
-- Name: current_inventory uq_current_inventory_product_store; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.current_inventory
    ADD CONSTRAINT uq_current_inventory_product_store UNIQUE (product_id, store_id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_registration_number_key; Type: CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_registration_number_key UNIQUE (registration_number);


--
-- Name: ix_current_inventory_product_store; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_current_inventory_product_store ON public.current_inventory USING btree (product_id, store_id);


--
-- Name: ix_current_inventory_updated_at; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_current_inventory_updated_at ON public.current_inventory USING btree (updated_at);


--
-- Name: ix_inventory_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_inventory_id ON public.inventory USING btree (id);


--
-- Name: ix_movements_product_store; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_movements_product_store ON public.movements USING btree (product_id, store_id);


--
-- Name: ix_movements_type_created; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_movements_type_created ON public.movements USING btree (movement_type, created_at);


--
-- Name: ix_products_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_products_id ON public.products USING btree (id);


--
-- Name: ix_products_sku; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE UNIQUE INDEX ix_products_sku ON public.products USING btree (sku);


--
-- Name: ix_stock_snapshots_product_store; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_stock_snapshots_product_store ON public.stock_snapshots USING btree (product_id, store_id);


--
-- Name: ix_stock_snapshots_taken_at; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_stock_snapshots_taken_at ON public.stock_snapshots USING btree (taken_at);


--
-- Name: ix_vehicles_id; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE INDEX ix_vehicles_id ON public.vehicles USING btree (id);


--
-- Name: ix_vehicles_vin; Type: INDEX; Schema: public; Owner: autoshop
--

CREATE UNIQUE INDEX ix_vehicles_vin ON public.vehicles USING btree (vin);


--
-- Name: current_inventory fk_current_inventory_product_id; Type: FK CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.current_inventory
    ADD CONSTRAINT fk_current_inventory_product_id FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: inventory inventory_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.inventory
    ADD CONSTRAINT inventory_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: movements movements_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.movements
    ADD CONSTRAINT movements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: stock_snapshots stock_snapshots_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: autoshop
--

ALTER TABLE ONLY public.stock_snapshots
    ADD CONSTRAINT stock_snapshots_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- PostgreSQL database dump complete
--

\unrestrict cK7hNOdDpi24U24AHYQs2KQjCsxaHe6ci76reWm1pfuVVlVGDbGQjU3xGSoRxqu

