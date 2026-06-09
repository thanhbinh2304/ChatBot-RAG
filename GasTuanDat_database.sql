--
-- PostgreSQL database dump
--

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.0

-- Started on 2026-06-08 23:42:34

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

--
-- TOC entry 138 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 4579 (class 0 OID 0)
-- Dependencies: 138
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 1462 (class 1247 OID 21889)
-- Name: objecttype; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.objecttype AS ENUM (
    'Nhanvien',
    'Nhacungcap',
    'Khachhang',
    'Sogas'
);


ALTER TYPE public.objecttype OWNER TO postgres;

--
-- TOC entry 1465 (class 1247 OID 21907)
-- Name: ordertype; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ordertype AS ENUM (
    'Dathang',
    'Xuathang',
    'Nhaphang'
);


ALTER TYPE public.ordertype OWNER TO postgres;

--
-- TOC entry 1474 (class 1247 OID 22352)
-- Name: paymentmethod; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.paymentmethod AS ENUM (
    'Cashes',
    'QR_Code'
);


ALTER TYPE public.paymentmethod OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 395 (class 1259 OID 17571)
-- Name: Account; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Account" (
    "accountId" uuid DEFAULT gen_random_uuid() NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    status boolean DEFAULT true NOT NULL,
    "createdAt" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
    "roleId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "deleteAt" timestamp(6) without time zone,
    "employeeId" uuid DEFAULT gen_random_uuid()
);


ALTER TABLE public."Account" OWNER TO postgres;

--
-- TOC entry 398 (class 1259 OID 21419)
-- Name: Area; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Area" (
    "areaId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "areaName" character varying(255) NOT NULL
);


ALTER TABLE public."Area" OWNER TO postgres;

--
-- TOC entry 407 (class 1259 OID 21666)
-- Name: Attribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Attribute" (
    "attributeId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "attributeName" character varying(255) NOT NULL
);


ALTER TABLE public."Attribute" OWNER TO postgres;

--
-- TOC entry 419 (class 1259 OID 22223)
-- Name: CashReceipt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CashReceipt" (
    "receiptId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "receiptDate" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "receiptAmount" numeric(38,2),
    note text,
    "customerId" uuid DEFAULT gen_random_uuid(),
    "createdBy" uuid DEFAULT gen_random_uuid(),
    "transactionTypeId" uuid DEFAULT gen_random_uuid(),
    "invoiceId" uuid DEFAULT gen_random_uuid(),
    "PaymentMethod" public.paymentmethod,
    "objectId" uuid,
    "supplierId" uuid,
    "receiptCode" character varying(255) NOT NULL,
    "createdDate" timestamp with time zone,
    "employeeId" uuid
);


ALTER TABLE public."CashReceipt" OWNER TO postgres;

--
-- TOC entry 401 (class 1259 OID 21545)
-- Name: Customer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Customer" (
    "customerId" uuid DEFAULT gen_random_uuid() NOT NULL,
    gender boolean,
    "dateOfBirth" date,
    note text,
    "fullName" character varying(255),
    "phoneNumber" character varying(255),
    email character varying(255),
    "wardId" uuid DEFAULT gen_random_uuid(),
    "customerGroupId" uuid DEFAULT gen_random_uuid(),
    "customerCode" character varying(255) NOT NULL,
    address text,
    debt numeric(38,2)
);


ALTER TABLE public."Customer" OWNER TO postgres;

--
-- TOC entry 421 (class 1259 OID 25408)
-- Name: CustomerGroup; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."CustomerGroup" (
    "customerGroupid" uuid DEFAULT gen_random_uuid() NOT NULL,
    "groupName" character varying(255) NOT NULL
);


ALTER TABLE public."CustomerGroup" OWNER TO postgres;

--
-- TOC entry 430 (class 1259 OID 36076)
-- Name: Data_Embedding; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Data_Embedding" (
    id bigint NOT NULL,
    process_id character varying NOT NULL,
    process_name text NOT NULL,
    metadata jsonb,
    content text NOT NULL,
    embedding public.vector
);


ALTER TABLE public."Data_Embedding" OWNER TO postgres;

--
-- TOC entry 431 (class 1259 OID 36079)
-- Name: Data_Embedding_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public."Data_Embedding" ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public."Data_Embedding_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 427 (class 1259 OID 35660)
-- Name: DebtReceipt; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DebtReceipt" (
    "receiptId" uuid NOT NULL,
    "debtDate" date,
    "dueDate" date,
    note text,
    "receiptCode" character varying(255) NOT NULL,
    status character varying(255),
    "customerId" uuid,
    "gasBookId" uuid
);


ALTER TABLE public."DebtReceipt" OWNER TO postgres;

--
-- TOC entry 428 (class 1259 OID 35667)
-- Name: DebtReceiptDetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."DebtReceiptDetail" (
    id uuid NOT NULL,
    price numeric(38,2),
    "priceList" character varying(255),
    quantity integer,
    "receiptId" uuid,
    "productId" uuid
);


ALTER TABLE public."DebtReceiptDetail" OWNER TO postgres;

--
-- TOC entry 396 (class 1259 OID 17608)
-- Name: Employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Employee" (
    "employeeId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "employeeCode" character varying(255) NOT NULL,
    "positionId" uuid DEFAULT gen_random_uuid() NOT NULL,
    note character varying(255),
    status boolean DEFAULT true NOT NULL,
    "hireDate" date NOT NULL,
    "createdAt" timestamp(6) without time zone,
    "updatedAt" timestamp(6) without time zone,
    gender character varying(255),
    "dateOfBirth" date,
    "phoneNumber" character varying(255),
    "fullName" character varying(255),
    email character varying(255),
    "wardId" uuid
);


ALTER TABLE public."Employee" OWNER TO postgres;

--
-- TOC entry 403 (class 1259 OID 21582)
-- Name: GasBook; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."GasBook" (
    "gasBookId" uuid DEFAULT gen_random_uuid() NOT NULL,
    gender boolean,
    "dateOfBirth" date,
    points integer,
    cycles smallint,
    note text,
    "fullName" character varying(255),
    "phoneNumber" character varying(255),
    email character varying(255),
    "wardId" uuid DEFAULT gen_random_uuid(),
    cycle integer,
    "customerGroupid" uuid DEFAULT gen_random_uuid(),
    address text,
    debt numeric(38,2),
    "gasBookCode" character varying(255)
);


ALTER TABLE public."GasBook" OWNER TO postgres;

--
-- TOC entry 422 (class 1259 OID 25866)
-- Name: Inventory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Inventory" (
    "stockId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "productId" uuid DEFAULT gen_random_uuid() NOT NULL,
    quantity integer,
    "inventoryId" uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."Inventory" OWNER TO postgres;

--
-- TOC entry 423 (class 1259 OID 26158)
-- Name: InvoiceDetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."InvoiceDetail" (
    id uuid NOT NULL,
    quantity integer NOT NULL,
    total numeric(38,2) NOT NULL,
    "unitPrice" numeric(38,2) NOT NULL,
    "invoiceId" uuid NOT NULL,
    "productId" uuid NOT NULL
);


ALTER TABLE public."InvoiceDetail" OWNER TO postgres;

--
-- TOC entry 400 (class 1259 OID 21474)
-- Name: Object; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Object" (
    "objectId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "fullName" character varying(255),
    "phoneNumber" character varying(255),
    address character varying,
    "wardId" uuid DEFAULT gen_random_uuid(),
    email character varying(255),
    gender boolean,
    "dateOfBirth" date
);


ALTER TABLE public."Object" OWNER TO postgres;

--
-- TOC entry 426 (class 1259 OID 26933)
-- Name: PasswordChangeVerification; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PasswordChangeVerification" (
    "verificationId" uuid NOT NULL,
    "accountId" uuid NOT NULL,
    "createdAt" timestamp(6) without time zone,
    "employeeEmail" character varying(255) NOT NULL,
    "expiresAt" timestamp(6) without time zone NOT NULL,
    "updatedAt" timestamp(6) without time zone,
    "usedAt" timestamp(6) without time zone,
    username character varying(255) NOT NULL,
    "verificationCodeHash" character varying(1200) NOT NULL
);


ALTER TABLE public."PasswordChangeVerification" OWNER TO postgres;

--
-- TOC entry 425 (class 1259 OID 26752)
-- Name: PasswordResetRequest; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PasswordResetRequest" (
    "requestId" uuid NOT NULL,
    "accountId" uuid,
    "approvalToken" uuid,
    "createdAt" timestamp(6) without time zone,
    "employeeEmail" character varying(255),
    "processedAt" timestamp(6) without time zone,
    status character varying(255),
    "updatedAt" timestamp(6) without time zone,
    username character varying(255),
    CONSTRAINT "PasswordResetRequest_status_check" CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying])::text[])))
);


ALTER TABLE public."PasswordResetRequest" OWNER TO postgres;

--
-- TOC entry 420 (class 1259 OID 22282)
-- Name: Payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Payment" (
    "paymentId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "paymentDate" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "paymentAmount" numeric(38,2),
    notes text,
    "objectId" uuid DEFAULT gen_random_uuid(),
    "createdBy" uuid DEFAULT gen_random_uuid(),
    "transactionTypeId" uuid DEFAULT gen_random_uuid(),
    "purchaseId" uuid DEFAULT gen_random_uuid(),
    "stockId" uuid DEFAULT gen_random_uuid(),
    "paymentMethod" public.paymentmethod,
    "supplierId" uuid,
    "customerId" uuid,
    "employeeId" uuid DEFAULT gen_random_uuid(),
    "paymentCode" character varying(255) NOT NULL
);


ALTER TABLE public."Payment" OWNER TO postgres;

--
-- TOC entry 394 (class 1259 OID 17551)
-- Name: Position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Position" (
    "positionId" uuid DEFAULT gen_random_uuid() NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public."Position" OWNER TO postgres;

--
-- TOC entry 408 (class 1259 OID 21678)
-- Name: PriceList; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PriceList" (
    "priceListId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "priceListName" character varying(255) NOT NULL
);


ALTER TABLE public."PriceList" OWNER TO postgres;

--
-- TOC entry 405 (class 1259 OID 21618)
-- Name: Product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Product" (
    "productId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "productName" character varying NOT NULL,
    unit smallint,
    cost numeric(38,2),
    "categoryId" uuid DEFAULT gen_random_uuid(),
    note text,
    "productCode" character varying(255) NOT NULL
);


ALTER TABLE public."Product" OWNER TO postgres;

--
-- TOC entry 409 (class 1259 OID 21691)
-- Name: ProductAttribute; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductAttribute" (
    "productId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "attributeId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "attributeValue" character varying(255),
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."ProductAttribute" OWNER TO postgres;

--
-- TOC entry 404 (class 1259 OID 21605)
-- Name: ProductCategory; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductCategory" (
    "categoryId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "categoryName" character varying(255) NOT NULL
);


ALTER TABLE public."ProductCategory" OWNER TO postgres;

--
-- TOC entry 410 (class 1259 OID 21722)
-- Name: ProductPrice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ProductPrice" (
    "productId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "priceListId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "sellingPrice" numeric(38,2),
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."ProductPrice" OWNER TO postgres;

--
-- TOC entry 429 (class 1259 OID 35740)
-- Name: PromotionDetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PromotionDetail" (
    id uuid NOT NULL,
    quantity integer,
    "productId" uuid,
    "promotionId" uuid,
    "rewardMilestoneId" uuid
);


ALTER TABLE public."PromotionDetail" OWNER TO postgres;

--
-- TOC entry 412 (class 1259 OID 21788)
-- Name: PurchaseDetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PurchaseDetail" (
    "purchaseId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "productId" uuid DEFAULT gen_random_uuid() NOT NULL,
    quantity integer,
    "purchasePrice" numeric(38,2),
    total numeric(38,2),
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."PurchaseDetail" OWNER TO postgres;

--
-- TOC entry 411 (class 1259 OID 21751)
-- Name: PurchaseOrder; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."PurchaseOrder" (
    "purchaseId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "purchaseDate" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "totalAmount" numeric(38,2),
    "employeeId" uuid DEFAULT gen_random_uuid(),
    "supplierId" uuid DEFAULT gen_random_uuid(),
    note text,
    "orderType" public.ordertype,
    "stockId" uuid DEFAULT gen_random_uuid(),
    "discountAmount" numeric(38,2),
    "paidAmount" numeric(38,2),
    "purchaseCode" character varying(255) NOT NULL
);


ALTER TABLE public."PurchaseOrder" OWNER TO postgres;

--
-- TOC entry 424 (class 1259 OID 26237)
-- Name: RewardMilestone; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."RewardMilestone" (
    "promotionId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "rewardQuantity" integer,
    "rewardName" character varying(255),
    "promotionName" character varying(255),
    "startDate" date,
    "endDate" date,
    "leastValue" numeric(38,2),
    value numeric(38,2),
    percentage double precision,
    notes character varying(255),
    "promotionCode" character varying(255)
);


ALTER TABLE public."RewardMilestone" OWNER TO postgres;

--
-- TOC entry 393 (class 1259 OID 17534)
-- Name: Role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Role" (
    "roleId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "roleName" character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    "createdAt" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "updatedAt" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "deletedAt" timestamp with time zone
);


ALTER TABLE public."Role" OWNER TO postgres;

--
-- TOC entry 413 (class 1259 OID 21821)
-- Name: SaleInvoice; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."SaleInvoice" (
    "invoiceId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "invoiceDate" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "totalAmount" numeric(38,2),
    "discountAmount" numeric(38,2),
    "paidAmount" numeric(38,2),
    note text,
    "employeeId" uuid DEFAULT gen_random_uuid(),
    "customerId" uuid DEFAULT gen_random_uuid(),
    "gasBookId" uuid DEFAULT gen_random_uuid(),
    "stockId" uuid DEFAULT gen_random_uuid(),
    "orderType" public.ordertype,
    "invoiceCode" character varying(255) NOT NULL,
    "PaymentMethod" public.paymentmethod
);


ALTER TABLE public."SaleInvoice" OWNER TO postgres;

--
-- TOC entry 406 (class 1259 OID 21641)
-- Name: Stock; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Stock" (
    name character varying(255),
    "wardId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "stockId" uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."Stock" OWNER TO postgres;

--
-- TOC entry 416 (class 1259 OID 22096)
-- Name: StockTake; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockTake" (
    "stockTakeId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "stockTakeDate" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    note text,
    "employeeId" uuid DEFAULT gen_random_uuid(),
    "stockId" uuid DEFAULT gen_random_uuid(),
    "stockTakeCode" character varying(255) NOT NULL
);


ALTER TABLE public."StockTake" OWNER TO postgres;

--
-- TOC entry 417 (class 1259 OID 22132)
-- Name: StockTakeDetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockTakeDetail" (
    "stockTakeId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "productId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "systymQuantity" smallint,
    "actualQuantity" smallint,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."StockTakeDetail" OWNER TO postgres;

--
-- TOC entry 414 (class 1259 OID 21974)
-- Name: StockTransfer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockTransfer" (
    "transferId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "transferDate" timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text) NOT NULL,
    "fromStockId" uuid DEFAULT gen_random_uuid(),
    "toStockId" uuid DEFAULT gen_random_uuid(),
    "employeeId" uuid DEFAULT gen_random_uuid(),
    note text,
    "transferCode" character varying(255) NOT NULL
);


ALTER TABLE public."StockTransfer" OWNER TO postgres;

--
-- TOC entry 415 (class 1259 OID 22074)
-- Name: StockTransferDetail; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."StockTransferDetail" (
    "transferId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "productId" uuid DEFAULT gen_random_uuid() NOT NULL,
    quantity smallint,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."StockTransferDetail" OWNER TO postgres;

--
-- TOC entry 402 (class 1259 OID 21563)
-- Name: Supplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Supplier" (
    "supplierId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "taxNumber" character varying,
    note text,
    "fullName" character varying(255),
    "phoneNumber" character varying(255),
    email character varying(255),
    "wardId" uuid DEFAULT gen_random_uuid(),
    "createdAt" timestamp(6) without time zone,
    "updatedAt" timestamp(6) without time zone,
    address text,
    debt numeric(38,2)
);


ALTER TABLE public."Supplier" OWNER TO postgres;

--
-- TOC entry 397 (class 1259 OID 17690)
-- Name: Token; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Token" (
    "tokenId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "accountId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "refreshToken" character varying(1200) NOT NULL,
    "expiresAt" timestamp with time zone NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp(6) without time zone
);


ALTER TABLE public."Token" OWNER TO postgres;

--
-- TOC entry 418 (class 1259 OID 22151)
-- Name: TransactionType; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."TransactionType" (
    "transactionTypeId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "transactionTypeName" character varying(255) NOT NULL
);


ALTER TABLE public."TransactionType" OWNER TO postgres;

--
-- TOC entry 399 (class 1259 OID 21430)
-- Name: Ward; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Ward" (
    "wardId" uuid DEFAULT gen_random_uuid() NOT NULL,
    "wardName" character varying(255) NOT NULL,
    "areaId" uuid DEFAULT gen_random_uuid() NOT NULL
);


