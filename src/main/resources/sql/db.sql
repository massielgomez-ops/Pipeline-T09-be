-- ========================================
-- BASE DE DATOS: agro_db
-- Sistema de Gestion Agricola
-- Version final corregida con JSON, geography,
-- JOINs, Stored Procedures e ÍNDICES
-- ========================================


-- ========================================
-- 1. CREAR BASE DE DATOS
-- ========================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'agro_db')
BEGIN
    CREATE DATABASE agro_db;
END
GO


USE agro_db;
GO


-- ========================================
-- 2. ELIMINAR TABLAS (orden por dependencias FK)
-- ========================================
DROP TRIGGER IF EXISTS tr_proveedores_after_update;
DROP TRIGGER IF EXISTS tr_proveedores_after_insert;
DROP TABLE IF EXISTS detalle_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS auditoria_proveedor;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS proveedores;
DROP TABLE IF EXISTS contacto;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS categoria;
GO


-- ========================================
-- 3. CREAR TABLAS (objetos MAESTRO primero)
-- ========================================


-- [MAESTRO] Tabla categoria
CREATE TABLE categoria (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    descripcion    VARCHAR(255),
    codigo         VARCHAR(30)  NOT NULL UNIQUE,
    prioridad      INT          CHECK (prioridad > 0),
    es_destacada   BIT          NOT NULL DEFAULT 0,
    fecha_vigencia DATE,
    state          CHAR(1)      NOT NULL DEFAULT 'A'
                                CONSTRAINT ck_categoria_state CHECK (state IN ('A','I')),
    created_at     DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at     DATETIME2,
    deleted_at     DATETIME2,
    restored_at    DATETIME2
);


-- [MAESTRO] Tabla cliente
-- JSON  : preferencias guarda config del cliente {"notificaciones":true,"idioma":"es","descuento":5}
-- GEOGRAPHY: ubicacion guarda coordenadas GPS reales
CREATE TABLE cliente (
    id               BIGINT        IDENTITY(1,1) PRIMARY KEY,
    nombre           VARCHAR(100)  NOT NULL,
    apellido         VARCHAR(100)  NOT NULL,
    email            VARCHAR(100)  NOT NULL UNIQUE,
    telefono         VARCHAR(20)   NOT NULL,
    direccion        VARCHAR(150),
    fecha_nacimiento DATE,
    limite_credito   DECIMAL(10,2) CHECK (limite_credito >= 0),
    preferencias     NVARCHAR(MAX),   -- JSON
    ubicacion        GEOGRAPHY,       -- SPATIAL
    state            CHAR(1)       NOT NULL DEFAULT 'A'
                                   CONSTRAINT ck_cliente_state CHECK (state IN ('A','I')),
    created_at       DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    updated_at       DATETIME2,
    deleted_at       DATETIME2,
    restored_at      DATETIME2
);


-- [MAESTRO] Tabla contacto
CREATE TABLE contacto (
    id             BIGINT       IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    telefono       VARCHAR(20)  NOT NULL,
    email          VARCHAR(100) NOT NULL,
    cargo          VARCHAR(100),
    extension      INT          CHECK (extension > 0),
    principal      BIT          NOT NULL DEFAULT 0,
    fecha_registro DATE,
    state          CHAR(1)      NOT NULL DEFAULT 'A'
                                CONSTRAINT ck_contacto_state CHECK (state IN ('A','I')),
    created_at     DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at     DATETIME2,
    deleted_at     DATETIME2,
    restored_at    DATETIME2
);


-- [MAESTRO] Tabla producto
-- FLOAT: precio | BIT: es_activo | DATE: fecha_vencimiento
CREATE TABLE producto (
    id                BIGINT       IDENTITY(1,1) PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    descripcion       VARCHAR(255),
    precio            FLOAT        NOT NULL CHECK (precio > 0),
    codigo            VARCHAR(30)  NOT NULL UNIQUE,
    stock             INT          NOT NULL DEFAULT 100 CHECK (stock >= 0),
    es_activo         BIT          NOT NULL DEFAULT 1,
    fecha_vencimiento DATE,
    state             CHAR(1)      NOT NULL DEFAULT 'A'
                                   CONSTRAINT ck_producto_state CHECK (state IN ('A','I')),
    created_at        DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at        DATETIME2,
    deleted_at        DATETIME2,
    restored_at       DATETIME2
);


-- [MAESTRO] Tabla proveedores
-- GEOGRAPHY: ubicacion GPS de la sede del proveedor
CREATE TABLE proveedores (
    id           BIGINT       IDENTITY(1,1) PRIMARY KEY,
    ruc          CHAR(11)     NOT NULL UNIQUE,
    cellphone    CHAR(9)      NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    address      VARCHAR(150),
    email        VARCHAR(100),
    ubicacion    GEOGRAPHY,      -- SPATIAL
    state        CHAR(1)      NOT NULL DEFAULT 'A'
                              CONSTRAINT ck_proveedores_state CHECK (state IN ('A','I')),
    created_at   DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2,
    deleted_at   DATETIME2,
    restored_at  DATETIME2
);


-- [TRANSACCIONAL] Tabla pedido
-- FK a cliente | CHECK en metodo_pago
CREATE TABLE pedido (
    id          BIGINT      IDENTITY(1,1) PRIMARY KEY,
    numero      VARCHAR(30) NOT NULL UNIQUE,
    fecha       DATE        NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    cliente_id  BIGINT      NOT NULL,
    metodo_pago VARCHAR(20) NOT NULL
                            CONSTRAINT ck_pedido_metodo
                            CHECK (metodo_pago IN ('efectivo','digital','credito','transferencia')),
    total       FLOAT       NOT NULL CHECK (total >= 0),
    descuento_total FLOAT   NOT NULL DEFAULT 0 CHECK (descuento_total >= 0),
    impuesto_total  FLOAT   NOT NULL DEFAULT 0 CHECK (impuesto_total >= 0),
    state       CHAR(1)     NOT NULL DEFAULT 'A'
                            CONSTRAINT ck_pedido_state CHECK (state IN ('A','I')),
    created_at  DATETIME2   NOT NULL DEFAULT SYSDATETIME(),
    updated_at  DATETIME2,
    deleted_at  DATETIME2,
    restored_at DATETIME2,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id)
);


-- [TRANSACCIONAL] Tabla detalle_pedido
-- FK a pedido y producto | UNIQUE compuesto evita duplicar producto en mismo pedido
CREATE TABLE detalle_pedido (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    pedido_id       BIGINT NOT NULL,
    producto_id     BIGINT NOT NULL,
    cantidad        INT    NOT NULL CHECK (cantidad > 0),
    precio_unitario FLOAT  NOT NULL CHECK (precio_unitario > 0),
    subtotal        FLOAT  NOT NULL CHECK (subtotal > 0),
    descuento_item  FLOAT  NOT NULL DEFAULT 0 CHECK (descuento_item >= 0),
    impuesto_item   FLOAT  NOT NULL DEFAULT 0 CHECK (impuesto_item >= 0),
    unidad_medida   VARCHAR(20) NOT NULL DEFAULT 'unidad',
    state           CHAR(1) NOT NULL DEFAULT 'A'
                            CONSTRAINT ck_detalle_pedido_state CHECK (state IN ('A','I')),
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2,
    CONSTRAINT fk_detalle_pedido          FOREIGN KEY (pedido_id)   REFERENCES pedido(id),
    CONSTRAINT fk_detalle_producto        FOREIGN KEY (producto_id) REFERENCES producto(id),
    CONSTRAINT uq_detalle_pedido_producto UNIQUE (pedido_id, producto_id)
);
GO


-- ========================================
-- 3b. ÍNDICES
-- ========================================


-- ── pedido ──────────────────────────────────────────────────────────────────
-- Cubre el JOIN pedido ↔ cliente presente en JOIN 1, 2, 3
-- y en sp_registrar_pedido / sp_historial_cliente.
-- SQL Server NO indexa FKs automáticamente.
CREATE INDEX ix_pedido_cliente_id
    ON pedido (cliente_id);


-- Índice compuesto para el patrón WHERE state = 'A' AND fecha BETWEEN …
-- usado en JOIN 3 (LEFT JOIN con filtro state) y en sp_historial_cliente.
-- state va primero: descarta filas inactivas antes de evaluar el rango de fechas.
CREATE INDEX ix_pedido_state_fecha
    ON pedido (state, fecha);


-- ── detalle_pedido ───────────────────────────────────────────────────────────
-- Cubre JOIN detalle_pedido ↔ pedido en JOIN 2, JOIN 4,
-- sp_registrar_pedido y sp_historial_cliente.
CREATE INDEX ix_detalle_pedido_id
    ON detalle_pedido (pedido_id);


-- Cubre JOIN detalle_pedido ↔ producto en JOIN 2 y JOIN 4
-- (productos más vendidos con SUM de cantidad y subtotal).
CREATE INDEX ix_detalle_producto_id
    ON detalle_pedido (producto_id);


-- ── cliente ──────────────────────────────────────────────────────────────────
-- Cubre WHERE c.state = 'A' en JOIN 5, sp_registrar_pedido
-- y sp_historial_cliente.
-- NOTA: email ya tiene índice implícito por su constraint UNIQUE.
CREATE INDEX ix_cliente_state
    ON cliente (state);


-- ── producto ─────────────────────────────────────────────────────────────────
-- Cubre WHERE pr.state = 'A' en sp_registrar_pedido
-- (validación de producto activo + lectura de precio y stock).
-- NOTA: codigo ya tiene índice implícito por su constraint UNIQUE.
CREATE INDEX ix_producto_state
    ON producto (state);


-- ── proveedores ──────────────────────────────────────────────────────────────
-- Patrón state = 'A' consistente con el resto del modelo;
-- cualquier consulta operativa sobre proveedores activos lo aprovechará.
-- NOTA: ruc ya tiene índice implícito por su constraint UNIQUE.
CREATE INDEX ix_proveedores_state
    ON proveedores (state);


GO


-- ========================================
-- 4. INSERTAR DATOS
-- ========================================


INSERT INTO categoria (nombre, descripcion, codigo, prioridad, es_destacada, fecha_vigencia, state)
VALUES
('Fertilizantes',          'Productos para nutrir plantas',     'CAT-001',  1,  1, '2026-12-31', 'A'),
('Herramientas',           'Herramientas agricolas',            'CAT-002',  2,  1, '2026-12-31', 'A'),
('Semillas',               'Variedad de semillas',              'CAT-003',  3,  0, '2026-12-31', 'A'),
('Pesticidas',             'Control de plagas',                 'CAT-004',  4,  0, '2026-12-31', 'A'),
('Riego',                  'Sistemas de riego',                 'CAT-005',  5,  1, '2026-12-31', 'A'),
('Sustratos',              'Tierra y sustratos',                'CAT-006',  6,  0, '2026-12-31', 'A'),
('Maquinaria',             'Maquinaria agricola',               'CAT-007',  7,  1, '2026-12-31', 'I'),
('Accesorios',             'Accesorios varios',                 'CAT-008',  8,  0, '2026-12-31', 'A'),
('Biocontrol',             'Control biologico',                 'CAT-009',  9,  0, '2026-12-31', 'A'),
('Invernadero',            'Insumos para invernadero',          'CAT-010', 10,  1, '2026-12-31', 'A'),
('Postcosecha',            'Manejo postcosecha',                'CAT-011', 11,  0, '2026-12-31', 'A'),
('Ganaderia',              'Productos para ganaderia',          'CAT-012', 12,  0, '2026-12-31', 'A'),
('Nutricion Foliar',       'Nutrientes foliares',               'CAT-013', 13,  1, '2026-12-31', 'A'),
('Agricultura de Precision','Sensores y medicion',              'CAT-014', 14,  0, '2026-12-31', 'A'),
('Energia Rural',          'Equipos de energia',                'CAT-015', 15,  0, '2026-12-31', 'I'),
('Proteccion',             'Equipos de proteccion personal',    'CAT-016', 16,  1, '2026-12-31', 'A');


-- Clientes con JSON (preferencias) y GEOGRAPHY (coordenadas GPS)
-- geography::Point(latitud, longitud, SRID=4326)
INSERT INTO cliente
    (nombre, apellido, email, telefono, direccion,
     fecha_nacimiento, limite_credito, preferencias, ubicacion, state)
VALUES
('Juan',     'Perez',   'juanperez@mail.com',    '999111222', 'Lima',
 '1994-03-10', 2500.00,
 '{"notificaciones":true,"idioma":"es","descuento":5}',
 geography::Point(-12.0464,-77.0428,4326), 'A'),


('Ana',      'Torres',  'ana.torres@mail.com',   '988222333', 'Arequipa',
 '1992-08-21', 3000.00,
 '{"notificaciones":false,"idioma":"es","descuento":10}',
 geography::Point(-16.4090,-71.5375,4326), 'A'),


('Luis',     'Mendoza', 'luis.m@mail.com',       '977333444', 'Cusco',
 '1988-11-15', 1800.00,
 '{"notificaciones":true,"idioma":"es","descuento":0}',
 geography::Point(-13.5319,-71.9675,4326), 'A'),


