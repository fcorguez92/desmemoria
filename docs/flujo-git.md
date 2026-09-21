# Flujo de trabajo con Git y GitHub (documento vivo)

Repositorio: <https://github.com/fcorguez92/desmemoria>. La rama `main` siempre
debe estar en un estado que arranca y pasa la prueba de humo.

## Conceptos en dos líneas

- **Rama:** una copia de trabajo paralela de la historia. Permite probar algo sin
  tocar `main`; si sale mal, se descarta.
- **Pull request (PR):** una petición en GitHub para incorporar una rama a `main`.
  Es el sitio donde se revisa el cambio antes de aceptarlo.
- **Merge:** aceptar el PR y unir la rama a `main`.

## Ciclo de cada cambio

1. Partir de `main` actualizada: `git switch main` y `git pull`.
2. Crear la rama: `git switch -c feat/nombre-corto`.
3. Trabajar con commits pequeños (un motivo por commit).
4. Antes de subir: pasar la prueba de humo (ver `CLAUDE.md`, "Verificación obligatoria").
5. Subir la rama: `git push -u origin feat/nombre-corto`.
6. Abrir el PR contra `main` con: qué cambia, por qué y cómo se ha probado.
7. Revisar y hacer el merge (lo decide el usuario). Después borrar la rama y
   actualizar `main` local.

## Nombres de rama

`feat/` funcionalidad nueva · `fix/` corrección · `docs/` documentación ·
`refactor/` reorganizar sin cambiar comportamiento · `art/` sprites y baldosas.

## Commits

Mensajes en inglés, en imperativo y con la primera línea de 72 caracteres como
máximo ("Add parry", "Fix echo pickup on the first frame"). Si hace falta
explicar el porqué, se deja una línea en blanco y se escribe debajo.

## Tipo de merge

**Squash merge**: todos los commits de la rama se funden en uno solo en `main`.
Mantiene la historia de `main` limpia (un commit por cambio) y permite
commitear con libertad dentro de la rama.

## Qué no se sube

Lo cubre `.gitignore` (`.godot/`, exportaciones, vistas previas). Nunca claves,
tokens ni contraseñas.

## Configuración recomendada en GitHub (la hace el usuario, en Settings)

- Branch protection sobre `main`: exigir pull request y prohibir force push.
- Merge: permitir solo *Squash merging* y borrar la rama al aceptar el PR.