ALTER TABLE public."Ward" OWNER TO postgres;

--
-- TOC entry 4537 (class 0 OID 17571)
-- Dependencies: 395
-- Data for Name: Account; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Account" ("accountId", username, password, status, "createdAt", "updatedAt", "roleId", "deleteAt", "employeeId") FROM stdin;
232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	admin123	$2a$10$AWh9i/phQl.MgU7VBIBg1ODHVVfazpgMdLMhvrZ0cv9DrSa.ywKRi	t	2026-05-16 04:12:31+00	2026-06-04 01:58:32.236668+00	5dc1e56a-5781-443c-8548-d2fd7ec42ffc	\N	4dd20344-7018-498b-b5dc-90e1a7f70255
f98eb979-088d-4de1-817c-b725c781ded8	banhang	$2a$10$uBX/YhRLYGyHUeX2BqLTDOpfE78074pC8jOWJi.96Y4Mw8YC1A1oe	t	2026-06-03 18:39:10.684536+00	2026-06-05 12:42:38.801958+00	9df9d6b3-7894-4840-81d8-b912c80f8f9c	\N	7f9220b0-51cd-4419-a989-11ab38c02235
\.


--
-- TOC entry 4540 (class 0 OID 21419)
-- Dependencies: 398
-- Data for Name: Area; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Area" ("areaId", "areaName") FROM stdin;
361cacd8-6c49-4e90-9e9f-3a748d7c9e98	Hà Nội
c77f774b-0ffa-462d-8e20-b100050ea0f2	Đà Nẵng\n
67073b68-32de-4dea-a74e-bb98359dcbac	Tuyên Quang
3bce45c2-aecf-4c45-b1a8-a84de08e5aef	Thanh Hóa
\.


--
-- TOC entry 4549 (class 0 OID 21666)
-- Dependencies: 407
-- Data for Name: Attribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Attribute" ("attributeId", "attributeName") FROM stdin;
4195742e-f33e-43ea-a063-c23abc591daf	Loại van
d1ebb685-0484-4a89-b7ab-6cea88a377af	Loại bình
\.


--
-- TOC entry 4561 (class 0 OID 22223)
-- Dependencies: 419
-- Data for Name: CashReceipt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CashReceipt" ("receiptId", "receiptDate", "receiptAmount", note, "customerId", "createdBy", "transactionTypeId", "invoiceId", "PaymentMethod", "objectId", "supplierId", "receiptCode", "createdDate", "employeeId") FROM stdin;
\.


--
-- TOC entry 4543 (class 0 OID 21545)
-- Dependencies: 401
-- Data for Name: Customer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Customer" ("customerId", gender, "dateOfBirth", note, "fullName", "phoneNumber", email, "wardId", "customerGroupId", "customerCode", address, debt) FROM stdin;
3e0d7e1f-9d11-46c2-bd2c-d7cb5c8c5d0b	\N	\N		Nguyễn Văn A		\N	\N	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00002	\N	\N
145541f3-0879-40f1-b727-5c467698d04f	\N	\N		Nguyễn Văn A		\N	\N	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00003	\N	\N
637cd524-635f-46d7-b094-2e2e9244d3b6	\N	\N		a		\N	\N	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00004	\N	\N
69b5687e-0bf0-4d37-b4ba-69dbe174c4d7	\N	\N		a		\N	\N	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00005	\N	\N
407728d1-4c49-47d6-9a0a-23a853434a9f	\N	\N		a		\N	\N	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00006	\N	\N
da887278-e7e8-4085-9b68-f50daca9b3a5	\N	\N		Thanh Binha	0397391877	binh2304tto@gmail.com	79e250d5-9e5b-469e-980b-7d2d711ffceb	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00001	aaa	33000000.00
91118c65-6b67-4796-abed-91eb1fe63a8d	\N	\N		Nguyên Thị Trà My		\N	79e250d5-9e5b-469e-980b-7d2d711ffceb	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00009	09	1197477.00
c5c2822d-ca59-4cb5-87db-a827780ab519	\N	\N		Phương Đỗ	0368327093	do1642005@gmail.com	\N	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00010	12 P. Chùa Bộc	\N
e5e1c302-444b-448e-8409-3408d6f92dec	\N	\N		aaa		\N	79e250d5-9e5b-469e-980b-7d2d711ffceb	db0725ef-b291-4bbc-8d99-6181e5a31500	KH00008	\N	1200000.00
4a1156fe-dc50-4b12-99d1-97e584874139	\N	\N		Khách Hàng A	+84 368 327 333	\N	\N	a1a56383-782e-4886-a9c7-dd371f8e4963	KH00011	\N	\N
\.


--
-- TOC entry 4563 (class 0 OID 25408)
-- Dependencies: 421
-- Data for Name: CustomerGroup; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."CustomerGroup" ("customerGroupid", "groupName") FROM stdin;
a1a56383-782e-4886-a9c7-dd371f8e4963	Khách lẻ
db0725ef-b291-4bbc-8d99-6181e5a31500	Khách buôn
\.


--
-- TOC entry 4572 (class 0 OID 36076)
-- Dependencies: 430
-- Data for Name: Data_Embedding; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Data_Embedding" (id, process_id, process_name, metadata, content, embedding) FROM stdin;
\.


--
-- TOC entry 4569 (class 0 OID 35660)
-- Dependencies: 427
-- Data for Name: DebtReceipt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DebtReceipt" ("receiptId", "debtDate", "dueDate", note, "receiptCode", status, "customerId", "gasBookId") FROM stdin;
f0425580-f4db-4cd8-8a9e-e7eeab36edff	2026-06-06	2026-06-30		PN00002	Đã trả nợ	\N	01b85b91-1808-4609-9e75-0ac2715aa8de
0e2828c5-9a9c-4b04-906a-b4ddc3956409	2026-06-07	2026-06-07		PN00004	Đã trả nợ	e5e1c302-444b-448e-8409-3408d6f92dec	\N
732348d5-b407-4248-b45e-3e5b4f04eb02	2026-06-07	2026-06-07		PN00006	Đã trả nợ	da887278-e7e8-4085-9b68-f50daca9b3a5	\N
a56ed1f0-54b9-4cb8-80fd-5df352b878cd	2026-06-08	2026-06-08		PN00007	Đã trả nợ	\N	ff4291f1-73df-48d1-a2ec-8614805f380b
\.


--
-- TOC entry 4570 (class 0 OID 35667)
-- Dependencies: 428
-- Data for Name: DebtReceiptDetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."DebtReceiptDetail" (id, price, "priceList", quantity, "receiptId", "productId") FROM stdin;
3abe0e8d-6665-4c1e-8114-61aa51fc233a	400000.00	Giá chung	1	f0425580-f4db-4cd8-8a9e-e7eeab36edff	0b743790-b844-4ba4-84d4-0ea11e77b8a7
312ff4e5-4640-4774-a75e-06fb129c0aa3	100000.00	Giá chung	1	0e2828c5-9a9c-4b04-906a-b4ddc3956409	0b743790-b844-4ba4-84d4-0ea11e77b8a7
89321214-1d0b-451f-bfef-b32e9311949b	400000.00	Giá chung	2	732348d5-b407-4248-b45e-3e5b4f04eb02	0b743790-b844-4ba4-84d4-0ea11e77b8a7
b7d30139-e9b1-44cb-80cd-e69997798e2a	1900.00	Giá chung	1	a56ed1f0-54b9-4cb8-80fd-5df352b878cd	d639b64c-a843-4c0a-810d-09b640bcddd4
\.


--
-- TOC entry 4538 (class 0 OID 17608)
-- Dependencies: 396
-- Data for Name: Employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Employee" ("employeeId", "employeeCode", "positionId", note, status, "hireDate", "createdAt", "updatedAt", gender, "dateOfBirth", "phoneNumber", "fullName", email, "wardId") FROM stdin;
807f2090-3914-4fc8-81d1-1c63e9d0f08f	SALE1	6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1	string	t	2026-05-20	2026-05-20 10:39:49.328866	2026-05-20 10:39:49.328866	Nam	2005-05-19	0396393612	Dũng	leebindz2304@gmail.com	8350abea-ef44-4e25-a0b6-db1b37b8271f
7f9220b0-51cd-4419-a989-11ab38c02235	SALE2	6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1	v	t	2026-06-01	2026-06-01 23:43:52.537086	2026-06-02 09:20:21.668992	\N	\N	012025368	Bình	v	8350abea-ef44-4e25-a0b6-db1b37b8271f
4dd20344-7018-498b-b5dc-90e1a7f70255	SALE4	6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1		t	2026-06-03	2026-06-03 09:32:36.002082	2026-06-04 01:48:19.580998	\N	\N		admin	tuandung15102005@gmail.com	79e250d5-9e5b-469e-980b-7d2d711ffceb
ee64a21b-015b-4e7f-8562-8760320397eb	SALE3	6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1	cc	t	2026-06-02	2026-06-02 11:40:36.966219	2026-06-04 06:57:49.117252	\N	\N	035289625	Nam	c	8350abea-ef44-4e25-a0b6-db1b37b8271f
33417cec-e45f-4473-9688-40dd64b0e2c0	SALE5	6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1	1	t	2026-06-07	2026-06-07 00:35:47.80116	2026-06-07 00:35:47.80216	\N	\N	0956874563	My	my@gmail.com	da24da12-1de8-4092-a1ef-f9340b7397c2
3b9f9195-df41-4f7c-9fd9-d23a158d79be	SALE6	6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1		t	2026-06-07	2026-06-07 00:37:31.142161	2026-06-07 00:37:31.144162	\N	\N	0978569875	Phương	fuong2k@gmail.com	8350abea-ef44-4e25-a0b6-db1b37b8271f
0c433676-6162-4979-8227-74f91131b51c	SALE7	6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1		t	2026-06-07	2026-06-07 00:38:39.402159	2026-06-07 00:38:39.404162	\N	\N	0975215544	huy	sjakk	79e250d5-9e5b-469e-980b-7d2d711ffceb
53a8c99e-769b-420f-b2bf-0ee798c157ae	KHO1	c57111f7-70bb-46c6-a20f-f00e465c0977		t	2026-06-07	2026-06-07 21:06:29.752363	2026-06-07 21:06:29.752363	\N	\N	0362352145	Đức	duc@gmail.com	79e250d5-9e5b-469e-980b-7d2d711ffceb
\.


--
-- TOC entry 4545 (class 0 OID 21582)
-- Dependencies: 403
-- Data for Name: GasBook; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."GasBook" ("gasBookId", gender, "dateOfBirth", points, cycles, note, "fullName", "phoneNumber", email, "wardId", cycle, "customerGroupid", address, debt, "gasBookCode") FROM stdin;
01b85b91-1808-4609-9e75-0ac2715aa8de	\N	\N	2	\N		Trần Thị B			\N	1	a1a56383-782e-4886-a9c7-dd371f8e4963	\N	800000.00	SG0003
ff4291f1-73df-48d1-a2ec-8614805f380b	\N	\N	5	\N		Nguyễn Văn A	0912345678		79e250d5-9e5b-469e-980b-7d2d711ffceb	1	a1a56383-782e-4886-a9c7-dd371f8e4963	123 Đường B	2000000.00	SG0002
\.


--
-- TOC entry 4564 (class 0 OID 25866)
-- Dependencies: 422
-- Data for Name: Inventory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Inventory" ("stockId", "productId", quantity, "inventoryId") FROM stdin;
adc32cee-8ca0-4b6d-8511-e829065d2691	0b743790-b844-4ba4-84d4-0ea11e77b8a7	98	275a555b-bd3f-4eed-81c2-d6a8868588f6
f273720d-1bf0-4404-b84f-2ba7b7031cfe	46013d6f-c850-447f-9799-8c4c5bc850de	0	c16facfc-ece6-4cf5-8308-236f5c2f585f
1d228b05-b92d-4e5c-a3b6-a7bc460acd68	46013d6f-c850-447f-9799-8c4c5bc850de	0	4e52ae9f-db47-4819-a091-31e879c62bf3
adc32cee-8ca0-4b6d-8511-e829065d2691	3ad36301-9b3f-4555-b973-615b0168bfe0	100	40b3b7dd-72fc-4079-b714-c5913d787170
02fcd124-aec3-45a7-9030-bfecea4e5caa	0f995999-4e25-4991-bc06-113d217436c9	99	7fa23e6f-211b-4ac0-9277-6d82f5f71497
02fcd124-aec3-45a7-9030-bfecea4e5caa	d04bbdf1-2caf-44d6-87b3-f50356ae04d1	0	81f14de0-9d4d-49f5-8b84-111749559cb2
adc32cee-8ca0-4b6d-8511-e829065d2691	d04bbdf1-2caf-44d6-87b3-f50356ae04d1	100	b993042e-0682-4151-9e2a-3f556b2e3dad
02fcd124-aec3-45a7-9030-bfecea4e5caa	026a6bfb-183b-48db-bcf4-dc416f869a3a	110	f4a33d95-5f8b-457b-b7ef-f8dc2ae7c238
adc32cee-8ca0-4b6d-8511-e829065d2691	46013d6f-c850-447f-9799-8c4c5bc850de	100	83737732-821f-4292-a96b-de78e0d9ed32
02fcd124-aec3-45a7-9030-bfecea4e5caa	96acdd46-9c38-4062-bb6b-dbf28ca7414f	0	7d76e725-54ad-4c05-94d9-010be310ee89
0a541d07-53a3-4ccf-ab21-97d7971853bc	0b743790-b844-4ba4-84d4-0ea11e77b8a7	14	a57995d1-2151-441a-901e-9a6c44777782
adc32cee-8ca0-4b6d-8511-e829065d2691	96acdd46-9c38-4062-bb6b-dbf28ca7414f	100	a90aa474-4032-40de-94de-d8528fce64e4
0a541d07-53a3-4ccf-ab21-97d7971853bc	96acdd46-9c38-4062-bb6b-dbf28ca7414f	0	e90bc37d-1cbf-400f-9f7b-f405919ac24d
1d228b05-b92d-4e5c-a3b6-a7bc460acd68	34706bfa-7e3d-47d4-81ab-b823e6b4409a	5	b1fdcb23-5534-4e44-be6b-ba9c7e8dfc94
02fcd124-aec3-45a7-9030-bfecea4e5caa	d639b64c-a843-4c0a-810d-09b640bcddd4	9999	21980c3b-94bc-455f-a798-45354dcea5ea
adc32cee-8ca0-4b6d-8511-e829065d2691	d639b64c-a843-4c0a-810d-09b640bcddd4	9999	ae02c004-c57f-4a90-b959-92b2820cff9b
02fcd124-aec3-45a7-9030-bfecea4e5caa	34706bfa-7e3d-47d4-81ab-b823e6b4409a	0	06ba2e46-766f-41b2-91ce-c747fa354782
adc32cee-8ca0-4b6d-8511-e829065d2691	34706bfa-7e3d-47d4-81ab-b823e6b4409a	109	5ef184e0-614b-4ad4-a035-4ab0986a370e
adc32cee-8ca0-4b6d-8511-e829065d2691	860a0d24-de6e-4105-8cd2-a91a8698095e	91	2cc9245e-3ff3-45a2-8d8a-0dd4fa06bc78
02fcd124-aec3-45a7-9030-bfecea4e5caa	1e9b0d2b-a33c-43c8-b802-26bc17b43937	18	7a679dc1-b353-4f53-8915-3f71738e6e90
02fcd124-aec3-45a7-9030-bfecea4e5caa	860a0d24-de6e-4105-8cd2-a91a8698095e	108	bb6be91e-880d-44bd-9b5a-2b4542fe97ef
02fcd124-aec3-45a7-9030-bfecea4e5caa	0b743790-b844-4ba4-84d4-0ea11e77b8a7	103	bc89ccfe-336b-4dd5-8f50-641321ce3fa7
02fcd124-aec3-45a7-9030-bfecea4e5caa	46013d6f-c850-447f-9799-8c4c5bc850de	5	5bd0c52a-3f9c-4943-8270-2d77bfbaacb3
0a541d07-53a3-4ccf-ab21-97d7971853bc	46013d6f-c850-447f-9799-8c4c5bc850de	5	50abd68c-7b16-492b-8c58-467fb4aaf4c6
adc32cee-8ca0-4b6d-8511-e829065d2691	1e9b0d2b-a33c-43c8-b802-26bc17b43937	200	b8d52c05-8ed2-43fe-9cba-e876b19251d3
\.


