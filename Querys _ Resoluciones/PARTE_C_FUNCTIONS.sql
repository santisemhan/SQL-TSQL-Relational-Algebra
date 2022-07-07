/*
	Definir una función que devuelva la edad de un paciente. 
	input: fecha de nacimiento. 
	output: edad expresada en años cumplidos. 
*/
CREATE OR ALTER FUNCTION edad_paciente (
	@fecha_nacimiento DATE
)
RETURNS INT 
AS
BEGIN
	DECLARE @Edad AS INT = DATEDIFF(YY, @fecha_nacimiento, GETDATE())
	IF MONTH(@fecha_nacimiento) < MONTH(GETDATE()) OR (MONTH(@fecha_nacimiento) = MONTH(GETDATE()) AND DAY(@fecha_nacimiento) < DAY(GETDATE()))
	BEGIN
		RETURN @Edad
	END
	RETURN @Edad - 1
END
GO

/*
	Definir las siguientes funciones para obtener, partiendo del nombre del estudio pasado como parámetro: 
	input: nombre del estudio. 
	output:	mayor precio del estudio. 
	menor precio del estudio. 
	precio promedio del estudio. 
*/

CREATE OR ALTER FUNCTION mayor_menor_promedio_precio_estudio(
	@Nombre_Estudio VARCHAR(50)
)
RETURNS TABLE 
AS
	RETURN SELECT MAX(P.precio) AS mayor_precio, MIN(P.precio) AS min_precio, AVG(P.precio) AS promedio_precio
		FROM estudios E
			INNER JOIN precios P ON P.idInstituto = E.idEstudio
		WHERE E.estudio = @Nombre_Estudio
GO

/*
	Definir las siguientes funciones que devuelva una lista ordenada alfabéticamente de: 
	• Obras sociales. 
	• Especialidades 
	• Institutos. 
	• Estudios. 
	OUTPUT: una Tabla conteniendo la información solicitada.
*/
CREATE OR ALTER FUNCTION obras_sociales_alf()
RETURNS TABLE 
AS
	RETURN SELECT * 
		FROM OOSS OS
		ORDER BY OS.nombre ASC 
		OFFSET 0 ROWS
GO

CREATE OR ALTER FUNCTION especialidades_alf()
RETURNS TABLE 
AS
	RETURN SELECT * 
		FROM especialidades ES
		ORDER BY ES.especialidad ASC 
		OFFSET 0 ROWS
GO

CREATE OR ALTER FUNCTION institutos_alf()
RETURNS TABLE 
AS
	RETURN SELECT * 
		FROM institutos I
		ORDER BY I.instituto ASC 
		OFFSET 0 ROWS
GO

CREATE OR ALTER FUNCTION estudios_alf()
RETURNS TABLE 
AS
	RETURN SELECT * 
		FROM estudios E
		ORDER BY E.estudio ASC 
		OFFSET 0 ROWS
GO

/*
	Definir una función que devuelva los n institutos más utilizados por especialidad. 
	input: nombre de la especialidad, cantidad máxima de institutos. 
	output: una Tabla de institutos (los n primeros). 
*/
CREATE OR ALTER FUNCTION institutos_especialidad(
	@Nombre_Especialidad VARCHAR(50),
	@Cantidad INT
)
RETURNS TABLE 
AS
	RETURN SELECT TOP (@Cantidad) 
			I.instituto, COUNT(1) AS cantidad
		FROM historias H
			INNER JOIN precios P ON P.idEstudio = H.idEstudio AND P.idInstituto = H.idInstituto
			INNER JOIN estudios E ON E.idEstudio = P.idEstudio
			INNER JOIN institutos I ON I.idInstituto = P.idInstituto
			INNER JOIN estuespe EE ON EE.idEstudio = E.idEstudio
			INNER JOIN especialidades ESP ON ESP.idEspecialidad = EE.idEspecialidad
		WHERE ESP.especialidad = @Nombre_Especialidad
		GROUP BY I.instituto
		ORDER BY cantidad DESC
GO

/*
	Definir una función que devuelva los estudios que no se realizaron en los últimos n días. 
	input: cantidad de días. 
	output: una Tabla de estudios.
*/
CREATE OR ALTER FUNCTION estudios_no_realizados(
	@Cantidad_Dias INT
)
RETURNS TABLE 
AS
	RETURN SELECT E.estudio
		FROM estudios E 
			LEFT JOIN historias H ON H.idEstudio = E.idEstudio AND H.fecha BETWEEN DATEADD(DAY, -@Cantidad_Dias, GETDATE()) AND GETDATE()
		WHERE H.idEstudio IS NULL
		GROUP BY E.estudio