('Maria',    'Lopez',   'maria.lopez@mail.com',  '966444555', 'Trujillo',
 '1996-05-30', 3200.00,
 '{"notificaciones":true,"idioma":"es","descuento":15}',
 geography::Point(-8.1116,-79.0289,4326),  'I'),


('Carlos',   'Rojas',   'carlos.r@mail.com',     '955555666', 'Piura',
 '1990-01-12', 1500.00,
 '{"notificaciones":false,"idioma":"es","descuento":0}',
 geography::Point(-5.1945,-80.6328,4326),  'A'),


('Jorge',    'Ramirez', 'jorge.r@mail.com',      '944666777', 'Tacna',
 '1987-07-22', 2800.00,
 '{"notificaciones":true,"idioma":"es","descuento":8}',
 geography::Point(-18.0066,-70.2462,4326), 'A'),


('Sofia',    'Castro',  'sofia.c@mail.com',      '933777888', 'Ica',
 '1998-04-01', 2100.00,
 '{"notificaciones":false,"idioma":"es","descuento":3}',
 geography::Point(-14.0678,-75.7286,4326), 'A'),


('Pedro',    'Diaz',    'pedro.d@mail.com',      '922888999', 'Puno',
 '1991-09-19', 2600.00,
 '{"notificaciones":true,"idioma":"es","descuento":0}',
 geography::Point(-15.8402,-70.0219,4326), 'A'),


('Elena',    'Salas',   'elena.s@mail.com',      '911111112', 'Chiclayo',
 '1993-12-08', 2900.00,
 '{"notificaciones":true,"idioma":"es","descuento":6}',
 geography::Point(-6.7700,-79.8409,4326),  'A'),


('Ricardo',  'Vega',    'ricardo.v@mail.com',    '911111113', 'Huancayo',
 '1989-02-17', 2400.00,
 '{"notificaciones":false,"idioma":"es","descuento":4}',
 geography::Point(-12.0651,-75.2049,4326), 'A'),


('Patricia', 'Nunez',   'patricia.n@mail.com',   '911111114', 'Ayacucho',
 '1995-10-14', 2750.00,
 '{"notificaciones":true,"idioma":"es","descuento":7}',
 geography::Point(-13.1631,-74.2236,4326), 'A'),


('Diego',    'Flores',  'diego.f@mail.com',      '911111115', 'Pucallpa',
 '1997-03-03', 1650.00,
 '{"notificaciones":false,"idioma":"es","descuento":2}',
 geography::Point(-8.3791,-74.5539,4326),  'A'),


('Valeria',  'Ortega',  'valeria.o@mail.com',    '911111116', 'Tarapoto',
 '1994-06-26', 3500.00,
 '{"notificaciones":true,"idioma":"es","descuento":12}',
 geography::Point(-6.4824,-76.3659,4326),  'A'),


('Raul',     'Campos',  'raul.c@mail.com',       '911111117', 'Huaraz',
 '1986-09-11', 2200.00,
 '{"notificaciones":true,"idioma":"es","descuento":1}',
 geography::Point(-9.5300,-77.5286,4326),  'I'),


('Daniela',  'Morales', 'daniela.m@mail.com',    '911111118', 'Moquegua',
 '1999-01-05', 3100.00,
 '{"notificaciones":false,"idioma":"es","descuento":9}',
 geography::Point(-17.1928,-70.9342,4326), 'A'),


('Alberto',  'Paredes', 'alberto.p@mail.com',    '911111119', 'Cajamarca',
 '1992-04-28', 2050.00,
 '{"notificaciones":true,"idioma":"es","descuento":5}',
 geography::Point(-7.1617,-78.5128,4326),  'A');


INSERT INTO contacto
    (nombre, telefono, email, cargo, extension, principal, fecha_registro, state)
VALUES
('Juan Perez',      '999111222', 'juanperez@mail.com',    'Comprador',  101, 1, '2026-01-10', 'A'),
('Ana Torres',      '988222333', 'ana.torres@mail.com',   'Asistente',  102, 0, '2026-01-10', 'A'),
('Luis Mendoza',    '977333444', 'luis.m@mail.com',       'Gerente',    103, 1, '2026-01-10', 'A'),
('Maria Lopez',     '966444555', 'maria.lopez@mail.com',  'Vendedora',  104, 0, '2026-01-10', 'I'),
('Carlos Rojas',    '955555666', 'carlos.r@mail.com',     'Logistica',  105, 0, '2026-01-10', 'A'),
('Jorge Ramirez',   '944666777', 'jorge.r@mail.com',      'Supervisor', 106, 1, '2026-01-10', 'A'),
('Sofia Castro',    '933777888', 'sofia.c@mail.com',      'Analista',   107, 0, '2026-01-10', 'A'),
('Pedro Diaz',      '922888999', 'pedro.d@mail.com',      'Operador',   108, 0, '2026-01-10', 'A'),
('Elena Salas',     '911111112', 'elena.s@mail.com',      'Compras',    109, 1, '2026-01-12', 'A'),
('Ricardo Vega',    '911111113', 'ricardo.v@mail.com',    'Tecnico',    110, 0, '2026-01-12', 'A'),
('Patricia Nunez',  '911111114', 'patricia.n@mail.com',   'Contadora',  111, 0, '2026-01-12', 'A'),
('Diego Flores',    '911111115', 'diego.f@mail.com',      'Jefe Campo', 112, 1, '2026-01-12', 'A'),
('Valeria Ortega',  '911111116', 'valeria.o@mail.com',    'Asesora',    113, 0, '2026-01-12', 'A'),
('Raul Campos',     '911111117', 'raul.c@mail.com',       'Almacen',    114, 0, '2026-01-12', 'I'),
('Daniela Morales', '911111118', 'daniela.m@mail.com',    'Planner',    115, 0, '2026-01-12', 'A'),
('Alberto Paredes', '911111119', 'alberto.p@mail.com',    'Inspector',  116, 1, '2026-01-12', 'A');


INSERT INTO producto
    (nombre, descripcion, precio, codigo, stock, es_activo, fecha_vencimiento, state)
VALUES
('Fertilizante NPK',   'Fertilizante completo',    50.00, 'PROD-001', 100, 1, '2027-01-01', 'A'),
('Pala',               'Herramienta de acero',      30.00, 'PROD-002',  40, 1, '2030-01-01', 'A'),
('Semilla de maiz',    'Semilla hibrida',           10.00, 'PROD-003', 500, 1, '2026-12-31', 'A'),
('Insecticida',        'Control de plagas',         25.00, 'PROD-004',  70, 1, '2027-06-30', 'I'),
('Aspersor',           'Riego eficiente',           15.00, 'PROD-005', 120, 1, '2030-01-01', 'A'),
('Sustrato universal', 'Tierra para plantas',       12.00, 'PROD-006',  90, 1, '2028-05-15', 'A'),
('Tractor',            'Maquinaria agricola',     5000.00, 'PROD-007',   5, 1, '2035-01-01', 'A'),
('Guantes',            'Accesorio de proteccion',   5.00, 'PROD-008', 250, 1, '2030-01-01', 'A'),
('Manguera 1/2',       'Manguera reforzada',       18.00, 'PROD-009', 140, 1, '2032-03-01', 'A'),
('Abono Organico',     'Abono natural granulado',  22.00, 'PROD-010', 180, 1, '2028-09-30', 'A'),
('Fungicida Plus',     'Control de hongos',        33.00, 'PROD-011',  65, 1, '2027-11-30', 'A'),
('Carretilla',         'Carretilla metalica',      95.00, 'PROD-012',  25, 1, '2034-01-01', 'A'),
('Tijera de poda',     'Poda profesional',         28.00, 'PROD-013',  85, 1, '2031-07-01', 'A'),
('Bomba de agua',      'Bomba electrica',         420.00, 'PROD-014',  12, 1, '2033-01-01', 'A'),
('Semilla de quinua',  'Semilla certificada',      14.00, 'PROD-015', 260, 1, '2027-12-31', 'A'),
('Casco de seguridad', 'EPP para campo',           19.00, 'PROD-016', 130, 1, '2031-01-01', 'A');


-- Proveedores con GEOGRAPHY (sede de la empresa)
INSERT INTO proveedores
    (ruc, cellphone, company_name, contact_name, address, email, ubicacion, state)
VALUES
('20123456789','987654321','AgroPeru SAC',            'Luis Mendoza',   'Lima',        'contacto@agroperu.pe',    geography::Point(-12.0464,-77.0428,4326), 'A'),
('20987654321','912345678','Fertilizantes del Sur',   'Ana Torres',     'Arequipa',    'ventas@fertisur.pe',      geography::Point(-16.4090,-71.5375,4326), 'A'),
('20456789123','999888777','BioCrop Peru',            'Carlos Rojas',   'Cusco',       'info@biocrop.pe',         geography::Point(-13.5319,-71.9675,4326), 'A'),
('20765432109','987123456','AgroTech Solutions',      'Maria Lopez',    'Trujillo',    'hola@agrotech.pe',        geography::Point(-8.1116,-79.0289,4326),  'I'),
('20234567890','912987654','GreenFields S.A.',        'Jorge Ramirez',  'Piura',       'contacto@greenfields.pe', geography::Point(-5.1945,-80.6328,4326),  'I'),
('20876543210','911234567','AgroAndes',               'Sofia Castro',   'Lambayeque',  'ventas@agroandes.pe',     geography::Point(-6.7714,-79.8409,4326),  'A'),
('20345678901','922345678','CampoFertil',             'Pedro Diaz',     'Tacna',       'admin@campofertil.pe',    geography::Point(-18.0066,-70.2462,4326), 'A'),
('20567890123','933456789','SolAgro',                 'Lucia Vega',     'Ica',         'contacto@solagro.pe',     geography::Point(-14.0678,-75.7286,4326), 'A'),
('20678901234','944567890','Andes Bioinsumos',        'Elena Salas',    'Huanuco',     'ventas@andesbio.pe',      geography::Point(-9.9306,-76.2422,4326),  'A'),
('20901234567','955678901','Rural Smart Tech',        'Ricardo Vega',   'Junin',       'info@ruralsmart.pe',      geography::Point(-11.1580,-75.9926,4326), 'A'),
('20111222333','966789012','Campos Verdes SAC',       'Patricia Nunez', 'Ayacucho',    'hola@camposverdes.pe',    geography::Point(-13.1631,-74.2236,4326), 'A'),
('20222333444','977890123','AgroSelva',               'Diego Flores',   'Ucayali',     'contacto@agroselva.pe',   geography::Point(-8.3791,-74.5539,4326),  'A'),
('20333444555','988901234','FitoPeru',                'Valeria Ortega', 'San Martin',  'ventas@fitoperu.pe',      geography::Point(-6.4824,-76.3659,4326),  'A'),
('20444555666','999012345','Siembra Norte',           'Raul Campos',    'Cajamarca',   'ventas@siembranorte.pe',  geography::Point(-7.1617,-78.5128,4326),  'I'),
('20555666777','911223344','AgriSupply',              'Daniela Morales','Moquegua',    'info@agrisupply.pe',      geography::Point(-17.1928,-70.9342,4326), 'A'),
('20666777888','922334455','BioAndina',               'Alberto Paredes','Ancash',      'contacto@bioandina.pe',   geography::Point(-9.5300,-77.5286,4326),  'A');


INSERT INTO pedido (numero, fecha, cliente_id, metodo_pago, total, state)
VALUES
('PED-001','2026-04-01',  1, 'efectivo',      110.00, 'A'),
('PED-002','2026-04-02',  2, 'digital',        65.00, 'A'),
('PED-003','2026-04-03',  3, 'digital',        75.00, 'A'),
('PED-004','2026-04-04',  4, 'efectivo',       50.00, 'I'),
('PED-005','2026-04-05',  5, 'credito',       120.00, 'A'),
('PED-006','2026-04-06',  6, 'transferencia',  45.00, 'A'),
('PED-007','2026-04-07',  7, 'digital',        84.00, 'A'),
('PED-008','2026-04-08',  8, 'efectivo',       38.00, 'A'),
('PED-009','2026-04-09',  9, 'digital',        66.00, 'A'),
('PED-010','2026-04-10', 10, 'transferencia',  95.00, 'A'),
('PED-011','2026-04-11', 11, 'credito',       132.00, 'A'),
('PED-012','2026-04-12', 12, 'efectivo',       28.00, 'A'),
('PED-013','2026-04-13', 13, 'digital',        54.00, 'A'),
('PED-014','2026-04-14', 14, 'transferencia', 420.00, 'A'),
('PED-015','2026-04-15', 15, 'credito',        70.00, 'A'),
('PED-016','2026-04-16', 16, 'efectivo',       57.00, 'A');


INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario, subtotal)
VALUES
( 1,  1, 1,   50.00,  50.00),
( 1,  2, 2,   30.00,  60.00),
( 2,  3, 5,   10.00,  50.00),
( 2,  8, 3,    5.00,  15.00),
( 3,  4, 3,   25.00,  75.00),
( 4,  5, 2,   15.00,  30.00),
( 4,  6, 1,   12.00,  12.00),
( 5, 10, 4,   22.00,  88.00),
( 6,  9, 2,   18.00,  36.00),
( 7, 11, 2,   33.00,  66.00),
( 8, 16, 2,   19.00,  38.00),
( 9, 13, 2,   28.00,  56.00),
(10, 12, 1,   95.00,  95.00),
(11, 15, 6,   14.00,  84.00),
(12, 13, 1,   28.00,  28.00),
(13, 10, 2,   22.00,  44.00),
(14, 14, 1,  420.00, 420.00),
(15,  3, 7,   10.00,  70.00),
(16, 11, 1,   33.00,  33.00);
GO


-- ========================================
-- 5. CONSULTAS DE VERIFICACION CON JOINS
-- ========================================


-- [JOIN 1] INNER JOIN: pedidos con nombre completo del cliente
-- Aprovecha: ix_pedido_cliente_id
SELECT
    p.numero                        AS nro_pedido,
    p.fecha                         AS fecha_pedido,
    c.nombre + ' ' + c.apellido     AS cliente,
    c.email,
    p.metodo_pago,
    p.total,
    p.state
FROM pedido p
INNER JOIN cliente c ON p.cliente_id = c.id
ORDER BY p.fecha;


-- [JOIN 2] INNER JOIN encadenado: detalle completo (4 tablas)
-- Aprovecha: ix_pedido_cliente_id, ix_detalle_pedido_id, ix_detalle_producto_id
SELECT
    p.numero                        AS nro_pedido,
    c.nombre + ' ' + c.apellido     AS cliente,
    pr.nombre                       AS producto,
    pr.codigo,
    dp.cantidad,
    dp.precio_unitario,
    dp.subtotal
FROM detalle_pedido dp
INNER JOIN pedido   p  ON dp.pedido_id   = p.id
INNER JOIN cliente  c  ON p.cliente_id   = c.id
INNER JOIN producto pr ON dp.producto_id = pr.id
ORDER BY p.numero, pr.nombre;


-- [JOIN 3] LEFT JOIN: todos los clientes aunque no tengan pedidos + dato JSON
-- Aprovecha: ix_pedido_cliente_id, ix_pedido_state_fecha, ix_cliente_state
SELECT
    c.nombre + ' ' + c.apellido              AS cliente,
    c.email,
    c.limite_credito,
    COUNT(p.id)                              AS total_pedidos,
    ISNULL(SUM(p.total), 0)                  AS monto_total_comprado,
    JSON_VALUE(c.preferencias,'$.descuento') AS descuento_pct
FROM cliente c
LEFT JOIN pedido p ON c.id = p.cliente_id AND p.state = 'A'
GROUP BY c.nombre, c.apellido, c.email, c.limite_credito, c.preferencias
ORDER BY monto_total_comprado DESC;


-- [JOIN 4] LEFT JOIN: productos mas vendidos con stock actual
-- Aprovecha: ix_detalle_producto_id
SELECT
    pr.codigo,
    pr.nombre                       AS producto,
    pr.precio,
    pr.stock,
    pr.es_activo,
    ISNULL(SUM(dp.cantidad), 0)     AS unidades_vendidas,
    ISNULL(SUM(dp.subtotal), 0)     AS ingreso_total
FROM producto pr
LEFT JOIN detalle_pedido dp ON pr.id = dp.producto_id
GROUP BY pr.id, pr.codigo, pr.nombre, pr.precio, pr.stock, pr.es_activo
ORDER BY unidades_vendidas DESC;


-- [JOIN 5] JSON + GEOGRAPHY: preferencias y coordenadas GPS de clientes activos
-- Aprovecha: ix_cliente_state
-- Nota: se usa .Lat para latitud y .Long para longitud
SELECT
    c.nombre + ' ' + c.apellido                      AS cliente,
    JSON_VALUE(c.preferencias,'$.idioma')             AS idioma,
    JSON_VALUE(c.preferencias,'$.notificaciones')     AS notificaciones,
    JSON_VALUE(c.preferencias,'$.descuento')          AS descuento,
    c.ubicacion.Lat                                   AS latitud,
    c.ubicacion.Long                                  AS longitud
FROM cliente c
WHERE c.state = 'A'
  AND c.ubicacion IS NOT NULL;


-- ========================================
-- [JOIN 6] INNER JOIN: proveedores activos con contacto asociado
-- Construccion:
--   Se usa INNER JOIN entre proveedores y contacto por email.
--   Solo devuelve filas donde ambas tablas tienen coincidencia.
-- Funcionamiento:
--   Si un proveedor no tiene contacto registrado con el mismo email,
--   no aparece en el resultado.
-- ========================================
SELECT
    p.ruc,
    p.company_name                  AS empresa,
    p.contact_name                  AS contacto_proveedor,
    c.nombre                        AS contacto_registrado,
    c.cargo,
    p.email,
    p.address                       AS direccion,
    p.state                         AS estado
FROM proveedores p
INNER JOIN contacto c ON p.email = c.email
WHERE p.state = 'A'
ORDER BY p.company_name;


-- ========================================
-- [JOIN 7] RIGHT JOIN: todos los contactos y su proveedor si existe
-- Construccion:
--   proveedores es la tabla izquierda y contacto la derecha.
-- Funcionamiento:
--   Retorna TODOS los contactos. Si no hay proveedor coincidente,
--   las columnas de proveedor quedan en NULL.
-- ========================================
SELECT
    p.ruc,
    p.company_name                  AS empresa,
    p.state                         AS estado_proveedor,
    c.nombre                        AS contacto_registrado,
    c.telefono                      AS telefono_contacto,
    c.cargo,
    CASE
        WHEN p.id IS NULL THEN 'CONTACTO SIN PROVEEDOR'
        ELSE 'CONTACTO RELACIONADO A PROVEEDOR'
    END                             AS observacion
FROM proveedores p
RIGHT JOIN contacto c ON p.email = c.email
ORDER BY c.nombre;


-- ========================================
-- [JOIN 8] FULL OUTER JOIN: auditoria de coincidencia proveedor-contacto
-- Construccion:
--   Combina proveedores y contacto mostrando coincidencias y no coincidencias.
-- Funcionamiento:
--   Muestra proveedores sin contacto y contactos sin proveedor asociado.
-- ========================================
SELECT
    ISNULL(p.company_name, 'SIN PROVEEDOR') AS empresa,
    p.ruc,
    ISNULL(c.nombre, 'SIN CONTACTO')        AS contacto,
    ISNULL(p.email, c.email)                AS email_relacion,
    CASE
        WHEN p.id IS NULL THEN 'CONTACTO SIN PROVEEDOR'
        WHEN c.id IS NULL THEN 'PROVEEDOR SIN CONTACTO'
        ELSE 'RELACION COMPLETA'
    END                                     AS diagnostico
FROM proveedores p
FULL OUTER JOIN contacto c ON p.email = c.email
ORDER BY empresa, contacto;
GO


-- ========================================
-- 6. STORED PROCEDURES
-- ========================================
-- Un Stored Procedure (SP) es un bloque de codigo SQL
-- guardado en el servidor con un nombre. Se llama con EXEC.
-- Ventajas: reutilizacion, seguridad, rendimiento, mantenimiento.
-- ========================================


-- --------------------------------------------------
-- SP 1: Registrar un nuevo pedido con su detalle
-- Parametros: numero, fecha, cliente_id, metodo_pago,
--             producto_id, cantidad
-- Valida: cliente activo, producto activo, stock suficiente
-- Usa transaccion para garantizar integridad total
-- Índices que aprovecha:
--   ix_cliente_state      → valida cliente activo
--   ix_producto_state     → valida producto activo + lee precio/stock
--   ix_pedido_cliente_id  → SELECT final con JOIN
--   ix_detalle_pedido_id  → SELECT final con JOIN
--   ix_detalle_producto_id→ SELECT final con JOIN
-- --------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_pedido;
GO
CREATE PROCEDURE sp_registrar_pedido
    @numero      VARCHAR(30),
    @fecha       DATE,
    @cliente_id  BIGINT,
    @metodo_pago VARCHAR(20),
    @producto_id BIGINT,
    @cantidad    INT
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE @precio_unit  FLOAT;
    DECLARE @stock_actual INT;
    DECLARE @subtotal     FLOAT;
    DECLARE @pedido_id    BIGINT;


    -- Validar cliente activo
    -- ix_cliente_state filtra state = 'A' eficientemente
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = @cliente_id AND state = 'A')
    BEGIN
        RAISERROR('El cliente no existe o esta inactivo.', 16, 1);
        RETURN;
    END


    -- Obtener precio y stock del producto
    -- ix_producto_state filtra state = 'A' eficientemente
    SELECT @precio_unit  = precio,
           @stock_actual = stock
    FROM producto
    WHERE id = @producto_id AND state = 'A';


    IF @precio_unit IS NULL
    BEGIN
        RAISERROR('El producto no existe o esta inactivo.', 16, 1);
        RETURN;
    END


    -- Validar stock suficiente
    IF @stock_actual < @cantidad
    BEGIN
        RAISERROR('Stock insuficiente para el producto solicitado.', 16, 1);
        RETURN;
    END


    SET @subtotal = @precio_unit * @cantidad;


    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insertar cabecera del pedido
        INSERT INTO pedido (numero, fecha, cliente_id, metodo_pago, total, state)
        VALUES (@numero, @fecha, @cliente_id, @metodo_pago, @subtotal, 'A');


        SET @pedido_id = SCOPE_IDENTITY();


        -- Insertar detalle del pedido
        INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario, subtotal)
        VALUES (@pedido_id, @producto_id, @cantidad, @precio_unit, @subtotal);


        -- Descontar stock del producto
        UPDATE producto
        SET stock      = stock - @cantidad,
            updated_at = SYSDATETIME()
        WHERE id = @producto_id;


        COMMIT TRANSACTION;


        -- Retornar resumen con JOIN
        -- ix_pedido_cliente_id, ix_detalle_pedido_id, ix_detalle_producto_id
        SELECT
            p.numero,
            p.fecha,
            c.nombre + ' ' + c.apellido AS cliente,
            pr.nombre                   AS producto,
            dp.cantidad,
            dp.precio_unitario,
            dp.subtotal                 AS total
        FROM pedido p
        INNER JOIN cliente        c  ON p.cliente_id   = c.id
        INNER JOIN detalle_pedido dp ON p.id           = dp.pedido_id
        INNER JOIN producto       pr ON dp.producto_id = pr.id
        WHERE p.id = @pedido_id;


    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @msg NVARCHAR(500) = 'Error al registrar el pedido: ' + ERROR_MESSAGE();
        THROW 50001, @msg, 1;
    END CATCH
END;
GO


-- --------------------------------------------------
-- SP 2: Consultar historial de compras de un cliente
-- Parametros: cliente_id, fecha_desde (opcional), fecha_hasta (opcional)
-- Devuelve 3 resultsets: datos del cliente, detalle de pedidos, resumen
-- Índices que aprovecha:
--   ix_pedido_cliente_id   → filtra pedidos por cliente
--   ix_pedido_state_fecha  → filtra state = 'A' AND fecha BETWEEN
--   ix_detalle_pedido_id   → JOIN detalle_pedido ↔ pedido
--   ix_detalle_producto_id → JOIN detalle_pedido ↔ producto
-- --------------------------------------------------
DROP PROCEDURE IF EXISTS sp_historial_cliente;
GO
CREATE PROCEDURE sp_historial_cliente
    @cliente_id  BIGINT,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;


    -- Fechas por defecto si no se pasan
    SET @fecha_desde = ISNULL(@fecha_desde, '2000-01-01');
    SET @fecha_hasta = ISNULL(@fecha_hasta, CAST(GETDATE() AS DATE));


    -- Validar que el cliente existe
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = @cliente_id)
    BEGIN
        RAISERROR('Cliente no encontrado.', 16, 1);
        RETURN;
    END


    -- Resultado 1: datos del cliente con JSON y GEOGRAPHY
    SELECT
        c.nombre + ' ' + c.apellido                  AS cliente,
        c.email,
        c.telefono,
        c.limite_credito,
        JSON_VALUE(c.preferencias,'$.descuento')      AS descuento_pct,
        c.ubicacion.Lat                               AS latitud,
        c.ubicacion.Long                              AS longitud
    FROM cliente c
    WHERE c.id = @cliente_id;


    -- Resultado 2: detalle de pedidos con INNER JOINs
    -- ix_pedido_cliente_id  → lookup rápido por cliente
    -- ix_pedido_state_fecha → filtro fecha BETWEEN (state no se filtra aquí, muestra todos)
    -- ix_detalle_pedido_id  → JOIN con detalle
    -- ix_detalle_producto_id→ JOIN con producto
    SELECT
        p.numero                    AS nro_pedido,
        p.fecha,
        p.metodo_pago,
        pr.codigo                   AS cod_producto,
        pr.nombre                   AS producto,
        dp.cantidad,
        dp.precio_unitario,
        dp.subtotal,
        p.total                     AS total_pedido,
        p.state                     AS estado
    FROM pedido p
    INNER JOIN detalle_pedido dp ON p.id           = dp.pedido_id
    INNER JOIN producto       pr ON dp.producto_id = pr.id
    WHERE p.cliente_id = @cliente_id
      AND p.fecha BETWEEN @fecha_desde AND @fecha_hasta
    ORDER BY p.fecha DESC, pr.nombre;


    -- Resultado 3: resumen del periodo
    -- ix_pedido_cliente_id  + ix_pedido_state_fecha → filtro compuesto
    SELECT
        COUNT(DISTINCT p.id)  AS total_pedidos,
        SUM(dp.cantidad)      AS unidades_compradas,
        SUM(dp.subtotal)      AS monto_total
    FROM pedido p
    INNER JOIN detalle_pedido dp ON p.id = dp.pedido_id
    WHERE p.cliente_id = @cliente_id
      AND p.fecha BETWEEN @fecha_desde AND @fecha_hasta
      AND p.state = 'A';