--
-- TOC entry 4565 (class 0 OID 26158)
-- Dependencies: 423
-- Data for Name: InvoiceDetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."InvoiceDetail" (id, quantity, total, "unitPrice", "invoiceId", "productId") FROM stdin;
6fbf6e85-3c46-434b-9b3f-bdb45676db3f	2	800000.00	400000.00	1a5a2227-b4f5-4548-a153-5f1ebc0818b4	0b743790-b844-4ba4-84d4-0ea11e77b8a7
b2906db0-93f2-47ac-942e-d137e874e3da	1	400000.00	400000.00	f0b8b0f5-1a37-4f58-9835-baedd62f9696	0b743790-b844-4ba4-84d4-0ea11e77b8a7
ddce160e-dae8-40ab-85cf-83ec933f7c2a	1	400000.00	400000.00	099d8425-e370-4c65-bcb2-d54210be52a4	0b743790-b844-4ba4-84d4-0ea11e77b8a7
20cd9605-7203-4394-9254-3266d9dcbff9	1	400000.00	400000.00	19831d51-5a81-4bf5-832c-eb0ed6124c80	0b743790-b844-4ba4-84d4-0ea11e77b8a7
30dd5641-cb63-41a0-ab22-85c26639936a	-1	0.00	0.00	19831d51-5a81-4bf5-832c-eb0ed6124c80	860a0d24-de6e-4105-8cd2-a91a8698095e
cc045264-466d-4dbd-8a92-0d9750953a79	3	1200000.00	400000.00	4af39d2a-7ad7-4950-8c0c-2703fa002660	0b743790-b844-4ba4-84d4-0ea11e77b8a7
d9f78e2e-7c57-466b-b662-550ec398eb91	-1	0.00	0.00	4af39d2a-7ad7-4950-8c0c-2703fa002660	860a0d24-de6e-4105-8cd2-a91a8698095e
4bb84631-f09d-4079-9f33-15b5be9ba5a2	1	400000.00	400000.00	610db931-1c24-4aba-949e-4323135968d7	0b743790-b844-4ba4-84d4-0ea11e77b8a7
6325f48f-c1f6-4fbd-be09-1cdf3e1ac9ba	1	400000.00	400000.00	11ef5b8a-b04e-4e3f-a9a8-c4df0359076f	0b743790-b844-4ba4-84d4-0ea11e77b8a7
f0265ea8-3d14-4944-80f4-2d8211a64f38	1	400000.00	400000.00	39a4cdff-cd84-4031-88c3-8eacf2a0f24d	0b743790-b844-4ba4-84d4-0ea11e77b8a7
a2fa2767-748c-4b24-996d-82c399889961	1	0.00	0.00	39a4cdff-cd84-4031-88c3-8eacf2a0f24d	0f995999-4e25-4991-bc06-113d217436c9
f20cfad6-84e7-44e3-99b7-c26e0cf19952	1	0.00	0.00	39a4cdff-cd84-4031-88c3-8eacf2a0f24d	026a6bfb-183b-48db-bcf4-dc416f869a3a
97623855-6f9b-4438-b06a-88204102abbd	-1	0.00	0.00	39a4cdff-cd84-4031-88c3-8eacf2a0f24d	860a0d24-de6e-4105-8cd2-a91a8698095e
15c67892-e8de-4ad7-9055-06efe4401d4a	1	400000.00	400000.00	e4214dc6-9791-41ab-9e8f-f1b44c0a3c36	34706bfa-7e3d-47d4-81ab-b823e6b4409a
6a7ce328-3871-450e-be04-f6a646dcff0c	-1	0.00	0.00	e4214dc6-9791-41ab-9e8f-f1b44c0a3c36	860a0d24-de6e-4105-8cd2-a91a8698095e
85cb4133-cd4c-4f57-b2c2-b5aeecc22421	1	400000.00	400000.00	a5b083b2-a40a-4f9c-8ab7-feca7211c929	0b743790-b844-4ba4-84d4-0ea11e77b8a7
673f0132-2e4f-4571-a709-743e481bf412	2	800000.00	400000.00	8634d021-ed79-4c51-8f03-c5b2c8cb3189	0b743790-b844-4ba4-84d4-0ea11e77b8a7
eebd0c66-83ca-4e99-be53-f391d0458b97	2	465086.00	232543.00	8634d021-ed79-4c51-8f03-c5b2c8cb3189	1e9b0d2b-a33c-43c8-b802-26bc17b43937
\.


--
-- TOC entry 4542 (class 0 OID 21474)
-- Dependencies: 400
-- Data for Name: Object; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Object" ("objectId", "fullName", "phoneNumber", address, "wardId", email, gender, "dateOfBirth") FROM stdin;
\.


--
-- TOC entry 4568 (class 0 OID 26933)
-- Dependencies: 426
-- Data for Name: PasswordChangeVerification; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PasswordChangeVerification" ("verificationId", "accountId", "createdAt", "employeeEmail", "expiresAt", "updatedAt", "usedAt", username, "verificationCodeHash") FROM stdin;
439d0de1-d4d3-4e9b-88f4-d4101e63ea87	f0da5bcc-52f4-43bf-99ae-70ec84a1838e	2026-05-22 11:19:00.42555	leebindz2304@gmail.com	2026-05-22 11:28:56.261	2026-05-22 11:19:58.37708	2026-05-22 11:19:58.333	sale1	$2a$10$TDflS9Z9gkTn4V.jfCWpZOpZjY8TGGm4Tl9XeYOTJ7r6q4YdIJwRK
\.


--
-- TOC entry 4567 (class 0 OID 26752)
-- Dependencies: 425
-- Data for Name: PasswordResetRequest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PasswordResetRequest" ("requestId", "accountId", "approvalToken", "createdAt", "employeeEmail", "processedAt", status, "updatedAt", username) FROM stdin;
1911449f-7f12-4947-a8a3-23f2c70e6067	f0da5bcc-52f4-43bf-99ae-70ec84a1838e	d4de9d61-acd1-4151-a10b-a8ab28dd158c	2026-05-21 21:35:03.041205	leebindz2304@gmail.com	\N	PENDING	2026-05-21 21:35:03.041205	sale1
49f408b8-20cf-43f9-bbc4-be86067f1d0e	f0da5bcc-52f4-43bf-99ae-70ec84a1838e	e07c9435-3fed-4b9d-bf8e-9b94f98dca4b	2026-05-21 21:44:55.202156	leebindz2304@gmail.com	\N	PENDING	2026-05-21 21:44:55.202156	sale1
fc0d6a7a-5e58-4adc-987e-d66fa9f79889	f0da5bcc-52f4-43bf-99ae-70ec84a1838e	946cf9e6-4770-4281-bbad-8ca5ea1a0d0a	2026-05-21 22:06:42.94043	leebindz2304@gmail.com	2026-05-21 22:10:03.21	APPROVED	2026-05-21 22:10:07.547799	sale1
df3c0c3c-4681-4d46-84fc-1cff63f82db0	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	d6f70161-eebe-4703-ad0a-a15e73decc88	2026-06-04 01:51:58.731258	tuandung15102005@gmail.com	\N	PENDING	2026-06-04 01:51:58.731258	admin123
be664c97-0867-4c07-beb9-740a9b3f7740	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	c7d5a75e-2a1a-4844-bf39-cad6e2afbbf9	2026-06-04 01:55:24.184079	tuandung15102005@gmail.com	\N	PENDING	2026-06-04 01:55:24.184079	admin123
099f6e50-29a4-4a55-8f3d-ea912be82e85	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	124ef20c-1778-4bc5-b604-8bb3942665d1	2026-06-04 01:58:26.231004	tuandung15102005@gmail.com	\N	PENDING	2026-06-04 01:58:26.231004	admin123
0a008ca5-2f77-4a45-921f-ba337a214f0f	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	39175539-530a-49ba-b95f-dab25d6ece82	2026-06-04 01:59:01.514934	tuandung15102005@gmail.com	\N	PENDING	2026-06-04 01:59:01.514934	admin123
8c8ecfaf-8d85-4085-82f2-c5cb269d9fab	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	a040d758-f497-498d-b15e-b49ca06099ef	2026-06-04 08:40:14.700764	tuandung15102005@gmail.com	\N	PENDING	2026-06-04 08:40:14.700764	admin123
6d817f98-89e9-4bb1-a6bd-333516b0c841	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	cdc1b4a7-f339-44c7-b019-a015e09cbac1	2026-06-04 13:43:05.38846	tuandung15102005@gmail.com	\N	PENDING	2026-06-04 13:43:05.38846	admin123
903c65ee-a7cd-43b2-a450-8208cb4b9170	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	cd794006-85c1-48c8-871b-bde21956d256	2026-06-04 13:58:29.556042	tuandung15102005@gmail.com	\N	PENDING	2026-06-04 13:58:29.556042	admin123
a12716f5-6573-4ee9-a844-d7dee17bd6f6	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	6678d21c-b398-4f8a-b44f-617d906db4cf	2026-06-05 15:02:50.945998	tuandung15102005@gmail.com	\N	PENDING	2026-06-05 15:02:50.945998	admin123
b17c5e73-19b6-4c70-9d67-0e7853910737	f98eb979-088d-4de1-817c-b725c781ded8	1065e4c6-d765-4c19-aff0-5ec39e2b3dce	2026-06-05 15:05:35.845994	v	\N	PENDING	2026-06-05 15:05:35.845994	banhang
ec01c1f3-5e4e-44ef-a721-e9938207a892	f98eb979-088d-4de1-817c-b725c781ded8	df908d9c-5134-4fc0-bcf1-5e3bb51b12bc	2026-06-05 15:18:48.787911	v	\N	PENDING	2026-06-05 15:18:48.787911	banhang
ae6e0e76-a56e-41ba-81af-4c3f6d61e7aa	f98eb979-088d-4de1-817c-b725c781ded8	4581e7ba-9c1f-4d4f-bbfa-071b74016ff0	2026-06-05 15:19:48.518989	v	\N	PENDING	2026-06-05 15:19:48.518989	banhang
d3203403-5b95-40ed-a8c8-585312ce6321	f98eb979-088d-4de1-817c-b725c781ded8	52ac2328-ad56-4396-880e-aa3c2cc9a7db	2026-06-05 15:24:13.509105	v	\N	PENDING	2026-06-05 15:24:13.509105	banhang
8ab57125-b4fb-4b96-bdda-4ac628adc963	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	26db8cc0-a424-419c-b6ca-aef02c6f4387	2026-06-05 19:40:07.395168	tuandung15102005@gmail.com	\N	PENDING	2026-06-05 19:40:07.395168	admin123
e6263e8b-99e2-4e1d-aee9-f4fac22c9bad	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	9d4df0fa-ec39-41c1-af07-6984e1322ae6	2026-06-05 22:29:48.427039	tuandung15102005@gmail.com	\N	PENDING	2026-06-05 22:29:48.427039	admin123
907cc1ca-45f4-4663-b4f4-b83f8fc1ae0a	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	cc98e38c-a4ad-4259-bbe6-08bd45bcb971	2026-06-06 08:00:05.095251	tuandung15102005@gmail.com	\N	PENDING	2026-06-06 08:00:05.095251	admin123
f96e28ea-2b2e-4dcd-8c40-689adbd3176d	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	4874b095-508e-4229-9ac0-fce2e35c893a	2026-06-06 10:10:37.544129	tuandung15102005@gmail.com	\N	PENDING	2026-06-06 10:10:37.544129	admin123
508155d0-4924-4e06-9816-b13153e53068	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	0b79639f-8771-4f9c-b8b0-b25a15a6aa7c	2026-06-06 10:17:46.637986	tuandung15102005@gmail.com	\N	PENDING	2026-06-06 10:17:46.637986	admin123
9fbda059-37da-4df9-b72b-37608f334b07	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	46b7743c-9964-445f-8477-af226b9f8f5a	2026-06-06 10:26:57.546366	tuandung15102005@gmail.com	\N	PENDING	2026-06-06 10:26:57.546366	admin123
2242d5fc-33fb-4135-808e-b1ad586ae93b	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	3e56f50f-5f45-4d32-accd-26fd6f38a7f0	2026-06-06 10:44:53.720122	tuandung15102005@gmail.com	\N	PENDING	2026-06-06 10:44:53.720122	admin123
e3389df3-6aee-4b32-9d4c-b5f9f33501ce	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	4d98ccbb-0208-4966-8664-feabab4de1ca	2026-06-08 15:07:43.921645	tuandung15102005@gmail.com	\N	PENDING	2026-06-08 15:07:43.921645	admin123
3820a3f9-5155-4078-88ef-a08f6ffc75a8	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	ace0044a-2622-404d-843b-13d111b9476f	2026-06-08 15:34:16.624786	tuandung15102005@gmail.com	\N	PENDING	2026-06-08 15:34:16.625443	admin123
\.


--
-- TOC entry 4562 (class 0 OID 22282)
-- Dependencies: 420
-- Data for Name: Payment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Payment" ("paymentId", "paymentDate", "paymentAmount", notes, "objectId", "createdBy", "transactionTypeId", "purchaseId", "stockId", "paymentMethod", "supplierId", "customerId", "employeeId", "paymentCode") FROM stdin;
f44fe23e-ede2-4243-acec-5aa35c316253	2026-06-02 19:36:51.303+00	600000.00	trả nợ	\N	\N	\N	6b8c5dd2-b7b5-4a78-b1a5-5b0f7437e249	0a541d07-53a3-4ccf-ab21-97d7971853bc	Cashes	ab2d45a6-fca1-4dbf-88d6-62e15ac1dc56	\N	807f2090-3914-4fc8-81d1-1c63e9d0f08f	PC011323
\.


--
-- TOC entry 4536 (class 0 OID 17551)
-- Dependencies: 394
-- Data for Name: Position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Position" ("positionId", name) FROM stdin;
6c934a35-a4ac-449c-9dd3-3e5fa1a87ed1	sale
c57111f7-70bb-46c6-a20f-f00e465c0977	kho
\.


--
-- TOC entry 4550 (class 0 OID 21678)
-- Dependencies: 408
-- Data for Name: PriceList; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PriceList" ("priceListId", "priceListName") FROM stdin;
973a6ba7-ee9c-41d7-8873-fab64247291b	Bảng giá chung
361704f0-7388-4ada-bad1-57235901c388	Bảng giá vip
4158752a-858d-4b34-b5fe-975ef9b0643c	Bảng giá buôn
\.


--
-- TOC entry 4547 (class 0 OID 21618)
-- Dependencies: 405
-- Data for Name: Product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Product" ("productId", "productName", unit, cost, "categoryId", note, "productCode") FROM stdin;
46013d6f-c850-447f-9799-8c4c5bc850de	Gas Vina	3	300000.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	GVN
1e9b0d2b-a33c-43c8-b802-26bc17b43937	Gas Vina	3	300000.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	BG01
3ad36301-9b3f-4555-b973-615b0168bfe0	Gas Vina	3	400000.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	BG02
0b743790-b844-4ba4-84d4-0ea11e77b8a7	Gas Hoàng Long	3	350000.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	GHL
860a0d24-de6e-4105-8cd2-a91a8698095e	Vỏ gas Vina	3	0.00	c91958fb-8db7-41fe-a4fd-3594c5282cb6	\N	VG01
d639b64c-a843-4c0a-810d-09b640bcddd4	Tiền vỏ	\N	0.00	b632533b-b348-4d87-bfc6-0fd807fd1dce	\N	DV01
0f995999-4e25-4991-bc06-113d217436c9	Bát tô	\N	0.00	b632533b-b348-4d87-bfc6-0fd807fd1dce	\N	DV02
026a6bfb-183b-48db-bcf4-dc416f869a3a	Đôi lót tay	\N	0.00	b632533b-b348-4d87-bfc6-0fd807fd1dce	\N	DV03
53c17946-1dfa-4810-83b0-d553e9bbbd3f	Gas Petrolimex	3	0.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	PT
d04bbdf1-2caf-44d6-87b3-f50356ae04d1	Gas Hoàng Long	3	300000.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	BG03
96acdd46-9c38-4062-bb6b-dbf28ca7414f	Gas Hải Linh	3	300000.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	GHLI
34706bfa-7e3d-47d4-81ab-b823e6b4409a	Gas Hải Linh	3	300000.00	55e6cd46-e2e9-4373-83aa-047869aff0e9	\N	BG04
\.


