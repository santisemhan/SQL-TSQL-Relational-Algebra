--Crear un procedimiento para ingresar el precio de un estudio. 
--input: nombre del estudio, nombre del instituto y precio. 
--Si ya existe el registro en Precios debe actualizarlo. 
--Si no existe debe crearlo. 
--Si no existen el estudio o el instituto debe crearlos. 

CREATE OR ALTER PROCEDURE Precio_Estudio 
	@Nombre_Estudio NVARCHAR(MAX),
	@Nombre_Instituto NVARCHAR(MAX),
	@Precio DECIMAL
AS
BEGIN TRY  
	IF NOT EXISTS(SELECT * FROM estudios E 
				  WHERE E.estudio = @Nombre_Estudio)
	BEGIN
		INSERT INTO estudios VALUES (@Nombre_Estudio, 1)
	END

	IF NOT EXISTS(SELECT * FROM institutos I 
				  WHERE I.instituto = @Nombre_Instituto)
	BEGIN
		INSERT INTO institutos VALUES (@Nombre_Instituto, 1)
	END

	IF EXISTS ( SELECT P.* 
				FROM Precios P
					INNER JOIN estudios E ON E.idEstudio = P.idEstudio
					INNER JOIN institutos I ON I.idInstituto = P.idInstituto
				WHERE E.estudio = @Nombre_Estudio AND I.instituto = @Nombre_Instituto)
	BEGIN
		UPDATE P 
		SET P.precio = @Precio
		FROM precios P
			INNER JOIN estudios E ON E.idEstudio = P.idEstudio
			INNER JOIN institutos I ON I.idInstituto = P.idInstituto 
		WHERE E.estudio = @Nombre_Estudio AND I.instituto = @Nombre_Instituto
	END
	ELSE 
	BEGIN
		DECLARE @idEstudio AS INT = (SELECT E.idEstudio 
									 FROM estudios E 
									 WHERE E.estudio = @Nombre_Estudio)
		DECLARE @idInstituto AS INT = (SELECT I.idInstituto 
									   FROM institutos I 
									   WHERE I.instituto = @Nombre_Instituto)
		INSERT INTO precios VALUES(@idEstudio, @idInstituto, @Precio)
	END	
END TRY  
BEGIN CATCH 
	PRINT 'ERROR CON LOS PRECIOS'
END CATCH  
GO

/*
	Crear un procedimiento para ingresar estudios programados. 
	input: nombre del estudio, dni del paciente, matrícula del médico, nombre del instituto, sigla de la ooss, 
	un entero que inserte la cantidad de estudios a realizarse, entero que indique el lapso en días en que los mismos deben realizarse. 
	Generar todos los registros necesarios en la tabla historias. 
*/
CREATE OR ALTER PROCEDURE Estudios_Programados 
	@Nombre_Estudio NVARCHAR(50),
	@Dni_Paciente INT,
	@Matricula DECIMAL,
	@Nombre_Instituto NVARCHAR(50),
	@SiglaOOSS NVARCHAR(50),
	@Cantidad_Estudios INT,
	@Lapso_Dias INT
AS
BEGIN TRY  
	DECLARE @idEstudio AS INT = (SELECT E.idEstudio 
									FROM estudios E 
									WHERE E.estudio = @Nombre_Estudio)
	DECLARE @idInstituto AS INT = (SELECT I.idInstituto 
									FROM institutos I 
									WHERE I.instituto = @Nombre_Instituto)
	INSERT INTO historias VALUES (
		@Dni_Paciente, @idEstudio, @idInstituto, DATEADD(DAY, @Lapso_Dias, GETDATE()), 
		@Matricula, @SiglaOOSS, 1, '', 0
	)
END TRY  
BEGIN CATCH  
	PRINT 'ERROR AL CREAR UNA HISTORIA'
END CATCH  
GO

/* 
	Crear un procedimiento para ingresar datos del afiliado. 
	input: dni del paciente, sigla de la ooss, nro del plan, nro de afiliado. 
	Si ya existe la tupla en Afiliados debe actualizar el nro de plan y el nro de afiliado. 
	Si no existe debe crearla.
*/
CREATE OR ALTER PROCEDURE Ingresar_Afiliado 
	@Dni_Paciente INT,
	@SiglaOOSS NVARCHAR(50),
	@NroPlan INT,
	@NroAfiliado INT
AS
BEGIN TRY  
	IF EXISTS (SELECT * FROM afiliados A
			   WHERE A.dni = @Dni_Paciente
				AND A.sigla = @SiglaOOSS)
	BEGIN
		UPDATE afiliados SET nroplan = @NroPlan, nroafiliado = @NroAfiliado
	END
	ELSE
	BEGIN
		INSERT INTO afiliados VALUES (@Dni_Paciente, @SiglaOOSS, @NroPlan, @NroAfiliado)
	END
