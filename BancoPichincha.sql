-- Notas generales:
-- - Usamos SERIAL para claves primarias internas y UUID para movimientos.
-- - Campos visibles como números de cuenta o tarjeta se generan desde el backend
--   con validaciones específicas (por ejemplo, algoritmo de Luhn).
-- - Comentarios indican la lógica detrás de cada decisión.

-- Habilitamos extensión para UUID si se va a usar en identificadores no secuenciales
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================
-- Tabla: SUCURSAL
-- ==============================================================
CREATE TABLE SUCURSAL (
   ID_SUCURSAL          SERIAL PRIMARY KEY, -- ID interno, no visible al cliente
   NOMBRE_SUCURSAL      VARCHAR(255),
   DIRECCION_SUCURSAL   VARCHAR(255),
   TELEFONO_SUCURSAL    VARCHAR(20),
   EMAIL_SUCURSAL       VARCHAR(255),
   ESTADO_SUCURSAL      VARCHAR(50)
);

-- ==============================================================
-- Tabla: CAJEROS
-- ==============================================================
CREATE TABLE CAJEROS (
   ID_CAJERO            SERIAL PRIMARY KEY, -- ID interno de cajero
   ID_SUCURSAL          INT,
   DIRECCION_CAJERO     VARCHAR(255),
   ESTADOOPERATIVO_CAJERO VARCHAR(50),
   FECHAMANTENIMIENTO_CAJERO DATE,
   TOTALDINERO_CAJERO   DECIMAL
);

-- ==============================================================
-- Tabla: PERSONA
-- ==============================================================
CREATE TABLE PERSONA (
   ID_PERSONA           SERIAL PRIMARY KEY,
   DIRECCION_PERSONA    VARCHAR(128),
   TELEFONO_PERSONA     VARCHAR(32),
   EMAIL_PERSONA        VARCHAR(64),
   TIPO_PERSONA         VARCHAR(32), -- NATURAL o JURIDICA
   NOMBRE_PERSONA       VARCHAR(125)
);

-- ==============================================================
-- NOTA IMPORTANTE:
-- PERSONANORMAL y PERSONAJURIDICA heredan su clave primaria desde la tabla PERSONA.
-- El backend debe:
-- 1. Insertar un registro en PERSONA para obtener el ID_PERSONA.
-- 2. Luego insertar en PERSONANORMAL o PERSONAJURIDICA utilizando ese mismo ID.
-- Esto permite extender la entidad persona según su tipo sin perder integridad.
-- ==============================================================

-- ==============================================================
-- Tabla: PERSONANORMAL
-- ==============================================================
CREATE TABLE PERSONANORMAL (
   ID_PERSONA           INT PRIMARY KEY,
   N_APELLIDO           VARCHAR(128),
   N_OCUPACION          VARCHAR(128),
   N_CEDULA             VARCHAR(15),
   N_FECHANACIMIENTO    DATE
);

-- ==============================================================
-- Tabla: PERSONAJURIDICA
-- ==============================================================
CREATE TABLE PERSONAJURIDICA (
   ID_PERSONA           INT PRIMARY KEY,
   PJ_RUC               CHAR(13),
   PJ_RAZONSOCIAL       VARCHAR(255),
   PJ_TIPOEMPRESA       VARCHAR(100)
);

-- ==============================================================
-- Tabla: CUENTA
-- ==============================================================
CREATE TABLE CUENTA (
   ID_CUENTA            SERIAL PRIMARY KEY,
   ID_PERSONA           INT NOT NULL,
   NUMERO_CUENTA        VARCHAR(20) NOT NULL UNIQUE,
   FECHA_APERTURA_CUENTA DATE,
   ESTADO_CUENTA        VARCHAR(50),
   SALDO_CUENTA         DECIMAL,
   TIPO_CUENTA          VARCHAR(30),
   PERMITERETIROS_CUENTA BOOLEAN,
   PERMITEPAGOS_CUENTA  BOOLEAN,
   SEGUROCONTRAFRAUDE   BOOLEAN
);

-- ==============================================================
-- NOTA IMPORTANTE:
-- CUENTAAHORRO y CUENTACORRIENTE heredan su clave primaria desde la tabla CUENTA.
-- Por lo tanto, NO deben tener SERIAL ni se autogeneran.
-- El backend debe primero insertar una CUENTA general, y luego según el tipo,
-- insertar en CUENTAAHORRO o CUENTACORRIENTE reutilizando el mismo ID_CUENTA.
-- Esto evita duplicidad y mantiene la integridad relacional.
-- ==============================================================

-- ==============================================================
-- Tabla: CUENTAAHORRO
-- ==============================================================
CREATE TABLE CUENTAAHORRO (
   ID_CUENTA            INT PRIMARY KEY, -- Hereda desde CUENTA
   CA_TASZAINTERESANUAL NUMERIC(5,2),
   CA_FECHAULTIMOINTERES DATE,
   CA_INTERESACUMULADOANUAL DECIMAL,
   CA_CUBIERTAPORSEGURO BOOLEAN
);