--
-- TOC entry 4551 (class 0 OID 21691)
-- Dependencies: 409
-- Data for Name: ProductAttribute; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ProductAttribute" ("productId", "attributeId", "attributeValue", id) FROM stdin;
46013d6f-c850-447f-9799-8c4c5bc850de	4195742e-f33e-43ea-a063-c23abc591daf	Van ngang	91e59ec6-9078-44c2-a066-910c537f4240
46013d6f-c850-447f-9799-8c4c5bc850de	d1ebb685-0484-4a89-b7ab-6cea88a377af	12kg	34ad1cc3-02b7-4f42-981a-bd0e9148764d
3ad36301-9b3f-4555-b973-615b0168bfe0	d1ebb685-0484-4a89-b7ab-6cea88a377af	45kg	1070db05-7d4f-45b6-a326-2b3d4db783e8
860a0d24-de6e-4105-8cd2-a91a8698095e	4195742e-f33e-43ea-a063-c23abc591daf	Van ngang	d476d1b8-cc8b-49c8-a010-3dadc2ab9f47
860a0d24-de6e-4105-8cd2-a91a8698095e	d1ebb685-0484-4a89-b7ab-6cea88a377af	12Kg	b93f4c35-5ac8-427f-90ad-006dda70a776
0b743790-b844-4ba4-84d4-0ea11e77b8a7	4195742e-f33e-43ea-a063-c23abc591daf	Van ngang	cb91bce9-edbf-4173-a354-fa66ab7c7c45
0b743790-b844-4ba4-84d4-0ea11e77b8a7	d1ebb685-0484-4a89-b7ab-6cea88a377af	12Kg	f534fd6e-1ccd-4b17-85d5-fd1a73750151
d04bbdf1-2caf-44d6-87b3-f50356ae04d1	4195742e-f33e-43ea-a063-c23abc591daf	Van chụp	56f50e8b-e7ee-4480-bc4d-0437420e7fbe
d04bbdf1-2caf-44d6-87b3-f50356ae04d1	d1ebb685-0484-4a89-b7ab-6cea88a377af	12kg	bee4e39c-ecba-4869-9576-f64fe86d0067
96acdd46-9c38-4062-bb6b-dbf28ca7414f	4195742e-f33e-43ea-a063-c23abc591daf	Van ngang	dafd4bd3-325f-4d6d-85bb-fd0c3e135b37
96acdd46-9c38-4062-bb6b-dbf28ca7414f	d1ebb685-0484-4a89-b7ab-6cea88a377af	12Kg	f90556f3-ca2c-4ab2-904d-2fe510729faf
34706bfa-7e3d-47d4-81ab-b823e6b4409a	4195742e-f33e-43ea-a063-c23abc591daf	Van chụp	bd69a3d7-94ad-460c-aba2-bb7063e3bb9c
34706bfa-7e3d-47d4-81ab-b823e6b4409a	d1ebb685-0484-4a89-b7ab-6cea88a377af	12Kg	d95a4ba1-465a-4822-b627-ad4712f8c189
1e9b0d2b-a33c-43c8-b802-26bc17b43937	4195742e-f33e-43ea-a063-c23abc591daf	Van chụp	ce8ff28a-4228-4594-a25c-83c987a04e2d
1e9b0d2b-a33c-43c8-b802-26bc17b43937	d1ebb685-0484-4a89-b7ab-6cea88a377af	12Kg	8c1036c4-16c1-4427-a1b2-86762868148e
\.


--
-- TOC entry 4546 (class 0 OID 21605)
-- Dependencies: 404
-- Data for Name: ProductCategory; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ProductCategory" ("categoryId", "categoryName") FROM stdin;
c91958fb-8db7-41fe-a4fd-3594c5282cb6	Vỏ gas
bd90eb19-cd7b-4c60-ab31-543f5c5b58f5	Khuyến mại
55e6cd46-e2e9-4373-83aa-047869aff0e9	Bình gas
b632533b-b348-4d87-bfc6-0fd807fd1dce	Dịch vụ
\.


--
-- TOC entry 4552 (class 0 OID 21722)
-- Dependencies: 410
-- Data for Name: ProductPrice; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ProductPrice" ("productId", "priceListId", "sellingPrice", id) FROM stdin;
46013d6f-c850-447f-9799-8c4c5bc850de	973a6ba7-ee9c-41d7-8873-fab64247291b	400000.00	98b4766a-bff7-4cdd-a0d9-034542c7c2a8
46013d6f-c850-447f-9799-8c4c5bc850de	4158752a-858d-4b34-b5fe-975ef9b0643c	350000.00	34c12834-cc78-4631-8fef-18bd39635a0e
46013d6f-c850-447f-9799-8c4c5bc850de	361704f0-7388-4ada-bad1-57235901c388	370000.00	6034fd20-11b1-4220-bec8-277cffd2d436
0b743790-b844-4ba4-84d4-0ea11e77b8a7	973a6ba7-ee9c-41d7-8873-fab64247291b	400000.00	ca6812b4-0af5-4dbb-aa13-4814f4b25324
0b743790-b844-4ba4-84d4-0ea11e77b8a7	4158752a-858d-4b34-b5fe-975ef9b0643c	380000.00	28baf1f8-67f2-4ded-8396-583d40082f87
0b743790-b844-4ba4-84d4-0ea11e77b8a7	361704f0-7388-4ada-bad1-57235901c388	390000.00	1476d0ee-d231-4008-9a1d-0ec225f0656c
d04bbdf1-2caf-44d6-87b3-f50356ae04d1	973a6ba7-ee9c-41d7-8873-fab64247291b	400000.00	0cd97962-7023-4214-8fe7-eeb8675863d3
d04bbdf1-2caf-44d6-87b3-f50356ae04d1	4158752a-858d-4b34-b5fe-975ef9b0643c	380000.00	63fa7998-b777-4220-a293-039a3cce861c
96acdd46-9c38-4062-bb6b-dbf28ca7414f	973a6ba7-ee9c-41d7-8873-fab64247291b	400000.00	2254f58d-3f49-4107-89c8-28381412c400
34706bfa-7e3d-47d4-81ab-b823e6b4409a	973a6ba7-ee9c-41d7-8873-fab64247291b	400000.00	5e3def7f-5e79-4df0-9e71-61ebe7a17d72
\.


--
-- TOC entry 4571 (class 0 OID 35740)
-- Dependencies: 429
-- Data for Name: PromotionDetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PromotionDetail" (id, quantity, "productId", "promotionId", "rewardMilestoneId") FROM stdin;
d9851241-ccf2-4257-a629-076db77de6d0	1	026a6bfb-183b-48db-bcf4-dc416f869a3a	\N	33fa57e4-7350-4178-b9d8-ffad3bfe3e30
d43bf4a5-561c-4f77-86d3-ed7606508e6e	1	0f995999-4e25-4991-bc06-113d217436c9	\N	5faea7be-514b-4bb7-9c94-ee64bd8f678a
2cb621a5-4aaf-4e5b-8bef-734451c642c1	1	026a6bfb-183b-48db-bcf4-dc416f869a3a	\N	183d6bf3-9cdc-4826-9141-6e30458267b7
c4f44bcf-5b1b-4fbe-8b4d-de4a3f08c24f	1	0f995999-4e25-4991-bc06-113d217436c9	\N	55893cb5-6653-4ff1-bb80-ca75b317208c
b39196e7-5e41-4e13-b910-7bff5af3a9fc	1	0b743790-b844-4ba4-84d4-0ea11e77b8a7	\N	0b9818bc-f122-412d-9e41-9afb8eada6d1
\.


--
-- TOC entry 4554 (class 0 OID 21788)
-- Dependencies: 412
-- Data for Name: PurchaseDetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PurchaseDetail" ("purchaseId", "productId", quantity, "purchasePrice", total, id) FROM stdin;
91385444-e6a9-407b-a27a-0b56c0ccbf01	0b743790-b844-4ba4-84d4-0ea11e77b8a7	20	200000.00	4000000.00	3333e996-5217-4370-874e-31dbe1699485
b58ef00c-68dd-497e-b51b-431a9423ccfb	860a0d24-de6e-4105-8cd2-a91a8698095e	-140	0.00	0.00	270a72db-d29c-4a00-af02-a203c3df72b3
1ca98090-4989-481c-af15-a9d4562bbfe4	0b743790-b844-4ba4-84d4-0ea11e77b8a7	105	100000.00	10500000.00	ad23e673-b0c7-41cf-a784-818701b8b554
ff0815a3-9496-4aa4-993f-ac50c8fb5e7b	1e9b0d2b-a33c-43c8-b802-26bc17b43937	4	0.00	0.00	6b3bbe19-375b-40d7-8410-3c36a76ee871
ff0815a3-9496-4aa4-993f-ac50c8fb5e7b	46013d6f-c850-447f-9799-8c4c5bc850de	3	0.00	0.00	b04beefa-d7c8-4c18-983f-18d9568edc76
b1373947-25d4-4c62-8864-96bac1342436	0b743790-b844-4ba4-84d4-0ea11e77b8a7	10	100000.00	1000000.00	c002e1e2-33e3-4892-9aef-d88c9631dfb3
091ce737-3eea-4ae5-aa5b-8c86ff8c87a5	860a0d24-de6e-4105-8cd2-a91a8698095e	5	0.00	0.00	edcf6be3-11b3-4c55-b36f-f18710e71018
091ce737-3eea-4ae5-aa5b-8c86ff8c87a5	0b743790-b844-4ba4-84d4-0ea11e77b8a7	5	0.00	0.00	7afc17da-ac2d-4f3a-af25-f704532e15f4
0018305e-79d5-4642-b0d9-9eb3b704ccda	1e9b0d2b-a33c-43c8-b802-26bc17b43937	100	300000.00	30000000.00	a403052a-bf33-4d33-bf5d-fc789be00846
5c6a471d-4ac5-409b-b866-28f21800666f	34706bfa-7e3d-47d4-81ab-b823e6b4409a	10	300000.00	3000000.00	90b93e5f-0e73-4c67-9690-ef92b3b84f81
5c6a471d-4ac5-409b-b866-28f21800666f	860a0d24-de6e-4105-8cd2-a91a8698095e	-10	0.00	0.00	67d1efec-ff9c-445b-9f3a-613c60a939ef
d00e0ad4-467a-4719-b89a-d5f166ee84b7	34706bfa-7e3d-47d4-81ab-b823e6b4409a	14	0.00	0.00	570cf493-4cf8-4bde-a3fb-0309752a4877
2d7c3c15-35ce-4fd7-b5cc-38833d4fc7e1	34706bfa-7e3d-47d4-81ab-b823e6b4409a	14	0.00	0.00	96bcf85b-f9ed-499a-b879-a5fc8b9fabab
d4fddd6c-7540-438e-b89d-65d8a354c001	0b743790-b844-4ba4-84d4-0ea11e77b8a7	10	300000.00	3000000.00	b7b72be9-0563-4612-8cc5-006b9479c427
d4fddd6c-7540-438e-b89d-65d8a354c001	96acdd46-9c38-4062-bb6b-dbf28ca7414f	1	0.00	0.00	0767901f-b3a2-4c76-8017-ca669b1ced39
d8d8ad8e-75ad-4974-8d6b-91c35c106faf	0b743790-b844-4ba4-84d4-0ea11e77b8a7	7	300000.00	2100000.00	b902b362-5f61-4c33-882f-91bd30a027de
d8d8ad8e-75ad-4974-8d6b-91c35c106faf	1e9b0d2b-a33c-43c8-b802-26bc17b43937	20	500000.00	10000000.00	a366bc47-c5d9-4f80-a764-87a56fb611a7
d8d8ad8e-75ad-4974-8d6b-91c35c106faf	026a6bfb-183b-48db-bcf4-dc416f869a3a	11	30000.00	330000.00	e01472d0-aeaf-4fb7-97e2-6e8e3b24de0d
5e9e75aa-2c58-4259-838a-c23eb1a2c9dc	1e9b0d2b-a33c-43c8-b802-26bc17b43937	7	500000.00	3500000.00	174eb45d-3b75-45d2-b812-74513432e1ea
02e008e4-17e4-4742-8f59-16ee9794a0ac	0b743790-b844-4ba4-84d4-0ea11e77b8a7	10	500000.00	5000000.00	053233cb-7fa5-41ad-b859-0b2a92667c09
02e008e4-17e4-4742-8f59-16ee9794a0ac	46013d6f-c850-447f-9799-8c4c5bc850de	5	450000.00	2250000.00	2b3508dd-d033-48eb-b8ef-60a9fbcf5190
e32ad955-39e5-48ec-8d06-d08d57c0768a	34706bfa-7e3d-47d4-81ab-b823e6b4409a	5	500000.00	2500000.00	9862431b-29b7-47fe-8c0a-fe21ea369ffd
66f91475-ba27-4c4c-af8c-6c2564625b8b	0b743790-b844-4ba4-84d4-0ea11e77b8a7	1	400000.00	400000.00	ef9d6b5f-9e6e-41cf-8a25-d63550e28645
\.


--
-- TOC entry 4553 (class 0 OID 21751)
-- Dependencies: 411
-- Data for Name: PurchaseOrder; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."PurchaseOrder" ("purchaseId", "purchaseDate", "totalAmount", "employeeId", "supplierId", note, "orderType", "stockId", "discountAmount", "paidAmount", "purchaseCode") FROM stdin;
529a2dcb-3ffd-49e1-b6f2-ccd72ff1334b	2026-06-02 03:22:29.566735+00	300001.00	807f2090-3914-4fc8-81d1-1c63e9d0f08f	ab2d45a6-fca1-4dbf-88d6-62e15ac1dc56		Dathang	\N	0.00	0.00	DHN00003
8a0c375d-f752-4514-b544-4fb8135be012	2026-06-02 03:23:54.115487+00	300001.00	807f2090-3914-4fc8-81d1-1c63e9d0f08f	ab2d45a6-fca1-4dbf-88d6-62e15ac1dc56		Dathang	\N	0.00	0.00	DHN00004
98f0d9ab-1c3f-44fe-b762-02ae20295fb1	2026-06-02 03:24:31.887911+00	300001.00	807f2090-3914-4fc8-81d1-1c63e9d0f08f	ab2d45a6-fca1-4dbf-88d6-62e15ac1dc56		Dathang	\N	0.00	0.00	DHN00005
2d7c3c15-35ce-4fd7-b5cc-38833d4fc7e1	2026-06-06 17:33:00.616307+00	0.00	7f9220b0-51cd-4419-a989-11ab38c02235	70670ca3-5670-4484-a9c2-b9892415ee1f		Dathang	adc32cee-8ca0-4b6d-8511-e829065d2691	0.00	0.00	DHN00016
d4fddd6c-7540-438e-b89d-65d8a354c001	2026-06-07 14:38:56.530451+00	3000000.00	\N	70670ca3-5670-4484-a9c2-b9892415ee1f		Nhaphang	0a541d07-53a3-4ccf-ab21-97d7971853bc	0.00	0.00	DHN00017
6b8c5dd2-b7b5-4a78-b1a5-5b0f7437e249	2026-06-02 04:02:39.190441+00	900003.00	807f2090-3914-4fc8-81d1-1c63e9d0f08f	ab2d45a6-fca1-4dbf-88d6-62e15ac1dc56		Nhaphang	0a541d07-53a3-4ccf-ab21-97d7971853bc	0.00	600000.00	DHN00008
136c962b-ce44-410e-961d-8c46463f90fe	2026-06-07 14:38:58.786905+00	3900000.00	\N	70670ca3-5670-4484-a9c2-b9892415ee1f		Nhaphang	0a541d07-53a3-4ccf-ab21-97d7971853bc	0.00	0.00	DHN00018
d8d8ad8e-75ad-4974-8d6b-91c35c106faf	2026-06-07 14:46:31.172939+00	12430000.00	ee64a21b-015b-4e7f-8562-8760320397eb	1fef3b26-5aab-429f-aada-d9e8a7a6ed04		Nhaphang	02fcd124-aec3-45a7-9030-bfecea4e5caa	0.00	0.00	DHN00019
5e9e75aa-2c58-4259-838a-c23eb1a2c9dc	2026-06-07 16:14:44.177795+00	3500000.00	807f2090-3914-4fc8-81d1-1c63e9d0f08f	7d65de23-e719-4dc6-86fe-4dc218f9e68e		Dathang	f273720d-1bf0-4404-b84f-2ba7b7031cfe	0.00	0.00	DHN00022
e32ad955-39e5-48ec-8d06-d08d57c0768a	2026-06-07 16:16:56.780598+00	2500000.00	7f9220b0-51cd-4419-a989-11ab38c02235	7d65de23-e719-4dc6-86fe-4dc218f9e68e		Nhaphang	1d228b05-b92d-4e5c-a3b6-a7bc460acd68	0.00	0.00	DHN00023
91385444-e6a9-407b-a27a-0b56c0ccbf01	2026-06-03 08:25:42.601991+00	4000000.00	\N	2910f504-3998-41c3-a84b-0983ccc34cc4		Nhaphang	02fcd124-aec3-45a7-9030-bfecea4e5caa	0.00	200000.00	DHN00009
b58ef00c-68dd-497e-b51b-431a9423ccfb	2026-06-03 08:54:37.227874+00	0.00	\N	2910f504-3998-41c3-a84b-0983ccc34cc4		Nhaphang	02fcd124-aec3-45a7-9030-bfecea4e5caa	0.00	0.00	DHN00006
02e008e4-17e4-4742-8f59-16ee9794a0ac	2026-06-07 15:48:46.121849+00	7250000.00	33417cec-e45f-4473-9688-40dd64b0e2c0	7d65de23-e719-4dc6-86fe-4dc218f9e68e		Dathang	f273720d-1bf0-4404-b84f-2ba7b7031cfe	0.00	0.00	DHN00020
1ca98090-4989-481c-af15-a9d4562bbfe4	2026-06-03 13:47:55.944446+00	10500000.00	\N	2910f504-3998-41c3-a84b-0983ccc34cc4		Nhaphang	02fcd124-aec3-45a7-9030-bfecea4e5caa	2000000.00	1000000.00	DHN00007
66f91475-ba27-4c4c-af8c-6c2564625b8b	2026-06-08 08:11:03.05194+00	400000.00	3b9f9195-df41-4f7c-9fd9-d23a158d79be	2910f504-3998-41c3-a84b-0983ccc34cc4		Nhaphang	02fcd124-aec3-45a7-9030-bfecea4e5caa	0.00	400000.00	DHN00021
ff0815a3-9496-4aa4-993f-ac50c8fb5e7b	2026-06-03 22:43:14.250678+00	0.00	4dd20344-7018-498b-b5dc-90e1a7f70255	70670ca3-5670-4484-a9c2-b9892415ee1f		Dathang	0a541d07-53a3-4ccf-ab21-97d7971853bc	0.00	0.00	DHN00010
b1373947-25d4-4c62-8864-96bac1342436	2026-06-04 02:05:49.254+00	1000000.00	\N	70670ca3-5670-4484-a9c2-b9892415ee1f		Nhaphang	0a541d07-53a3-4ccf-ab21-97d7971853bc	100000.00	500000.00	DHN00011
091ce737-3eea-4ae5-aa5b-8c86ff8c87a5	2026-06-04 06:50:54.897169+00	0.00	ee64a21b-015b-4e7f-8562-8760320397eb	ab2d45a6-fca1-4dbf-88d6-62e15ac1dc56		Nhaphang	02fcd124-aec3-45a7-9030-bfecea4e5caa	0.00	0.00	DHN00013
0018305e-79d5-4642-b0d9-9eb3b704ccda	2026-06-05 13:28:20.127887+00	30000000.00	\N	69f2f5ec-d034-47d9-ae78-f010adda848e		Nhaphang	adc32cee-8ca0-4b6d-8511-e829065d2691	1000000.00	0.00	DHN00012
5c6a471d-4ac5-409b-b866-28f21800666f	2026-06-06 03:48:16.289557+00	3000000.00	\N	a75e1685-c14b-4bab-9535-69fa00598f8b		Nhaphang	adc32cee-8ca0-4b6d-8511-e829065d2691	0.00	0.00	DHN00014
d00e0ad4-467a-4719-b89a-d5f166ee84b7	2026-06-06 17:32:57.872309+00	0.00	7f9220b0-51cd-4419-a989-11ab38c02235	70670ca3-5670-4484-a9c2-b9892415ee1f		Dathang	adc32cee-8ca0-4b6d-8511-e829065d2691	0.00	0.00	DHN00015
\.


