# Producción: plan maestro (documento vivo)

Une los tres planes por disciplina en un solo orden de trabajo:

- **Mundo y puzles** → fases `W0…WR` de `docs/puzles.md` (sección "Orden de implementación").
- **Sistemas, combate y progresión** → cambios `K01…K41` de `docs/reunion/disenadores/DECISIONES-EDITOR-SISTEMAS.md` (§5) y piezas de motor de `docs/enemigos.md`.
- **Arte** → hitos `H0…H9` de `docs/produccion-arte.md`.

Aquí solo se decide **en qué orden se hace todo** y **cuándo se para**. El detalle de cada paquete está en los documentos enlazados. Es una propuesta pendiente de aprobación del usuario.

## 1. Reglas de producción

1. **Un paquete = una rama = un PR** (`docs/flujo-git.md`), con su prueba en `tests/smoke_test.gd` y la prueba de humo en verde antes de abrirlo.
2. **Núcleo jugable antes que contenido.** Primero lo que cambia la sensación de jugar (frasco, ataques arriba/abajo, mecánicas de puzle), después las salas y el arte que las usan.
3. **Cada hito se cierra jugándolo**, con cronómetro: muertes por jefe, Ecos en la mano al morir, sitios donde uno se pierde. Los tests miden reglas, no sensaciones.
4. **Cada PR de cambio grande pasa por una revisión independiente** (subagente revisor) antes de pedir el merge.
5. **Cada hito es un punto de parada válido**: el juego debe quedar terminable y coherente en cualquiera de ellos. Un proyecto pequeño y terminado vale más que uno grande a medias.
6. **Lo que se recorta se recorta por orden** (§5), nunca "lo que apetezca".

## 2. Hitos jugables

El punto de partida es `main` con las ocho salas del vertical slice, el Centinela, el dash y la prueba de humo de 509 comprobaciones.

| Hito | Qué se puede jugar al terminarlo | Mundo | Sistemas | Arte | Tamaño |
|---|---|---|---|---|---|
| **M0. Base y combate legible** | El mismo juego, con el frasco nuevo (cura 3 vidas, sorbo interrumpible), ataque arriba y abajo con pogo, aviso rojo de golpes no parables, lienzo del Caminante a 112×96 | W0 (marker_groups, `%`, simulador ampliado, verificador de mundo, retoque R7) | K01-K08 | H0 | L |
| **M1. Estado del mundo y economía** | Se guarda lo que haces (puertas, palancas, coleccionables); fragmentos de vida y Bolsas de Rastro; nuevo árbol de habilidades de 14 mejoras | W1, W2 (compuertas, disparadores, frágil, Volver al Ancla) | K09-K13, K24 | H1-01 (sombreador) | L |
| **M2. El Último Umbral y el Cinturón con cara propia** | Las ocho salas actuales con retoques R1-R9, secretos y su aspecto de región; tienda de reliquias; Nombres leídos | W3, W4, W5 (retoques) | K14-K15, K17-K23 | H1 | L |
| **M3. Cinturón completo y primer jefe nuevo (Jacinto)** | Cinturón alto/La Era, doble salto o equivalente del acto, Jacinto, enemigos nuevos (cuervo, espantapájaros) | Salas del Cinturón | K28-K32 (vuelo, `telegraph_zone`, dormant, `boss_base`, Spawner) | H2-H3 | L |
| **M4. Línea de corte A: "el juego pequeño y terminado"** | Umbral + Cinturón completos con 2 jefes, 5 PNJ del Umbral, interfaz y sonido esenciales. **Puede publicarse como juego completo corto** | — | K39-K40 (ayuda, estadísticas) | H4 (total ≈ 168 puntos de arte) | — |
| **M5. El Archivo** (línea B) | Segunda región, Sellos, estados Lento/Fijado, 2 jefes | W6 (Receptor), W3 (Ciclo, carril) | K33, K34, K36 | H5 | L |
| **M6. Costa y Minas** (línea C, parte 1) | Excavar, Nombrar con piedras de lectura, barca de Mirena | W5 (Excavar), W7-W8 | K25-K26, K37, K38 | H6-H7 | L |
| **M7. La Herida y el final** (línea C, parte 2) | Puerta Sin Muro, últimos jefes, los cuatro finales | resto | resto | H8 | L |
| **M8. Opcionales** | Maestrías, Nuevo Ciclo, Oda, Casimar, retratos | WA, WR | K16, K27, K41 | H9 | — |

**Recomendación firme: comprometerse con M0-M4 y no más.** Jugar M4 entero, medir cuánto cuesta de verdad una sala y un jefe, y decidir M5 con datos. Las 136 salas del guion maestro son el techo del diseño, no una promesa: el coste de arte de las tres últimas regiones (≈ 130 puntos) se compara con reducir el alcance (choque C-10 de los artistas).

## 3. Orden de los primeros paquetes (los 14 que desbloquean todo)