END TRY  
BEGIN CATCH  
	PRINT 'ERROR AL MODIFICAR/CREAR AFILIADO'
END CATCH  
GO

/*
	Crear un procedimiento para que proyecte los estudios realizados en un determinado mes. 
	input: mes y año. 
	Proyectar los datos del afiliado y los de los estudios realizados. 
*/
CREATE OR ALTER PROCEDURE Estudios_Mes_Año 
	@Mes INT,
	@Año INT
AS
	SELECT E.estudio 
	FROM historias H
		INNER JOIN estudios E ON E.idEstudio = H.idEstudio
	WHERE MONTH(H.fecha) = @Mes AND YEAR(H.fecha) = @Año
	GROUP BY E.estudio
GO

/* 
	Crear un procedimiento que proyecte los pacientes según un rango de edad. 
	input: edad mínima y edad máxima. 
	Proyectar los datos del paciente. 
*/
CREATE OR ALTER PROCEDURE Pacientes_Rango_Edad
	@Edad_Minima INT,
	@Edad_Maxima INT
AS
	SELECT *
	FROM pacientes P
	WHERE (CONVERT(int,CONVERT(char(8),GETDATE(),112))-CONVERT(char(8),P.nacimiento,112))/10000 
		BETWEEN @Edad_Minima AND @Edad_Maxima	
GO

/*
	Crear un procedimiento que proyecte los datos de los médicos para una determinada especialidad. 
	input: nombre de la especialidad y sexo (default null). 
	Proyectar los datos de los médicos activos que cumplan con la condición. 
	Si no se especifica sexo, listar ambos. 
*/
CREATE OR ALTER PROCEDURE Medicos_Especialidad
	@Especialidad VARCHAR(50),
	@Sexo VARCHAR(1) = NULL
AS
	SELECT M.* 
	FROM medicos M
		INNER JOIN espemedi EM ON EM.matricula = M.matricula
		INNER JOIN especialidades E ON E.idEspecialidad = EM.idEspecialidad
	WHERE E.especialidad = @Especialidad 
		AND (@Sexo IS NULL OR M.sexo = @Sexo)
		AND M.activo = 1
GO

/*
	Crear un procedimiento que proyecte los estudios que están cubiertos por una determinada obra social. 
	input: nombre de la ooss, nombre del plan (default null ). 
	Proyectar los estudios y la cobertura que poseen (estudio y porcentaje cubierto. 
	Si no se ingresa plan, se deben listar todos los planes de la obra social.
*/
CREATE OR ALTER PROCEDURE Estudios_no_cubiertos
	@OOSS VARCHAR(50),
	@Nombre_Plan VARCHAR(50) = NULL
AS
	SELECT * 
	FROM estudios E
		INNER JOIN coberturas C1 ON C1.idEstudio = E.idEstudio AND C1.sigla = @OOSS
	WHERE NOT EXISTS (
		SELECT *
		FROM coberturas C
			INNER JOIN planes P ON P.sigla = @OOSS AND (@Nombre_Plan IS NULL OR P.nombre = @Nombre_Plan)
		WHERE C.idEstudio = E.idEstudio
			AND C.sigla = @OOSS
	)
GO

/*
	Crear un procedimiento que proyecte cantidad de estudios realizados agrupados por ooss, nombre del plan y matricula del médico. 
	input: nombre de la ooss, nombre del plan, matrícula del médico. 
	Proyectar la cantidad de estudios realizados. 
	Si no se indica alguno de los parámetros se deben discriminar todas las ocurrencias. 
*/
CREATE OR ALTER PROCEDURE cantidad_estudios_realizados
	@OOSS VARCHAR(50) = NULL,
	@Nombre_Plan VARCHAR(50) = NULL,
	@Matricula INT = NULL
AS
	SELECT H.sigla, P.nombre as nombre_plan, H.matricula, COUNT(1) as cantidad_estudios
	FROM historias H
		INNER JOIN afiliados A ON A.dni = H.dni AND A.sigla = H.sigla
		INNER JOIN planes P ON P.nroplan = A.nroplan AND P.sigla = A.sigla
	WHERE (@OOSS IS NULL OR H.sigla = @OOSS) 
		AND (@Nombre_Plan IS NULL OR P.nombre = @Nombre_Plan) 
		AND (@Matricula IS NULL OR H.matricula = @Matricula) 
	GROUP BY H.sigla, P.nombre, H.matricula
