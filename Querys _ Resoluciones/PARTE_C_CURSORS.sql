/*
	Definir un Cursor que liste la ficha de los pacientes de los últimos seis meses conforme al siguiente formato de salida: 
	Datos del paciente. 
	Identificación del médico. 
	Detalle de los estudios realizados. 
*/
DECLARE pacientes_estudio_cursor CURSOR 
FOR	
SELECT P.nombre + ' ' + P.apellido AS nombre_completo,  P.dni, P.sexo, P.nacimiento,
	M.matricula, E.estudio
FROM historias H
	INNER JOIN pacientes P ON P.dni = H.dni
	INNER JOIN medicos M ON M.matricula = H.matricula
	INNER JOIN estudios E ON E.idEstudio = H.idEstudio
WHERE H.fecha >= DATEADD(MONTH, -6, GETDATE()) 

DECLARE @Nombre_Completo VARCHAR(250);
DECLARE @Dni INT;
DECLARE @Sexo VARCHAR(1);
DECLARE @Fecha_Nacimiento DATE;
DECLARE @Matricula INT;
DECLARE @Nombre_Estudio VARCHAR(250)

DECLARE @Break CHAR = CHAR(13)

OPEN pacientes_estudio_cursor;
FETCH NEXT FROM pacientes_estudio_cursor INTO @Nombre_Completo, @Dni, @Sexo, @Fecha_Nacimiento, @Matricula, @Nombre_Estudio;
WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT CONCAT('-----PACIENTE-----', @Break, 
		'Nombre: ', @Nombre_Completo, @Break, 
		'DNI: ', @Dni, @Break,
		'Sexo: ', @Sexo, @Break,
		'Fecha de nacimiento: ', @Fecha_Nacimiento, @Break, 
		'-----MEDICO-----', @Break, 
		'Matricula: ', @Matricula, @Break, 
		'-----ESTUDIO-----', @Break, 
		'Nombre: ', @Nombre_Estudio, @Break, 
		'===============================')
	FETCH NEXT FROM pacientes_estudio_cursor INTO @Nombre_Completo, @Dni, @Sexo, @Fecha_Nacimiento, @Matricula, @Nombre_Estudio;
END
CLOSE pacientes_estudio_cursor;
DEALLOCATE pacientes_estudio_cursor;
GO

/*
	Definir un Cursor que liste el detalle de los planes que cubren un determinado 
	estudio identificando el porcentaje cubierto y la obra social, según formato: 
	Estudio. 
	Obra social. 
	Plan y Cobertura (ordenado en forma decreciente). 
*/

DECLARE planes_estudios CURSOR 
FOR	
SELECT E.estudio, P.sigla, P.nroplan, C.cobertura
FROM estudios E
	INNER JOIN coberturas C ON C.idEstudio = E.idEstudio
	INNER JOIN planes P ON P.nroplan = C.nroplan AND P.sigla = C.sigla
ORDER BY E.estudio, P.sigla, P.nroplan, C.cobertura DESC

DECLARE @Nombre_Estudio VARCHAR(250);
DECLARE @Sigla VARCHAR(50);
DECLARE @NroPlan INT;
DECLARE @Cobertura INT;

DECLARE @Break CHAR = CHAR(13)

OPEN planes_estudios;
FETCH NEXT FROM planes_estudios INTO @Nombre_Estudio, @Sigla, @NroPlan, @Cobertura;
WHILE @@FETCH_STATUS = 0
BEGIN
PRINT CONCAT( 'Estudio: ', @Nombre_Estudio, @Break, 
		'Obra Social: ', @Sigla, @Break,
		'Nro. Plan: ', @NroPlan, @Break,
		'Porcentaje Cobertura: ', @Cobertura, @Break, 
		'===============================')
	FETCH NEXT FROM planes_estudios INTO @Nombre_Estudio, @Sigla, @NroPlan, @Cobertura;
END
CLOSE planes_estudios;
DEALLOCATE planes_estudios;
GO

/*
	Definir un Cursor que liste la cantidad estudios realizados mostrando parciales por paciente y por instituto, conforme al siguiente detalle: 
	Datos del paciente 
	Nombre del Instituto 		
	Cantidad de estudios.
	Total de estudios (realizados por el paciente) 
	Total de estudios realizados (todos los pacientes)
*/
DECLARE estudios_paciente CURSOR 
FOR	
WITH cantidad_estudios_institutos AS (SELECT I.idInstituto, COUNT(1) as cantidad_estudios 
									 FROM historias H
										INNER JOIN institutos I ON I.idInstituto = H.idInstituto
									 GROUP BY I.idInstituto)