--
-- TOC entry 4566 (class 0 OID 26237)
-- Dependencies: 424
-- Data for Name: RewardMilestone; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."RewardMilestone" ("promotionId", "rewardQuantity", "rewardName", "promotionName", "startDate", "endDate", "leastValue", value, percentage, notes, "promotionCode") FROM stdin;
d4a2a7f4-b45f-4ea4-99eb-a2002a2895f1	20	Gas Vina - 45kg, Gas Vina - Van chụp - 12Kg	Trung thu cho em	2026-06-12	2026-06-28	100000.00	10000.00	0		RM81020
55893cb5-6653-4ff1-bb80-ca75b317208c	\N	\N	Tết sẻ chia	2026-06-05	2026-06-19	200000.00	10000.00	0		RM38666
5faea7be-514b-4bb7-9c94-ee64bd8f678a	\N	\N	KMBG01	2026-06-04	2027-12-04	0.00	0.00	0		RM68204
33fa57e4-7350-4178-b9d8-ffad3bfe3e30	\N	\N	KMBG03	2026-06-04	2026-07-31	0.00	0.00	0		RM93585
183d6bf3-9cdc-4826-9141-6e30458267b7	\N	\N	KMBG05	2026-06-06	2026-06-30	0.00	0.00	0		RM47116
b4eea152-a383-4907-a406-c53daef01434	\N	\N	Mega Live 6.6	2026-06-06	2026-07-06	400000.00	50000.00	0		RM73107
0b9818bc-f122-412d-9e41-9afb8eada6d1	\N	\N	Rằm tháng 6	2026-06-12	2026-06-20	300000.00	30000.00	0		RM61798
\.


--
-- TOC entry 4535 (class 0 OID 17534)
-- Dependencies: 393
-- Data for Name: Role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Role" ("roleId", "roleName", description, "createdAt", "updatedAt", "deletedAt") FROM stdin;
5dc1e56a-5781-443c-8548-d2fd7ec42ffc	admin	Chủ cửa hàng	2026-04-01 10:03:54+00	2026-04-01 10:04:30.350286+00	\N
9df9d6b3-7894-4840-81d8-b912c80f8f9c	Nhân viên	Nhân viên	2026-06-03 18:35:51+00	2026-06-03 18:35:52+00	\N
\.


--
-- TOC entry 4555 (class 0 OID 21821)
-- Dependencies: 413
-- Data for Name: SaleInvoice; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."SaleInvoice" ("invoiceId", "invoiceDate", "totalAmount", "discountAmount", "paidAmount", note, "employeeId", "customerId", "gasBookId", "stockId", "orderType", "invoiceCode", "PaymentMethod") FROM stdin;
8634d021-ed79-4c51-8f03-c5b2c8cb3189	2026-06-07 16:22:30.081+00	1265086.00	67609.00	0.00		3b9f9195-df41-4f7c-9fd9-d23a158d79be	91118c65-6b67-4796-abed-91eb1fe63a8d	\N	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00008	Cashes
1a5a2227-b4f5-4548-a153-5f1ebc0818b4	2026-06-08 05:24:32.285+00	800000.00	100000.00	0.00		\N	e5e1c302-444b-448e-8409-3408d6f92dec	\N	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00009	Cashes
f0b8b0f5-1a37-4f58-9835-baedd62f9696	2026-06-08 05:42:48.399+00	400000.00	0.00	0.00		\N	e5e1c302-444b-448e-8409-3408d6f92dec	\N	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00010	Cashes
099d8425-e370-4c65-bcb2-d54210be52a4	2026-06-08 06:29:25.624+00	400000.00	0.00	400000.00		\N	91118c65-6b67-4796-abed-91eb1fe63a8d	\N	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00011	Cashes
19831d51-5a81-4bf5-832c-eb0ed6124c80	2026-06-04 03:03:41.223+00	400000.00	0.00	400000.00		\N	\N	ff4291f1-73df-48d1-a2ec-8614805f380b	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00002	Cashes
4af39d2a-7ad7-4950-8c0c-2703fa002660	2026-06-04 06:52:07.289+00	1200000.00	0.00	400000.00		\N	\N	ff4291f1-73df-48d1-a2ec-8614805f380b	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00001	Cashes
610db931-1c24-4aba-949e-4323135968d7	2026-06-05 12:46:55.907+00	400000.00	200000.00	100000.00		\N	e5e1c302-444b-448e-8409-3408d6f92dec	\N	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00003	Cashes
11ef5b8a-b04e-4e3f-a9a8-c4df0359076f	2026-06-05 13:42:19.071+00	400000.00	0.00	0.00		\N	\N	01b85b91-1808-4609-9e75-0ac2715aa8de	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00004	Cashes
39a4cdff-cd84-4031-88c3-8eacf2a0f24d	2026-06-05 13:56:27.091+00	400000.00	0.00	0.00		\N	\N	ff4291f1-73df-48d1-a2ec-8614805f380b	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00005	Cashes
e4214dc6-9791-41ab-9e8f-f1b44c0a3c36	2026-06-06 03:50:56.674+00	400000.00	0.00	0.00		\N	\N	01b85b91-1808-4609-9e75-0ac2715aa8de	adc32cee-8ca0-4b6d-8511-e829065d2691	Xuathang	HDX00006	Cashes
a5b083b2-a40a-4f9c-8ab7-feca7211c929	2026-06-07 15:51:04.387+00	400000.00	111000.00	289000.00		\N	91118c65-6b67-4796-abed-91eb1fe63a8d	\N	02fcd124-aec3-45a7-9030-bfecea4e5caa	Xuathang	HDX00007	Cashes
\.


--
-- TOC entry 4548 (class 0 OID 21641)
-- Dependencies: 406
-- Data for Name: Stock; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Stock" (name, "wardId", "stockId") FROM stdin;
Kho trung tâm	da24da12-1de8-4092-a1ef-f9340b7397c2	adc32cee-8ca0-4b6d-8511-e829065d2691
Chi nhánh 2	79e250d5-9e5b-469e-980b-7d2d711ffceb	0a541d07-53a3-4ccf-ab21-97d7971853bc
Chi nhánh 1	da24da12-1de8-4092-a1ef-f9340b7397c2	02fcd124-aec3-45a7-9030-bfecea4e5caa
Chi nhánh 3	8350abea-ef44-4e25-a0b6-db1b37b8271f	f273720d-1bf0-4404-b84f-2ba7b7031cfe
Chi nhánh 4	79e250d5-9e5b-469e-980b-7d2d711ffceb	1d228b05-b92d-4e5c-a3b6-a7bc460acd68
\.


--
-- TOC entry 4558 (class 0 OID 22096)
-- Dependencies: 416
-- Data for Name: StockTake; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockTake" ("stockTakeId", "stockTakeDate", note, "employeeId", "stockId", "stockTakeCode") FROM stdin;
f7f0f0a9-2e60-4932-adb2-5ec03241cb58	2026-06-03 05:16:03.871+00		4dd20344-7018-498b-b5dc-90e1a7f70255	adc32cee-8ca0-4b6d-8511-e829065d2691	PK00001
862b3f8e-dd30-4213-9420-b4eb3f1f8f43	2026-06-03 05:16:26.589+00		4dd20344-7018-498b-b5dc-90e1a7f70255	02fcd124-aec3-45a7-9030-bfecea4e5caa	PK00002
b3645aeb-f1f7-4a6c-87da-0c18e6a06c35	2026-06-03 07:53:13.174+00		4dd20344-7018-498b-b5dc-90e1a7f70255	02fcd124-aec3-45a7-9030-bfecea4e5caa	PK00003
1c9d11f9-23d0-4c53-90e0-59e95ada5e18	2026-06-04 04:03:20.199+00		4dd20344-7018-498b-b5dc-90e1a7f70255	02fcd124-aec3-45a7-9030-bfecea4e5caa	PK00004
0603ee7d-5cad-4e35-854d-2f6abaa16ea1	2026-06-05 13:21:20.987+00		4dd20344-7018-498b-b5dc-90e1a7f70255	02fcd124-aec3-45a7-9030-bfecea4e5caa	PK00005
1b5265f8-ab58-4b4b-9671-e3dd80b25070	2026-06-06 03:43:41.111+00		4dd20344-7018-498b-b5dc-90e1a7f70255	adc32cee-8ca0-4b6d-8511-e829065d2691	PK00006
5eaa9fba-890e-47c1-adc7-5679cd8ac820	2026-06-07 14:00:36.659+00		4dd20344-7018-498b-b5dc-90e1a7f70255	adc32cee-8ca0-4b6d-8511-e829065d2691	PK00007
99694b4d-ce79-44fb-992a-d97c4cf9c67c	2026-06-07 14:23:35.456+00		4dd20344-7018-498b-b5dc-90e1a7f70255	0a541d07-53a3-4ccf-ab21-97d7971853bc	PK00008
\.


--
-- TOC entry 4559 (class 0 OID 22132)
-- Dependencies: 417
-- Data for Name: StockTakeDetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockTakeDetail" ("stockTakeId", "productId", "systymQuantity", "actualQuantity", id) FROM stdin;
f7f0f0a9-2e60-4932-adb2-5ec03241cb58	1e9b0d2b-a33c-43c8-b802-26bc17b43937	0	100	3dcbc5d1-119a-4ba6-9395-cd417ee44c8d
f7f0f0a9-2e60-4932-adb2-5ec03241cb58	3ad36301-9b3f-4555-b973-615b0168bfe0	0	100	ff3b7796-2fa9-4ed3-b1ab-29c2a36f0fc1
862b3f8e-dd30-4213-9420-b4eb3f1f8f43	46013d6f-c850-447f-9799-8c4c5bc850de	9	10	239bc3ee-0c60-4555-b0b4-002fc2d6141d
b3645aeb-f1f7-4a6c-87da-0c18e6a06c35	860a0d24-de6e-4105-8cd2-a91a8698095e	0	100	c5b941dc-82e9-499f-8950-24c8c15d53dd
1c9d11f9-23d0-4c53-90e0-59e95ada5e18	0b743790-b844-4ba4-84d4-0ea11e77b8a7	93	100	3dd88e85-46de-44b2-ad52-470375d26c20
0603ee7d-5cad-4e35-854d-2f6abaa16ea1	0b743790-b844-4ba4-84d4-0ea11e77b8a7	103	104	f296459b-826c-4ad3-b333-9a64fabac6cd
1b5265f8-ab58-4b4b-9671-e3dd80b25070	860a0d24-de6e-4105-8cd2-a91a8698095e	0	100	627b1836-5660-410e-881b-8210e6601ff7
99694b4d-ce79-44fb-992a-d97c4cf9c67c	0b743790-b844-4ba4-84d4-0ea11e77b8a7	12	14	244608f6-45f2-4961-8ae9-792c7487473f
5eaa9fba-890e-47c1-adc7-5679cd8ac820	0b743790-b844-4ba4-84d4-0ea11e77b8a7	99	98	45687beb-29b7-43d0-aefe-5224d7bd09e6
\.


--
-- TOC entry 4556 (class 0 OID 21974)
-- Dependencies: 414
-- Data for Name: StockTransfer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockTransfer" ("transferId", "transferDate", "fromStockId", "toStockId", "employeeId", note, "transferCode") FROM stdin;
f62f24c0-05ce-4896-bdc8-9d60faa4ce35	2026-06-03 05:36:24.627+00	02fcd124-aec3-45a7-9030-bfecea4e5caa	0a541d07-53a3-4ccf-ab21-97d7971853bc	4dd20344-7018-498b-b5dc-90e1a7f70255		DC00001
d4745cc4-a7cd-4e30-a3aa-39050f0193ad	2026-06-05 13:05:58.96+00	adc32cee-8ca0-4b6d-8511-e829065d2691	02fcd124-aec3-45a7-9030-bfecea4e5caa	4dd20344-7018-498b-b5dc-90e1a7f70255		DC00002
405bc3e7-d67a-44e2-8026-feff22f05957	2026-06-07 14:04:54.834+00	adc32cee-8ca0-4b6d-8511-e829065d2691	0a541d07-53a3-4ccf-ab21-97d7971853bc	4dd20344-7018-498b-b5dc-90e1a7f70255		DC00003
\.


--
-- TOC entry 4557 (class 0 OID 22074)
-- Dependencies: 415
-- Data for Name: StockTransferDetail; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."StockTransferDetail" ("transferId", "productId", quantity, id) FROM stdin;
d4745cc4-a7cd-4e30-a3aa-39050f0193ad	0b743790-b844-4ba4-84d4-0ea11e77b8a7	1	2aa5b828-55e3-48f9-9fdb-5de0ebf95f84
f62f24c0-05ce-4896-bdc8-9d60faa4ce35	46013d6f-c850-447f-9799-8c4c5bc850de	5	41b2166b-ae38-4529-aeab-32b315695a3c
405bc3e7-d67a-44e2-8026-feff22f05957	0b743790-b844-4ba4-84d4-0ea11e77b8a7	2	6e75a57d-6cd5-46a6-9fa4-16a53a618dab
\.


