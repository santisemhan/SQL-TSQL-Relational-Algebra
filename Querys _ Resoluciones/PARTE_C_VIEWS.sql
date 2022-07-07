-- Crear  una vista vw_estudios que proyecte: nombre y el estado (activo = sí o no) de los estudios.
CREATE OR ALTER VIEW vw_estudios 
AS
	SELECT E.estudio, IIF(E.activo = 1, 'Si', 'No') AS estado 
	FROM estudios E;
GO

-- Crear  una vista vw_ooss que proyecte: nombre y categoría (obra social o prepaga) de las obras sociales.
CREATE OR ALTER VIEW vw_ooss
AS
	SELECT OS.nombre, OS.categoria 
	FROM OOSS AS OS;
GO
-- Crear una vista vw_pacientes que proyecte: dni, nombre, apellido, sexo y fecha de nacimiento de los pacientes, 
-- obra social a la que pertenece, plan y nº de afiliado y categoría de ésta. (utilizar join ) 	

-- NOTA PARA SANTIAGO: ¿Porque sale duplicado?
CREATE OR ALTER VIEW vw_pacientes
AS 
	SELECT P.dni, P.nombre, P.apellido, P.sexo, P.nacimiento, 
		OS.nombre as obra_social, PL.nombre AS nombre_plan, OS.categoria
	FROM historias AS H
		INNER JOIN pacientes P ON P.dni = H.dni
		INNER JOIN afiliados A ON A.dni = P.dni AND A.sigla = H.sigla
		INNER JOIN planes PL ON PL.sigla = A.sigla AND A.nroplan = PL.nroplan
		INNER JOIN OOSS OS ON OS.sigla = PL.sigla
GO

-- Crear una vista vw_pacientes_sin_cobertura que proyecte: dni, nombre, apellido, sexo y fecha de nacimiento de los pacientes	

-- NOTA PARA TOMAS: No salen pacientes que no tienen ninguna cobertura, agregar y verificar que funcione la query
CREATE OR ALTER VIEW vw_pacientes_sin_cobertura
AS 
	SELECT P.dni, P.nombre, P.apellido, P.sexo, P.nacimiento
	FROM pacientes P 
		INNER JOIN afiliados A ON A.dni = P.dni
		INNER JOIN planes PL ON PL.sigla = A.sigla AND A.nroplan = PL.nroplan
		LEFT JOIN coberturas C ON C.sigla = PL.sigla
	WHERE C.cobertura IS NULL
	GROUP BY P.dni, P.nombre, P.apellido, P.sexo, P.nacimiento
GO

-- Crear una vista vw_total_medicos_sin_especialidades que proyecte: la cantidad de los médicos que no 
-- tienen especificada la especialidad agrupados por sexo (proyectar: masculino - femenino).	

-- NOTA PARA TOMAS: Todos los medicos no tienen especialidad, agregarle a algunos la especialidad
CREATE OR ALTER VIEW vw_medicos_varias_especialidades 
AS
	SELECT IIF(M.sexo = 'M', 'Masculinos', 'Femeninos') AS sexo, COUNT(1) AS cantidad 
	FROM medicos M
		LEFT JOIN espemedi EM ON EM.matricula = M.matricula
	GROUP BY M.sexo
GO

-- Crear una vista vw_afiliados_con_una_cobertura que proyecte: 
-- datos de los afiliados (nombre y afiliación y plan) que posean 1 sola cobertura médica. 
CREATE OR ALTER VIEW vw_afiliados_con_una_cobertura
AS
	SELECT PA.nombre + ' ' + PA.apellido AS nombre_completo, PA.dni, A.nroplan, P.nombre
	FROM afiliados A 
		INNER JOIN planes P ON P.nroplan = A.nroplan AND A.sigla = P.sigla
		INNER JOIN coberturas C ON C.sigla = A.sigla AND C.nroplan = P.nroplan
		INNER JOIN pacientes PA ON PA.dni = A.dni 
	GROUP BY PA.dni, P.nombre, A.nroplan, PA.nombre, PA.apellido
	HAVING COUNT(1) = 1
GO

-- Crear una vista  vw_cantidad_estudios_por_instituto que proyecte: el nombre del instituto, 
-- el nombre del estudio y a la cantidad veces que se solicitó.

-- NOTA PARA TOMAS: Agregar que un estudio sea solicitado mas de 1 vez por instituto asi se puede ver que funciona bien
CREATE OR ALTER VIEW vw_cantidad_estudios_por_instituto
AS
	SELECT E.estudio, I.instituto, COUNT(1) AS cantidad_veces_solicitado
	FROM historias H
		INNER JOIN estudios E ON E.idEstudio = H.idEstudio
		INNER JOIN institutos I ON I.idInstituto = H.idInstituto
	GROUP BY E.estudio, I.instituto
