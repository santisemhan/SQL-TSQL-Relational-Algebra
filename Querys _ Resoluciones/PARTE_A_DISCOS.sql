USE TP2_Parte_A

-- ¿Cuantos temas tienen los álbumes del género rock?
SELECT COUNT(1) AS Cantidad_Rock
FROM Albumes AS A 
	INNER JOIN Generos AS G ON G.codGenero = A.codGenero
WHERE G.descripcion LIKE 'ROCK%'; -- Rock nacional y rock internacional

-- ¿Cuántos artistas distintos hicieron álbumes del género clásico?
SELECT AR.nombre AS Artista
FROM Albumes AS A 
	INNER JOIN Generos AS G ON G.codGenero = A.codGenero
	INNER JOIN Artistas AS AR ON AR.codArtista = A.codArtista
WHERE G.descripcion = 'Clasica'
GROUP BY AR.nombre;

-- ¿Cuáles son los géneros que tienen más de tres álbumes?
SELECT G.descripcion AS Genero, COUNT(1) AS Cantidad
FROM Albumes AS A 
	INNER JOIN Generos AS G ON G.codGenero = A.codGenero
GROUP BY G.descripcion
HAVING COUNT(1) > 3;

-- ¿Cuál es el álbum con más temas (considere que puede haber más de uno)?
WITH Temas_Cantidad AS (
	SELECT A.titulo AS Titulo_Album, COUNT(1) AS Cantidad_Temas
	FROM Albumes AS A
		INNER JOIN Temas AS T ON T.codAlbum = A.codAlbum
	GROUP BY A.titulo
) SELECT * 
	FROM Temas_Cantidad TC
	WHERE TC.Cantidad_Temas = (SELECT MAX(TC1.Cantidad_Temas) 
							   FROM Temas_Cantidad TC1);

-- ¿Cuáles son los álbumes que tienen un título que es igual al título de alguno de los temas del mismo?
SELECT A.titulo AS Titulo_Album 
FROM Albumes A
	INNER JOIN Temas T ON T.codAlbum = A.codAlbum 
WHERE T.titulo = A.titulo;

-- Determine el nombre de los artistas y de los álbumes de aquellos álbumes del género pop con temas que contengan una letra ñ en el título.
SELECT AR.nombre AS Nombre_Artista, A.titulo AS Nombre_Album 
FROM Albumes A
	INNER JOIN Generos G ON G.codGenero = A.codGenero 
	INNER JOIN Temas T ON T.codAlbum = A.codAlbum
	INNER JOIN Artistas AR ON AR.codArtista = A.codArtista
WHERE G.descripcion = 'POP' 
	AND T.titulo LIKE '%ñ%'
GROUP BY AR.nombre, A.titulo;

-- ¿Cuáles son los clientes con saldo negativo?
SELECT C.*
FROM Clientes C
WHERE C.saldo < 0;

-- Determine si el bruto de las facturas es igual a la sumatoria de sus ítems.
SELECT F.nroFactura, F.bruto, SUM(ITF.precio) AS Sumatoria_Items, 
	IIF(SUM(ITF.precio) = F.bruto, 'Es Igual', 'No es igual')	
FROM Facturas F
	INNER JOIN ItemsFactura ITF ON ITF.nroFactura = F.nroFactura
GROUP BY F.nroFactura, F.bruto;


-- Determine cuales facturas tienen menos cantidad de artículos vendidos que los pedidos.
WITH Cantidad_Facturados AS (
	SELECT F.nroFactura, COUNT(1) as Cantidad_Facturados
	FROM Facturas F
			INNER JOIN ItemsFactura ITF ON ITF.nroFactura = F.nroFactura
	GROUP BY F.nroFactura
), Cantidad_Pedidos AS (
	SELECT F.nroFactura, COUNT(1) as Cantidad_Pedidos
	FROM Facturas F
			INNER JOIN ItemsPedido ITP ON ITP.codPedido = F.codPedido
	GROUP BY F.nroFactura
)
SELECT F.nroFactura AS Factura, CF.Cantidad_Facturados, CP.Cantidad_Pedidos 
FROM Facturas F
	INNER JOIN Cantidad_Facturados CF ON CF.nroFactura = F.nroFactura
	INNER JOIN Cantidad_Pedidos CP ON CP.nroFactura = F.codPedido
WHERE CF.Cantidad_Facturados <> CP.Cantidad_Pedidos;

-- Determine el artículo que esté compuesto por más componentes.
SELECT P.codProducto as Producto_con_composiciones
FROM Productos P
	INNER JOIN Composiciones C ON C.codProducto = P.codProducto;

-- ¿Cuáles son los productos que no figuran en ningún pedido?
SELECT P.* 
FROM Productos P
	LEFT JOIN ItemsPedido IP ON IP.codProducto = P.codProducto
WHERE IP.codPedido IS NULL;

--Determine el cliente con la factura más costosa.
SELECT C.codCliente, C.nombre
FROM Facturas F
	INNER JOIN Clientes C ON C.codCliente = F.codCliente
WHERE F.final = (
	SELECT MAX(F1.final) 
	FROM Facturas F1
);

-- ¿Cuáles son los artículos cuyo stock es menor al punto de reposición?
SELECT *
FROM Productos P
WHERE P.stock < P.puntoReposicion;

-- ¿Cuáles son los discos que pertenezcan a géneros que contengan una letra p en la descripción pero que no tengan una letra s?
SELECT A.titulo as Disco, G.descripcion 
FROM Albumes A
	INNER JOIN Generos G ON G.codGenero = A.codGenero
WHERE G.descripcion LIKE '%p%' AND G.descripcion NOT LIKE '%s%';

-- ¿Cuáles son los pedidos que tienen productos con una descripción que contenga más de 60 caracteres en total?
SELECT P.nroPedido
FROM Pedidos P 
	INNER JOIN ItemsPedido IPE ON IPE.codPedido = P.nroPedido
	INNER JOIN Productos PR ON PR.codProducto = IPE.codProducto
WHERE LEN(PR.descripcion) >= 60
GROUP BY P.nroPedido

-- Determine el total de todas las facturas de cada cliente del mes de febrero del corriente año.
SELECT C.nombre as Nombre_Cliente, IIF(F.Final IS NOT NULL, SUM(F.final), 0) AS Factura_Final, YEAR(GETDATE()) AS Año_Corriente
FROM Clientes C
	LEFT JOIN Facturas F ON F.codCliente = C.codCliente
WHERE MONTH(F.fecha) = 2 AND YEAR(F.fecha) = YEAR(GETDATE())
GROUP BY C.nombre, F.Final