--
-- TOC entry 4544 (class 0 OID 21563)
-- Dependencies: 402
-- Data for Name: Supplier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Supplier" ("supplierId", "taxNumber", note, "fullName", "phoneNumber", email, "wardId", "createdAt", "updatedAt", address, debt) FROM stdin;
7d65de23-e719-4dc6-86fe-4dc218f9e68e	\N	\N	Công ty Gas Vạn Lộc	0986256789	m@gmail.com	\N	2026-06-07 22:46:43.485258	2026-06-08 00:08:51.826245	\N	-2500000.00
15e2ac87-9860-4516-8983-79df5b805d1c	\N	\N	Công ty Văn Hải	0325465565	mkao@gmail.com	\N	2026-06-08 00:11:04.213383	2026-06-08 00:11:04.21738	\N	\N
ab2d45a6-fca1-4dbf-88d6-62e15ac1dc56	\N	\N	Công ty khí gas Thanh Bình	0303923476	binhwork@gmail.com	da24da12-1de8-4092-a1ef-f9340b7397c2	2026-05-20 20:43:58.558073	2026-06-03 15:45:56.610542	\N	-1500005.00
2910f504-3998-41c3-a84b-0983ccc34cc4	\N		a	0123456789	\N	8350abea-ef44-4e25-a0b6-db1b37b8271f	2026-06-03 12:41:16.529749	2026-06-03 20:57:48.030033	hello	11300000.00
69f2f5ec-d034-47d9-ae78-f010adda848e	\N	\N	Công ty gas Vina	0987654321	\N	79e250d5-9e5b-469e-980b-7d2d711ffceb	2026-06-05 20:26:40.413322	2026-06-05 20:29:15.127308	\N	29000000.00
a75e1685-c14b-4bab-9535-69fa00598f8b	\N	\N	Công ty Gas Hải Linh		\N	\N	2026-06-06 10:21:11.224124	2026-06-06 10:49:04.468223	\N	3000000.00
6592728a-eb66-4345-af4f-c39a43abf5b2	\N	\N	Công ty Gas Thành Long	0368954785	thanhfong1232@gmail.com	da24da12-1de8-4092-a1ef-f9340b7397c2	2026-06-07 00:43:01.803515	2026-06-07 00:43:01.806517	29 Mai hắc đế	\N
1fef3b26-5aab-429f-aada-d9e8a7a6ed04	\N	\N	Công ty ga Bảo Phan	0325789625	baokjan@gmail.com	\N	2026-06-07 00:45:01.43338	2026-06-07 23:01:32.053717	56 tiền giang	12430000.00
70670ca3-5670-4484-a9c2-b9892415ee1f	\N	vvvvvvvvv	công ty Abc	0236524539	example	79e250d5-9e5b-469e-980b-7d2d711ffceb	2026-06-02 11:58:05.446928	2026-06-08 00:08:12.058022	\N	1300000.00
\.


--
-- TOC entry 4539 (class 0 OID 17690)
-- Dependencies: 397
-- Data for Name: Token; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Token" ("tokenId", "accountId", "refreshToken", "expiresAt", "createdAt", "updatedAt") FROM stdin;
fbea0a70-6901-4096-a461-589a985b5b14	f98eb979-088d-4de1-817c-b725c781ded8	eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJiYW5oYW5nIiwiaWF0IjoxNzgwOTA3NjI1LCJleHAiOjE3ODE1MTI0MjUsInR5cGUiOiJyZWZyZXNoIn0.kSdZKZFLTzTytiQgAirkO4pH8OoaofeQzTROzJLRkeM	2026-06-15 08:33:45.875+00	2026-06-03 18:42:57.668682+00	2026-06-08 15:33:46.041498
7b306758-d540-4e81-b5b1-31315317c4aa	232ad5e0-3e73-4498-ba68-57bb1f3fc2c3	eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbjEyMyIsImlhdCI6MTc4MDkzNDE1MSwiZXhwIjoxNzgxNTM4OTUxLCJ0eXBlIjoicmVmcmVzaCJ9.fpg5eD6dwySPa_7w7OvawSFEoI4EDsQcWgTCGgt5j6o	2026-06-15 15:55:51.252+00	2026-06-04 03:01:54.944117+00	2026-06-08 22:55:51.442265
\.


--
-- TOC entry 4560 (class 0 OID 22151)
-- Dependencies: 418
-- Data for Name: TransactionType; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."TransactionType" ("transactionTypeId", "transactionTypeName") FROM stdin;
\.


--
-- TOC entry 4541 (class 0 OID 21430)
-- Dependencies: 399
-- Data for Name: Ward; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Ward" ("wardId", "wardName", "areaId") FROM stdin;
79e250d5-9e5b-469e-980b-7d2d711ffceb	Thanh Trì	361cacd8-6c49-4e90-9e9f-3a748d7c9e98
8350abea-ef44-4e25-a0b6-db1b37b8271f	Hoàng Mai	361cacd8-6c49-4e90-9e9f-3a748d7c9e98
da24da12-1de8-4092-a1ef-f9340b7397c2	Cầu Giấy	361cacd8-6c49-4e90-9e9f-3a748d7c9e98
\.


--
-- TOC entry 4620 (class 0 OID 0)
-- Dependencies: 431
-- Name: Data_Embedding_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Data_Embedding_id_seq"', 41, true);


--
-- TOC entry 4156 (class 2606 OID 17593)
-- Name: Account Account_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Account"
    ADD CONSTRAINT "Account_pkey" PRIMARY KEY ("accountId");


--
-- TOC entry 4158 (class 2606 OID 18927)
-- Name: Account Account_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Account"
    ADD CONSTRAINT "Account_username_key" UNIQUE (username);


--
-- TOC entry 4166 (class 2606 OID 21429)
-- Name: Area Area_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Area"
    ADD CONSTRAINT "Area_pkey" PRIMARY KEY ("areaId");


--
-- TOC entry 4196 (class 2606 OID 21676)
-- Name: Attribute Attribute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Attribute"
    ADD CONSTRAINT "Attribute_pkey" PRIMARY KEY ("attributeId");


--
-- TOC entry 4246 (class 2606 OID 22258)
-- Name: CashReceipt CashReceipt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_pkey" PRIMARY KEY ("receiptId");


--
-- TOC entry 4248 (class 2606 OID 35122)
-- Name: CashReceipt CashReceipt_receiptCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_receiptCode_key" UNIQUE ("receiptCode");


--
-- TOC entry 4254 (class 2606 OID 25418)
-- Name: CustomerGroup CustomerGroup_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CustomerGroup"
    ADD CONSTRAINT "CustomerGroup_pkey" PRIMARY KEY ("customerGroupid");


--
-- TOC entry 4172 (class 2606 OID 35496)
-- Name: Customer Customer_customerCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_customerCode_key" UNIQUE ("customerCode");


--
-- TOC entry 4174 (class 2606 OID 26102)
-- Name: Customer Customer_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_email_key" UNIQUE (email);


--
-- TOC entry 4176 (class 2606 OID 21555)
-- Name: Customer Customer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_pkey" PRIMARY KEY ("customerId");


--
-- TOC entry 4283 (class 2606 OID 36086)
-- Name: Data_Embedding Data_Embedding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Data_Embedding"
    ADD CONSTRAINT "Data_Embedding_pkey" PRIMARY KEY (id);


--
-- TOC entry 4285 (class 2606 OID 36094)
-- Name: Data_Embedding Data_Embedding_process_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Data_Embedding"
    ADD CONSTRAINT "Data_Embedding_process_id_key" UNIQUE (process_id);


--
-- TOC entry 4279 (class 2606 OID 35671)
-- Name: DebtReceiptDetail DebtReceiptDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DebtReceiptDetail"
    ADD CONSTRAINT "DebtReceiptDetail_pkey" PRIMARY KEY (id);


--
-- TOC entry 4275 (class 2606 OID 35666)
-- Name: DebtReceipt DebtReceipt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DebtReceipt"
    ADD CONSTRAINT "DebtReceipt_pkey" PRIMARY KEY ("receiptId");


--
-- TOC entry 4160 (class 2606 OID 17628)
-- Name: Employee Employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employee"
    ADD CONSTRAINT "Employee_pkey" PRIMARY KEY ("employeeId");


--
-- TOC entry 4182 (class 2606 OID 21592)
-- Name: GasBook GasBook_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GasBook"
    ADD CONSTRAINT "GasBook_pkey" PRIMARY KEY ("gasBookId");


--
-- TOC entry 4256 (class 2606 OID 26014)
-- Name: Inventory Inventory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Inventory"
    ADD CONSTRAINT "Inventory_pkey" PRIMARY KEY ("inventoryId");


--
-- TOC entry 4260 (class 2606 OID 26162)
-- Name: InvoiceDetail InvoiceDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InvoiceDetail"
    ADD CONSTRAINT "InvoiceDetail_pkey" PRIMARY KEY (id);


--
-- TOC entry 4170 (class 2606 OID 21490)
-- Name: Object Object_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Object"
    ADD CONSTRAINT "Object_pkey" PRIMARY KEY ("objectId");


--
-- TOC entry 4271 (class 2606 OID 26939)
-- Name: PasswordChangeVerification PasswordChangeVerification_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PasswordChangeVerification"
    ADD CONSTRAINT "PasswordChangeVerification_pkey" PRIMARY KEY ("verificationId");


--
-- TOC entry 4269 (class 2606 OID 26759)
-- Name: PasswordResetRequest PasswordResetRequest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PasswordResetRequest"
    ADD CONSTRAINT "PasswordResetRequest_pkey" PRIMARY KEY ("requestId");


--
-- TOC entry 4250 (class 2606 OID 35131)
-- Name: Payment Payment_paymentCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_paymentCode_key" UNIQUE ("paymentCode");


--
-- TOC entry 4252 (class 2606 OID 22323)
-- Name: Payment Payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_pkey" PRIMARY KEY ("paymentId");


--
-- TOC entry 4154 (class 2606 OID 25436)
-- Name: Position Position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Position"
    ADD CONSTRAINT "Position_pkey" PRIMARY KEY ("positionId");


--
-- TOC entry 4198 (class 2606 OID 21688)
-- Name: PriceList PriceList_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PriceList"
    ADD CONSTRAINT "PriceList_pkey" PRIMARY KEY ("priceListId");


--
-- TOC entry 4200 (class 2606 OID 22407)
-- Name: ProductAttribute ProductAttribute_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductAttribute"
    ADD CONSTRAINT "ProductAttribute_pkey" PRIMARY KEY (id);


--
-- TOC entry 4186 (class 2606 OID 26900)
-- Name: ProductCategory ProductCategory_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductCategory"
    ADD CONSTRAINT "ProductCategory_pkey" PRIMARY KEY ("categoryId");


--
-- TOC entry 4204 (class 2606 OID 22418)
-- Name: ProductPrice ProductPrice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductPrice"
    ADD CONSTRAINT "ProductPrice_pkey" PRIMARY KEY (id);


--
-- TOC entry 4188 (class 2606 OID 21634)
-- Name: Product Product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "Product_pkey" PRIMARY KEY ("productId");


--
-- TOC entry 4190 (class 2606 OID 35140)
-- Name: Product Product_productCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "Product_productCode_key" UNIQUE ("productCode");


--
-- TOC entry 4281 (class 2606 OID 35744)
-- Name: PromotionDetail PromotionDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PromotionDetail"
    ADD CONSTRAINT "PromotionDetail_pkey" PRIMARY KEY (id);


--
-- TOC entry 4214 (class 2606 OID 26078)
-- Name: PurchaseDetail PurchaseDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseDetail"
    ADD CONSTRAINT "PurchaseDetail_pkey" PRIMARY KEY (id);


--
-- TOC entry 4208 (class 2606 OID 21774)
-- Name: PurchaseOrder PurchaseOrder_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseOrder"
    ADD CONSTRAINT "PurchaseOrder_pkey" PRIMARY KEY ("purchaseId");


--
-- TOC entry 4210 (class 2606 OID 35149)
-- Name: PurchaseOrder PurchaseOrder_purchaseCoded_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseOrder"
    ADD CONSTRAINT "PurchaseOrder_purchaseCoded_key" UNIQUE ("purchaseCode");


--
-- TOC entry 4262 (class 2606 OID 35472)
-- Name: RewardMilestone RewardMilestone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RewardMilestone"
    ADD CONSTRAINT "RewardMilestone_pkey" PRIMARY KEY ("promotionId");


--
-- TOC entry 4152 (class 2606 OID 17546)
-- Name: Role Role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Role"
    ADD CONSTRAINT "Role_pkey" PRIMARY KEY ("roleId");


--
-- TOC entry 4218 (class 2606 OID 35158)
-- Name: SaleInvoice SaleInvoice_invoiceCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SaleInvoice"
    ADD CONSTRAINT "SaleInvoice_invoiceCode_key" UNIQUE ("invoiceCode");


--
-- TOC entry 4220 (class 2606 OID 21856)
-- Name: SaleInvoice SaleInvoice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SaleInvoice"
    ADD CONSTRAINT "SaleInvoice_pkey" PRIMARY KEY ("invoiceId");


--
-- TOC entry 4240 (class 2606 OID 26040)
-- Name: StockTakeDetail StockTakeDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTakeDetail"
    ADD CONSTRAINT "StockTakeDetail_pkey" PRIMARY KEY (id);


--
-- TOC entry 4236 (class 2606 OID 22119)
-- Name: StockTake StockTake_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTake"
    ADD CONSTRAINT "StockTake_pkey" PRIMARY KEY ("stockTakeId");


--
-- TOC entry 4238 (class 2606 OID 35167)
-- Name: StockTake StockTake_stockTakeCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTake"
    ADD CONSTRAINT "StockTake_stockTakeCode_key" UNIQUE ("stockTakeCode");


--
-- TOC entry 4232 (class 2606 OID 26051)
-- Name: StockTransferDetail StockTransferDetail_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransferDetail"
    ADD CONSTRAINT "StockTransferDetail_pkey" PRIMARY KEY (id);


--
-- TOC entry 4226 (class 2606 OID 21997)
-- Name: StockTransfer StockTransfer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransfer"
    ADD CONSTRAINT "StockTransfer_pkey" PRIMARY KEY ("transferId");


--
-- TOC entry 4228 (class 2606 OID 35176)
-- Name: StockTransfer StockTransfer_transferCode_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransfer"
    ADD CONSTRAINT "StockTransfer_transferCode_key" UNIQUE ("transferCode");


--
-- TOC entry 4194 (class 2606 OID 25484)
-- Name: Stock Stock_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stock"
    ADD CONSTRAINT "Stock_pkey" PRIMARY KEY ("stockId");


--
-- TOC entry 4180 (class 2606 OID 21573)
-- Name: Supplier Supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Supplier"
    ADD CONSTRAINT "Supplier_pkey" PRIMARY KEY ("supplierId");


--
-- TOC entry 4162 (class 2606 OID 19056)
-- Name: Token Token_accountId_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Token"
    ADD CONSTRAINT "Token_accountId_key" UNIQUE ("accountId");


--
-- TOC entry 4164 (class 2606 OID 17704)
-- Name: Token Token_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Token"
    ADD CONSTRAINT "Token_pkey" PRIMARY KEY ("tokenId");


--
-- TOC entry 4244 (class 2606 OID 22161)
-- Name: TransactionType TransactionType_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."TransactionType"
    ADD CONSTRAINT "TransactionType_pkey" PRIMARY KEY ("transactionTypeId");


--
-- TOC entry 4168 (class 2606 OID 21446)
-- Name: Ward Ward_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Ward"
    ADD CONSTRAINT "Ward_pkey" PRIMARY KEY ("wardId");


--
-- TOC entry 4277 (class 2606 OID 35685)
-- Name: DebtReceipt uk283yiox10ks314aei2s5gqt0v; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DebtReceipt"
    ADD CONSTRAINT uk283yiox10ks314aei2s5gqt0v UNIQUE ("receiptCode");


--
-- TOC entry 4184 (class 2606 OID 35653)
-- Name: GasBook uk73237vn0ex6dho5g7q4n9mq1x; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GasBook"
    ADD CONSTRAINT uk73237vn0ex6dho5g7q4n9mq1x UNIQUE ("gasBookCode");


--
-- TOC entry 4202 (class 2606 OID 26028)
-- Name: ProductAttribute uk_attribute_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductAttribute"
    ADD CONSTRAINT uk_attribute_product UNIQUE ("attributeId", "productId");


--
-- TOC entry 4206 (class 2606 OID 26032)
-- Name: ProductPrice uk_price_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductPrice"
    ADD CONSTRAINT uk_price_product UNIQUE ("priceListId", "productId");


--
-- TOC entry 4216 (class 2606 OID 26081)
-- Name: PurchaseDetail uk_purchase_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseDetail"
    ADD CONSTRAINT uk_purchase_product UNIQUE ("purchaseId", "productId");


--
-- TOC entry 4258 (class 2606 OID 26023)
-- Name: Inventory uk_stock_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Inventory"
    ADD CONSTRAINT uk_stock_product UNIQUE ("stockId", "productId");


--
-- TOC entry 4242 (class 2606 OID 26043)
-- Name: StockTakeDetail uk_stocktake_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTakeDetail"
    ADD CONSTRAINT uk_stocktake_product UNIQUE ("stockTakeId", "productId");


--
-- TOC entry 4234 (class 2606 OID 26055)
-- Name: StockTransferDetail uk_stocktransfer_product; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransferDetail"
    ADD CONSTRAINT uk_stocktransfer_product UNIQUE ("transferId", "productId");


--
-- TOC entry 4267 (class 2606 OID 35778)
-- Name: RewardMilestone ukg7fuhrjn037aqlnltihnasu4d; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."RewardMilestone"
    ADD CONSTRAINT ukg7fuhrjn037aqlnltihnasu4d UNIQUE ("promotionCode");


--
-- TOC entry 4273 (class 2606 OID 26941)
-- Name: PasswordChangeVerification ukovhwov7fleivncbonkwngxchb; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PasswordChangeVerification"
    ADD CONSTRAINT ukovhwov7fleivncbonkwngxchb UNIQUE ("accountId");


--
-- TOC entry 4177 (class 1259 OID 35823)
-- Name: idx_customer_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_customer_code ON public."Customer" USING btree ("customerCode");