GO

-- Crear una vista  vw_cantidad_estudios_por_medico que proyecte: los datos la matrícula y 
-- el nombre del médico junto a la cantidad de estudios
CREATE OR ALTER VIEW vw_cantidad_estudios_por_medico
AS
	SELECT M.matricula, M.nombre + ' ' + M.apellido AS nombre_completo, COUNT(1) AS cantidad_estudios 
	FROM historias H
		INNER JOIN medicos M ON M.matricula = H.matricula
	GROUP BY M.matricula, M.nombre, M.apellido
GO

-- Crear una vista  vw_historias_de_estudios que proyecte: los datos del paciente, el estudio realizado, 
-- el instituto, matricula y nombre del medico solicitante, fecha del estudio, obra social que factura el estudio, y observaciones.
CREATE OR ALTER VIEW vw_historias_de_estudios
AS
	SELECT P.nombre + ' ' + P.apellido AS nombre_completo, P.dni, P.nacimiento, P.sexo,
		I.instituto, M.matricula, M.nombre + ' ' + M.apellido AS nombre_completo_medico,
		H.fecha as fecha_estudio, OS.nombre AS obra_social, H.observaciones
	FROM historias H
		INNER JOIN pacientes P ON P.dni = H.dni
		INNER JOIN institutos I ON I.idInstituto = H.idInstituto
		INNER JOIN medicos M ON M.matricula = H.matricula
		INNER JOIN afiliados A ON A.dni = P.dni AND A.sigla = H.sigla
		INNER JOIN planes PL ON PL.sigla = A.sigla AND A.nroplan = PL.nroplan
		INNER JOIN OOSS OS ON OS.sigla = PL.sigla
GO

-- Crear una vista  vw_pagos_pacientes que proyecte: nombre y dni del paciente, el estudio realizado, la fecha y el monto a pagar.
CREATE OR ALTER VIEW vw_pagos_pacientes
AS
	SELECT P.nombre + ' ' + P.apellido AS nombre_completo, P.dni, E.estudio, H.fecha, PR.precio 
	FROM historias H
		INNER JOIN pacientes P ON P.dni = H.dni
		INNER JOIN estudios E ON E.idEstudio = H.idEstudio
		INNER JOIN precios PR ON PR.idInstituto = H.idInstituto AND PR.idEstudio = E.idEstudio
GO

-- Crear una vista vw_ooss_pacientes que proyecte: nombre de todas las obras con el nombre y estado de todos sus planes, 
-- detallando dni, nombre y apellido de los afiliados a los distintos planes.

-- NOTA PARA TOMAS: Poner algun plan en inactivo con pacientes
CREATE OR ALTER VIEW vw_ooss_pacientes
AS
	SELECT OS.nombre AS obra_social, P.nombre as plan_, IIF(P.activo = 1, 'Activo', 'Inactivo') AS estado,
		PA.dni, PA.nombre, PA.apellido
	FROM OOSS OS
		INNER JOIN planes P ON P.sigla = OS.sigla
		INNER JOIN afiliados A ON A.sigla = P.sigla AND A.nroplan = P.nroplan
		INNER JOIN pacientes PA ON PA.dni = A.dni
GO

-- Crear una vista  vw_estudios_sin_cobertura que proyecte: nombre del estudio que no es cubierto por ninguna obra social
CREATE OR ALTER VIEW vw_estudios_sin_cobertura
AS 
	SELECT E.estudio 
	FROM estudios E 
		LEFT JOIN coberturas C ON C.idEstudio = E.idEstudio
	WHERE C.cobertura IS NULL
GO

-- Crear una vista  vw_planes_sin_cobertura que proyecte: nombre de la obra social y el plan que no  cubran  ningún estudio.
CREATE OR ALTER VIEW vw_planes_sin_cobertura
AS 
	SELECT OS.nombre AS obra_social, P.nombre 
	FROM planes P
		LEFT JOIN coberturas C ON C.nroplan = P.nroplan AND P.sigla = C.sigla
		INNER JOIN OOSS OS ON OS.sigla = P.sigla 
	WHERE C.cobertura IS NULL
GO