SELECT P.nombre + ' ' + P.apellido AS nombre_completo,  P.dni, P.sexo, P.nacimiento, 
	I.instituto AS instituto, COUNT(1) AS cantidad_estudios_en_instituto, CEI.cantidad_estudios as cantidad_estudios_instituto
FROM historias H
	INNER JOIN pacientes P ON P.dni = H.dni
	INNER JOIN institutos I ON I.idInstituto = H.idInstituto
	INNER JOIN cantidad_estudios_institutos CEI ON CEI.idInstituto = I.idInstituto
GROUP BY P.nombre, P.apellido, P.dni, P.sexo, P.nacimiento, I.instituto, CEI.cantidad_estudios 

DECLARE @Nombre_Completo VARCHAR(250);
DECLARE @Dni INT;
DECLARE @Sexo VARCHAR(1);
DECLARE @Fecha_Nacimiento DATE;
DECLARE @Nombre_Instituto VARCHAR(50);
DECLARE @Cantidad_Estudios_En_Insituto INT;
DECLARE @Cantidad_Estudios_Instituto INT;

DECLARE @Break CHAR = CHAR(13)

OPEN estudios_paciente;
FETCH NEXT FROM estudios_paciente INTO @Nombre_Completo, @Dni, @Sexo, @Fecha_Nacimiento, @Nombre_Instituto, @Cantidad_Estudios_En_Insituto, @Cantidad_Estudios_Instituto
WHILE @@FETCH_STATUS = 0
BEGIN
PRINT CONCAT('-----PACIENTE-----', @Break, 
		'Nombre: ', @Nombre_Completo, @Break, 
		'DNI: ', @Dni, @Break,
		'Sexo: ', @Sexo, @Break,
		'Fecha de nacimiento: ', @Fecha_Nacimiento, @Break, 
		'-----INSTITUTO-----', @Break, 
		'Nombre: ', @Nombre_Instituto, @Break,
		'Cantidad de estudios del paciente en el instituto: ', @Cantidad_Estudios_En_Insituto, @Break,
		'Cantidad de estudios del instituto: ', @Cantidad_Estudios_Instituto, @Break,
		'===============================')
	FETCH NEXT FROM estudios_paciente INTO @Nombre_Completo, @Dni, @Sexo, @Fecha_Nacimiento, @Nombre_Instituto, @Cantidad_Estudios_En_Insituto, @Cantidad_Estudios_Instituto
END
CLOSE estudios_paciente;
DEALLOCATE estudios_paciente;
GO

/*
	Definir un Cursor que liste la cantidad estudios solicitados mostrando parciales por estudio y por médico, y detalle de los estudios solicitados conforme al siguiente formato: 
	Datos del médico 
	Nombre del estudio 
	Fecha 		Paciente 

	Cantidad del estudio 

	Cantidad de estudios del médico 
*/
DECLARE estudios_paciente CURSOR 
FOR	
WITH cantidad_estudios_institutos AS (SELECT I.idInstituto, COUNT(1) as cantidad_estudios 
									 FROM historias H
										INNER JOIN institutos I ON I.idInstituto = H.idInstituto
									 GROUP BY I.idInstituto)
SELECT P.nombre + ' ' + P.apellido AS nombre_completo,  P.dni, P.sexo, P.nacimiento, 
	I.instituto AS instituto, COUNT(1) AS cantidad_estudios_en_instituto, CEI.cantidad_estudios as cantidad_estudios_instituto
FROM historias H
	INNER JOIN pacientes P ON P.dni = H.dni
	INNER JOIN institutos I ON I.idInstituto = H.idInstituto
	INNER JOIN cantidad_estudios_institutos CEI ON CEI.idInstituto = I.idInstituto
GROUP BY P.nombre, P.apellido, P.dni, P.sexo, P.nacimiento, I.instituto, CEI.cantidad_estudios 

DECLARE @Nombre_Completo VARCHAR(250);
DECLARE @Dni INT;
DECLARE @Sexo VARCHAR(1);
DECLARE @Fecha_Nacimiento DATE;
DECLARE @Nombre_Instituto VARCHAR(50);
DECLARE @Cantidad_Estudios_En_Insituto INT;
DECLARE @Cantidad_Estudios_Instituto INT;

DECLARE @Break CHAR = CHAR(13)