--
-- TOC entry 4178 (class 1259 OID 35824)
-- Name: idx_customer_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_customer_name ON public."Customer" USING btree ("fullName");


--
-- TOC entry 4191 (class 1259 OID 35825)
-- Name: idx_product_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_code ON public."Product" USING btree ("productCode");


--
-- TOC entry 4192 (class 1259 OID 35826)
-- Name: idx_product_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_product_name ON public."Product" USING btree ("productName");


--
-- TOC entry 4211 (class 1259 OID 35827)
-- Name: idx_purchase_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_purchase_code ON public."PurchaseOrder" USING btree ("purchaseCode");


--
-- TOC entry 4212 (class 1259 OID 35828)
-- Name: idx_purchase_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_purchase_date ON public."PurchaseOrder" USING btree ("purchaseDate");


--
-- TOC entry 4263 (class 1259 OID 35829)
-- Name: idx_reward_milestone_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reward_milestone_code ON public."RewardMilestone" USING btree ("promotionCode");


--
-- TOC entry 4264 (class 1259 OID 35831)
-- Name: idx_reward_milestone_end; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reward_milestone_end ON public."RewardMilestone" USING btree ("endDate");


--
-- TOC entry 4265 (class 1259 OID 35830)
-- Name: idx_reward_milestone_start; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_reward_milestone_start ON public."RewardMilestone" USING btree ("startDate");


--
-- TOC entry 4221 (class 1259 OID 35832)
-- Name: idx_saleinvoice_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_saleinvoice_code ON public."SaleInvoice" USING btree ("invoiceCode");


--
-- TOC entry 4222 (class 1259 OID 35834)
-- Name: idx_saleinvoice_customer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_saleinvoice_customer ON public."SaleInvoice" USING btree ("customerId");


--
-- TOC entry 4223 (class 1259 OID 35833)
-- Name: idx_saleinvoice_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_saleinvoice_date ON public."SaleInvoice" USING btree ("invoiceDate");


--
-- TOC entry 4224 (class 1259 OID 35835)
-- Name: idx_saleinvoice_stock; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_saleinvoice_stock ON public."SaleInvoice" USING btree ("stockId");


--
-- TOC entry 4229 (class 1259 OID 35836)
-- Name: idx_stock_transfer_code; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stock_transfer_code ON public."StockTransfer" USING btree ("transferCode");


--
-- TOC entry 4230 (class 1259 OID 35837)
-- Name: idx_stock_transfer_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stock_transfer_date ON public."StockTransfer" USING btree ("transferDate");


--
-- TOC entry 4286 (class 2606 OID 25381)
-- Name: Account Account_employeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Account"
    ADD CONSTRAINT "Account_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4287 (class 2606 OID 17594)
-- Name: Account Account_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Account"
    ADD CONSTRAINT "Account_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public."Role"("roleId");


--
-- TOC entry 4322 (class 2606 OID 22264)
-- Name: CashReceipt CashReceipt_createdBy_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_createdBy_fkey" FOREIGN KEY ("createdBy") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4323 (class 2606 OID 25927)
-- Name: CashReceipt CashReceipt_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public."Customer"("customerId");


--
-- TOC entry 4324 (class 2606 OID 22274)
-- Name: CashReceipt CashReceipt_invoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES public."SaleInvoice"("invoiceId");


--
-- TOC entry 4325 (class 2606 OID 25932)
-- Name: CashReceipt CashReceipt_objectId_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_objectId_fkey1" FOREIGN KEY ("objectId") REFERENCES public."Object"("objectId");


--
-- TOC entry 4326 (class 2606 OID 25937)
-- Name: CashReceipt CashReceipt_supplierId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES public."Supplier"("supplierId");


--
-- TOC entry 4327 (class 2606 OID 22269)
-- Name: CashReceipt CashReceipt_transactionTypeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT "CashReceipt_transactionTypeId_fkey" FOREIGN KEY ("transactionTypeId") REFERENCES public."TransactionType"("transactionTypeId");


--
-- TOC entry 4293 (class 2606 OID 25424)
-- Name: Customer Customer_customerGroupId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_customerGroupId_fkey" FOREIGN KEY ("customerGroupId") REFERENCES public."CustomerGroup"("customerGroupid");


--
-- TOC entry 4294 (class 2606 OID 25402)
-- Name: Customer Customer_wardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Customer"
    ADD CONSTRAINT "Customer_wardId_fkey" FOREIGN KEY ("wardId") REFERENCES public."Ward"("wardId");


--
-- TOC entry 4288 (class 2606 OID 25444)
-- Name: Employee Employee_positionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employee"
    ADD CONSTRAINT "Employee_positionId_fkey" FOREIGN KEY ("positionId") REFERENCES public."Position"("positionId");


--
-- TOC entry 4296 (class 2606 OID 35199)
-- Name: GasBook GasBook_customerGroupid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GasBook"
    ADD CONSTRAINT "GasBook_customerGroupid_fkey" FOREIGN KEY ("customerGroupid") REFERENCES public."CustomerGroup"("customerGroupid");


--
-- TOC entry 4297 (class 2606 OID 25458)
-- Name: GasBook GasBook_wardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."GasBook"
    ADD CONSTRAINT "GasBook_wardId_fkey" FOREIGN KEY ("wardId") REFERENCES public."Ward"("wardId");


--
-- TOC entry 4337 (class 2606 OID 25881)
-- Name: Inventory Inventory_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Inventory"
    ADD CONSTRAINT "Inventory_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4338 (class 2606 OID 26015)
-- Name: Inventory Inventory_stockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Inventory"
    ADD CONSTRAINT "Inventory_stockId_fkey" FOREIGN KEY ("stockId") REFERENCES public."Stock"("stockId");


--
-- TOC entry 4292 (class 2606 OID 21491)
-- Name: Object Object_wardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Object"
    ADD CONSTRAINT "Object_wardId_fkey" FOREIGN KEY ("wardId") REFERENCES public."Ward"("wardId");


--
-- TOC entry 4329 (class 2606 OID 22329)
-- Name: Payment Payment_createdBy_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_createdBy_fkey" FOREIGN KEY ("createdBy") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4330 (class 2606 OID 25949)
-- Name: Payment Payment_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public."Customer"("customerId");


--
-- TOC entry 4331 (class 2606 OID 22324)
-- Name: Payment Payment_objectId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_objectId_fkey" FOREIGN KEY ("objectId") REFERENCES public."Object"("objectId");


--
-- TOC entry 4332 (class 2606 OID 22339)
-- Name: Payment Payment_purchaseId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES public."PurchaseOrder"("purchaseId");


--
-- TOC entry 4333 (class 2606 OID 25954)
-- Name: Payment Payment_stockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_stockId_fkey" FOREIGN KEY ("stockId") REFERENCES public."Stock"("stockId");


--
-- TOC entry 4334 (class 2606 OID 25944)
-- Name: Payment Payment_supplierId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES public."Supplier"("supplierId");


--
-- TOC entry 4335 (class 2606 OID 22334)
-- Name: Payment Payment_transactionTypeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT "Payment_transactionTypeId_fkey" FOREIGN KEY ("transactionTypeId") REFERENCES public."TransactionType"("transactionTypeId");


--
-- TOC entry 4300 (class 2606 OID 21711)
-- Name: ProductAttribute ProductAttribute_attributeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductAttribute"
    ADD CONSTRAINT "ProductAttribute_attributeId_fkey" FOREIGN KEY ("attributeId") REFERENCES public."Attribute"("attributeId");


--
-- TOC entry 4301 (class 2606 OID 21706)
-- Name: ProductAttribute ProductAttribute_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductAttribute"
    ADD CONSTRAINT "ProductAttribute_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4302 (class 2606 OID 21742)
-- Name: ProductPrice ProductPrice_priceListId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductPrice"
    ADD CONSTRAINT "ProductPrice_priceListId_fkey" FOREIGN KEY ("priceListId") REFERENCES public."PriceList"("priceListId");


--
-- TOC entry 4303 (class 2606 OID 21737)
-- Name: ProductPrice ProductPrice_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ProductPrice"
    ADD CONSTRAINT "ProductPrice_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4298 (class 2606 OID 26902)
-- Name: Product Product_categoryId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "Product_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES public."ProductCategory"("categoryId");


--
-- TOC entry 4345 (class 2606 OID 35806)
-- Name: PromotionDetail PromotionDetail_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PromotionDetail"
    ADD CONSTRAINT "PromotionDetail_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4346 (class 2606 OID 35811)
-- Name: PromotionDetail PromotionDetail_promotionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PromotionDetail"
    ADD CONSTRAINT "PromotionDetail_promotionId_fkey" FOREIGN KEY ("promotionId") REFERENCES public."RewardMilestone"("promotionId");


--
-- TOC entry 4307 (class 2606 OID 21808)
-- Name: PurchaseDetail PurchaseDetail_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseDetail"
    ADD CONSTRAINT "PurchaseDetail_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4308 (class 2606 OID 21803)
-- Name: PurchaseDetail PurchaseDetail_purchaseId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseDetail"
    ADD CONSTRAINT "PurchaseDetail_purchaseId_fkey" FOREIGN KEY ("purchaseId") REFERENCES public."PurchaseOrder"("purchaseId");


--
-- TOC entry 4304 (class 2606 OID 21775)
-- Name: PurchaseOrder PurchaseOrder_employeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseOrder"
    ADD CONSTRAINT "PurchaseOrder_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4305 (class 2606 OID 25859)
-- Name: PurchaseOrder PurchaseOrder_stockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseOrder"
    ADD CONSTRAINT "PurchaseOrder_stockId_fkey" FOREIGN KEY ("stockId") REFERENCES public."Stock"("stockId");


--
-- TOC entry 4306 (class 2606 OID 21780)
-- Name: PurchaseOrder PurchaseOrder_supplierId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PurchaseOrder"
    ADD CONSTRAINT "PurchaseOrder_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES public."Supplier"("supplierId");


--
-- TOC entry 4309 (class 2606 OID 21862)
-- Name: SaleInvoice SaleInvoice_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SaleInvoice"
    ADD CONSTRAINT "SaleInvoice_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public."Customer"("customerId");


--
-- TOC entry 4310 (class 2606 OID 21857)
-- Name: SaleInvoice SaleInvoice_employeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SaleInvoice"
    ADD CONSTRAINT "SaleInvoice_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4311 (class 2606 OID 21867)
-- Name: SaleInvoice SaleInvoice_gasBookId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SaleInvoice"
    ADD CONSTRAINT "SaleInvoice_gasBookId_fkey" FOREIGN KEY ("gasBookId") REFERENCES public."GasBook"("gasBookId");


--
-- TOC entry 4312 (class 2606 OID 25895)
-- Name: SaleInvoice SaleInvoice_stockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."SaleInvoice"
    ADD CONSTRAINT "SaleInvoice_stockId_fkey" FOREIGN KEY ("stockId") REFERENCES public."Stock"("stockId");


--
-- TOC entry 4320 (class 2606 OID 25919)
-- Name: StockTakeDetail StockTakeDetail_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTakeDetail"
    ADD CONSTRAINT "StockTakeDetail_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4321 (class 2606 OID 22145)
-- Name: StockTakeDetail StockTakeDetail_stockTakeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTakeDetail"
    ADD CONSTRAINT "StockTakeDetail_stockTakeId_fkey" FOREIGN KEY ("stockTakeId") REFERENCES public."StockTake"("stockTakeId");


--
-- TOC entry 4318 (class 2606 OID 22120)
-- Name: StockTake StockTake_employeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTake"
    ADD CONSTRAINT "StockTake_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4319 (class 2606 OID 25492)
-- Name: StockTake StockTake_stockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTake"
    ADD CONSTRAINT "StockTake_stockId_fkey" FOREIGN KEY ("stockId") REFERENCES public."Stock"("stockId");


--
-- TOC entry 4316 (class 2606 OID 25909)
-- Name: StockTransferDetail StockTransferDetail_productId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransferDetail"
    ADD CONSTRAINT "StockTransferDetail_productId_fkey" FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4317 (class 2606 OID 22087)
-- Name: StockTransferDetail StockTransferDetail_transferId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransferDetail"
    ADD CONSTRAINT "StockTransferDetail_transferId_fkey" FOREIGN KEY ("transferId") REFERENCES public."StockTransfer"("transferId");


--
-- TOC entry 4313 (class 2606 OID 22008)
-- Name: StockTransfer StockTransfer_employeeId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransfer"
    ADD CONSTRAINT "StockTransfer_employeeId_fkey" FOREIGN KEY ("employeeId") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4314 (class 2606 OID 25505)
-- Name: StockTransfer StockTransfer_fromStockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransfer"
    ADD CONSTRAINT "StockTransfer_fromStockId_fkey" FOREIGN KEY ("fromStockId") REFERENCES public."Stock"("stockId");


--
-- TOC entry 4315 (class 2606 OID 25510)
-- Name: StockTransfer StockTransfer_toStockId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."StockTransfer"
    ADD CONSTRAINT "StockTransfer_toStockId_fkey" FOREIGN KEY ("toStockId") REFERENCES public."Stock"("stockId");


--
-- TOC entry 4299 (class 2606 OID 25485)
-- Name: Stock Stock_wardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Stock"
    ADD CONSTRAINT "Stock_wardId_fkey" FOREIGN KEY ("wardId") REFERENCES public."Ward"("wardId");


--
-- TOC entry 4295 (class 2606 OID 25475)
-- Name: Supplier Supplier_wardId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Supplier"
    ADD CONSTRAINT "Supplier_wardId_fkey" FOREIGN KEY ("wardId") REFERENCES public."Ward"("wardId");


--
-- TOC entry 4290 (class 2606 OID 17705)
-- Name: Token Token_accountId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Token"
    ADD CONSTRAINT "Token_accountId_fkey" FOREIGN KEY ("accountId") REFERENCES public."Account"("accountId");


--
-- TOC entry 4291 (class 2606 OID 21447)
-- Name: Ward Ward_areaId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Ward"
    ADD CONSTRAINT "Ward_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES public."Area"("areaId");


--
-- TOC entry 4343 (class 2606 OID 35698)
-- Name: DebtReceiptDetail fk3vp60xgvie0t20o0qksmx9le8; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DebtReceiptDetail"
    ADD CONSTRAINT fk3vp60xgvie0t20o0qksmx9le8 FOREIGN KEY ("receiptId") REFERENCES public."DebtReceipt"("receiptId");


--
-- TOC entry 4341 (class 2606 OID 35688)
-- Name: DebtReceipt fk5as1wnqj38v6dfbbrl73lw27u; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DebtReceipt"
    ADD CONSTRAINT fk5as1wnqj38v6dfbbrl73lw27u FOREIGN KEY ("customerId") REFERENCES public."Customer"("customerId");


--
-- TOC entry 4344 (class 2606 OID 35703)
-- Name: DebtReceiptDetail fk7sea2he9mwjb5ns701nunuowq; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DebtReceiptDetail"
    ADD CONSTRAINT fk7sea2he9mwjb5ns701nunuowq FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4336 (class 2606 OID 26282)
-- Name: Payment fk84eekkbolmd9lbs9m0gfwh5un; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Payment"
    ADD CONSTRAINT fk84eekkbolmd9lbs9m0gfwh5un FOREIGN KEY ("employeeId") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4339 (class 2606 OID 26277)
-- Name: InvoiceDetail fkgosvg31wdc0u72dyoxegg4x12; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InvoiceDetail"
    ADD CONSTRAINT fkgosvg31wdc0u72dyoxegg4x12 FOREIGN KEY ("productId") REFERENCES public."Product"("productId");


--
-- TOC entry 4342 (class 2606 OID 35693)
-- Name: DebtReceipt fkiy182seefoqsnpg1psu2mapxu; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."DebtReceipt"
    ADD CONSTRAINT fkiy182seefoqsnpg1psu2mapxu FOREIGN KEY ("gasBookId") REFERENCES public."GasBook"("gasBookId");


--
-- TOC entry 4289 (class 2606 OID 26433)
-- Name: Employee fkki1beqaq9s52ias2hc3cxknls; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employee"
    ADD CONSTRAINT fkki1beqaq9s52ias2hc3cxknls FOREIGN KEY ("wardId") REFERENCES public."Ward"("wardId");


--
-- TOC entry 4347 (class 2606 OID 35848)
-- Name: PromotionDetail fknj85k1y5y1y7ukptijprcbu15; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."PromotionDetail"
    ADD CONSTRAINT fknj85k1y5y1y7ukptijprcbu15 FOREIGN KEY ("rewardMilestoneId") REFERENCES public."RewardMilestone"("promotionId");


--
-- TOC entry 4328 (class 2606 OID 35184)
-- Name: CashReceipt fknsyrlqv9vx02c08fcu89ebure; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."CashReceipt"
    ADD CONSTRAINT fknsyrlqv9vx02c08fcu89ebure FOREIGN KEY ("employeeId") REFERENCES public."Employee"("employeeId");