GO

/*
	Crear un procedimiento que proyecte dni, fecha de nacimiento, nombre y apellido de los pacientes que correspondan a los n (valor solicitado) 
	pacientes más viejos cuyo apellido cumpla con determinado patrón de caracteres. 
	input: cantidad (valor n), patrón caracteres (default null). 
	Proyectar los pacientes que cumplan con la condición. 
*/
CREATE OR ALTER PROCEDURE pacientes_viejos_apellido
	@Cantidad INT,
	@Patron VARCHAR(MAX) = NULL
AS
	SELECT TOP (@Cantidad)
		P.dni, P.nacimiento, P.nombre, P.apellido 
	FROM pacientes P 
	WHERE P.apellido LIKE '%' + @Patron + '%'
	ORDER BY P.nacimiento ASC
GO

/*
	Crear un procedimiento que devuelva el precio total a liquidar a un determinado instituto. 
	input: nombre del instituto, periodo a liquidar. 
	output: precio neto. 
	Devuelve el neto a liquidar al instituto para ese período en una variable. 
*/
CREATE OR ALTER PROCEDURE instituto_liquidacion
	@Nombre_Instituto VARCHAR(50),
	@PeriodoDesde DATE,
	@PeriodoHasta DATE
AS
	DECLARE @idInstituto AS INT = (SELECT I.idInstituto 
									FROM institutos I 
									WHERE I.instituto = @Nombre_Instituto)
	SELECT SUM(P.precio) as precio_neto 
	FROM historias H
		INNER JOIN institutos I ON I.idInstituto = H.idInstituto
		INNER JOIN precios P ON P.idEstudio = H.idEstudio AND P.idInstituto = I.idInstituto
	WHERE H.fecha BETWEEN @PeriodoDesde AND @PeriodoHasta
GO

/*
	Crear un procedimiento que devuelva el precio mínimo y el precio máximo que debe abonar a una obra social. 
	input: sigla de la obra social o prepaga 
	output: mínimo, máximo. 
	Devolver en dos variables separadas el monto mínimo y máximo a ser cobrados por la obra social o prepaga. 
*/
CREATE OR ALTER PROCEDURE precio_min_max_os
	@Sigla AS VARCHAR(50)
AS
	SELECT CAST(MIN(C.cobertura * P.precio / 100) AS decimal (7,2)) AS minimo_a_pagar, CAST(MAX(C.cobertura * P.precio / 100) AS decimal(7,2)) AS maximo_a_pagar 
	FROM historias H
		INNER JOIN precios P ON P.idEstudio = H.idEstudio AND P.idInstituto = H.idInstituto
		INNER JOIN coberturas C ON C.sigla = H.sigla AND C.idEstudio = H.idEstudio
	WHERE H.sigla = @Sigla
GO

/*
	Crear un procedimiento que devuelva la cantidad posible de juntas médicas que puedan crearse combinando los médicos existentes. 
	input: / output: entero. 
	Retornar la cantidad de combinaciones posibles de juntas entre médicos (2 a 6) que se pueden generar con los médicos activos de la Base de Datos. 
	Nota: Combinatoria (m médicos tomados de a n ) = m! / n! (m-n)! en una variable. 
*/
CREATE OR ALTER PROCEDURE cantidad_juntas_medicas
AS
	SELECT 'TODO' AS TODO
GO

/*
	Crear un procedimiento que devuelva la cantidad de pacientes y médicos que efectuaron estudios en un determinado período. 
	input: / output: dos enteros. 
	Ingresar período a consultar (mes y año) 
	Retornar cantidad de pacientes que se realizaron uno o más estudios y cantidad de médicos solicitantes de los mismos, en dos variables.
*/
CREATE OR ALTER PROCEDURE cantidad_pacientes_medicos
	@Mes INT,
	@Año INT
AS
	DECLARE @CantidadPacientes AS INT = (SELECT COUNT(1)
										 FROM pacientes P
										 WHERE EXISTS (
											SELECT * 
											FROM historias H
											WHERE YEAR(H.fecha) = @Año AND MONTH(H.fecha) = @Mes
												AND P.dni = H.dni
										 ))
	DECLARE @CantidadMedicos AS INT = (SELECT COUNT(1) 
										FROM medicos M
										WHERE EXISTS (
											SELECT * 
											FROM historias H
											WHERE YEAR(H.fecha) = @Año AND MONTH(H.fecha) = @Mes
												AND M.matricula = H.matricula
										 ))
	SELECT @CantidadPacientes AS Cantidad_Pacientes, @CantidadMedicos AS Cantidad_Medicos
GO