END;
GO


-- ========================================
-- 7. EJECUTAR LOS STORED PROCEDURES
-- ========================================


-- SP1: Registrar pedido para Juan Perez (id=1)
--      comprando 10 unidades de Semilla de maiz (id=3)
EXEC sp_registrar_pedido
    @numero      = 'PED-017',
    @fecha       = '2026-05-01',
    @cliente_id  = 1,
    @metodo_pago = 'digital',
    @producto_id = 3,
    @cantidad    = 10;


-- SP2: Ver historial completo de Juan Perez en 2026
EXEC sp_historial_cliente
    @cliente_id  = 1,
    @fecha_desde = '2026-01-01',
    @fecha_hasta = '2026-12-31';
GO


-- ========================================
-- 8. ÍNDICES Y PLAN DE EJECUCIÓN - CRUD PROVEEDORES
-- ========================================
-- Cada consulta se ejecuta antes y después del índice usando
-- SET STATISTICS IO/TIME para comparar lecturas lógicas y tiempo.
-- Para demostrar el plan de ejecución real en SQL Server Management Studio:
--   1. Activar Include Actual Execution Plan (Ctrl+M).
--   2. Ejecutar primero la consulta ANTES del índice y guardar captura.
--   3. Crear el índice.
--   4. Ejecutar la misma consulta DESPUÉS del índice y guardar captura.
--   5. Comparar operadores como Table Scan, Index Scan, Index Seek y Sort.
-- ========================================


-- --------------------------------------------------
-- INDICE 1: FILTERED INDEX para proveedores activos por nombre
-- Antes del índice: el motor tiende a escanear más filas.
-- Después del índice: puede hacer Index Seek sobre proveedores activos.
-- Plan esperado:
--   antes  -> Scan sobre proveedores.
--   despues-> Index Seek sobre ix_proveedores_nombre_activo.
-- --------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.address,
    p.email
FROM proveedores p
WHERE p.state = 'A'
  AND p.company_name LIKE 'Agro%';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


CREATE INDEX ix_proveedores_nombre_activo
    ON proveedores (company_name)
    INCLUDE (ruc, address, email)
    WHERE state = 'A';
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.address,
    p.email
FROM proveedores p
WHERE p.state = 'A'
  AND p.company_name LIKE 'Agro%';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- --------------------------------------------------
-- INDICE 2: índice compuesto para búsquedas por estado y nombre
-- Antes del índice: posible scan + sort.
-- Después del índice: búsqueda y orden soportados por el índice.
-- Plan esperado:
--   antes  -> Scan + posible operador Sort.
--   despues-> Index Seek/Scan ordenado sobre ix_proveedores_state_company.
-- --------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.contact_name,
    p.cellphone
FROM proveedores p
WHERE p.state = 'A'
ORDER BY p.company_name;


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


CREATE INDEX ix_proveedores_state_company
    ON proveedores (state, company_name)
    INCLUDE (ruc, contact_name, cellphone);
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.contact_name,
    p.cellphone
FROM proveedores p
WHERE p.state = 'A'
ORDER BY p.company_name;


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- --------------------------------------------------
-- INDICE 3: índice cubriente para búsqueda por email
-- Antes del índice: más lecturas para recuperar columnas proyectadas.
-- Después del índice: consulta cubierta por el índice.
-- Plan esperado:
--   antes  -> Scan o búsqueda con lecturas extra.
--   despues-> búsqueda cubierta sin lookup adicional.
-- --------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.email,
    p.state
FROM proveedores p
WHERE p.email = 'contacto@agroperu.pe';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


CREATE INDEX ix_proveedores_email_cubriente
    ON proveedores (email)
    INCLUDE (ruc, company_name, state);
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.email,
    p.state
FROM proveedores p
WHERE p.email = 'contacto@agroperu.pe';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- ========================================
-- 9. TRIGGERS - CRUD PROVEEDORES
-- ========================================
-- Se crea una tabla de bitácora para auditar inserciones y cambios.
-- ========================================


CREATE TABLE auditoria_proveedor (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    proveedor_id     BIGINT NOT NULL,
    operacion        VARCHAR(20) NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior   NVARCHAR(255),
    valor_nuevo      NVARCHAR(255),
    usuario_bd       NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
    fecha_evento     DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO


-- --------------------------------------------------
-- Trigger 1: AFTER INSERT
-- Automatiza la bitácora de nuevos proveedores registrados.
-- --------------------------------------------------
CREATE TRIGGER tr_proveedores_after_insert
ON proveedores
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT
        i.id,
        'INSERT',
        'registro_completo',
        NULL,
        'Empresa=' + i.company_name + ', Email=' + ISNULL(i.email, 'SIN EMAIL') + ', Estado=' + i.state
    FROM inserted i;
END;
GO


-- --------------------------------------------------
-- Trigger 2: AFTER UPDATE
-- Audita cambios sensibles del proveedor: nombre, email y estado.
-- Además actualiza updated_at automáticamente.
-- --------------------------------------------------
CREATE TRIGGER tr_proveedores_after_update
ON proveedores
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT i.id, 'UPDATE', 'company_name', d.company_name, i.company_name
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE ISNULL(i.company_name, '') <> ISNULL(d.company_name, '');


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT i.id, 'UPDATE', 'email', d.email, i.email
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE ISNULL(i.email, '') <> ISNULL(d.email, '');


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT i.id, 'UPDATE', 'state', d.state, i.state
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE ISNULL(i.state, '') <> ISNULL(d.state, '');


    UPDATE p
    SET p.updated_at = SYSDATETIME()
    FROM proveedores p
    INNER JOIN inserted i ON p.id = i.id;
END;
GO


-- Pruebas rápidas del CRUD de proveedores
INSERT INTO proveedores
    (ruc, cellphone, company_name, contact_name, address, email, ubicacion, state)
VALUES
    ('20999999991', '900000001', 'Proveedor Demo', 'Demo Contacto', 'Lima Demo', 'demo@proveedor.pe', geography::Point(-12.0500,-77.0300,4326), 'A');
GO


UPDATE proveedores
SET company_name = 'Proveedor Demo Actualizado',
    email = 'demo.actualizado@proveedor.pe',
    state = 'I'
WHERE ruc = '20999999991';
GO


SELECT *
FROM auditoria_proveedor
ORDER BY fecha_evento DESC;
GO


-- ========================================
-- ========================================
-- BASE DE DATOS: agro_db
-- Sistema de Gestion Agricola
-- Version final corregida con JSON, geography,
-- JOINs, Stored Procedures e ÍNDICES
-- ========================================


-- ========================================
-- 1. CREAR BASE DE DATOS
-- ========================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'agro_db')
BEGIN
    CREATE DATABASE agro_db;
END
GO


USE agro_db;
GO


-- ========================================
-- 2. ELIMINAR TABLAS (orden por dependencias FK)
-- ========================================
DROP TRIGGER IF EXISTS tr_proveedores_after_update;
DROP TRIGGER IF EXISTS tr_proveedores_after_insert;
DROP TABLE IF EXISTS detalle_pedido;
DROP TABLE IF EXISTS pedido;
DROP TABLE IF EXISTS auditoria_proveedor;
DROP TABLE IF EXISTS producto;
DROP TABLE IF EXISTS proveedores;
DROP TABLE IF EXISTS contacto;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS categoria;
GO


-- ========================================
-- 3. CREAR TABLAS (objetos MAESTRO primero)
-- ========================================


-- [MAESTRO] Tabla categoria
CREATE TABLE categoria (
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    descripcion    VARCHAR(255),
    codigo         VARCHAR(30)  NOT NULL UNIQUE,
    prioridad      INT          CHECK (prioridad > 0),
    es_destacada   BIT          NOT NULL DEFAULT 0,
    fecha_vigencia DATE,
    state          CHAR(1)      NOT NULL DEFAULT 'A'
                                CONSTRAINT ck_categoria_state CHECK (state IN ('A','I')),
    created_at     DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at     DATETIME2,
    deleted_at     DATETIME2,
    restored_at    DATETIME2
);


-- [MAESTRO] Tabla cliente
-- JSON  : preferencias guarda config del cliente {"notificaciones":true,"idioma":"es","descuento":5}
-- GEOGRAPHY: ubicacion guarda coordenadas GPS reales
CREATE TABLE cliente (
    id               BIGINT        IDENTITY(1,1) PRIMARY KEY,
    nombre           VARCHAR(100)  NOT NULL,
    apellido         VARCHAR(100)  NOT NULL,
    email            VARCHAR(100)  NOT NULL UNIQUE,
    telefono         VARCHAR(20)   NOT NULL,
    direccion        VARCHAR(150),
    fecha_nacimiento DATE,
    limite_credito   DECIMAL(10,2) CHECK (limite_credito >= 0),
    preferencias     NVARCHAR(MAX),   -- JSON
    ubicacion        GEOGRAPHY,       -- SPATIAL
    state            CHAR(1)       NOT NULL DEFAULT 'A'
                                   CONSTRAINT ck_cliente_state CHECK (state IN ('A','I')),
    created_at       DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    updated_at       DATETIME2,
    deleted_at       DATETIME2,
    restored_at      DATETIME2
);


-- [MAESTRO] Tabla contacto
CREATE TABLE contacto (
    id             BIGINT       IDENTITY(1,1) PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    telefono       VARCHAR(20)  NOT NULL,
    email          VARCHAR(100) NOT NULL,
    cargo          VARCHAR(100),
    extension      INT          CHECK (extension > 0),
    principal      BIT          NOT NULL DEFAULT 0,
    fecha_registro DATE,
    state          CHAR(1)      NOT NULL DEFAULT 'A'
                                CONSTRAINT ck_contacto_state CHECK (state IN ('A','I')),
    created_at     DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at     DATETIME2,
    deleted_at     DATETIME2,
    restored_at    DATETIME2
);


-- [MAESTRO] Tabla producto
-- FLOAT: precio | BIT: es_activo | DATE: fecha_vencimiento
CREATE TABLE producto (
    id                BIGINT       IDENTITY(1,1) PRIMARY KEY,
    nombre            VARCHAR(100) NOT NULL,
    descripcion       VARCHAR(255),
    precio            FLOAT        NOT NULL CHECK (precio > 0),
    codigo            VARCHAR(30)  NOT NULL UNIQUE,
    stock             INT          NOT NULL DEFAULT 100 CHECK (stock >= 0),
    es_activo         BIT          NOT NULL DEFAULT 1,
    fecha_vencimiento DATE,
    state             CHAR(1)      NOT NULL DEFAULT 'A'
                                   CONSTRAINT ck_producto_state CHECK (state IN ('A','I')),
    created_at        DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at        DATETIME2,
    deleted_at        DATETIME2,
    restored_at       DATETIME2
);


-- [MAESTRO] Tabla proveedores
-- GEOGRAPHY: ubicacion GPS de la sede del proveedor
CREATE TABLE proveedores (
    id           BIGINT       IDENTITY(1,1) PRIMARY KEY,
    ruc          CHAR(11)     NOT NULL UNIQUE,
    cellphone    CHAR(9)      NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    address      VARCHAR(150),
    email        VARCHAR(100),
    ubicacion    GEOGRAPHY,      -- SPATIAL
    state        CHAR(1)      NOT NULL DEFAULT 'A'
                              CONSTRAINT ck_proveedores_state CHECK (state IN ('A','I')),
    created_at   DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    updated_at   DATETIME2,
    deleted_at   DATETIME2,
    restored_at  DATETIME2
);


-- [TRANSACCIONAL] Tabla pedido
-- FK a cliente | CHECK en metodo_pago
CREATE TABLE pedido (
    id          BIGINT      IDENTITY(1,1) PRIMARY KEY,
    numero      VARCHAR(30) NOT NULL UNIQUE,
    fecha       DATE        NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    cliente_id  BIGINT      NOT NULL,
    metodo_pago VARCHAR(20) NOT NULL
                            CONSTRAINT ck_pedido_metodo
                            CHECK (metodo_pago IN ('efectivo','digital','credito','transferencia')),
    total       FLOAT       NOT NULL CHECK (total >= 0),
    descuento_total FLOAT   NOT NULL DEFAULT 0 CHECK (descuento_total >= 0),
    impuesto_total  FLOAT   NOT NULL DEFAULT 0 CHECK (impuesto_total >= 0),
    state       CHAR(1)     NOT NULL DEFAULT 'A'
                            CONSTRAINT ck_pedido_state CHECK (state IN ('A','I')),
    created_at  DATETIME2   NOT NULL DEFAULT SYSDATETIME(),
    updated_at  DATETIME2,
    deleted_at  DATETIME2,
    restored_at DATETIME2,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (cliente_id) REFERENCES cliente(id)
);