OPEN estudios_paciente;
FETCH NEXT FROM estudios_paciente INTO @Nombre_Completo, @Dni, @Sexo, @Fecha_Nacimiento, @Nombre_Instituto, @Cantidad_Estudios_En_Insituto, @Cantidad_Estudios_Instituto
WHILE @@FETCH_STATUS = 0
BEGIN
PRINT CONCAT('-----PACIENTE-----', @Break, 
		'Nombre: ', @Nombre_Completo, @Break, 
		'DNI: ', @Dni, @Break,
		'Sexo: ', @Sexo, @Break,
		'Fecha de nacimiento: ', @Fecha_Nacimiento, @Break, 
		'-----INSTITUTO-----', @Break, 
		'Nombre: ', @Nombre_Instituto, @Break,
		'Cantidad de estudios del paciente en el instituto: ', @Cantidad_Estudios_En_Insituto, @Break,
		'Cantidad de estudios del instituto: ', @Cantidad_Estudios_Instituto, @Break,
		'===============================')
	FETCH NEXT FROM estudios_paciente INTO @Nombre_Completo, @Dni, @Sexo, @Fecha_Nacimiento, @Nombre_Instituto, @Cantidad_Estudios_En_Insituto, @Cantidad_Estudios_Instituto
END
CLOSE estudios_paciente;
DEALLOCATE estudios_paciente;
GO

/*
	Crear una Stored Procedure que defina un Cursor que liste el resumen mensual de los importes a cargo de una obra social. 
	Input: nombre de la obra social, mes y año a liquidar. 
	Obra social 
	Nombre del Instituto 
	Detalle del estudio 

	Subtotal del Instituto 

	Total de la obra social 
*/
CREATE OR ALTER PROCEDURE resumen_mensual_os
	@Nombre_OS NVARCHAR(50),
	@Año INT,
	@Mes INT
AS
DECLARE resumen_mensual_os_inst CURSOR 
FOR	
SELECT OS.nombre, 
	I.instituto as nombre_instituto, 
	SUM(CAST(IIF(C.cobertura IS NULL, 0, C.Cobertura * PR.precio / 100) AS decimal(7,2))) AS total_pagar_obra_social,
	CAST(SUM(PR.precio) AS DECIMAL(7,2)) AS total_instituto
FROM historias H
	INNER JOIN afiliados A ON A.dni = H.dni
	INNER JOIN planes P ON P.nroplan = A.nroplan AND P.sigla = A.sigla
	INNER JOIN OOSS OS ON OS.sigla = P.sigla
	INNER JOIN precios PR ON PR.idEstudio = H.idEstudio AND PR.idInstituto = H.idInstituto
	INNER JOIN coberturas C ON C.sigla = H.sigla AND C.nroplan = A.nroplan AND C.idEstudio = H.idEstudio
	INNER JOIN institutos I ON I.idInstituto = H.idInstituto
WHERE OS.nombre = @Nombre_OS 
	AND MONTH(H.fecha) = @Mes 
	AND YEAR(H.fecha) = @Año
GROUP BY OS.nombre, I.instituto

DECLARE @OS AS VARCHAR(50);
DECLARE @Insituto AS VARCHAR(50);
DECLARE @Total_Pagar_OS DECIMAL;
DECLARE @Total_Recibir_Insituto DECIMAL;

DECLARE @Break CHAR = CHAR(13)

OPEN resumen_mensual_os_inst;
FETCH NEXT FROM resumen_mensual_os_inst INTO @OS, @Insituto, @Total_Pagar_OS, @Total_Recibir_Insituto
WHILE @@FETCH_STATUS = 0
BEGIN
PRINT CONCAT('Obra Social: ', @OS, @Break, 
		'Instituto: ', @Insituto, @Break,
		'Total Pagar Obra Social: ', @Total_Pagar_OS, @Break,
		'Total a Recibir Instituto: ', @Total_Recibir_Insituto, @Break,
		'===============================')
	FETCH NEXT FROM resumen_mensual_os_inst INTO @OS, @Insituto, @Total_Pagar_OS, @Total_Recibir_Insituto
END
CLOSE resumen_mensual_os_inst;
DEALLOCATE resumen_mensual_os_inst;
GO

