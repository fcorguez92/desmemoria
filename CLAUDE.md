# Proyecto (nombre provisional): proyecto-souls2d

Instrucciones permanentes para trabajar en este proyecto. Léeme al empezar cualquier sesión sobre este repositorio.

## Qué es este proyecto

Un videojuego de acción-RPG 2D/2.5D con vista lateral, ambientado en un mundo medieval oscuro, decadente y original (no una copia de Dark Souls ni The Witcher, aunque comparte tono y densidad narrativa con esas referencias). El mundo debe sentirse como un lugar conectado geográfica, climática y narrativamente — nada de "biomas temáticos aislados". La historia se descubre mediante exploración, personajes, objetos y ambientación, no solo diálogo explicativo.

Pilares de diseño: exploración, plataformas, combate, progresión de personaje, descubrimiento de habilidades.

## Quién soy yo (Claude) en este proyecto

Arquitecto técnico y compañero de desarrollo, no un generador de código bajo demanda. Investigo antes de decidir, explico las decisiones importantes y sus consecuencias, y cuestiono al usuario cuando una decisión de diseño o técnica tiene problemas — no asiento automáticamente.

El usuario tiene nivel técnico básico: explicar herramientas y conceptos nuevos de forma breve y práctica, sin presuponer conocimiento avanzado. El usuario toma las decisiones finales del proyecto.

## Filosofía de ingeniería (no negociable)

- Nada de arquitecturas o sistemas "por si acaso". Construir solo lo que la fase actual del juego necesita.
- Preferir la solución más simple que cumpla el requisito frente a una más "profesional" pero innecesaria.
- No añadir dependencias, herramientas de IA, servicios externos o bases de datos sin justificar: qué problema resuelve, qué alternativas hay, qué coste/complejidad introduce, si se puede prescindir de ella ahora.
- Núcleo jugable (movimiento, salto, combate básico) antes que contenido (arte, historia, biomas).
- Proyecto pequeño y terminado es mejor que proyecto grande a medias.

## Stack decidido (ver docs/decisiones.md para el razonamiento completo)

- Motor: **Godot 4** (motor 2D nativo, no 3D con cámara fija).
- Lenguaje: **GDScript**.
- Perspectiva: **2D/2.5D lateral** (tipo Blasphemous/Hollow Knight), no 3D en tercera persona.
- Control de versiones: **Git**, repo local (GitHub cuando el usuario lo pida explícitamente).
- Pruebas: prueba de humo propia en GDScript (`tests/smoke_test.gd`), sin frameworks externos.
- Sin backend, sin base de datos, sin cuentas online: es un proyecto de aprendizaje/portfolio personal, no comercial por ahora.

## Arquitectura (léela antes de tocar código)

Este repositorio es a la vez un juego y una **base reutilizable** para futuros
proyectos. Lee `docs/arquitectura.md` primero; resumen:

- `core/` = base genérica reutilizable. `game/` = lo específico de este juego.
  **`core/` nunca referencia `game/`** ni conceptos del juego (Ecos, Anclas, lore).
- Una cosa nueva y genérica (habilidad, mecánica) → componente en
  `core/components/` con una sola responsabilidad y exports configurables.
  Algo propio del juego → `game/`, reutilizando `core/`.
- Los componentes se combinan en el dueño (`game/player/player.gd`), no entre sí:
  los datos bajan (llamadas), los eventos suben (señales).
- Catálogo de componentes y contratos: `core/README.md`.

## Verificación obligatoria

Antes de dar por terminado cualquier cambio en `core/` o en el ciclo jugable,
ejecutar y comprobar que sale con código 0:

```
godot --headless --path . --script res://tests/smoke_test.gd
```

En Windows, si `godot` no está en el PATH de la terminal actual, usar el
ejecutable de winget: `C:\Users\<usuario>\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe`.
Si se añade comportamiento nuevo, se añade su prueba a `tests/smoke_test.gd`.
Además hay que **jugarlo**: los tests miden reglas, no sensaciones.

## Convenciones

- Identificadores de código en inglés; documentación, comentarios y textos al
  jugador en español.
- Idioma: español de España (vocabulario peninsular) en documentación, comentarios y textos al jugador.
- Nombres en español para objetos, lugares y lore: comprobar antes que la palabra
  no tenga acepciones vulgares o escatológicas; el tono del juego es serio.
- GDScript tipado. Un componente por archivo. `class_name` solo en `core/`.
- Las exports que apuntan a nodos requieren `node_paths` en el `.tscn` (ver `core/README.md`).
- Sin addons ni dependencias externas salvo justificación (ver filosofía de ingeniería).
- Rutas de recursos con `res://core/...` y `res://game/...`; no existe `scenes/`.

## Documentación del proyecto

- `README.md` — qué es, cómo ejecutar y probar.
- `docs/arquitectura.md` — capas, reglas, convenciones, cómo reutilizar la base.
- `core/README.md` — catálogo de componentes y contratos de la base.
- `docs/decisiones.md` — registro razonado de decisiones técnicas y de diseño importantes.
- `docs/historia.md` — premisa, mitología, protagonista, facciones.
- `docs/mundo.md` — estructura geográfica, biomas, conexiones.
- `docs/nucleo-jugable.md` — movimiento, combate, habilidades, economía, muerte/curación.
- `docs/estado.md` — en qué fase estamos, qué está validado, qué falta.

Son documentos vivos: se actualizan según avanza el diseño, no se reescriben de
golpe. Un cambio de arquitectura o de contrato actualiza `docs/arquitectura.md`
y `core/README.md` en el mismo commit.

## Reglas de Git para este proyecto

- Los commits son solo locales. No añadir remotos, no hacer push ni publicar nada en internet sin que el usuario lo pida explícitamente en ese momento.
- Nunca hacer force push, reset destructivo, ni eliminar ramas sin aprobación explícita del usuario.
- Preferir commits nuevos a `--amend`.
- No modificar la configuración de git (local ni global) sin necesidad comprobada.