-- [TRANSACCIONAL] Tabla detalle_pedido
-- FK a pedido y producto | UNIQUE compuesto evita duplicar producto en mismo pedido
CREATE TABLE detalle_pedido (
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    pedido_id       BIGINT NOT NULL,
    producto_id     BIGINT NOT NULL,
    cantidad        INT    NOT NULL CHECK (cantidad > 0),
    precio_unitario FLOAT  NOT NULL CHECK (precio_unitario > 0),
    subtotal        FLOAT  NOT NULL CHECK (subtotal > 0),
    descuento_item  FLOAT  NOT NULL DEFAULT 0 CHECK (descuento_item >= 0),
    impuesto_item   FLOAT  NOT NULL DEFAULT 0 CHECK (impuesto_item >= 0),
    unidad_medida   VARCHAR(20) NOT NULL DEFAULT 'unidad',
    state           CHAR(1) NOT NULL DEFAULT 'A'
                            CONSTRAINT ck_detalle_pedido_state CHECK (state IN ('A','I')),
    created_at      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    updated_at      DATETIME2,
    CONSTRAINT fk_detalle_pedido          FOREIGN KEY (pedido_id)   REFERENCES pedido(id),
    CONSTRAINT fk_detalle_producto        FOREIGN KEY (producto_id) REFERENCES producto(id),
    CONSTRAINT uq_detalle_pedido_producto UNIQUE (pedido_id, producto_id)
);
GO


-- ========================================
-- 3b. ÍNDICES
-- ========================================


-- ── pedido ──────────────────────────────────────────────────────────────────
-- Cubre el JOIN pedido ↔ cliente presente en JOIN 1, 2, 3
-- y en sp_registrar_pedido / sp_historial_cliente.
-- SQL Server NO indexa FKs automáticamente.
CREATE INDEX ix_pedido_cliente_id
    ON pedido (cliente_id);


-- Índice compuesto para el patrón WHERE state = 'A' AND fecha BETWEEN …
-- usado en JOIN 3 (LEFT JOIN con filtro state) y en sp_historial_cliente.
-- state va primero: descarta filas inactivas antes de evaluar el rango de fechas.
CREATE INDEX ix_pedido_state_fecha
    ON pedido (state, fecha);


-- ── detalle_pedido ───────────────────────────────────────────────────────────
-- Cubre JOIN detalle_pedido ↔ pedido en JOIN 2, JOIN 4,
-- sp_registrar_pedido y sp_historial_cliente.
CREATE INDEX ix_detalle_pedido_id
    ON detalle_pedido (pedido_id);


-- Cubre JOIN detalle_pedido ↔ producto en JOIN 2 y JOIN 4
-- (productos más vendidos con SUM de cantidad y subtotal).
CREATE INDEX ix_detalle_producto_id
    ON detalle_pedido (producto_id);


-- ── cliente ──────────────────────────────────────────────────────────────────
-- Cubre WHERE c.state = 'A' en JOIN 5, sp_registrar_pedido
-- y sp_historial_cliente.
-- NOTA: email ya tiene índice implícito por su constraint UNIQUE.
CREATE INDEX ix_cliente_state
    ON cliente (state);


-- ── producto ─────────────────────────────────────────────────────────────────
-- Cubre WHERE pr.state = 'A' en sp_registrar_pedido
-- (validación de producto activo + lectura de precio y stock).
-- NOTA: codigo ya tiene índice implícito por su constraint UNIQUE.
CREATE INDEX ix_producto_state
    ON producto (state);


-- ── proveedores ──────────────────────────────────────────────────────────────
-- Patrón state = 'A' consistente con el resto del modelo;
-- cualquier consulta operativa sobre proveedores activos lo aprovechará.
-- NOTA: ruc ya tiene índice implícito por su constraint UNIQUE.
CREATE INDEX ix_proveedores_state
    ON proveedores (state);


GO


-- ========================================
-- 4. INSERTAR DATOS
-- ========================================


INSERT INTO categoria (nombre, descripcion, codigo, prioridad, es_destacada, fecha_vigencia, state)
VALUES
('Fertilizantes',          'Productos para nutrir plantas',     'CAT-001',  1,  1, '2026-12-31', 'A'),
('Herramientas',           'Herramientas agricolas',            'CAT-002',  2,  1, '2026-12-31', 'A'),
('Semillas',               'Variedad de semillas',              'CAT-003',  3,  0, '2026-12-31', 'A'),
('Pesticidas',             'Control de plagas',                 'CAT-004',  4,  0, '2026-12-31', 'A'),
('Riego',                  'Sistemas de riego',                 'CAT-005',  5,  1, '2026-12-31', 'A'),
('Sustratos',              'Tierra y sustratos',                'CAT-006',  6,  0, '2026-12-31', 'A'),
('Maquinaria',             'Maquinaria agricola',               'CAT-007',  7,  1, '2026-12-31', 'I'),
('Accesorios',             'Accesorios varios',                 'CAT-008',  8,  0, '2026-12-31', 'A'),
('Biocontrol',             'Control biologico',                 'CAT-009',  9,  0, '2026-12-31', 'A'),
('Invernadero',            'Insumos para invernadero',          'CAT-010', 10,  1, '2026-12-31', 'A'),
('Postcosecha',            'Manejo postcosecha',                'CAT-011', 11,  0, '2026-12-31', 'A'),
('Ganaderia',              'Productos para ganaderia',          'CAT-012', 12,  0, '2026-12-31', 'A'),
('Nutricion Foliar',       'Nutrientes foliares',               'CAT-013', 13,  1, '2026-12-31', 'A'),
('Agricultura de Precision','Sensores y medicion',              'CAT-014', 14,  0, '2026-12-31', 'A'),
('Energia Rural',          'Equipos de energia',                'CAT-015', 15,  0, '2026-12-31', 'I'),
('Proteccion',             'Equipos de proteccion personal',    'CAT-016', 16,  1, '2026-12-31', 'A');


-- Clientes con JSON (preferencias) y GEOGRAPHY (coordenadas GPS)
-- geography::Point(latitud, longitud, SRID=4326)
INSERT INTO cliente
    (nombre, apellido, email, telefono, direccion,
     fecha_nacimiento, limite_credito, preferencias, ubicacion, state)
VALUES
('Juan',     'Perez',   'juanperez@mail.com',    '999111222', 'Lima',
 '1994-03-10', 2500.00,
 '{"notificaciones":true,"idioma":"es","descuento":5}',
 geography::Point(-12.0464,-77.0428,4326), 'A'),


('Ana',      'Torres',  'ana.torres@mail.com',   '988222333', 'Arequipa',
 '1992-08-21', 3000.00,
 '{"notificaciones":false,"idioma":"es","descuento":10}',
 geography::Point(-16.4090,-71.5375,4326), 'A'),


('Luis',     'Mendoza', 'luis.m@mail.com',       '977333444', 'Cusco',
 '1988-11-15', 1800.00,
 '{"notificaciones":true,"idioma":"es","descuento":0}',
 geography::Point(-13.5319,-71.9675,4326), 'A'),


('Maria',    'Lopez',   'maria.lopez@mail.com',  '966444555', 'Trujillo',
 '1996-05-30', 3200.00,
 '{"notificaciones":true,"idioma":"es","descuento":15}',
 geography::Point(-8.1116,-79.0289,4326),  'I'),


('Carlos',   'Rojas',   'carlos.r@mail.com',     '955555666', 'Piura',
 '1990-01-12', 1500.00,
 '{"notificaciones":false,"idioma":"es","descuento":0}',
 geography::Point(-5.1945,-80.6328,4326),  'A'),


('Jorge',    'Ramirez', 'jorge.r@mail.com',      '944666777', 'Tacna',
 '1987-07-22', 2800.00,
 '{"notificaciones":true,"idioma":"es","descuento":8}',
 geography::Point(-18.0066,-70.2462,4326), 'A'),


('Sofia',    'Castro',  'sofia.c@mail.com',      '933777888', 'Ica',
 '1998-04-01', 2100.00,
 '{"notificaciones":false,"idioma":"es","descuento":3}',
 geography::Point(-14.0678,-75.7286,4326), 'A'),


('Pedro',    'Diaz',    'pedro.d@mail.com',      '922888999', 'Puno',
 '1991-09-19', 2600.00,
 '{"notificaciones":true,"idioma":"es","descuento":0}',
 geography::Point(-15.8402,-70.0219,4326), 'A'),


('Elena',    'Salas',   'elena.s@mail.com',      '911111112', 'Chiclayo',
 '1993-12-08', 2900.00,
 '{"notificaciones":true,"idioma":"es","descuento":6}',
 geography::Point(-6.7700,-79.8409,4326),  'A'),


('Ricardo',  'Vega',    'ricardo.v@mail.com',    '911111113', 'Huancayo',
 '1989-02-17', 2400.00,
 '{"notificaciones":false,"idioma":"es","descuento":4}',
 geography::Point(-12.0651,-75.2049,4326), 'A'),


('Patricia', 'Nunez',   'patricia.n@mail.com',   '911111114', 'Ayacucho',
 '1995-10-14', 2750.00,
 '{"notificaciones":true,"idioma":"es","descuento":7}',
 geography::Point(-13.1631,-74.2236,4326), 'A'),


('Diego',    'Flores',  'diego.f@mail.com',      '911111115', 'Pucallpa',
 '1997-03-03', 1650.00,
 '{"notificaciones":false,"idioma":"es","descuento":2}',
 geography::Point(-8.3791,-74.5539,4326),  'A'),


('Valeria',  'Ortega',  'valeria.o@mail.com',    '911111116', 'Tarapoto',
 '1994-06-26', 3500.00,
 '{"notificaciones":true,"idioma":"es","descuento":12}',
 geography::Point(-6.4824,-76.3659,4326),  'A'),


('Raul',     'Campos',  'raul.c@mail.com',       '911111117', 'Huaraz',
 '1986-09-11', 2200.00,
 '{"notificaciones":true,"idioma":"es","descuento":1}',
 geography::Point(-9.5300,-77.5286,4326),  'I'),


('Daniela',  'Morales', 'daniela.m@mail.com',    '911111118', 'Moquegua',
 '1999-01-05', 3100.00,
 '{"notificaciones":false,"idioma":"es","descuento":9}',
 geography::Point(-17.1928,-70.9342,4326), 'A'),


('Alberto',  'Paredes', 'alberto.p@mail.com',    '911111119', 'Cajamarca',
 '1992-04-28', 2050.00,
 '{"notificaciones":true,"idioma":"es","descuento":5}',
 geography::Point(-7.1617,-78.5128,4326),  'A');


INSERT INTO contacto
    (nombre, telefono, email, cargo, extension, principal, fecha_registro, state)
VALUES
('Juan Perez',      '999111222', 'juanperez@mail.com',    'Comprador',  101, 1, '2026-01-10', 'A'),
('Ana Torres',      '988222333', 'ana.torres@mail.com',   'Asistente',  102, 0, '2026-01-10', 'A'),
('Luis Mendoza',    '977333444', 'luis.m@mail.com',       'Gerente',    103, 1, '2026-01-10', 'A'),
('Maria Lopez',     '966444555', 'maria.lopez@mail.com',  'Vendedora',  104, 0, '2026-01-10', 'I'),
('Carlos Rojas',    '955555666', 'carlos.r@mail.com',     'Logistica',  105, 0, '2026-01-10', 'A'),
('Jorge Ramirez',   '944666777', 'jorge.r@mail.com',      'Supervisor', 106, 1, '2026-01-10', 'A'),
('Sofia Castro',    '933777888', 'sofia.c@mail.com',      'Analista',   107, 0, '2026-01-10', 'A'),
('Pedro Diaz',      '922888999', 'pedro.d@mail.com',      'Operador',   108, 0, '2026-01-10', 'A'),
('Elena Salas',     '911111112', 'elena.s@mail.com',      'Compras',    109, 1, '2026-01-12', 'A'),
('Ricardo Vega',    '911111113', 'ricardo.v@mail.com',    'Tecnico',    110, 0, '2026-01-12', 'A'),
('Patricia Nunez',  '911111114', 'patricia.n@mail.com',   'Contadora',  111, 0, '2026-01-12', 'A'),
('Diego Flores',    '911111115', 'diego.f@mail.com',      'Jefe Campo', 112, 1, '2026-01-12', 'A'),
('Valeria Ortega',  '911111116', 'valeria.o@mail.com',    'Asesora',    113, 0, '2026-01-12', 'A'),
('Raul Campos',     '911111117', 'raul.c@mail.com',       'Almacen',    114, 0, '2026-01-12', 'I'),
('Daniela Morales', '911111118', 'daniela.m@mail.com',    'Planner',    115, 0, '2026-01-12', 'A'),
('Alberto Paredes', '911111119', 'alberto.p@mail.com',    'Inspector',  116, 1, '2026-01-12', 'A');