/*
	Crear una Stored Procedure que liste una tabla de referencias cruzadas que exprese la cantidad de estudios 
	realizados por los pacientes de una determinada obra social discriminando por plan. Los distintos planes serán las columnas y los estudios las filas.
	Input:obra social. 
	Obra Social: nombre de la obra social 
					Plan A   Plan B    Plan C 
	Estudio 1    	   n         n          - 
	Estudio 2           n          -          n 
*/
CREATE OR ALTER PROCEDURE cant_estudios_planes (
	@Nombre_OS AS VARCHAR(50)
)
AS
	DECLARE estudios CURSOR 
	FOR	 
	SELECT E.idEstudio, E.estudio
	FROM estudios E

	DECLARE planes CURSOR 
	FOR	 
	SELECT P.sigla, P.nroplan, P.nombre 
	FROM planes P 
		INNER JOIN OOSS OS ON OS.sigla = P.sigla
	WHERE OS.nombre = @Nombre_OS

	DECLARE @idEstudio INT;
	DECLARE @estudio VARCHAR(50);

	DECLARE @Sigla VARCHAR(50);
	DECLARE @NroPlan AS INT;
	DECLARE @Nombre_Plan AS VARCHAR(50)

	DECLARE @TableWasCreated BIT = 0;
	DECLARE @Break CHAR = CHAR(13)

	DECLARE @Planes VARCHAR(MAX) = '						';
	DECLARE @Estudio_Planes VARCHAR(MAX);

	OPEN estudios;
	FETCH NEXT FROM estudios INTO @idEstudio, @Estudio
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(@TableWasCreated = 0)
		BEGIN
			OPEN planes
			FETCH NEXT FROM planes INTO @Sigla, @NroPlan, @Nombre_Plan
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Planes = @Planes + '	' + @Nombre_Plan
				FETCH NEXT FROM planes INTO @Sigla, @NroPlan, @Nombre_Plan
			END
			PRINT @Planes
			SET @TableWasCreated = 1
		END
	CLOSE planes
	OPEN planes
	SET @Estudio_Planes = @Estudio + '						';
	FETCH NEXT FROM planes INTO @Sigla, @NroPlan, @Nombre_Plan
			WHILE @@FETCH_STATUS = 0
			BEGIN	
				SET @Estudio_Planes = @Estudio_Planes + '	' + CAST((SELECT COUNT(1) 
																 FROM historias H 
																	INNER JOIN afiliados A ON H.dni = A.dni
																	INNER JOIN planes P ON P.sigla = A.sigla AND P.nroplan = A.nroplan
																 WHERE H.idEstudio = @idEstudio
																	AND P.nroplan = @NroPlan AND P.sigla = @Sigla) AS VARCHAR(20))
				FETCH NEXT FROM planes INTO @Sigla, @NroPlan, @Nombre_Plan
			END
			PRINT @Estudio_Planes
	FETCH NEXT FROM estudios INTO @idEstudio, @Estudio	
	END
	CLOSE estudios;
	DEALLOCATE estudios;
	CLOSE planes;
	DEALLOCATE planes;
GO

/*
	Crear un procedimiento que defina un Cursor que devuelva una tabla de referencias cruzadas que exprese la cantidad de estudios realizados por institutos en un determinado período. 
	Input:fecha desde, fecha hasta. 

	Período: del nn/nn/nn al nn/nn/nn 
	Estudio I Estudio II Estudio III 
	Inst. A n n - 
	Inst. B n - n 
*/

CREATE OR ALTER PROCEDURE cant_estudios_instituto (
	@Fecha_Desde DATE,
	@Fecha_Hasta Date
)
AS
	DECLARE estudios CURSOR 
	FOR	 
	SELECT E.idEstudio, E.estudio
	FROM estudios E

	DECLARE institutos CURSOR 
	FOR	 
	SELECT I.idInstituto, I.instituto
	FROM institutos I 

	DECLARE @idEstudio INT;
	DECLARE @estudio VARCHAR(50);

	DECLARE @IdInstituto INT;
	DECLARE @Instituto AS VARCHAR(50);

	DECLARE @TableWasCreated BIT = 0;
	DECLARE @Break CHAR = CHAR(13)

	DECLARE @Estudios VARCHAR(MAX) = '						';
	DECLARE @Instituto_Estudios VARCHAR(MAX);

	OPEN institutos;
	FETCH NEXT FROM institutos INTO @IdInstituto, @Instituto
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF(@TableWasCreated = 0)
		BEGIN
			OPEN estudios
			FETCH NEXT FROM estudios INTO @idEstudio, @estudio
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Estudios = @Estudios + '	' + @estudio
				FETCH NEXT FROM estudios INTO @idEstudio, @estudio
			END
			PRINT @Estudios
			SET @TableWasCreated = 1
		END
	CLOSE estudios
	OPEN estudios
	SET @Instituto_Estudios = @Instituto + '						';
	FETCH NEXT FROM estudios INTO @idEstudio, @estudio
			WHILE @@FETCH_STATUS = 0
			BEGIN	
				SET @Instituto_Estudios = @Instituto_Estudios + '	' + CAST((SELECT COUNT(1) 
																			 FROM historias H 
																			 WHERE H.idEstudio = @idEstudio
																				AND H.idInstituto = @IdInstituto
																				AND H.fecha BETWEEN @Fecha_Desde AND @Fecha_Hasta) AS VARCHAR);
				FETCH NEXT FROM estudios INTO @idEstudio, @estudio
			END
			PRINT @Instituto_Estudios
	FETCH NEXT FROM institutos INTO @IdInstituto, @Instituto
	END
	CLOSE institutos;
	DEALLOCATE institutos;
	CLOSE estudios;
	DEALLOCATE estudios;
