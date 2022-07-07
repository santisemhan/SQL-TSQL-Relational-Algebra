USE TP2_Parte_B

-- ¿Cuáles son los privilegios de cada usuario?
SELECT U.nombre, U.alias, P.tipo AS Privilegio, C.nombre AS Privilegio_en
FROM Usuarios U
	INNER JOIN Privilegios P ON P.usuarioId = U.id
	INNER JOIN Categorias C ON C.id = P.categoriaId;

-- ¿Cuál es el usuario que escribió la noticia más votada?
SELECT N.titulo as Noticia, U.alias, U.nombre, SUM(V.votos_opcion_1 + V.votos_opcion_2 + V.votos_opcion_3) AS Votaciones
FROM Votaciones V
	INNER JOIN Noticias N ON N.id = V.noticiaId
	INNER JOIN Usuarios U ON U.id = N.autor
GROUP BY N.titulo, U.alias, U.nombre
HAVING SUM(V.votos_opcion_1 + V.votos_opcion_2 + V.votos_opcion_3) = (SELECT MAX(V1.votos_opcion_1 + V1.votos_opcion_2 + V1.votos_opcion_3)
																	   FROM Votaciones V1);

-- ¿Cuántos votos recibió en total cada noticia?
SELECT N.titulo AS Noticia,  V.votos_opcion_1 + V.votos_opcion_2 + V.votos_opcion_3 AS Votaciones
FROM Votaciones V
	INNER JOIN Noticias N ON N.id = V.noticiaId;

-- ¿Qué usuarios escribieron noticias que pertenezcan al género policiales y que tengan al menos un comentario?
SELECT U.alias, U.nombre 
FROM Noticias N 
	INNER JOIN Categorias C ON C.id = N.idCategoria
	INNER JOIN Comentarios CO ON CO.noticiaId = N.id
	INNER JOIN Usuarios U ON U.id = N.autor
WHERE C.nombre = 'Policias'
GROUP BY U.alias, U.nombre;