--
-- TOC entry 4340 (class 2606 OID 26272)
-- Name: InvoiceDetail fko0y53e6o4o2djwiv4ou1bg5kd; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."InvoiceDetail"
    ADD CONSTRAINT fko0y53e6o4o2djwiv4ou1bg5kd FOREIGN KEY ("invoiceId") REFERENCES public."SaleInvoice"("invoiceId");


--
-- TOC entry 4498 (class 0 OID 17571)
-- Dependencies: 395
-- Name: Account; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Account" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4501 (class 0 OID 21419)
-- Dependencies: 398
-- Name: Area; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Area" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4510 (class 0 OID 21666)
-- Dependencies: 407
-- Name: Attribute; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Attribute" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4522 (class 0 OID 22223)
-- Dependencies: 419
-- Name: CashReceipt; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."CashReceipt" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4504 (class 0 OID 21545)
-- Dependencies: 401
-- Name: Customer; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Customer" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4524 (class 0 OID 25408)
-- Dependencies: 421
-- Name: CustomerGroup; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."CustomerGroup" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4533 (class 0 OID 36076)
-- Dependencies: 430
-- Name: Data_Embedding; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Data_Embedding" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4530 (class 0 OID 35660)
-- Dependencies: 427
-- Name: DebtReceipt; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."DebtReceipt" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4531 (class 0 OID 35667)
-- Dependencies: 428
-- Name: DebtReceiptDetail; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."DebtReceiptDetail" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4499 (class 0 OID 17608)
-- Dependencies: 396
-- Name: Employee; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Employee" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4506 (class 0 OID 21582)
-- Dependencies: 403
-- Name: GasBook; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."GasBook" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4525 (class 0 OID 25866)
-- Dependencies: 422
-- Name: Inventory; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Inventory" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4526 (class 0 OID 26158)
-- Dependencies: 423
-- Name: InvoiceDetail; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."InvoiceDetail" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4503 (class 0 OID 21474)
-- Dependencies: 400
-- Name: Object; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Object" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4529 (class 0 OID 26933)
-- Dependencies: 426
-- Name: PasswordChangeVerification; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."PasswordChangeVerification" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4528 (class 0 OID 26752)
-- Dependencies: 425
-- Name: PasswordResetRequest; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."PasswordResetRequest" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4523 (class 0 OID 22282)
-- Dependencies: 420
-- Name: Payment; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Payment" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4497 (class 0 OID 17551)
-- Dependencies: 394
-- Name: Position; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Position" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4511 (class 0 OID 21678)
-- Dependencies: 408
-- Name: PriceList; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."PriceList" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4508 (class 0 OID 21618)
-- Dependencies: 405
-- Name: Product; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Product" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4512 (class 0 OID 21691)
-- Dependencies: 409
-- Name: ProductAttribute; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."ProductAttribute" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4507 (class 0 OID 21605)
-- Dependencies: 404
-- Name: ProductCategory; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."ProductCategory" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4513 (class 0 OID 21722)
-- Dependencies: 410
-- Name: ProductPrice; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."ProductPrice" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4532 (class 0 OID 35740)
-- Dependencies: 429
-- Name: PromotionDetail; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."PromotionDetail" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4515 (class 0 OID 21788)
-- Dependencies: 412
-- Name: PurchaseDetail; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."PurchaseDetail" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4514 (class 0 OID 21751)
-- Dependencies: 411
-- Name: PurchaseOrder; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."PurchaseOrder" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4527 (class 0 OID 26237)
-- Dependencies: 424
-- Name: RewardMilestone; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."RewardMilestone" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4496 (class 0 OID 17534)
-- Dependencies: 393
-- Name: Role; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Role" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4516 (class 0 OID 21821)
-- Dependencies: 413
-- Name: SaleInvoice; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."SaleInvoice" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4509 (class 0 OID 21641)
-- Dependencies: 406
-- Name: Stock; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Stock" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4519 (class 0 OID 22096)
-- Dependencies: 416
-- Name: StockTake; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."StockTake" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4520 (class 0 OID 22132)
-- Dependencies: 417
-- Name: StockTakeDetail; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."StockTakeDetail" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4517 (class 0 OID 21974)
-- Dependencies: 414
-- Name: StockTransfer; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."StockTransfer" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4518 (class 0 OID 22074)
-- Dependencies: 415
-- Name: StockTransferDetail; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."StockTransferDetail" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4505 (class 0 OID 21563)
-- Dependencies: 402
-- Name: Supplier; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Supplier" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4500 (class 0 OID 17690)
-- Dependencies: 397
-- Name: Token; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Token" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4521 (class 0 OID 22151)
-- Dependencies: 418
-- Name: TransactionType; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."TransactionType" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4502 (class 0 OID 21430)
-- Dependencies: 399
-- Name: Ward; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public."Ward" ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4580 (class 0 OID 0)
-- Dependencies: 138
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- TOC entry 4581 (class 0 OID 0)
-- Dependencies: 395
-- Name: TABLE "Account"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Account" TO anon;
GRANT ALL ON TABLE public."Account" TO authenticated;
GRANT ALL ON TABLE public."Account" TO service_role;


--
-- TOC entry 4582 (class 0 OID 0)
-- Dependencies: 398
-- Name: TABLE "Area"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Area" TO anon;
GRANT ALL ON TABLE public."Area" TO authenticated;
GRANT ALL ON TABLE public."Area" TO service_role;


--
-- TOC entry 4583 (class 0 OID 0)
-- Dependencies: 407
-- Name: TABLE "Attribute"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Attribute" TO anon;
GRANT ALL ON TABLE public."Attribute" TO authenticated;
GRANT ALL ON TABLE public."Attribute" TO service_role;


--
-- TOC entry 4584 (class 0 OID 0)
-- Dependencies: 419
-- Name: TABLE "CashReceipt"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."CashReceipt" TO anon;
GRANT ALL ON TABLE public."CashReceipt" TO authenticated;
GRANT ALL ON TABLE public."CashReceipt" TO service_role;


--
-- TOC entry 4585 (class 0 OID 0)
-- Dependencies: 401
-- Name: TABLE "Customer"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Customer" TO anon;
GRANT ALL ON TABLE public."Customer" TO authenticated;
GRANT ALL ON TABLE public."Customer" TO service_role;


--
-- TOC entry 4586 (class 0 OID 0)
-- Dependencies: 421
-- Name: TABLE "CustomerGroup"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."CustomerGroup" TO anon;
GRANT ALL ON TABLE public."CustomerGroup" TO authenticated;
GRANT ALL ON TABLE public."CustomerGroup" TO service_role;


--
-- TOC entry 4587 (class 0 OID 0)
-- Dependencies: 430
-- Name: TABLE "Data_Embedding"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Data_Embedding" TO anon;
GRANT ALL ON TABLE public."Data_Embedding" TO authenticated;
GRANT ALL ON TABLE public."Data_Embedding" TO service_role;


--
-- TOC entry 4588 (class 0 OID 0)
-- Dependencies: 431
-- Name: SEQUENCE "Data_Embedding_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public."Data_Embedding_id_seq" TO anon;
GRANT ALL ON SEQUENCE public."Data_Embedding_id_seq" TO authenticated;
GRANT ALL ON SEQUENCE public."Data_Embedding_id_seq" TO service_role;


--
-- TOC entry 4589 (class 0 OID 0)
-- Dependencies: 427
-- Name: TABLE "DebtReceipt"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."DebtReceipt" TO anon;
GRANT ALL ON TABLE public."DebtReceipt" TO authenticated;
GRANT ALL ON TABLE public."DebtReceipt" TO service_role;


--
-- TOC entry 4590 (class 0 OID 0)
-- Dependencies: 428
-- Name: TABLE "DebtReceiptDetail"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."DebtReceiptDetail" TO anon;
GRANT ALL ON TABLE public."DebtReceiptDetail" TO authenticated;
GRANT ALL ON TABLE public."DebtReceiptDetail" TO service_role;


--
-- TOC entry 4591 (class 0 OID 0)
-- Dependencies: 396
-- Name: TABLE "Employee"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Employee" TO anon;
GRANT ALL ON TABLE public."Employee" TO authenticated;
GRANT ALL ON TABLE public."Employee" TO service_role;


--
-- TOC entry 4592 (class 0 OID 0)
-- Dependencies: 403
-- Name: TABLE "GasBook"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."GasBook" TO anon;
GRANT ALL ON TABLE public."GasBook" TO authenticated;
GRANT ALL ON TABLE public."GasBook" TO service_role;


--
-- TOC entry 4593 (class 0 OID 0)
-- Dependencies: 422
-- Name: TABLE "Inventory"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Inventory" TO anon;
GRANT ALL ON TABLE public."Inventory" TO authenticated;
GRANT ALL ON TABLE public."Inventory" TO service_role;


--
-- TOC entry 4594 (class 0 OID 0)
-- Dependencies: 423
-- Name: TABLE "InvoiceDetail"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."InvoiceDetail" TO anon;
GRANT ALL ON TABLE public."InvoiceDetail" TO authenticated;
GRANT ALL ON TABLE public."InvoiceDetail" TO service_role;


--
-- TOC entry 4595 (class 0 OID 0)
-- Dependencies: 400
-- Name: TABLE "Object"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Object" TO anon;
GRANT ALL ON TABLE public."Object" TO authenticated;
GRANT ALL ON TABLE public."Object" TO service_role;


--
-- TOC entry 4596 (class 0 OID 0)
-- Dependencies: 426
-- Name: TABLE "PasswordChangeVerification"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."PasswordChangeVerification" TO anon;
GRANT ALL ON TABLE public."PasswordChangeVerification" TO authenticated;
GRANT ALL ON TABLE public."PasswordChangeVerification" TO service_role;


--
-- TOC entry 4597 (class 0 OID 0)
-- Dependencies: 425
-- Name: TABLE "PasswordResetRequest"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."PasswordResetRequest" TO anon;
GRANT ALL ON TABLE public."PasswordResetRequest" TO authenticated;
GRANT ALL ON TABLE public."PasswordResetRequest" TO service_role;


--
-- TOC entry 4598 (class 0 OID 0)
-- Dependencies: 420
-- Name: TABLE "Payment"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Payment" TO anon;
GRANT ALL ON TABLE public."Payment" TO authenticated;
GRANT ALL ON TABLE public."Payment" TO service_role;


--
-- TOC entry 4599 (class 0 OID 0)
-- Dependencies: 394
-- Name: TABLE "Position"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Position" TO anon;
GRANT ALL ON TABLE public."Position" TO authenticated;
GRANT ALL ON TABLE public."Position" TO service_role;


--
-- TOC entry 4600 (class 0 OID 0)
-- Dependencies: 408
-- Name: TABLE "PriceList"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."PriceList" TO anon;
GRANT ALL ON TABLE public."PriceList" TO authenticated;
GRANT ALL ON TABLE public."PriceList" TO service_role;


--
-- TOC entry 4601 (class 0 OID 0)
-- Dependencies: 405
-- Name: TABLE "Product"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Product" TO anon;
GRANT ALL ON TABLE public."Product" TO authenticated;
GRANT ALL ON TABLE public."Product" TO service_role;


--
-- TOC entry 4602 (class 0 OID 0)
-- Dependencies: 409
-- Name: TABLE "ProductAttribute"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."ProductAttribute" TO anon;
GRANT ALL ON TABLE public."ProductAttribute" TO authenticated;
GRANT ALL ON TABLE public."ProductAttribute" TO service_role;


--
-- TOC entry 4603 (class 0 OID 0)
-- Dependencies: 404
-- Name: TABLE "ProductCategory"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."ProductCategory" TO anon;
GRANT ALL ON TABLE public."ProductCategory" TO authenticated;
GRANT ALL ON TABLE public."ProductCategory" TO service_role;


--
-- TOC entry 4604 (class 0 OID 0)
-- Dependencies: 410
-- Name: TABLE "ProductPrice"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."ProductPrice" TO anon;
GRANT ALL ON TABLE public."ProductPrice" TO authenticated;
GRANT ALL ON TABLE public."ProductPrice" TO service_role;


--
-- TOC entry 4605 (class 0 OID 0)
-- Dependencies: 429
-- Name: TABLE "PromotionDetail"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."PromotionDetail" TO anon;
GRANT ALL ON TABLE public."PromotionDetail" TO authenticated;
GRANT ALL ON TABLE public."PromotionDetail" TO service_role;


--
-- TOC entry 4606 (class 0 OID 0)
-- Dependencies: 412
-- Name: TABLE "PurchaseDetail"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."PurchaseDetail" TO anon;
GRANT ALL ON TABLE public."PurchaseDetail" TO authenticated;
GRANT ALL ON TABLE public."PurchaseDetail" TO service_role;


--
-- TOC entry 4607 (class 0 OID 0)
-- Dependencies: 411
-- Name: TABLE "PurchaseOrder"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."PurchaseOrder" TO anon;
GRANT ALL ON TABLE public."PurchaseOrder" TO authenticated;
GRANT ALL ON TABLE public."PurchaseOrder" TO service_role;


--
-- TOC entry 4608 (class 0 OID 0)
-- Dependencies: 424
-- Name: TABLE "RewardMilestone"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."RewardMilestone" TO anon;
GRANT ALL ON TABLE public."RewardMilestone" TO authenticated;
GRANT ALL ON TABLE public."RewardMilestone" TO service_role;


--
-- TOC entry 4609 (class 0 OID 0)
-- Dependencies: 393
-- Name: TABLE "Role"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Role" TO anon;
GRANT ALL ON TABLE public."Role" TO authenticated;
GRANT ALL ON TABLE public."Role" TO service_role;


--
-- TOC entry 4610 (class 0 OID 0)
-- Dependencies: 413
-- Name: TABLE "SaleInvoice"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."SaleInvoice" TO anon;
GRANT ALL ON TABLE public."SaleInvoice" TO authenticated;
GRANT ALL ON TABLE public."SaleInvoice" TO service_role;


--
-- TOC entry 4611 (class 0 OID 0)
-- Dependencies: 406
-- Name: TABLE "Stock"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Stock" TO anon;
GRANT ALL ON TABLE public."Stock" TO authenticated;
GRANT ALL ON TABLE public."Stock" TO service_role;


--
-- TOC entry 4612 (class 0 OID 0)
-- Dependencies: 416
-- Name: TABLE "StockTake"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."StockTake" TO anon;
GRANT ALL ON TABLE public."StockTake" TO authenticated;
GRANT ALL ON TABLE public."StockTake" TO service_role;


--
-- TOC entry 4613 (class 0 OID 0)
-- Dependencies: 417
-- Name: TABLE "StockTakeDetail"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."StockTakeDetail" TO anon;
GRANT ALL ON TABLE public."StockTakeDetail" TO authenticated;
GRANT ALL ON TABLE public."StockTakeDetail" TO service_role;


--
-- TOC entry 4614 (class 0 OID 0)
-- Dependencies: 414
-- Name: TABLE "StockTransfer"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."StockTransfer" TO anon;
GRANT ALL ON TABLE public."StockTransfer" TO authenticated;
GRANT ALL ON TABLE public."StockTransfer" TO service_role;


--
-- TOC entry 4615 (class 0 OID 0)
-- Dependencies: 415
-- Name: TABLE "StockTransferDetail"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."StockTransferDetail" TO anon;
GRANT ALL ON TABLE public."StockTransferDetail" TO authenticated;
GRANT ALL ON TABLE public."StockTransferDetail" TO service_role;


--
-- TOC entry 4616 (class 0 OID 0)
-- Dependencies: 402
-- Name: TABLE "Supplier"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Supplier" TO anon;
GRANT ALL ON TABLE public."Supplier" TO authenticated;
GRANT ALL ON TABLE public."Supplier" TO service_role;


--
-- TOC entry 4617 (class 0 OID 0)
-- Dependencies: 397
-- Name: TABLE "Token"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Token" TO anon;
GRANT ALL ON TABLE public."Token" TO authenticated;
GRANT ALL ON TABLE public."Token" TO service_role;


--
-- TOC entry 4618 (class 0 OID 0)
-- Dependencies: 418
-- Name: TABLE "TransactionType"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."TransactionType" TO anon;
GRANT ALL ON TABLE public."TransactionType" TO authenticated;
GRANT ALL ON TABLE public."TransactionType" TO service_role;


--
-- TOC entry 4619 (class 0 OID 0)
-- Dependencies: 399
-- Name: TABLE "Ward"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."Ward" TO anon;
GRANT ALL ON TABLE public."Ward" TO authenticated;
GRANT ALL ON TABLE public."Ward" TO service_role;


--
-- TOC entry 2797 (class 826 OID 16494)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- TOC entry 2798 (class 826 OID 16495)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- TOC entry 2796 (class 826 OID 16493)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- TOC entry 2800 (class 826 OID 16497)
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- TOC entry 2795 (class 826 OID 16492)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- TOC entry 2799 (class 826 OID 16496)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


-- Completed on 2026-06-08 23:42:40

--
-- PostgreSQL database dump complete
--

