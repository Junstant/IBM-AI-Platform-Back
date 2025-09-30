--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Debian 17.5-1.pgdg120+1)
-- Dumped by pg_dump version 17.5 (Debian 17.5-1.pgdg120+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
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
-- Name: customers; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.customers (
    customer_id integer NOT NULL,
    company_name character varying(100) NOT NULL,
    contact_person character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    phone character varying(20) NOT NULL,
    address text NOT NULL,
    city character varying(50) NOT NULL,
    state character varying(50) NOT NULL,
    postal_code character varying(20) NOT NULL,
    credit_limit numeric(10,2),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.customers OWNER TO rentalco;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.customers_customer_id_seq OWNER TO rentalco;

--
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.customers_customer_id_seq OWNED BY public.customers.customer_id;


--
-- Name: employee_locations; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.employee_locations (
    assignment_id integer NOT NULL,
    employee_id integer,
    location_id integer,
    is_primary boolean DEFAULT false,
    start_date date NOT NULL,
    end_date date,
    assignment_type character varying(50),
    CONSTRAINT employee_locations_assignment_type_check CHECK (((assignment_type)::text = ANY (ARRAY[('Permanent'::character varying)::text, ('Temporary'::character varying)::text, ('Rotating'::character varying)::text])))
);


ALTER TABLE public.employee_locations OWNER TO rentalco;

--
-- Name: employee_locations_assignment_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.employee_locations_assignment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employee_locations_assignment_id_seq OWNER TO rentalco;

--
-- Name: employee_locations_assignment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.employee_locations_assignment_id_seq OWNED BY public.employee_locations.assignment_id;


--
-- Name: employees; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.employees (
    employee_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    "position" character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    phone character varying(20) NOT NULL,
    hire_date date NOT NULL,
    primary_location_id integer,
    certification text[],
    is_active boolean DEFAULT true
);


ALTER TABLE public.employees OWNER TO rentalco;

--
-- Name: employees_employee_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.employees_employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.employees_employee_id_seq OWNER TO rentalco;

--
-- Name: employees_employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.employees_employee_id_seq OWNED BY public.employees.employee_id;


--
-- Name: equipment; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.equipment (
    equipment_id integer NOT NULL,
    category_id integer,
    equipment_name character varying(100) NOT NULL,
    model_number character varying(50) NOT NULL,
    manufacturer character varying(100) NOT NULL,
    purchase_date date NOT NULL,
    purchase_price numeric(10,2) NOT NULL,
    current_value numeric(10,2) NOT NULL,
    daily_rental_rate numeric(10,2) NOT NULL,
    weekly_rental_rate numeric(10,2) NOT NULL,
    monthly_rental_rate numeric(10,2) NOT NULL,
    status character varying(20),
    maintenance_interval integer NOT NULL,
    last_maintenance_date date,
    hours_used integer DEFAULT 0,
    condition_rating integer,
    location_id integer,
    notes text,
    CONSTRAINT equipment_condition_rating_check CHECK (((condition_rating >= 1) AND (condition_rating <= 5))),
    CONSTRAINT equipment_status_check CHECK (((status)::text = ANY (ARRAY[('Available'::character varying)::text, ('Rented'::character varying)::text, ('Maintenance'::character varying)::text, ('Retired'::character varying)::text])))
);


ALTER TABLE public.equipment OWNER TO rentalco;

--
-- Name: equipment_attachments; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.equipment_attachments (
    attachment_id integer NOT NULL,
    equipment_id integer,
    attachment_name character varying(100) NOT NULL,
    attachment_type character varying(50) NOT NULL,
    daily_rate numeric(10,2) NOT NULL,
    status character varying(20),
    location_id integer,
    notes text,
    CONSTRAINT equipment_attachments_status_check CHECK (((status)::text = ANY (ARRAY[('Available'::character varying)::text, ('Rented'::character varying)::text, ('Maintenance'::character varying)::text, ('Retired'::character varying)::text])))
);


ALTER TABLE public.equipment_attachments OWNER TO rentalco;

--
-- Name: equipment_attachments_attachment_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.equipment_attachments_attachment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_attachments_attachment_id_seq OWNER TO rentalco;

--
-- Name: equipment_attachments_attachment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.equipment_attachments_attachment_id_seq OWNED BY public.equipment_attachments.attachment_id;


--
-- Name: equipment_categories; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.equipment_categories (
    category_id integer NOT NULL,
    category_name character varying(50) NOT NULL,
    description text,
    daily_insurance_rate numeric(10,2) NOT NULL
);


ALTER TABLE public.equipment_categories OWNER TO rentalco;

--
-- Name: equipment_categories_category_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.equipment_categories_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_categories_category_id_seq OWNER TO rentalco;

--
-- Name: equipment_categories_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.equipment_categories_category_id_seq OWNED BY public.equipment_categories.category_id;


--
-- Name: equipment_equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.equipment_equipment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_equipment_id_seq OWNER TO rentalco;

--
-- Name: equipment_equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.equipment_equipment_id_seq OWNED BY public.equipment.equipment_id;


--
-- Name: inventory_locations; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.inventory_locations (
    location_id integer NOT NULL,
    location_name character varying(100) NOT NULL,
    address text NOT NULL,
    city character varying(50) NOT NULL,
    state character varying(50) NOT NULL,
    postal_code character varying(20) NOT NULL,
    phone character varying(20),
    is_active boolean DEFAULT true,
    manager_id integer
);


ALTER TABLE public.inventory_locations OWNER TO rentalco;

--
-- Name: inventory_locations_location_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.inventory_locations_location_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventory_locations_location_id_seq OWNER TO rentalco;

--
-- Name: inventory_locations_location_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.inventory_locations_location_id_seq OWNED BY public.inventory_locations.location_id;


--
-- Name: maintenance_records; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.maintenance_records (
    maintenance_id integer NOT NULL,
    equipment_id integer,
    maintenance_date date NOT NULL,
    maintenance_type character varying(50),
    description text NOT NULL,
    cost numeric(10,2) NOT NULL,
    performed_by integer,
    hours_added integer,
    parts_replaced text,
    next_maintenance_date date,
    status character varying(20),
    notes text,
    CONSTRAINT maintenance_records_maintenance_type_check CHECK (((maintenance_type)::text = ANY (ARRAY[('Scheduled'::character varying)::text, ('Repair'::character varying)::text, ('Inspection'::character varying)::text, ('Emergency'::character varying)::text]))),
    CONSTRAINT maintenance_records_status_check CHECK (((status)::text = ANY (ARRAY[('Scheduled'::character varying)::text, ('In Progress'::character varying)::text, ('Completed'::character varying)::text, ('Postponed'::character varying)::text])))
);


ALTER TABLE public.maintenance_records OWNER TO rentalco;

--
-- Name: maintenance_records_maintenance_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.maintenance_records_maintenance_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.maintenance_records_maintenance_id_seq OWNER TO rentalco;

--
-- Name: maintenance_records_maintenance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.maintenance_records_maintenance_id_seq OWNED BY public.maintenance_records.maintenance_id;


--
-- Name: payments; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.payments (
    payment_id integer NOT NULL,
    rental_id integer,
    payment_date date NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(50) NOT NULL,
    transaction_reference character varying(100),
    processed_by integer,
    is_refund boolean DEFAULT false,
    notes text
);


ALTER TABLE public.payments OWNER TO rentalco;

--
-- Name: payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.payments_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_payment_id_seq OWNER TO rentalco;

--
-- Name: payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.payments_payment_id_seq OWNED BY public.payments.payment_id;


--
-- Name: rental_items; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.rental_items (
    rental_item_id integer NOT NULL,
    rental_id integer,
    equipment_id integer,
    hourly_usage integer,
    daily_rate numeric(10,2) NOT NULL,
    quantity integer DEFAULT 1,
    start_condition text,
    end_condition text,
    damages_reported boolean DEFAULT false,
    damage_description text,
    damage_charges numeric(10,2) DEFAULT 0.00
);


ALTER TABLE public.rental_items OWNER TO rentalco;

--
-- Name: rental_items_rental_item_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.rental_items_rental_item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rental_items_rental_item_id_seq OWNER TO rentalco;

--
-- Name: rental_items_rental_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.rental_items_rental_item_id_seq OWNED BY public.rental_items.rental_item_id;


--
-- Name: rentals; Type: TABLE; Schema: public; Owner: rentalco
--

CREATE TABLE public.rentals (
    rental_id integer NOT NULL,
    customer_id integer,
    rental_date date NOT NULL,
    expected_return_date date NOT NULL,
    actual_return_date date,
    total_amount numeric(10,2),
    deposit_amount numeric(10,2),
    deposit_returned boolean DEFAULT false,
    status character varying(20),
    created_by integer,
    pickup_location_id integer,
    return_location_id integer,
    insurance_coverage boolean DEFAULT true,
    po_number character varying(50),
    notes text,
    CONSTRAINT rentals_status_check CHECK (((status)::text = ANY (ARRAY[('Reserved'::character varying)::text, ('Active'::character varying)::text, ('Completed'::character varying)::text, ('Cancelled'::character varying)::text])))
);


ALTER TABLE public.rentals OWNER TO rentalco;

--
-- Name: rentals_rental_id_seq; Type: SEQUENCE; Schema: public; Owner: rentalco
--

CREATE SEQUENCE public.rentals_rental_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rentals_rental_id_seq OWNER TO rentalco;

--
-- Name: rentals_rental_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rentalco
--

ALTER SEQUENCE public.rentals_rental_id_seq OWNED BY public.rentals.rental_id;


--
-- Name: customers customer_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.customers ALTER COLUMN customer_id SET DEFAULT nextval('public.customers_customer_id_seq'::regclass);


--
-- Name: employee_locations assignment_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employee_locations ALTER COLUMN assignment_id SET DEFAULT nextval('public.employee_locations_assignment_id_seq'::regclass);


--
-- Name: employees employee_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employees ALTER COLUMN employee_id SET DEFAULT nextval('public.employees_employee_id_seq'::regclass);


--
-- Name: equipment equipment_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment ALTER COLUMN equipment_id SET DEFAULT nextval('public.equipment_equipment_id_seq'::regclass);


--
-- Name: equipment_attachments attachment_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment_attachments ALTER COLUMN attachment_id SET DEFAULT nextval('public.equipment_attachments_attachment_id_seq'::regclass);


--
-- Name: equipment_categories category_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment_categories ALTER COLUMN category_id SET DEFAULT nextval('public.equipment_categories_category_id_seq'::regclass);


--
-- Name: inventory_locations location_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.inventory_locations ALTER COLUMN location_id SET DEFAULT nextval('public.inventory_locations_location_id_seq'::regclass);


--
-- Name: maintenance_records maintenance_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.maintenance_records ALTER COLUMN maintenance_id SET DEFAULT nextval('public.maintenance_records_maintenance_id_seq'::regclass);


--
-- Name: payments payment_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.payments ALTER COLUMN payment_id SET DEFAULT nextval('public.payments_payment_id_seq'::regclass);


--
-- Name: rental_items rental_item_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rental_items ALTER COLUMN rental_item_id SET DEFAULT nextval('public.rental_items_rental_item_id_seq'::regclass);


--
-- Name: rentals rental_id; Type: DEFAULT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rentals ALTER COLUMN rental_id SET DEFAULT nextval('public.rentals_rental_id_seq'::regclass);


--
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- Name: employee_locations employee_locations_employee_id_location_id_start_date_key; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employee_locations
    ADD CONSTRAINT employee_locations_employee_id_location_id_start_date_key UNIQUE (employee_id, location_id, start_date);


--
-- Name: employee_locations employee_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employee_locations
    ADD CONSTRAINT employee_locations_pkey PRIMARY KEY (assignment_id);


--
-- Name: employees employees_email_key; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_email_key UNIQUE (email);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (employee_id);


--
-- Name: equipment_attachments equipment_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment_attachments
    ADD CONSTRAINT equipment_attachments_pkey PRIMARY KEY (attachment_id);


--
-- Name: equipment_categories equipment_categories_category_name_key; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment_categories
    ADD CONSTRAINT equipment_categories_category_name_key UNIQUE (category_name);


--
-- Name: equipment_categories equipment_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment_categories
    ADD CONSTRAINT equipment_categories_pkey PRIMARY KEY (category_id);


--
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (equipment_id);


--
-- Name: inventory_locations inventory_locations_location_name_key; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.inventory_locations
    ADD CONSTRAINT inventory_locations_location_name_key UNIQUE (location_name);


--
-- Name: inventory_locations inventory_locations_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.inventory_locations
    ADD CONSTRAINT inventory_locations_pkey PRIMARY KEY (location_id);


--
-- Name: maintenance_records maintenance_records_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.maintenance_records
    ADD CONSTRAINT maintenance_records_pkey PRIMARY KEY (maintenance_id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- Name: rental_items rental_items_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rental_items
    ADD CONSTRAINT rental_items_pkey PRIMARY KEY (rental_item_id);


--
-- Name: rentals rentals_pkey; Type: CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rentals
    ADD CONSTRAINT rentals_pkey PRIMARY KEY (rental_id);


--
-- Name: idx_current_assignments; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_current_assignments ON public.employee_locations USING btree (employee_id, location_id, end_date);


--
-- Name: idx_customer_contact; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_customer_contact ON public.customers USING btree (contact_person);


--
-- Name: idx_customer_credit; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_customer_credit ON public.customers USING btree (credit_limit, is_active);


--
-- Name: idx_customer_location; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_customer_location ON public.customers USING btree (city, state);


--
-- Name: idx_customer_name; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_customer_name ON public.customers USING btree (company_name);


--
-- Name: idx_employee_certification; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_employee_certification ON public.employees USING gin (certification);


--
-- Name: idx_employee_location_dates; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_employee_location_dates ON public.employee_locations USING btree (start_date, end_date);


--
-- Name: idx_employee_name; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_employee_name ON public.employees USING btree (last_name, first_name);


--
-- Name: idx_employee_position; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_employee_position ON public.employees USING btree ("position");


--
-- Name: idx_equipment_availability; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_equipment_availability ON public.equipment USING btree (status);


--
-- Name: idx_equipment_category_status; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_equipment_category_status ON public.equipment USING btree (category_id, status);


--
-- Name: idx_equipment_condition; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_equipment_condition ON public.equipment USING btree (condition_rating);


--
-- Name: idx_equipment_location_status; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_equipment_location_status ON public.equipment USING btree (location_id, status);


--
-- Name: idx_equipment_maintenance_date; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_equipment_maintenance_date ON public.equipment USING btree (last_maintenance_date);


--
-- Name: idx_equipment_rental_rates; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_equipment_rental_rates ON public.equipment USING btree (daily_rental_rate, weekly_rental_rate, monthly_rental_rate);


--
-- Name: idx_equipment_upcoming_maintenance; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_equipment_upcoming_maintenance ON public.maintenance_records USING btree (equipment_id, next_maintenance_date) WHERE ((status)::text <> 'Completed'::text);


--
-- Name: idx_maintenance_next_date; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_maintenance_next_date ON public.maintenance_records USING btree (next_maintenance_date);


--
-- Name: idx_maintenance_status; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_maintenance_status ON public.maintenance_records USING btree (status);


--
-- Name: idx_maintenance_type_date; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_maintenance_type_date ON public.maintenance_records USING btree (maintenance_type, maintenance_date);


--
-- Name: idx_overdue_rentals; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_overdue_rentals ON public.rentals USING btree (expected_return_date) WHERE ((actual_return_date IS NULL) AND ((status)::text = 'Active'::text));


--
-- Name: idx_payments_date; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_payments_date ON public.payments USING btree (payment_date);


--
-- Name: idx_payments_method; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_payments_method ON public.payments USING btree (payment_method);


--
-- Name: idx_payments_refund; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_payments_refund ON public.payments USING btree (is_refund);


--
-- Name: idx_payments_rental_date; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_payments_rental_date ON public.payments USING btree (rental_id, payment_date);


--
-- Name: idx_rental_customer_status; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_rental_customer_status ON public.rentals USING btree (customer_id, status);


--
-- Name: idx_rental_dates; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_rental_dates ON public.rentals USING btree (rental_date, expected_return_date, actual_return_date);


--
-- Name: idx_rental_item_equipment_rental; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_rental_item_equipment_rental ON public.rental_items USING btree (equipment_id, rental_id);


--
-- Name: idx_rental_items_damages; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_rental_items_damages ON public.rental_items USING btree (damages_reported);


--
-- Name: idx_rental_items_hourly_usage; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_rental_items_hourly_usage ON public.rental_items USING btree (hourly_usage);


--
-- Name: idx_rental_location_dates; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_rental_location_dates ON public.rentals USING btree (pickup_location_id, rental_date);


--
-- Name: idx_rental_status_dates; Type: INDEX; Schema: public; Owner: rentalco
--

CREATE INDEX idx_rental_status_dates ON public.rentals USING btree (status, rental_date, expected_return_date);


--
-- Name: employee_locations employee_locations_employee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employee_locations
    ADD CONSTRAINT employee_locations_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employees(employee_id);


--
-- Name: employee_locations employee_locations_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employee_locations
    ADD CONSTRAINT employee_locations_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.inventory_locations(location_id);


--
-- Name: employees employees_primary_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_primary_location_id_fkey FOREIGN KEY (primary_location_id) REFERENCES public.inventory_locations(location_id);


--
-- Name: equipment_attachments equipment_attachments_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment_attachments
    ADD CONSTRAINT equipment_attachments_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(equipment_id);


--
-- Name: equipment_attachments equipment_attachments_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment_attachments
    ADD CONSTRAINT equipment_attachments_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.inventory_locations(location_id);


--
-- Name: equipment equipment_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.equipment_categories(category_id);


--
-- Name: equipment equipment_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_location_id_fkey FOREIGN KEY (location_id) REFERENCES public.inventory_locations(location_id);


--
-- Name: inventory_locations inventory_locations_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.inventory_locations
    ADD CONSTRAINT inventory_locations_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.employees(employee_id);


--
-- Name: maintenance_records maintenance_records_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.maintenance_records
    ADD CONSTRAINT maintenance_records_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(equipment_id);


--
-- Name: maintenance_records maintenance_records_performed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.maintenance_records
    ADD CONSTRAINT maintenance_records_performed_by_fkey FOREIGN KEY (performed_by) REFERENCES public.employees(employee_id);


--
-- Name: payments payments_processed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_processed_by_fkey FOREIGN KEY (processed_by) REFERENCES public.employees(employee_id);


--
-- Name: payments payments_rental_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rentals(rental_id);


--
-- Name: rental_items rental_items_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rental_items
    ADD CONSTRAINT rental_items_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(equipment_id);


--
-- Name: rental_items rental_items_rental_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rental_items
    ADD CONSTRAINT rental_items_rental_id_fkey FOREIGN KEY (rental_id) REFERENCES public.rentals(rental_id);


--
-- Name: rentals rentals_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rentals
    ADD CONSTRAINT rentals_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.employees(employee_id);


--
-- Name: rentals rentals_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rentals
    ADD CONSTRAINT rentals_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.customers(customer_id);


--
-- Name: rentals rentals_pickup_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rentals
    ADD CONSTRAINT rentals_pickup_location_id_fkey FOREIGN KEY (pickup_location_id) REFERENCES public.inventory_locations(location_id);


--
-- Name: rentals rentals_return_location_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: rentalco
--

ALTER TABLE ONLY public.rentals
    ADD CONSTRAINT rentals_return_location_id_fkey FOREIGN KEY (return_location_id) REFERENCES public.inventory_locations(location_id);


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: rentalco
--

ALTER DEFAULT PRIVILEGES FOR ROLE rentalco IN SCHEMA public GRANT ALL ON SEQUENCES TO rentalco;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: rentalco
--

ALTER DEFAULT PRIVILEGES FOR ROLE rentalco IN SCHEMA public GRANT ALL ON TABLES TO rentalco;


--
-- PostgreSQL database dump complete
--