GO

/*
	Definir un Cursor que actualice el campo observaciones del último registro de cada paciente de la tabla historias con las siguientes indicaciones: 

	Repetir estudio: si el mismo se realizó en el segundo instituto registrado en la tabla (orden alfabético). 
	Diagnóstico no confirmado: si el mismo se realizó en cualquier otro instituto y fue solicitado por el tercer médico de la tabla (orden alfabético). 
*/

DECLARE repetir_estudio CURSOR 
FOR	
SELECT P.dni, H.idEstudio, H.fecha 
FROM pacientes P
	INNER JOIN historias H ON H.dni = P.dni
WHERE H.idInstituto = (
	SELECT I.idInstituto
	FROM institutos I 
	ORDER BY I.instituto ASC
	OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
)
GROUP BY P.dni, H.idEstudio, H.fecha 

DECLARE diagnostico_no_confirmado CURSOR
FOR
SELECT P.dni, H.idEstudio, H.fecha 
FROM pacientes P
	INNER JOIN historias H ON H.dni = P.dni
WHERE H.idInstituto <> (
	SELECT I.idInstituto
	FROM institutos I 
	ORDER BY I.instituto ASC
	OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY
) AND H.matricula = (
	SELECT M.matricula 
	FROM medicos M
	ORDER BY M.apellido, M.nombre
	OFFSET 2 ROWS FETCH NEXT 1 ROWS ONLY
)
GROUP BY P.dni, H.idEstudio, H.fecha 

DECLARE @Dni INT;
DECLARE @IdEstudio INT;
DECLARE @Fecha DATE;

OPEN repetir_estudio;
FETCH NEXT FROM repetir_estudio INTO @Dni, @IdEstudio, @Fecha;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE historias 
	SET observaciones = 'Repetir Estudio' 
	WHERE dni = @Dni 
		AND idEstudio = @IdEstudio
		AND fecha = @Fecha
	FETCH NEXT FROM repetir_estudio INTO @Dni, @IdEstudio, @Fecha;
END
CLOSE repetir_estudio;
DEALLOCATE repetir_estudio;

OPEN diagnostico_no_confirmado;
FETCH NEXT FROM diagnostico_no_confirmado INTO @Dni, @IdEstudio, @Fecha;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE historias 
	SET observaciones = 'Diagnostico no confirmado' 
	WHERE dni = @Dni 
		AND idEstudio = @IdEstudio
		AND fecha = @Fecha
	FETCH NEXT FROM diagnostico_no_confirmado INTO @Dni, @IdEstudio, @Fecha;
END
CLOSE diagnostico_no_confirmado;
DEALLOCATE diagnostico_no_confirmado;
GO

/*
	Definir un Cursor que actualice el campo precio de la tabla precios incrementando en un 2% los
	mismos para cada distinta especialidad de las restantes. 

	Ej.: 1º especialidad un 2%, 2º especialidad un 4%, ... 
*/

DECLARE especialidad CURSOR 
FOR	
SELECT E.idEspecialidad
FROM especialidades E

DECLARE @idEspecialidad AS INT;
DECLARE @Porcentaje_Aumentar AS INT = 2;

OPEN especialidad;
FETCH NEXT FROM repetir_estudio INTO @idEspecialidad;
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE precios 
		SET precio = precio + (precio * (@Porcentaje_Aumentar / 100))
	WHERE idEstudio IN (SELECT EE.idEstudio 
						FROM estuespe EE
							INNER JOIN estudios E ON EE.idEstudio = E.idEstudio
						WHERE EE.idEspecialidad = @idEspecialidad)
	SET @Porcentaje_Aumentar = @Porcentaje_Aumentar + 2
END
CLOSE especialidad;
DEALLOCATE especialidad;
GO