GO

/*
	Definir una función que devuelva los estudios y la cantidad de veces que se repitieron para un mismo paciente 
	a partir de una cantidad mínima que se especifique y dentro de un determinado período de tiempo. 
	input: cantidad mínima, fecha desde, fecha hasta. 
	output: una Tabla que proyecte el paciente, el estudio y la cantidad.
*/
CREATE OR ALTER FUNCTION estudios_no_realizados(
	@Cantidad_Minima INT,
	@Fecha_Desde DATE,
	@Fecha_Hasta DATE
)
RETURNS TABLE 
AS
	RETURN SELECT P.nombre + ' ' + P.apellido AS nombre_completo, E.estudio, COUNT(1) AS cantidad_repetido  
		FROM historias H 
			INNER JOIN pacientes P ON P.dni = H.dni
			INNER JOIN estudios E ON E.idEstudio = H.idEstudio
		WHERE H.fecha BETWEEN @Fecha_Desde AND @Fecha_Hasta
		GROUP BY P.nombre, P.apellido, E.estudio
		HAVING COUNT(1) > @Cantidad_Minima
GO

/* 
	Definir una función que devuelva los médicos que ordenaron repetir un mismo estudio a un mismo paciente en los últimos n días. 
	input: cantidad de días. 
	output:  Tabla que proyecte el estudio repetido, nombre y fechas de realización, identificación del paciente y del médico. 
*/
CREATE OR ALTER FUNCTION medicos_repetir_mismo_estudio(
	@Cantidad_Dias INT
)
RETURNS TABLE 
AS
	RETURN SELECT E.estudio, P.nombre + ' ' + P.apellido AS nombre_completo, H.fecha AS fecha_realizacion, P.dni, H.matricula
		FROM historias H 
			INNER JOIN pacientes P ON P.dni = H.dni
			INNER JOIN estudios E ON E.idEstudio = H.idEstudio
		GROUP BY P.nombre, P.apellido, E.estudio, H.fecha, P.dni, H.matricula
		HAVING COUNT(1) > 1
GO

/*
	Definir una función que devuelva una cadena de caracteres en letras minúsculas con la letra inicial de cada palabra en mayúscula. 
	input: string inicial. 
	output:  string convertido.
*/
CREATE OR ALTER FUNCTION string_letra_ini_may(
	@String_Incial VARCHAR(MAX)
)
RETURNS VARCHAR(MAX) 
AS
BEGIN
	DECLARE @Reset BIT = 1;
	DECLARE @String_Convertido varchar(MAX) = '';
	DECLARE @index INT = 1;
	DECLARE @c CHAR(1);

	while (@index <= len(@String_Incial))
	SELECT @c = substring(@String_Incial, @index, 1),
		@String_Convertido = @String_Convertido + CASE WHEN @Reset = 1 THEN UPPER(@c) ELSE LOWER(@c) END,
		@Reset = CASE WHEN @c like '[a-zA-Z]' THEN 0 ELSE 1 END,
		@index = @index + 1
	return @String_Convertido
END
GO

/*
	Definir una función que devuelva las obras sociales que cubren un determinado estudio en todos los 
	planes que tiene y que se realizan en algún instituto registrado en la base. 
	input: nombre del estudio. 
	output: una Tabla que proyecta la obra social y la categoría. 
*/
CREATE OR ALTER FUNCTION ooss_estudio_planes(
	@Nombre_Estudio VARCHAR(50)
)
RETURNS TABLE 
AS
	RETURN SELECT P.sigla AS obra_social, P.nombre as nombre_plan, E.estudio, I.instituto  
		FROM estudios E
			INNER JOIN coberturas C ON C.idEstudio = E.idEstudio
			INNER JOIN planes P ON P.nroplan = C.nroplan AND P.sigla = C.sigla
			INNER JOIN precios PR ON PR.idEstudio = E.idEstudio
			INNER JOIN institutos I ON I.idInstituto = PR.idInstituto
		WHERE E.estudio = @Nombre_Estudio 
			AND cobertura > 0
GO