INSERT INTO producto
    (nombre, descripcion, precio, codigo, stock, es_activo, fecha_vencimiento, state)
VALUES
('Fertilizante NPK',   'Fertilizante completo',    50.00, 'PROD-001', 100, 1, '2027-01-01', 'A'),
('Pala',               'Herramienta de acero',      30.00, 'PROD-002',  40, 1, '2030-01-01', 'A'),
('Semilla de maiz',    'Semilla hibrida',           10.00, 'PROD-003', 500, 1, '2026-12-31', 'A'),
('Insecticida',        'Control de plagas',         25.00, 'PROD-004',  70, 1, '2027-06-30', 'I'),
('Aspersor',           'Riego eficiente',           15.00, 'PROD-005', 120, 1, '2030-01-01', 'A'),
('Sustrato universal', 'Tierra para plantas',       12.00, 'PROD-006',  90, 1, '2028-05-15', 'A'),
('Tractor',            'Maquinaria agricola',     5000.00, 'PROD-007',   5, 1, '2035-01-01', 'A'),
('Guantes',            'Accesorio de proteccion',   5.00, 'PROD-008', 250, 1, '2030-01-01', 'A'),
('Manguera 1/2',       'Manguera reforzada',       18.00, 'PROD-009', 140, 1, '2032-03-01', 'A'),
('Abono Organico',     'Abono natural granulado',  22.00, 'PROD-010', 180, 1, '2028-09-30', 'A'),
('Fungicida Plus',     'Control de hongos',        33.00, 'PROD-011',  65, 1, '2027-11-30', 'A'),
('Carretilla',         'Carretilla metalica',      95.00, 'PROD-012',  25, 1, '2034-01-01', 'A'),
('Tijera de poda',     'Poda profesional',         28.00, 'PROD-013',  85, 1, '2031-07-01', 'A'),
('Bomba de agua',      'Bomba electrica',         420.00, 'PROD-014',  12, 1, '2033-01-01', 'A'),
('Semilla de quinua',  'Semilla certificada',      14.00, 'PROD-015', 260, 1, '2027-12-31', 'A'),
('Casco de seguridad', 'EPP para campo',           19.00, 'PROD-016', 130, 1, '2031-01-01', 'A');


-- Proveedores con GEOGRAPHY (sede de la empresa)
INSERT INTO proveedores
    (ruc, cellphone, company_name, contact_name, address, email, ubicacion, state)
VALUES
('20123456789','987654321','AgroPeru SAC',            'Luis Mendoza',   'Lima',        'contacto@agroperu.pe',    geography::Point(-12.0464,-77.0428,4326), 'A'),
('20987654321','912345678','Fertilizantes del Sur',   'Ana Torres',     'Arequipa',    'ventas@fertisur.pe',      geography::Point(-16.4090,-71.5375,4326), 'A'),
('20456789123','999888777','BioCrop Peru',            'Carlos Rojas',   'Cusco',       'info@biocrop.pe',         geography::Point(-13.5319,-71.9675,4326), 'A'),
('20765432109','987123456','AgroTech Solutions',      'Maria Lopez',    'Trujillo',    'hola@agrotech.pe',        geography::Point(-8.1116,-79.0289,4326),  'I'),
('20234567890','912987654','GreenFields S.A.',        'Jorge Ramirez',  'Piura',       'contacto@greenfields.pe', geography::Point(-5.1945,-80.6328,4326),  'I'),
('20876543210','911234567','AgroAndes',               'Sofia Castro',   'Lambayeque',  'ventas@agroandes.pe',     geography::Point(-6.7714,-79.8409,4326),  'A'),
('20345678901','922345678','CampoFertil',             'Pedro Diaz',     'Tacna',       'admin@campofertil.pe',    geography::Point(-18.0066,-70.2462,4326), 'A'),
('20567890123','933456789','SolAgro',                 'Lucia Vega',     'Ica',         'contacto@solagro.pe',     geography::Point(-14.0678,-75.7286,4326), 'A'),
('20678901234','944567890','Andes Bioinsumos',        'Elena Salas',    'Huanuco',     'ventas@andesbio.pe',      geography::Point(-9.9306,-76.2422,4326),  'A'),
('20901234567','955678901','Rural Smart Tech',        'Ricardo Vega',   'Junin',       'info@ruralsmart.pe',      geography::Point(-11.1580,-75.9926,4326), 'A'),
('20111222333','966789012','Campos Verdes SAC',       'Patricia Nunez', 'Ayacucho',    'hola@camposverdes.pe',    geography::Point(-13.1631,-74.2236,4326), 'A'),
('20222333444','977890123','AgroSelva',               'Diego Flores',   'Ucayali',     'contacto@agroselva.pe',   geography::Point(-8.3791,-74.5539,4326),  'A'),
('20333444555','988901234','FitoPeru',                'Valeria Ortega', 'San Martin',  'ventas@fitoperu.pe',      geography::Point(-6.4824,-76.3659,4326),  'A'),
('20444555666','999012345','Siembra Norte',           'Raul Campos',    'Cajamarca',   'ventas@siembranorte.pe',  geography::Point(-7.1617,-78.5128,4326),  'I'),
('20555666777','911223344','AgriSupply',              'Daniela Morales','Moquegua',    'info@agrisupply.pe',      geography::Point(-17.1928,-70.9342,4326), 'A'),
('20666777888','922334455','BioAndina',               'Alberto Paredes','Ancash',      'contacto@bioandina.pe',   geography::Point(-9.5300,-77.5286,4326),  'A');


INSERT INTO pedido (numero, fecha, cliente_id, metodo_pago, total, state)
VALUES
('PED-001','2026-04-01',  1, 'efectivo',      110.00, 'A'),
('PED-002','2026-04-02',  2, 'digital',        65.00, 'A'),
('PED-003','2026-04-03',  3, 'digital',        75.00, 'A'),
('PED-004','2026-04-04',  4, 'efectivo',       50.00, 'I'),
('PED-005','2026-04-05',  5, 'credito',       120.00, 'A'),
('PED-006','2026-04-06',  6, 'transferencia',  45.00, 'A'),
('PED-007','2026-04-07',  7, 'digital',        84.00, 'A'),
('PED-008','2026-04-08',  8, 'efectivo',       38.00, 'A'),
('PED-009','2026-04-09',  9, 'digital',        66.00, 'A'),
('PED-010','2026-04-10', 10, 'transferencia',  95.00, 'A'),
('PED-011','2026-04-11', 11, 'credito',       132.00, 'A'),
('PED-012','2026-04-12', 12, 'efectivo',       28.00, 'A'),
('PED-013','2026-04-13', 13, 'digital',        54.00, 'A'),
('PED-014','2026-04-14', 14, 'transferencia', 420.00, 'A'),
('PED-015','2026-04-15', 15, 'credito',        70.00, 'A'),
('PED-016','2026-04-16', 16, 'efectivo',       57.00, 'A');


INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario, subtotal)
VALUES
( 1,  1, 1,   50.00,  50.00),
( 1,  2, 2,   30.00,  60.00),
( 2,  3, 5,   10.00,  50.00),
( 2,  8, 3,    5.00,  15.00),
( 3,  4, 3,   25.00,  75.00),
( 4,  5, 2,   15.00,  30.00),
( 4,  6, 1,   12.00,  12.00),
( 5, 10, 4,   22.00,  88.00),
( 6,  9, 2,   18.00,  36.00),
( 7, 11, 2,   33.00,  66.00),
( 8, 16, 2,   19.00,  38.00),
( 9, 13, 2,   28.00,  56.00),
(10, 12, 1,   95.00,  95.00),
(11, 15, 6,   14.00,  84.00),
(12, 13, 1,   28.00,  28.00),
(13, 10, 2,   22.00,  44.00),
(14, 14, 1,  420.00, 420.00),
(15,  3, 7,   10.00,  70.00),
(16, 11, 1,   33.00,  33.00);
GO


-- ========================================
-- 5. CONSULTAS DE VERIFICACION CON JOINS
-- ========================================


-- [JOIN 1] INNER JOIN: pedidos con nombre completo del cliente
-- Aprovecha: ix_pedido_cliente_id
SELECT
    p.numero                        AS nro_pedido,
    p.fecha                         AS fecha_pedido,
    c.nombre + ' ' + c.apellido     AS cliente,
    c.email,
    p.metodo_pago,
    p.total,
    p.state
FROM pedido p
INNER JOIN cliente c ON p.cliente_id = c.id
ORDER BY p.fecha;


-- [JOIN 2] INNER JOIN encadenado: detalle completo (4 tablas)
-- Aprovecha: ix_pedido_cliente_id, ix_detalle_pedido_id, ix_detalle_producto_id
SELECT
    p.numero                        AS nro_pedido,
    c.nombre + ' ' + c.apellido     AS cliente,
    pr.nombre                       AS producto,
    pr.codigo,
    dp.cantidad,
    dp.precio_unitario,
    dp.subtotal
FROM detalle_pedido dp
INNER JOIN pedido   p  ON dp.pedido_id   = p.id
INNER JOIN cliente  c  ON p.cliente_id   = c.id
INNER JOIN producto pr ON dp.producto_id = pr.id
ORDER BY p.numero, pr.nombre;


-- [JOIN 3] LEFT JOIN: todos los clientes aunque no tengan pedidos + dato JSON
-- Aprovecha: ix_pedido_cliente_id, ix_pedido_state_fecha, ix_cliente_state
SELECT
    c.nombre + ' ' + c.apellido              AS cliente,
    c.email,
    c.limite_credito,
    COUNT(p.id)                              AS total_pedidos,
    ISNULL(SUM(p.total), 0)                  AS monto_total_comprado,
    JSON_VALUE(c.preferencias,'$.descuento') AS descuento_pct
FROM cliente c
LEFT JOIN pedido p ON c.id = p.cliente_id AND p.state = 'A'
GROUP BY c.nombre, c.apellido, c.email, c.limite_credito, c.preferencias
ORDER BY monto_total_comprado DESC;


-- [JOIN 4] LEFT JOIN: productos mas vendidos con stock actual
-- Aprovecha: ix_detalle_producto_id
SELECT
    pr.codigo,
    pr.nombre                       AS producto,
    pr.precio,
    pr.stock,
    pr.es_activo,
    ISNULL(SUM(dp.cantidad), 0)     AS unidades_vendidas,
    ISNULL(SUM(dp.subtotal), 0)     AS ingreso_total
FROM producto pr
LEFT JOIN detalle_pedido dp ON pr.id = dp.producto_id
GROUP BY pr.id, pr.codigo, pr.nombre, pr.precio, pr.stock, pr.es_activo
ORDER BY unidades_vendidas DESC;


-- [JOIN 5] JSON + GEOGRAPHY: preferencias y coordenadas GPS de clientes activos
-- Aprovecha: ix_cliente_state
-- Nota: se usa .Lat para latitud y .Long para longitud
SELECT
    c.nombre + ' ' + c.apellido                      AS cliente,
    JSON_VALUE(c.preferencias,'$.idioma')             AS idioma,
    JSON_VALUE(c.preferencias,'$.notificaciones')     AS notificaciones,
    JSON_VALUE(c.preferencias,'$.descuento')          AS descuento,
    c.ubicacion.Lat                                   AS latitud,
    c.ubicacion.Long                                  AS longitud
FROM cliente c
WHERE c.state = 'A'
  AND c.ubicacion IS NOT NULL;


-- ========================================
-- [JOIN 6] INNER JOIN: proveedores activos con contacto asociado
-- Construccion:
--   Se usa INNER JOIN entre proveedores y contacto por email.
--   Solo devuelve filas donde ambas tablas tienen coincidencia.
-- Funcionamiento:
--   Si un proveedor no tiene contacto registrado con el mismo email,
--   no aparece en el resultado.
-- ========================================
SELECT
    p.ruc,
    p.company_name                  AS empresa,
    p.contact_name                  AS contacto_proveedor,
    c.nombre                        AS contacto_registrado,
    c.cargo,
    p.email,
    p.address                       AS direccion,
    p.state                         AS estado
FROM proveedores p
INNER JOIN contacto c ON p.email = c.email
WHERE p.state = 'A'
ORDER BY p.company_name;


-- ========================================
-- [JOIN 7] RIGHT JOIN: todos los contactos y su proveedor si existe
-- Construccion:
--   proveedores es la tabla izquierda y contacto la derecha.
-- Funcionamiento:
--   Retorna TODOS los contactos. Si no hay proveedor coincidente,
--   las columnas de proveedor quedan en NULL.
-- ========================================
SELECT
    p.ruc,
    p.company_name                  AS empresa,
    p.state                         AS estado_proveedor,
    c.nombre                        AS contacto_registrado,
    c.telefono                      AS telefono_contacto,
    c.cargo,
    CASE
        WHEN p.id IS NULL THEN 'CONTACTO SIN PROVEEDOR'
        ELSE 'CONTACTO RELACIONADO A PROVEEDOR'
    END                             AS observacion
