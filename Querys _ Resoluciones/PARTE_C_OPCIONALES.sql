/*
	Cuál es el menor precio de un estudio en cada instituto. 
	Indicar el nombre del estudio y el nombre del instituto, ordenando el resultado por estudio e instituto.
*/
WITH instituto_estudio_menor_precio AS (SELECT I.idInstituto, I.instituto,  MIN(P.precio) AS Precio
										FROM institutos I
											INNER JOIN historias H ON H.idInstituto = I.idInstituto
											INNER JOIN precios P ON P.idEstudio = H.idEstudio AND P.idInstituto = I.idInstituto
										GROUP BY I.idInstituto, I.instituto)
SELECT E.estudio , IEMP.instituto, IEMP.Precio
FROM instituto_estudio_menor_precio IEMP
	INNER JOIN precios P ON P.precio = IEMP.Precio 
		AND P.idInstituto = IEMP.idInstituto
	INNER JOIN estudios E ON E.idEstudio = P.idEstudio
ORDER BY E.estudio, IEMP.instituto;

/*
	Cuáles son los pacientes que no poseen cobertura.
*/
SELECT P.dni, P.nombre, P.apellido, P.sexo, P.nacimiento
FROM pacientes P 		
WHERE NOT EXISTS (
	SELECT * 
	FROM afiliados A
		INNER JOIN planes PL ON PL.sigla = A.sigla AND A.nroplan = PL.nroplan
		INNER JOIN coberturas C ON C.sigla = PL.sigla
	WHERE A.dni = P.dni
);

/*
	Cuáles es el médico con más especialidades y que atendieron a pacientes que tengan una letra N en el apellido.
*/
WITH medico_cantidad_especialidades AS (SELECT M.matricula, COUNT(1) AS cantidad_especialidades
										FROM medicos M
											INNER JOIN espemedi EM ON EM.matricula = M.matricula
										GROUP BY M.matricula
										ORDER BY cantidad_especialidades DESC
										OFFSET 0 ROWS)
SELECT M.nombre + ' ' + M.apellido AS nombre_medico 
FROM medicos M
	INNER JOIN historias H ON H.matricula = M.matricula
	INNER JOIN pacientes P ON P.dni = H.dni
WHERE M.matricula = (
	SELECT TOP 1 MCE.matricula
	FROM medico_cantidad_especialidades MCE
) AND P.apellido LIKE '%n%'
GROUP BY M.nombre, M.apellido;

/*
	Cuál es la especialidad que más estudios tiene recetados. Indicar el nombre de la especialidad y la cantidad de estudios
*/
SELECT E.especialidad, COUNT(1) AS cantidad_estudios_recetados
FROM especialidades E
	INNER JOIN estuespe EE ON EE.idEspecialidad = E.idEspecialidad
	INNER JOIN historias H ON H.idEstudio = EE.idEstudio
GROUP BY E.especialidad
ORDER BY cantidad_estudios_recetados DESC

/*
	Cuál es el estudio que figura en más especialidades.
*/
SELECT E.especialidad, COUNT(1) AS cantidad_estudios
FROM especialidades E
	INNER JOIN estuespe EE ON EE.idEspecialidad = E.idEspecialidad
GROUP BY E.especialidad

/*
	Cuánto dinero implica los estudios ya realizados por sus pacientes de aquellos pacientes 
	que pertenezcan al médico con dinero recetado en estudios.
*/
SELECT M.nombre + ' ' + M.apellido AS nombre_medico , M.matricula, SUM(P.precio) AS dinero_estudio_medico
FROM medicos M
	INNER JOIN historias H ON H.matricula = M.matricula
	INNER JOIN precios P ON P.idEstudio = H.idEstudio AND P.idInstituto = H.idInstituto
GROUP BY M.matricula, M.nombre, M.apellido

/*
	Cuál es el gasto de dinero realizado por cada obra social sumando los estudios de todos sus afiliados.
*/
SELECT OS.nombre AS obra_social, IIF(H.sigla IS NULL, 0, SUM(P.precio)) AS total_dinero
FROM OOSS OS
	LEFT JOIN historias H ON H.sigla = OS.sigla
	LEFT JOIN precios P ON P.idEstudio = H.idEstudio AND P.idInstituto = H.idInstituto
GROUP BY OS.nombre, H.sigla

/*
	Determine los 3 pacientes que más pagaron en concepto de estudios y que poseían cobertura a través de una obra social. 
	Proyecte el nombre, el apellido, la obra social, el plan y el importe abonado por el usuario.  
*/
SELECT TOP 3 PA.nombre, PA.apellido, OS.nombre AS obra_social, PL.nombre AS _plan, SUM(P.precio) AS total
FROM historias H
	INNER JOIN precios P ON P.idEstudio = H.idEstudio and P.idInstituto = H.idInstituto
	INNER JOIN pacientes PA ON PA.dni = H.dni
	INNER JOIN afiliados A ON A.dni = PA.dni
	INNER JOIN planes PL ON PL.sigla = A.sigla AND PL.nroplan = A.nroplan
	INNER JOIN OOSS OS ON OS.sigla = PL.sigla
WHERE EXISTS (SELECT * 
		FROM afiliados A
			INNER JOIN planes PL ON PL.sigla = A.sigla AND A.nroplan = PL.nroplan
			INNER JOIN coberturas C ON C.sigla = PL.sigla
		WHERE A.dni = PA.dni)
GROUP BY PA.nombre, PA.apellido, OS.nombre, PL.nombre
ORDER BY total DESC