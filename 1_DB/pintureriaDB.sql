-- Crear la base de datos solo si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'pintureriaDB')
BEGIN
    CREATE DATABASE pintureriaDB;
END
GO

-- Usar la base de datos
USE pintureriaDB;
GO


-- Tabla Productos (requerida para DetalleVentas)
CREATE TABLE Productos (
    id_producto INT PRIMARY KEY IDENTITY(1,1),
    nombre VARCHAR(50) NOT NULL,
    precio DECIMAL(10,2) CHECK (precio > 0),   -- Precio positivo
    stock INT CHECK (stock >= 0)               -- Stock no negativo
);

-- Tabla Clientes 
CREATE TABLE Clientes (
    DUI VARCHAR(10) PRIMARY KEY CHECK (DUI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    nombre VARCHAR(50) NOT NULL,
    telefono VARCHAR(8) CHECK (telefono LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    email VARCHAR(50) UNIQUE CHECK (email LIKE '%_@__%.__%')  -- Formato de email válido
);

-- Tabla Empleados (mayores de 18 años)
CREATE TABLE Empleados (
    id_empleado INT PRIMARY KEY IDENTITY(1,1),
    DUI VARCHAR(10) UNIQUE CHECK (DUI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    nombre VARCHAR(50) NOT NULL,
    fecha_nacimiento DATE CHECK (DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) >= 18),
    puesto VARCHAR(20) NOT NULL
);

-- Tabla Direcciones
CREATE TABLE Direcciones (
    id_direccion INT PRIMARY KEY IDENTITY(1,1),
    DUI_cliente VARCHAR(10) FOREIGN KEY REFERENCES Clientes(DUI),
    direccion VARCHAR(100) NOT NULL,
    ciudad VARCHAR(20) NOT NULL,
    tipo_direccion VARCHAR(10) CHECK (tipo_direccion IN ('Casa', 'Trabajo', 'Otro'))
);

-- Tabla Ventas
CREATE TABLE Ventas (
    id_venta INT PRIMARY KEY IDENTITY(1,1),
    DUI_cliente VARCHAR(10) FOREIGN KEY REFERENCES Clientes(DUI),
    id_empleado INT FOREIGN KEY REFERENCES Empleados(id_empleado),
    fecha_venta DATE DEFAULT GETDATE(),
    total DECIMAL(10,2) CHECK (total >= 0)
);

-- Tabla DetalleVentas
CREATE TABLE DetalleVentas (
    id_detalle INT PRIMARY KEY IDENTITY(1,1),
    id_venta INT FOREIGN KEY REFERENCES Ventas(id_venta),
    id_producto INT FOREIGN KEY REFERENCES Productos(id_producto),
    cantidad INT CHECK (cantidad > 0),
    subtotal DECIMAL(10,2) CHECK (subtotal >= 0)
);

-- Tabla Envios
CREATE TABLE Envios (
    id_envio INT PRIMARY KEY IDENTITY(1,1),
    id_venta INT FOREIGN KEY REFERENCES Ventas(id_venta),
    id_direccion INT FOREIGN KEY REFERENCES Direcciones(id_direccion),
    estado VARCHAR(15) CHECK (estado IN ('Pendiente', 'En camino', 'Entregado')),
    fecha_envio DATE
);

-- Tabla Bitacora
CREATE TABLE Bitacora (
    id_reg INT PRIMARY KEY IDENTITY(1,1),
    usuario_sistema VARCHAR(50) DEFAULT CURRENT_USER,
    fecha_hora_sistema DATETIME DEFAULT GETDATE(),
    nombre_tabla VARCHAR(50),
    transaccion VARCHAR(10) CHECK (transaccion IN ('Insert', 'Update', 'Delete'))
);