-- ==============================================================
-- Tabla: CUENTACORRIENTE
-- ==============================================================
CREATE TABLE CUENTACORRIENTE (
   ID_CUENTA            INT PRIMARY KEY, -- Hereda desde CUENTA
   CC_LIMITESOBREGIRO   DECIMAL,
   CC_MONTOSOBREGIRO    DECIMAL,
   CC_FECHA             DATE,
   CC_ESTADOSOBREGIRO   VARCHAR(30),
   CC_INTERESSOBREGIRO  DECIMAL
);

-- ==============================================================
-- NOTA IMPORTANTE:
-- MOVIMIENTOTARJETA, MOVIMIENTOSINTARJETA, DEPOSITO, TRANSFERENCIA,
-- RETIROCONTARJETA y RETIROSINTARJETA heredan su ID_MOVIMIENTO desde MOVIMIENTOS.
-- Por lo tanto, NO deben generar su propio UUID. El backend debe:
-- 1. Crear un registro en MOVIMIENTOS (obteniendo su UUID).
-- 2. Insertar el mismo UUID en la tabla especializada correspondiente.
-- Este patrón permite extender movimientos con detalles específicos sin duplicar claves.
-- ==============================================================

-- ==============================================================
-- Tabla: TARJETAS
-- ==============================================================
CREATE TABLE TARJETAS (
   ID_TARJETA           SERIAL PRIMARY KEY,
   ID_CUENTA            INT,
   NUMERO_TARJETA       CHAR(16) NOT NULL UNIQUE,
   TIPO_TARJETA         VARCHAR(50),
   ESTADO_TARJETA       VARCHAR(50),
   FECHAEMICION_TARJETA DATE,
   CVV_TARJETA          CHAR(3),
   SALDO_TARJETA        DECIMAL,
   FECHAEXPIRA_TARJETA  DATE
);

-- ==============================================================
-- Tabla: MOVIMIENTOS
-- ==============================================================
CREATE TABLE MOVIMIENTOS (
   ID_MOVIMIENTO        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
   ID_CUENTA            INT,
   M_MONTO              DECIMAL,
   M_FECHA              DATE,
   M_CONTAJGETA         BOOLEAN,
   M_DESCRIPCION        VARCHAR(255),
   M_ESTADO             VARCHAR(50),
   M_UBICACION          VARCHAR(255)
);

-- ==============================================================
-- Tabla: MOVIMIENTOTARJETA
-- ==============================================================
CREATE TABLE MOVIMIENTOTARJETA (
   ID_MOVIMIENTO        UUID PRIMARY KEY, -- Hereda desde MOVIMIENTOS
   ID_TARJETA           INT,
   MT_PINSEGURIDAD      CHAR(4),
   MT_INTENTOSFALLIDO   INT,
   MT_MONTOMAXIMO       DECIMAL
);

-- ==============================================================
-- Tabla: MOVIMIENTOSINTARJETA
-- ==============================================================
CREATE TABLE MOVIMIENTOSINTARJETA (
   ID_MOVIMIENTO        UUID PRIMARY KEY, -- Hereda desde MOVIMIENTOS
   MST_MONTOMAXIMO      DECIMAL,
   MST_TIPO             VARCHAR(50),
   MST_NUMEROCELULAR    VARCHAR(20)
);

-- ==============================================================
-- Tabla: DEPOSITO
-- ==============================================================
CREATE TABLE DEPOSITO (
   ID_MOVIMIENTO        UUID PRIMARY KEY, -- Hereda desde MOVIMIENTOSINTARJETA
   D_CUENTAORIGEN       VARCHAR(20),
   D_CUENTADESTINO      VARCHAR(20)
);

-- ==============================================================
-- Tabla: TRANSFERENCIA
-- ==============================================================
CREATE TABLE TRANSFERENCIA (
   ID_MOVIMIENTO        UUID PRIMARY KEY, -- Hereda desde MOVIMIENTOSINTARJETA
   T_CUENTADESTINO      VARCHAR(20),
   T_CUENTAORIGEN       VARCHAR(20),
   T_BANCODESTINO       VARCHAR(50)
);

-- ==============================================================
-- Tabla: RETIROSINTARJETA
-- ==============================================================
CREATE TABLE RETIROSINTARJETA (
   ID_MOVIMIENTO        UUID PRIMARY KEY, -- Hereda desde MOVIMIENTOSINTARJETA
   RST_CODIGOGENERADO   VARCHAR(10),
   RST_NUMMAXRETIROS    INT,
   RST_FECHAHORA        TIMESTAMP
);


-- ==============================================================
-- Tabla: RETIROCONTARJETA
-- ==============================================================
CREATE TABLE RETIROCONTARJETA (
   ID_MOVIMIENTO        UUID PRIMARY KEY, -- Hereda desde MOVIMIENTOTARJETA
   RCT_NUMMAXRETIROS    INT,
   RCT_CANAL            VARCHAR(30)
);