FROM proveedores p
RIGHT JOIN contacto c ON p.email = c.email
ORDER BY c.nombre;


-- ========================================
-- [JOIN 8] FULL OUTER JOIN: auditoria de coincidencia proveedor-contacto
-- Construccion:
--   Combina proveedores y contacto mostrando coincidencias y no coincidencias.
-- Funcionamiento:
--   Muestra proveedores sin contacto y contactos sin proveedor asociado.
-- ========================================
SELECT
    ISNULL(p.company_name, 'SIN PROVEEDOR') AS empresa,
    p.ruc,
    ISNULL(c.nombre, 'SIN CONTACTO')        AS contacto,
    ISNULL(p.email, c.email)                AS email_relacion,
    CASE
        WHEN p.id IS NULL THEN 'CONTACTO SIN PROVEEDOR'
        WHEN c.id IS NULL THEN 'PROVEEDOR SIN CONTACTO'
        ELSE 'RELACION COMPLETA'
    END                                     AS diagnostico
FROM proveedores p
FULL OUTER JOIN contacto c ON p.email = c.email
ORDER BY empresa, contacto;
GO


-- ========================================
-- 6. STORED PROCEDURES
-- ========================================
-- Un Stored Procedure (SP) es un bloque de codigo SQL
-- guardado en el servidor con un nombre. Se llama con EXEC.
-- Ventajas: reutilizacion, seguridad, rendimiento, mantenimiento.
-- ========================================


-- --------------------------------------------------
-- SP 1: Registrar un nuevo pedido con su detalle
-- Parametros: numero, fecha, cliente_id, metodo_pago,
--             producto_id, cantidad
-- Valida: cliente activo, producto activo, stock suficiente
-- Usa transaccion para garantizar integridad total
-- Índices que aprovecha:
--   ix_cliente_state      → valida cliente activo
--   ix_producto_state     → valida producto activo + lee precio/stock
--   ix_pedido_cliente_id  → SELECT final con JOIN
--   ix_detalle_pedido_id  → SELECT final con JOIN
--   ix_detalle_producto_id→ SELECT final con JOIN
-- --------------------------------------------------
DROP PROCEDURE IF EXISTS sp_registrar_pedido;
GO
CREATE PROCEDURE sp_registrar_pedido
    @numero      VARCHAR(30),
    @fecha       DATE,
    @cliente_id  BIGINT,
    @metodo_pago VARCHAR(20),
    @producto_id BIGINT,
    @cantidad    INT
AS
BEGIN
    SET NOCOUNT ON;


    DECLARE @precio_unit  FLOAT;
    DECLARE @stock_actual INT;
    DECLARE @subtotal     FLOAT;
    DECLARE @pedido_id    BIGINT;


    -- Validar cliente activo
    -- ix_cliente_state filtra state = 'A' eficientemente
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = @cliente_id AND state = 'A')
    BEGIN
        RAISERROR('El cliente no existe o esta inactivo.', 16, 1);
        RETURN;
    END


    -- Obtener precio y stock del producto
    -- ix_producto_state filtra state = 'A' eficientemente
    SELECT @precio_unit  = precio,
           @stock_actual = stock
    FROM producto
    WHERE id = @producto_id AND state = 'A';


    IF @precio_unit IS NULL
    BEGIN
        RAISERROR('El producto no existe o esta inactivo.', 16, 1);
        RETURN;
    END


    -- Validar stock suficiente
    IF @stock_actual < @cantidad
    BEGIN
        RAISERROR('Stock insuficiente para el producto solicitado.', 16, 1);
        RETURN;
    END


    SET @subtotal = @precio_unit * @cantidad;


    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insertar cabecera del pedido
        INSERT INTO pedido (numero, fecha, cliente_id, metodo_pago, total, state)
        VALUES (@numero, @fecha, @cliente_id, @metodo_pago, @subtotal, 'A');


        SET @pedido_id = SCOPE_IDENTITY();


        -- Insertar detalle del pedido
        INSERT INTO detalle_pedido (pedido_id, producto_id, cantidad, precio_unitario, subtotal)
        VALUES (@pedido_id, @producto_id, @cantidad, @precio_unit, @subtotal);


        -- Descontar stock del producto
        UPDATE producto
        SET stock      = stock - @cantidad,
            updated_at = SYSDATETIME()
        WHERE id = @producto_id;


        COMMIT TRANSACTION;


        -- Retornar resumen con JOIN
        -- ix_pedido_cliente_id, ix_detalle_pedido_id, ix_detalle_producto_id
        SELECT
            p.numero,
            p.fecha,
            c.nombre + ' ' + c.apellido AS cliente,
            pr.nombre                   AS producto,
            dp.cantidad,
            dp.precio_unitario,
            dp.subtotal                 AS total
        FROM pedido p
        INNER JOIN cliente        c  ON p.cliente_id   = c.id
        INNER JOIN detalle_pedido dp ON p.id           = dp.pedido_id
        INNER JOIN producto       pr ON dp.producto_id = pr.id
        WHERE p.id = @pedido_id;


    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @msg NVARCHAR(500) = 'Error al registrar el pedido: ' + ERROR_MESSAGE();
        THROW 50001, @msg, 1;
    END CATCH
END;
GO


-- --------------------------------------------------
-- SP 2: Consultar historial de compras de un cliente
-- Parametros: cliente_id, fecha_desde (opcional), fecha_hasta (opcional)
-- Devuelve 3 resultsets: datos del cliente, detalle de pedidos, resumen
-- Índices que aprovecha:
--   ix_pedido_cliente_id   → filtra pedidos por cliente
--   ix_pedido_state_fecha  → filtra state = 'A' AND fecha BETWEEN
--   ix_detalle_pedido_id   → JOIN detalle_pedido ↔ pedido
--   ix_detalle_producto_id → JOIN detalle_pedido ↔ producto
-- --------------------------------------------------
DROP PROCEDURE IF EXISTS sp_historial_cliente;
GO
CREATE PROCEDURE sp_historial_cliente
    @cliente_id  BIGINT,
    @fecha_desde DATE = NULL,
    @fecha_hasta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;


    -- Fechas por defecto si no se pasan
    SET @fecha_desde = ISNULL(@fecha_desde, '2000-01-01');
    SET @fecha_hasta = ISNULL(@fecha_hasta, CAST(GETDATE() AS DATE));


    -- Validar que el cliente existe
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id = @cliente_id)
    BEGIN
        RAISERROR('Cliente no encontrado.', 16, 1);
        RETURN;
    END


    -- Resultado 1: datos del cliente con JSON y GEOGRAPHY
    SELECT
        c.nombre + ' ' + c.apellido                  AS cliente,
        c.email,
        c.telefono,
        c.limite_credito,
        JSON_VALUE(c.preferencias,'$.descuento')      AS descuento_pct,
        c.ubicacion.Lat                               AS latitud,
        c.ubicacion.Long                              AS longitud
    FROM cliente c
    WHERE c.id = @cliente_id;


    -- Resultado 2: detalle de pedidos con INNER JOINs
    -- ix_pedido_cliente_id  → lookup rápido por cliente
    -- ix_pedido_state_fecha → filtro fecha BETWEEN (state no se filtra aquí, muestra todos)
    -- ix_detalle_pedido_id  → JOIN con detalle
    -- ix_detalle_producto_id→ JOIN con producto
    SELECT
        p.numero                    AS nro_pedido,
        p.fecha,
        p.metodo_pago,
        pr.codigo                   AS cod_producto,
        pr.nombre                   AS producto,
        dp.cantidad,
        dp.precio_unitario,
        dp.subtotal,
        p.total                     AS total_pedido,
        p.state                     AS estado
    FROM pedido p
    INNER JOIN detalle_pedido dp ON p.id           = dp.pedido_id
    INNER JOIN producto       pr ON dp.producto_id = pr.id
    WHERE p.cliente_id = @cliente_id
      AND p.fecha BETWEEN @fecha_desde AND @fecha_hasta
    ORDER BY p.fecha DESC, pr.nombre;


    -- Resultado 3: resumen del periodo
    -- ix_pedido_cliente_id  + ix_pedido_state_fecha → filtro compuesto
    SELECT
        COUNT(DISTINCT p.id)  AS total_pedidos,
        SUM(dp.cantidad)      AS unidades_compradas,
        SUM(dp.subtotal)      AS monto_total
    FROM pedido p
    INNER JOIN detalle_pedido dp ON p.id = dp.pedido_id
    WHERE p.cliente_id = @cliente_id
      AND p.fecha BETWEEN @fecha_desde AND @fecha_hasta
      AND p.state = 'A';
END;
GO


-- ========================================
-- 7. EJECUTAR LOS STORED PROCEDURES
-- ========================================


-- SP1: Registrar pedido para Juan Perez (id=1)
--      comprando 10 unidades de Semilla de maiz (id=3)
EXEC sp_registrar_pedido
    @numero      = 'PED-017',
    @fecha       = '2026-05-01',
    @cliente_id  = 1,
    @metodo_pago = 'digital',
    @producto_id = 3,
    @cantidad    = 10;


-- SP2: Ver historial completo de Juan Perez en 2026
EXEC sp_historial_cliente
    @cliente_id  = 1,
    @fecha_desde = '2026-01-01',
    @fecha_hasta = '2026-12-31';
GO


-- ========================================
-- 8. ÍNDICES Y PLAN DE EJECUCIÓN - CRUD PROVEEDORES
-- ========================================
-- Cada consulta se ejecuta antes y después del índice usando
-- SET STATISTICS IO/TIME para comparar lecturas lógicas y tiempo.
-- Para demostrar el plan de ejecución real en SQL Server Management Studio:
--   1. Activar Include Actual Execution Plan (Ctrl+M).
--   2. Ejecutar primero la consulta ANTES del índice y guardar captura.
--   3. Crear el índice.
--   4. Ejecutar la misma consulta DESPUÉS del índice y guardar captura.
--   5. Comparar operadores como Table Scan, Index Scan, Index Seek y Sort.
-- ========================================


-- --------------------------------------------------
-- INDICE 1: FILTERED INDEX para proveedores activos por nombre
-- Antes del índice: el motor tiende a escanear más filas.
-- Después del índice: puede hacer Index Seek sobre proveedores activos.
-- Plan esperado:
--   antes  -> Scan sobre proveedores.
--   despues-> Index Seek sobre ix_proveedores_nombre_activo.
-- --------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.address,
    p.email
FROM proveedores p
WHERE p.state = 'A'
  AND p.company_name LIKE 'Agro%';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


CREATE INDEX ix_proveedores_nombre_activo
    ON proveedores (company_name)
    INCLUDE (ruc, address, email)
    WHERE state = 'A';
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.address,
    p.email
FROM proveedores p
WHERE p.state = 'A'
  AND p.company_name LIKE 'Agro%';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- --------------------------------------------------
-- INDICE 2: índice compuesto para búsquedas por estado y nombre
-- Antes del índice: posible scan + sort.
-- Después del índice: búsqueda y orden soportados por el índice.
-- Plan esperado:
--   antes  -> Scan + posible operador Sort.
--   despues-> Index Seek/Scan ordenado sobre ix_proveedores_state_company.
-- --------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.contact_name,
    p.cellphone
FROM proveedores p
WHERE p.state = 'A'
ORDER BY p.company_name;


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


CREATE INDEX ix_proveedores_state_company
    ON proveedores (state, company_name)
    INCLUDE (ruc, contact_name, cellphone);
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.contact_name,
    p.cellphone
FROM proveedores p
WHERE p.state = 'A'
ORDER BY p.company_name;


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- --------------------------------------------------
-- INDICE 3: índice cubriente para búsqueda por email
-- Antes del índice: más lecturas para recuperar columnas proyectadas.
-- Después del índice: consulta cubierta por el índice.
-- Plan esperado:
--   antes  -> Scan o búsqueda con lecturas extra.
--   despues-> búsqueda cubierta sin lookup adicional.
-- --------------------------------------------------
SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.email,
    p.state
FROM proveedores p
WHERE p.email = 'contacto@agroperu.pe';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


CREATE INDEX ix_proveedores_email_cubriente
    ON proveedores (email)
    INCLUDE (ruc, company_name, state);
GO


SET STATISTICS IO ON;
SET STATISTICS TIME ON;


SELECT
    p.ruc,
    p.company_name,
    p.email,
    p.state
FROM proveedores p
WHERE p.email = 'contacto@agroperu.pe';


SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- ========================================
-- 9. TRIGGERS - CRUD PROVEEDORES
-- ========================================
-- Se crea una tabla de bitácora para auditar inserciones y cambios.
-- ========================================