| # | Paquete | Dep. | Prueba clave | Coste |
|---|---|---|---|---|
| 1 | K03 frasco rediseñado (`HealthComponent.heal_amount`/`heal_time`, sorbo cancelable) | — | cura exactamente `heal_amount`; un golpe cancela sin gastar carga | M |
| 2 | K02 `parryable` + aviso rojo | — | el golpe rojo atraviesa la guardia | S |
| 3 | H0-01/H0-02 paleta de 31 colores y primitivas del rig en `tools/lib/raster.js` | — | `git diff` de `art/source/` vacío | S+S |
| 4 | K01/H0-03 lienzo 112×96 del Caminante | 3 | cada fotograma nuevo = el antiguo desplazado; pies coinciden | S |
| 5 | K06/K07 ataque arriba y abajo con pogo | 4 | rebote ≈ 126 px; sin rebote en pinchos | M+M |
| 6 | K08 animaciones `attack_up`, `attack_down`, `heal` | 4 | validador de hojas | M |
| 7 | W0 `marker_groups` + `%` + `sim_saltos.js` ampliado + `verifica_mundo.js` | — | un muro 2×3 de marcadores da 1 pieza; la Chimenea simulada da 14-20 | S+S+M+S |
| 8 | H0-04/H0-05 manifiesto y validador de hojas | 3 | hojas defectuosas fallan con su mensaje | M+S |
| 9 | K04/K05 estadísticas con topes y HUD | 1 | topes con todo comprado | S+S |
| 10 | W1 FlagStore + guardado sin subir `FORMAT_VERSION` + coleccionables `!` | 7 | ida y vuelta; partida antigua carga | M+M |
| 11 | K09-K12 fragmentos, vida máxima, precios, presupuesto de Ecos | 9, 10 | 4 fragmentos = +1 vida; el árbol suma 1.800 | M+S+S+S |
| 12 | W2 compuerta, disparadores, frágil, Volver al Ancla | 10 | el Aljibe se comporta como antes | S×4 |
| 13 | H0-06 atlas recortado del Centinela | 8 | ≤ 16 MB, la pelea idéntica | M |
| 14 | H1-01 sombreador de desaturación | 3 | el Caminante, el Ancla y el HUD no cambian | M |

Los paquetes 1-2-3 son independientes entre sí y pueden ir en paralelo (ramas distintas, subagentes en worktree).

## 4. Cómo trabajar con subagentes

- **Implementación de paquetes independientes:** un subagente por rama en worktree aislado; se integran por cherry-pick y yo ejecuto la prueba de humo antes de abrir el PR.
- **Arte y sonido generados por código:** subagente dedicado (los generadores `tools/*.js` son deterministas y se validan con el diff).
- **Revisión:** un subagente revisor independiente por PR con cambios en `core/` o en el ciclo jugable, con el criterio de `docs/flujo-git.md`.
- **Diseño de sala:** un subagente escribe el `.map` y su plan de salto; yo lo valido con `tools/sim_saltos.js` y, sobre todo, **lo juego**.
- Los subagentes proponen; el usuario decide lo que cambia reglas del proyecto.

## 5. Orden de recorte (si hay que bajar alcance, primero lo primero)

1. Mecánicas M8 (corriente) y M9 (luz); ampliaciones M10 y M12.
2. Salas opcionales de maestría y secretos de camino oculto.
3. Opcionales de arte H9 (≈ 45 puntos): Casimar, Rufo, Oda, retratos, Reliquias dibujadas.
4. Voz (Nombrar en combate, K16), candado y alfileres del mapa (K27), Nuevo Ciclo (K41).
5. Tipos de cuerpo de enemigo avanzados y minijefes; élites como comunes con más vida.
6. Regiones enteras desde la última (Herida, Minas, Costa), cerrando la historia de forma abreviada con el Mirador.

**Nunca se recorta:** FlagStore, compuertas y disparadores, ataques arriba/abajo, frasco rediseñado, `%`, el simulador de saltos ampliado, las tres piedras del canon, la prueba de humo.

## 6. Asuntos abiertos que necesitan decisión del usuario

Listados con su contexto en `DECISIONES-EDITOR-SISTEMAS.md` §4, `DECISIONES-EDITOR-MUNDO.md` y `DECISIONES-EDITOR-ARTE.md` §4. Los que más afectan al orden:

1. **El frasco deja de curar del todo** (3 → 5 vidas, sorbo de 0,70 s). Es el cambio que más toca la sensación actual; bloquea M0.
2. **Versionar o no los `.sprite` generados** (cambia una regla de `CLAUDE.md`; paquete H0-07).
3. **Descargar la fuente m5x7** (licencia CC0 a comprobar).
4. **Alcance:** comprometerse con M0-M4 y reevaluar.
5. **Hebra de Cal en el canon** (16 reliquias) y los asuntos de canon menores: Página de Corvel, SEC-08 y MIN-20 del mapa macro.