-- ==============================================================
-- Tabla: VAUCHER
-- ==============================================================
CREATE TABLE VAUCHER (
   ID_VAUCHER           SERIAL PRIMARY KEY,
   ID_CAJERO            INT,
   ID_MOVIMIENTO        UUID,
   COSTO_VAUCHER        DECIMAL
);

CREATE TABLE USUARIOS (
   ID_USUARIO SERIAL PRIMARY KEY NOT NULL,
   USERNAME_USUARIO VARCHAR(20) UNIQUE NOT NULL,
   PASSWORD_USUARIO TEXT NOT NULL
);

-- ==============================================================
-- Índices únicos adicionales y restricciones referenciales (FK)
-- ==============================================================
CREATE UNIQUE INDEX RETIROCONTARJETA_PK ON RETIROCONTARJETA(ID_MOVIMIENTO);
CREATE UNIQUE INDEX CUENTA_NUMERO_UNIQUE ON CUENTA(NUMERO_CUENTA);
CREATE UNIQUE INDEX TARJETAS_NUMERO_UNIQUE ON TARJETAS(NUMERO_TARJETA);

ALTER TABLE CAJEROS ADD CONSTRAINT FK_CAJEROS_TIENE_SUCURSAL FOREIGN KEY (ID_SUCURSAL) REFERENCES SUCURSAL(ID_SUCURSAL) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE CUENTA ADD CONSTRAINT FK_CUENTA_PERTENECE_PERSONA FOREIGN KEY (ID_PERSONA) REFERENCES PERSONA(ID_PERSONA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE CUENTAAHORRO ADD CONSTRAINT FK_CUENTAAH_HEREDA_CUENTA FOREIGN KEY (ID_CUENTA) REFERENCES CUENTA(ID_CUENTA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE CUENTACORRIENTE ADD CONSTRAINT FK_CUENTACO_HEREDA2_CUENTA FOREIGN KEY (ID_CUENTA) REFERENCES CUENTA(ID_CUENTA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE MOVIMIENTOS ADD CONSTRAINT FK_MOVIMIEN_HACE_CUENTA FOREIGN KEY (ID_CUENTA) REFERENCES CUENTA(ID_CUENTA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE MOVIMIENTOSINTARJETA ADD CONSTRAINT FK_MOVIMIEN_HACERCON2_MOVIMIEN FOREIGN KEY (ID_MOVIMIENTO) REFERENCES MOVIMIENTOS(ID_MOVIMIENTO) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE MOVIMIENTOTARJETA ADD CONSTRAINT FK_MOVIMIEN_HACERCON_MOVIMIEN FOREIGN KEY (ID_MOVIMIENTO) REFERENCES MOVIMIENTOS(ID_MOVIMIENTO) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE MOVIMIENTOTARJETA ADD CONSTRAINT FK_MOVIMIEN_UTILIZA_TARJETAS FOREIGN KEY (ID_TARJETA) REFERENCES TARJETAS(ID_TARJETA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE PERSONAJURIDICA ADD CONSTRAINT FK_PERSONAJ_ES_PERSONA FOREIGN KEY (ID_PERSONA) REFERENCES PERSONA(ID_PERSONA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE PERSONANORMAL ADD CONSTRAINT FK_PERSONAN_ES2_PERSONA FOREIGN KEY (ID_PERSONA) REFERENCES PERSONA(ID_PERSONA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE RETIROCONTARJETA ADD CONSTRAINT FK_RETIROCO_ES_UN_MOVIMIEN FOREIGN KEY (ID_MOVIMIENTO) REFERENCES MOVIMIENTOTARJETA(ID_MOVIMIENTO) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE RETIROSINTARJETA ADD CONSTRAINT FK_RETIROSI_MEDIO2_MOVIMIEN FOREIGN KEY (ID_MOVIMIENTO) REFERENCES MOVIMIENTOSINTARJETA(ID_MOVIMIENTO) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE TARJETAS ADD CONSTRAINT FK_TARJETAS_ADQUIERE_CUENTA FOREIGN KEY (ID_CUENTA) REFERENCES CUENTA(ID_CUENTA) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE DEPOSITO ADD CONSTRAINT FK_DEPOSITO_MEDIO_MOVIMIEN FOREIGN KEY (ID_MOVIMIENTO) REFERENCES MOVIMIENTOSINTARJETA(ID_MOVIMIENTO) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE TRANSFERENCIA ADD CONSTRAINT FK_TRANSFER_MEDIO3_MOVIMIEN FOREIGN KEY (ID_MOVIMIENTO) REFERENCES MOVIMIENTOSINTARJETA(ID_MOVIMIENTO) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE VAUCHER ADD CONSTRAINT FK_VAUCHER_EMITE_CAJEROS FOREIGN KEY (ID_CAJERO) REFERENCES CAJEROS(ID_CAJERO) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE VAUCHER ADD CONSTRAINT FK_VAUCHER_REGISTRA_MOVIMIEN FOREIGN KEY (ID_MOVIMIENTO) REFERENCES MOVIMIENTOS(ID_MOVIMIENTO) ON DELETE RESTRICT ON UPDATE RESTRICT;