-- Crear una vista  vw_tabla_de_precios que proyecte: nombre del estudio, obra social, plan, instituto, porcentaje cubierto, 
-- precio del estudio y neto a facturar a la obra social y al paciente.
CREATE OR ALTER VIEW vw_tabla_de_precios
AS
	WITH estudio_plan AS (
		SELECT E.idEstudio,E.estudio, OS.nombre AS obra_social, P.nroPlan ,P.nombre AS nombre_plan, P.sigla 
				FROM estudios E, planes P
					INNER JOIN OOSS OS ON OS.sigla = P.sigla
		),
		estudio_instituto AS (
			SELECT E.idEstudio, I.IdInstituto 
			FROM estudios E, institutos I
		),
		precios_estudio_instituto AS (
			SELECT IE.*, P.precio
			FROM estudio_instituto IE
				INNER JOIN precios P ON P.idEstudio = IE.idEstudio 
					AND P.idInstituto = IE.idInstituto
		)
		SELECT EP.estudio, EP.obra_social, EP.nroplan, EP.nombre_plan, I.instituto, 
			ISNULL(C.cobertura, 0) AS porcentaje_cubierto, 
			PEI.precio AS total,
			CAST(IIF(C.cobertura IS NULL, PEI.precio, ((100 - C.Cobertura) * PEI.precio) / 100) AS decimal(7,2)) AS total_pagar_paciente, 
			CAST(IIF(C.cobertura IS NULL, 0, C.Cobertura * PEI.precio / 100) AS decimal(7,2)) AS total_pagar_obra_social
		FROM precios_estudio_instituto PEI
			INNER JOIN estudio_plan EP ON EP.idEstudio = PEI.idEstudio
			LEFT JOIN coberturas C ON C.idEstudio = PEI.idEstudio 
				AND C.sigla = EP.sigla AND C.nroplan = EP.nroplan
			INNER JOIN institutos I ON I.idInstituto = PEI.idInstituto
GO


-- Crear una vista  vw_nomina_de_medicos que proyecte: La nomina de los médicos indicando en una sola columna el nombre y 
-- el apellido con el formato Dr. o Dra. Con el nombre en minúscula y apellido en mayúscula.
CREATE OR ALTER VIEW vw_nomina_de_medicos 
AS
	SELECT IIF(M.sexo = 'M', 'Dr. ', 'Dra. ') + UPPER(M.nombre + ' ' + M.apellido) AS nomina
	FROM medicos M
GO

--Crear una vista  vw_estudios_en_tres_meses que proyecte: los estudios realizados en los últimos tres meses

-- NOTA PARA TOMAS: Agregar estudios realizados en los ultimos 3 meses para poder ver resultados
CREATE OR ALTER VIEW vw_estudios_en_tres_meses 
AS
	SELECT E.estudio
	FROM historias H
		INNER JOIN estudios E ON E.idEstudio = H.idEstudio
	WHERE H.fecha >= DATEADD(MONTH, -3, GETDATE()) 
	GROUP BY E.estudio
GO

-- Crear una vista  vw_estudios_por_mes que agrupe por mes la cantidad de estudios realizados a los pacientes
-- en el último año diferenciándolos por sexo y estudio realizado.

-- NOTA PARA TOMAS:  Hacer que esta query muestre datos (año 2022) y que alguno sea cantidad 2
CREATE OR ALTER VIEW vw_estudios_por_mes
AS 
	SELECT E.estudio, FORMAT(H.fecha,'MM') AS mes, P.sexo, COUNT(1) AS cantidad
	FROM historias H
		INNER JOIN estudios E ON E.idEstudio = H.idEstudio
		INNER JOIN pacientes P ON P.dni = H.dni
	WHERE YEAR(H.fecha) = YEAR(GETDATE())
	GROUP BY E.estudio, FORMAT(H.fecha,'MM'), P.sexo
GO

-- Crear una vista  vw_estudios_por_instituto que agrupe por semana la cantidad de estudios 
-- que realizó cada instituto en los últimos 7 días.

-- NOTA PARA TOMAS: Agregar datos para ver informacion
CREATE OR ALTER VIEW vw_estudios_por_instituto
AS 
	WITH cantidad_estudios AS(SELECT I.idInstituto, COUNT(1) AS cantidad_estudios
							FROM institutos I
								INNER JOIN historias H ON H.idInstituto = I.idInstituto
								INNER JOIN estudios E ON E.idEstudio = H.idEstudio
							WHERE H.fecha >= DATEADD(DAY, -7, GETDATE()) 
							GROUP BY I.idInstituto)
	SELECT I.instituto, IIF(CE.cantidad_estudios IS NULL, 0, CE.cantidad_estudios) as cantidad_estudios
	FROM institutos I
		LEFT JOIN cantidad_estudios CE ON CE.idInstituto = I.idInstituto
GO

-- Crear una vista  vw_estudios_en_sabado que proyecte la cantidad de estudios que se realizaron un día sábado.
CREATE OR ALTER VIEW vw_estudios_en_sabado
AS
	SELECT COUNT(1) AS cantidad_estudios_sabado
	FROM historias H 
	WHERE DATENAME(DW, H.fecha) = 'Saturday' 
GO