CREATE TABLE auditoria_proveedor (
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    proveedor_id     BIGINT NOT NULL,
    operacion        VARCHAR(20) NOT NULL,
    campo_modificado VARCHAR(50) NOT NULL,
    valor_anterior   NVARCHAR(255),
    valor_nuevo      NVARCHAR(255),
    usuario_bd       NVARCHAR(128) NOT NULL DEFAULT SYSTEM_USER,
    fecha_evento     DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO


-- --------------------------------------------------
-- Trigger 1: AFTER INSERT
-- Automatiza la bitácora de nuevos proveedores registrados.
-- --------------------------------------------------
CREATE TRIGGER tr_proveedores_after_insert
ON proveedores
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT
        i.id,
        'INSERT',
        'registro_completo',
        NULL,
        'Empresa=' + i.company_name + ', Email=' + ISNULL(i.email, 'SIN EMAIL') + ', Estado=' + i.state
    FROM inserted i;
END;
GO


-- --------------------------------------------------
-- Trigger 2: AFTER UPDATE
-- Audita cambios sensibles del proveedor: nombre, email y estado.
-- Además actualiza updated_at automáticamente.
-- --------------------------------------------------
CREATE TRIGGER tr_proveedores_after_update
ON proveedores
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT i.id, 'UPDATE', 'company_name', d.company_name, i.company_name
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE ISNULL(i.company_name, '') <> ISNULL(d.company_name, '');


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT i.id, 'UPDATE', 'email', d.email, i.email
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE ISNULL(i.email, '') <> ISNULL(d.email, '');


    INSERT INTO auditoria_proveedor
        (proveedor_id, operacion, campo_modificado, valor_anterior, valor_nuevo)
    SELECT i.id, 'UPDATE', 'state', d.state, i.state
    FROM inserted i
    INNER JOIN deleted d ON i.id = d.id
    WHERE ISNULL(i.state, '') <> ISNULL(d.state, '');


    UPDATE p
    SET p.updated_at = SYSDATETIME()
    FROM proveedores p
    INNER JOIN inserted i ON p.id = i.id;
END;
GO


-- Pruebas rápidas del CRUD de proveedores
INSERT INTO proveedores
    (ruc, cellphone, company_name, contact_name, address, email, ubicacion, state)
VALUES
    ('20999999991', '900000001', 'Proveedor Demo', 'Demo Contacto', 'Lima Demo', 'demo@proveedor.pe', geography::Point(-12.0500,-77.0300,4326), 'A');
GO


UPDATE proveedores
SET company_name = 'Proveedor Demo Actualizado',
    email = 'demo.actualizado@proveedor.pe',
    state = 'I'
WHERE ruc = '20999999991';
GO


SELECT *
FROM auditoria_proveedor
ORDER BY fecha_evento DESC;
GO


-- ========================================
-- 10. CLIENTE: JOINs, VISTAS, INDICES Y TRIGGERS
-- ========================================
-- Ordenado para evidenciar: primero Proveedor (seccion 9), luego Cliente.
-- ========================================


-- ========================================
-- 10.1 VISTAS (CLIENTE)
-- ========================================
DROP VIEW IF EXISTS vw_cliente_resumen_compras;
GO
CREATE VIEW vw_cliente_resumen_compras
AS
SELECT
    c.id,
    c.nombre,
    c.apellido,
    c.email,
    c.state,
    COUNT(p.id) AS total_pedidos_activos,
    ISNULL(SUM(p.total), 0) AS monto_total_activo,
    MAX(p.fecha) AS fecha_ultima_compra
FROM cliente c
LEFT JOIN pedido p ON p.cliente_id = c.id AND p.state = 'A'
GROUP BY c.id, c.nombre, c.apellido, c.email, c.state;
GO

DROP VIEW IF EXISTS vw_cliente_preferencias_geo;
GO
CREATE VIEW vw_cliente_preferencias_geo
AS
SELECT
    c.id,
    c.nombre,
    c.apellido,
    c.email,
    JSON_VALUE(c.preferencias, '$.idioma') AS idioma,
    JSON_VALUE(c.preferencias, '$.notificaciones') AS notificaciones,
    JSON_VALUE(c.preferencias, '$.descuento') AS descuento_pct,
    c.ubicacion.Lat AS latitud,
    c.ubicacion.Long AS longitud
FROM cliente c
WHERE c.state = 'A'
  AND c.ubicacion IS NOT NULL;
GO


-- ========================================
-- 10.2 JOINs COMPLEJOS (MINIMO 3 TIPOS)
-- ========================================

-- [J1] INNER JOIN
-- Construccion: cliente -> pedido -> detalle_pedido -> producto.
-- Funcionamiento: solo aparecen compras con coincidencia completa.
SELECT
    c.id AS cliente_id,
    c.nombre + ' ' + c.apellido AS cliente,
    p.numero AS nro_pedido,
    p.fecha,
    pr.codigo AS producto_codigo,
    pr.nombre AS producto,
    dp.cantidad,
    dp.subtotal
FROM cliente c
INNER JOIN pedido p ON p.cliente_id = c.id
INNER JOIN detalle_pedido dp ON dp.pedido_id = p.id
INNER JOIN producto pr ON pr.id = dp.producto_id
WHERE c.state = 'A' AND p.state = 'A'
ORDER BY p.fecha DESC;
GO

-- [J2] LEFT JOIN
-- Construccion: cliente como base y pedido como opcional.
-- Funcionamiento: incluye clientes sin pedidos (agregados en 0).
SELECT
    c.id,
    c.nombre + ' ' + c.apellido AS cliente,
    c.email,
    COUNT(p.id) AS total_pedidos,
    ISNULL(SUM(p.total), 0) AS monto_total
FROM cliente c
LEFT JOIN pedido p ON p.cliente_id = c.id AND p.state = 'A'
GROUP BY c.id, c.nombre, c.apellido, c.email
ORDER BY monto_total DESC;
GO

-- [J3] RIGHT JOIN
-- Construccion: pedido (izquierda), cliente (derecha).
-- Funcionamiento: lista todos los clientes aunque no tengan pedido.
SELECT
    c.id AS cliente_id,
    c.nombre + ' ' + c.apellido AS cliente,
    p.id AS pedido_id,
    p.numero,
    p.total
FROM pedido p
RIGHT JOIN cliente c ON p.cliente_id = c.id
ORDER BY c.id, p.numero;
GO

-- [J4] FULL OUTER JOIN
-- Construccion: cliente y contacto unidos por email.
-- Funcionamiento: diagnostica coincidencias y faltantes en ambos lados.
SELECT
    ISNULL(c.email, ct.email) AS email_relacion,
    c.id AS cliente_id,
    c.nombre + ' ' + c.apellido AS cliente,
    ct.id AS contacto_id,
    ct.nombre AS contacto,
    CASE
        WHEN c.id IS NULL THEN 'CONTACTO SIN CLIENTE'
        WHEN ct.id IS NULL THEN 'CLIENTE SIN CONTACTO'
        ELSE 'RELACION COMPLETA'
    END AS diagnostico
FROM cliente c
FULL OUTER JOIN contacto ct ON c.email = ct.email
ORDER BY email_relacion;
GO


-- ========================================
-- 10.3 CONSULTAS + INDICES (ANTES Y DESPUES)
-- ========================================
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- [I1] Indice compuesto + INCLUDE
DROP INDEX IF EXISTS ix_cliente_state_apellido_nombre ON cliente;
GO
-- ANTES
SELECT c.id, c.apellido, c.nombre, c.email, c.telefono
FROM cliente c
WHERE c.state = 'A' AND c.apellido LIKE 'M%'
ORDER BY c.apellido, c.nombre;
GO
CREATE INDEX ix_cliente_state_apellido_nombre
    ON cliente (state, apellido, nombre)
    INCLUDE (email, telefono);
GO
-- DESPUES
SELECT c.id, c.apellido, c.nombre, c.email, c.telefono
FROM cliente c
WHERE c.state = 'A' AND c.apellido LIKE 'M%'
ORDER BY c.apellido, c.nombre;
GO

-- [I2] Filtered index
DROP INDEX IF EXISTS ix_cliente_credito_activo_filtrado ON cliente;
GO
-- ANTES
SELECT TOP (10) c.id, c.nombre, c.apellido, c.limite_credito, c.email
FROM cliente c
WHERE c.state = 'A' AND c.limite_credito >= 2500
ORDER BY c.limite_credito DESC;
GO
CREATE INDEX ix_cliente_credito_activo_filtrado
    ON cliente (limite_credito DESC)
    INCLUDE (nombre, apellido, email)
    WHERE state = 'A';
GO
-- DESPUES
SELECT TOP (10) c.id, c.nombre, c.apellido, c.limite_credito, c.email
FROM cliente c
WHERE c.state = 'A' AND c.limite_credito >= 2500
ORDER BY c.limite_credito DESC;
GO

-- [I3] Spatial index
DROP INDEX IF EXISTS sidx_cliente_ubicacion ON cliente;
GO
DECLARE @punto_ref GEOGRAPHY = geography::Point(-12.0464, -77.0428, 4326);
-- ANTES
SELECT c.id, c.nombre, c.apellido, c.email,
       c.ubicacion.STDistance(@punto_ref) AS distancia_metros
FROM cliente c
WHERE c.ubicacion IS NOT NULL
  AND c.ubicacion.STDistance(@punto_ref) <= 50000
ORDER BY distancia_metros;
GO
CREATE SPATIAL INDEX sidx_cliente_ubicacion
ON cliente(ubicacion)
USING GEOGRAPHY_AUTO_GRID
WITH (CELLS_PER_OBJECT = 16);
GO
DECLARE @punto_ref2 GEOGRAPHY = geography::Point(-12.0464, -77.0428, 4326);
-- DESPUES
SELECT c.id, c.nombre, c.apellido, c.email,
       c.ubicacion.STDistance(@punto_ref2) AS distancia_metros
FROM cliente c
WHERE c.ubicacion IS NOT NULL
  AND c.ubicacion.STDistance(@punto_ref2) <= 50000
ORDER BY distancia_metros;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO


-- ========================================
-- 10.4 TRIGGERS (2) DE CLIENTE
-- ========================================
IF OBJECT_ID('dbo.cliente_bitacora', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.cliente_bitacora (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        cliente_id BIGINT NULL,
        accion VARCHAR(20) NOT NULL,
        usuario_bd SYSNAME NOT NULL DEFAULT SUSER_SNAME(),
        fecha_evento DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        detalle NVARCHAR(4000) NULL,
        old_data NVARCHAR(MAX) NULL,
        new_data NVARCHAR(MAX) NULL
    );
END;
GO

-- [T1] AFTER INSERT: valida JSON y registra alta.
DROP TRIGGER IF EXISTS tr_cliente_after_insert;
GO
CREATE TRIGGER tr_cliente_after_insert
ON cliente
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.preferencias IS NOT NULL
          AND ISJSON(i.preferencias) <> 1
    )
    BEGIN
        THROW 50011, 'JSON invalido en cliente.preferencias. Operacion cancelada.', 1;
    END;

    INSERT INTO dbo.cliente_bitacora (cliente_id, accion, detalle, new_data)
    SELECT
        i.id,
        'INSERT',
        'Alta de cliente',
        (
            SELECT i.nombre, i.apellido, i.email, i.telefono, i.limite_credito, i.state
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i;
END;
GO

-- [T2] AFTER UPDATE: audita cambios sensibles.
DROP TRIGGER IF EXISTS tr_cliente_after_update;
GO
CREATE TRIGGER tr_cliente_after_update
ON cliente
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.cliente_bitacora (cliente_id, accion, detalle, old_data, new_data)
    SELECT
        i.id,
        'UPDATE',
        'Cambio sensible en cliente',
        (
            SELECT d.email, d.telefono, d.limite_credito, d.state
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        ),
        (
            SELECT i.email, i.telefono, i.limite_credito, i.state
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        )
    FROM inserted i
    INNER JOIN deleted d ON d.id = i.id
    WHERE ISNULL(i.email, '') <> ISNULL(d.email, '')
       OR ISNULL(i.telefono, '') <> ISNULL(d.telefono, '')
       OR ISNULL(i.limite_credito, -1) <> ISNULL(d.limite_credito, -1)
       OR ISNULL(i.state, '') <> ISNULL(d.state, '');
END;
GO


-- ========================================
-- 10.5 PRUEBAS RAPIDAS (CLIENTE)
-- ========================================
SELECT TOP (20) * FROM vw_cliente_resumen_compras ORDER BY monto_total_activo DESC;
GO
SELECT TOP (20) * FROM vw_cliente_preferencias_geo ORDER BY id;
GO

IF NOT EXISTS (SELECT 1 FROM cliente WHERE email = 'cliente.demotrigger@mail.com')
BEGIN
    INSERT INTO cliente (
        nombre, apellido, email, telefono, direccion,
        fecha_nacimiento, limite_credito, preferencias, ubicacion, state
    )
    VALUES (
        'Cliente', 'DemoTrigger', 'cliente.demotrigger@mail.com', '900111222', 'Lima',
        '1995-01-01', 2300,
        '{"notificaciones":true,"idioma":"es","descuento":5}',
        geography::Point(-12.0500, -77.0400, 4326),
        'A'
    );
END;
GO

UPDATE cliente
SET limite_credito = limite_credito + 100,
    telefono = '900333444',
    updated_at = SYSDATETIME()
WHERE email = 'cliente.demotrigger@mail.com';
GO

SELECT TOP (50)
    id,
    cliente_id,
    accion,
    usuario_bd,
    fecha_evento,
    detalle,
    old_data,
    new_data
FROM dbo.cliente_bitacora
ORDER BY id DESC;
GO