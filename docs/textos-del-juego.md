# Textos del juego (canon definitivo, listos para pegar)

Estado: textos finales, corregidos y coherentes con `historia.md`, `personajes.md` y `guion-maestro.md`. Idioma: español de España. Todo lo que el jugador lee en el mundo (inscripciones, notas, placas, cartas) va entre **« »** y mide **160 caracteres o menos**; la comprobación se hizo con un recuento real (Node.js) sobre este mismo archivo. Los textos que ya existen en el juego se respetan **tal cual** y se marcan como *(existente)*.

## 0. Cómo leer este documento y límites del motor actual

- **Hoy, cada sala admite una sola inscripción**, y solo tres salas la tienen puesta (La Chimenea, Las Galerías Bajas y La Pasarela, esta última con el texto vacío): el marcador `i` toma el campo `note` de su sala (`game/levels/room.gd`), y el Umbral tiene además la `I` con texto propio en `game/environment/inscription.tscn`. Los textos de más abajo que no caben en esas ranuras requieren un **marcador de inscripción con texto propio** (como el del Umbral) o un objeto legible. Se marca **[nuevo marcador]** donde hace falta.
- **Pendiente en el código:** la sala `La Pasarela de los Mensajeros` tiene un marcador `i` en el Mirador pero su campo `note` está vacío; el texto está en §3.2 («El Mirador»).
- Los avisos de habilidad hoy dicen "Dash", "Doble salto" y "Salto de pared" (`ABILITY_NAMES` en `player.gd`). Los nombres del canon están en §8.
- Los **Nombres** (30) se marcan con **[Nombre: X]**: al leer el texto, el Nombre pasa a la lista del diario. Ver `guion-maestro.md` §10.
- Los tres textos existentes que el canon respeta, sin cambiar una coma:

> **El Último Umbral, piedra de la entrada** *(existente, `inscription.tscn`)*: "Aquí grabamos los nombres que aún recordamos: Ossenna. Fara. El niño del molino, que nunca dijo el suyo. Mientras alguien lea esto, siguen siendo alguien." **[Nombre: Ossenna] [Nombre: Fara]**

> **Las Galerías Bajas, ante la puerta del Aljibe** *(existente, `galerias_bajas.tscn`, campo `note`)*: "El Aljibe queda sellado por orden del Archivo. El Custodio de guardia no abandonará su puesto hasta que alguien lo releve. Nadie ha venido a relevarlo."

> **La Chimenea** *(existente, `chimenea.tscn`, campo `note`)*: "Aquí descansaban los mensajeros de la Orden antes de la Pasarela. Corrían tan deprisa que la Desmemoria no les daba alcance. Hasta que dejaron de correr."

El texto del Aljibe es la clave del juego: *relevo* es la palabra que une al Centinela, a las Minas, a la Herida y al epílogo secreto.

---

## 1. Guía de estilo breve

1. **El juego no explica: deja restos.** Primero el jugador *ve* algo (un cuenco, un hueco, un arrastre); después, si quiere, *lee* algo que lo reinterpreta. El texto nunca dice lo que la imagen ya dice.
2. **Tres voces**, y cada texto elige una:
   - **Los vivos** (notas, graffiti, ofrendas): primera persona, cansada, concreta, con prisa. Se tutean.
   - **La Orden** (placas, órdenes, registros): impersonal, administrativa, en pasiva ("queda sellado", "se ruega"). El horror viene de lo burocrático.
   - **El mundo** (descripciones de objeto): tercera persona, seca, un punto de ternura. Nunca sabe más que el jugador.
3. **Frases cortas.** Una imagen por texto. La última frase es la que duele o la que deja una pregunta; no se rellena. Se prefiere el punto al punto y coma. Máximo una coma por frase cuando se pueda.
4. **Se dice el hecho y se calla la causa.** Cada texto importante admite **dos lecturas** compatibles. "Cerraron la puerta por dentro. Nadie dice quién se quedó fuera."
5. **Evitar:** explicar la Desmemoria con abstracciones ("el olvido todo lo consume"); adjetivos solemnes encadenados; profecías y "el elegido"; humor moderno; exposición disfrazada de nota; términos vulgares o escatológicos (la crudeza es de hechos, no de léxico); repetir el patrón "El X de la Y" más de dos veces seguidas.
6. **Al protagonista nunca se le nombra** y, si se le habla, es de tú, sin título. Se usa el tuteo ("tú", "vosotros"); no se usa el "vos".
7. **Mayúsculas:** nombres propios e instituciones (la Orden, el Archivo, la Desmemoria, la Herida, la Primera Memoria, los Custodios, los Descreídos). **Los que quedan** en minúscula (son gente). Anclas, Ecos, Hitos y Nombres con mayúscula inicial. Salas: artículo en mayúscula ("El Aljibe").
8. **Aún (la persona) con tilde y mayúscula, siempre como nombre.** En los textos de la Herida se evita el adverbio *aún* para no confundir.
9. **Vocabulario del mundo:** *raspado/a* (afectado por la Desmemoria), *quedar en blanco*, *asentar* (dejar por escrito), *sellar*, *dar por perdido*, *quedarse en la lengua* (un nombre olvidado a medias), *vela* (≈ una hora), *jornada*. Léxico de escribas: *legajo, foliar, cuño, rúbrica*.
10. **Ejemplos:**

| Mal | Bien |
|---|---|
| "La terrible Desmemoria devoró a todos los habitantes de la aldea." | "Doce cuencos en la mesa. Una sola cuchara usada." |
| "Aquí murió valientemente el capitán Aldric." | "Aldric sostuvo el puente. Nadie recuerda de quién era el puente." |
| "Los Custodios eran malvados por cavar tan hondo." | "Cavaron porque no soportaban perder nada. Cavaron mucho." |

---

## 2. Textos de sistema y de arranque

### Tarjeta de apertura (premisa pública)

> La Orden del Archivo juró que nada se perdería.
> Cavó hasta el origen de la memoria.
> Desde entonces algo borra el mundo. No mata: hace que nadie recuerde que existías.
> Tú no puedes olvidar.

### Avisos y menús

| Dónde | Texto |
|---|---|
| Al descansar en un Ancla (ya existe el aviso "Z: Recordar") | "Pronuncias los nombres." |
| Si hay Nombres nuevos desde el último descanso | "Pronuncias los nombres. Nuevos: {lista}." |
| Al leer un Nombre | "Nombre: {nombre}. Lo sostienes." |
| Diario de la pausa, título | "Nombres que sostienes" |
| Diario, por región | "{Región} {n}/5" |
| Diario, total | "Sostenidos: {n}/30" |
| Opción nueva del menú del Ancla (tras recibir el Paño) | "Callar un nombre" |
| Aviso al elegir | "El Hito dejará de decirlo. No se puede deshacer." |
| Confirmación | "Callar" / "No" |
| Resultado | "El Hito ya no dice «{nombre}». Tú sí lo sabes." |
| Fuente de un nombre callado | "Una línea en blanco. Ya no dice nada." |
| Piedra de lectura que pide un nombre | "Esta piedra pide un nombre." |
| Uso de Nombrar | "Mantén Z: nombrar" |
| Escalera de la Sala de Aún | "Cada peldaño pide un nombre. Faltan {n}." |
| Cuerpo de Ansel, antes de Compartir | "Es tu cuerpo. Todavía no." |
| Cuerpo de Ansel, tras Compartir | "Z: Recogerte" |
| Asiento | "Z: Sentarte" |
| El Margen | "Z: Entrar" |
| Coraza del Aljibe, epílogo | "Z: Relevar la guardia" |

### El Paño (objeto)

"Un lienzo blanco, lavado hasta el hueso. Con él se borra un nombre del Hito. Quien lo borra no lo olvida: lo calla."

### Insignia de Mensajera (objeto)

"Un pie alado de hierro, desgastado por el uso. Corrió hasta donde nadie esperaba."

---

## 3. Textos por región

Formato: **Sala · colocación**, tipo, texto. Los nombres de sala están en §9.

### 3.1 El Último Umbral

*Historia ambiental:* los vecinos se fueron hace pocos días, deprisa, y dejaron platos y nombres. Aquí aún no hay Desmemoria; hay miedo y duelo. Hilo: **la gente que se marchó eligió a quién recordar**.

- **El Último Umbral · piedra de la entrada** — *(existente, ver §0.)* **[Nombre: Ossenna] [Nombre: Fara]**
- **El Último Umbral · base del primer Hito** — piedra más antigua. Descripción: "La piedra más vieja del Hito. Dice solo: Tamar. Nadie sabe quién era." **[nuevo marcador]**
- **El Último Umbral · junto a esa piedra** — una piedra menor, más cuidada. «Linde.» y descripción: "La letra no es la de ningún otro nombre. Alguien la puso de noche." **[nuevo marcador]**
- **El Último Umbral · ofrenda junto al primer Ancla** (platillo con moneda, cinta roja y un diente de leche) — «Para quien guarda lo nuestro: guárdalo un poco más.» **[nuevo marcador]**
- **El Último Umbral · pared de la cabaña, escrito con carbón** — «Tomás, Inés, el pequeño Rubén. Si alguien vuelve, que lo diga en voz alta.» **[Nombre: Tomás] [Nombre: Inés] [Nombre: Rubén]** **[nuevo marcador]**
- **El Último Umbral · mesa de la cabaña** (doce cuencos; once llenos y fríos, uno rebañado; una silla pequeña volcada) — nota clavada con una espina: «Los demás se negaron a comer. Yo también, pero tuve hambre.» **[nuevo marcador]**
- **El Último Umbral · carro volcado** — sin texto. Entre el grano, una muñeca (ver §6).
- **El Último Umbral · marcas de arrastre hacia el foso** — sin texto. Al fondo, un zapato que no se puede recoger.
- **El Último Umbral · segunda Ancla, en lo alto** (velas gastadas en círculo y un cuenco con agua limpia) — «Aquí descansó el último en irse. Dejó agua para el siguiente.» **[nuevo marcador]**
- **El Último Umbral · cartel en el poste de la salida** — «Cinturón Yermo. Quien tenga a quién esperar, que espere aquí. No sigan.» **[nuevo marcador]**
- **Detrás del Estandarte · jirón de tela con el emblema de la Orden, atado con alambre** — nota prendida: «El Archivo no vino. Se quedó con lo suyo.»
- **El Patio de los Nombres · junto al Fogón** — placa: «Aquí se leen los nombres cada noche. Quien falte a la lectura, que no falte a la memoria.»
- **La Fragua del Umbral · sobre el yunque** — «Hierro de la Orden, forjado para encerrar. Ahora sirve para abrir.»
- **La Puerta Tapiada · dintel** — «Cerrado por orden de quienes aún mandaban. Que nadie diga que no avisamos.» (Marcas de uñas en el lado de dentro, a poca altura.)
- **El Sótano de los Cantores · tras la Puerta Tapiada** *(se abre con Excavar)* — grabado en la roca: «Cantad bajito a la que todavía está. Su nombre es Aún. No lo gritéis: se cansa.»

### 3.2 El Cinturón Yermo

*Historia ambiental:* campos que dejaron de dar de comer. La Desmemoria llegó primero a lo cultivado: la tierra olvidó qué sembrar. Los campesinos siguieron arando por costumbre. Hilo: **la rutina como último vestigio de identidad**.

**Las Terrazas Secas y el subsuelo (construido)**

- **Las Terrazas Secas · borde del foso** (barandilla de cuerda medio caída; una cuenta de rosario en la piedra) — aviso clavado: «No es un error. Abajo hay camino. Quien baje, que cuente los peldaños para volver.» **[nuevo marcador]**
- **Las Terrazas Secas · cornisa del Ancla** — «Aquí se esperaba el relevo del riego. Ya nadie sube a esperar.» **[nuevo marcador]**
- **La Cisterna · zona de aterrizaje** — «Aquí se guardaba el agua de todos. Ahora se guarda el sitio donde estuvo.» **[nuevo marcador]**
- **Las Galerías Bajas · ante la puerta del Aljibe** — *(existente, ver §0.)*
- **El Aljibe · pared de la arena, visible tras vencer al Centinela** — placa: «Guardia del paso. Consigna: esperar al Prior. El Prior no ha venido.» **[nuevo marcador]**

**Los Pasos Rotos (construido)**

- **La Chimenea · descanso** — *(existente, ver §0.)*
- **La Pasarela de los Mensajeros · vigas del primer hueco** — cartas clavadas sin sobre: «A la Venta del Cruce, para Elisa: que sepa que llegué. Que sepa que no llegué más lejos.» **[nuevo marcador]**
- **La Pasarela de los Mensajeros · mojón del segundo hueco** — «Aquí se cortaba el camino cada invierno. Los Mensajeros lo cruzaban igual.» **[nuevo marcador]**
- **El Mirador · inscripción (el campo `note` de la Pasarela, hoy vacío)** — «Desde aquí se ve adonde corrían. Quien llegue, que descanse un poco. Lo de allá no se va a mover.»
- **El Mirador · una carta sin clavar, sobre una piedra, junto a una linterna encendida** — carta de Oda, entre el sobre y el texto: «A la casa de los Varga, en las Terrazas. Vuestro hijo está bien. No dejéis que lo manden a las Minas: allí abajo se oye algo. Oda.» **[Nombre: Oda Bellver]**

**La Torre de Riego (construido)**

- **La Torre de Riego · placa de la rueda parada, con la cuerda aún tensa** — «Torre de Riego. Vigía: Tomasa. Cerró la última compuerta y nadie más abrió la torre.» **[Nombre: Tomasa]** **[nuevo marcador]**

**El resto del Cinturón**

- **La Casa Varga · marco de la puerta** (se llega con el doble salto) — «En el marco, una "A" y una "L". Las marcas de la "L" siguen subiendo más arriba.»
- **El Surco Ciego · terraza arada sin una planta, con un espantapájaros mirando el foso** — placa al pie: «Aquí se sembraba trigo. Se sigue sembrando. Nadie recuerda qué.»
- **El Campo de los Ferrán · mojón** (parche gris con el borde limpio, como cortado con tijera) — «Lindero de los Ferrán. El lindero sigue. Los Ferrán, no.»
- **El Campo de los Ferrán · espantapájaros** — «Lleva el delantal de Eulalia Ferrán. Su marido se lo puso para tener con quién hablar.» **[Nombre: Eulalia Ferrán]**
- **El Cruce del Pan · mesa de piedra con tres sitios y tres rayas de tiza** — «Se deja pan para los que van de paso. Si no pasa nadie, que lo coman los pájaros.»
- **La Acequia · esqueleto con la azada en la mano, sentado contra el muro, mirando el surco** — nota en su bolsillo: «Sigo hasta que la tierra me diga qué hacer. Lleva meses sin decirme nada.»
- **Un muro del Cinturón · graffiti de los Descreídos** — «No guardéis el hambre. Soltadla.»
- **Justo debajo · contra-graffiti de la Orden, de otra mano** — «Quien suelta, pierde. Quien pierde, no vuelve.»
- **El Brocal (pozo)** — cuerda cortada, cubo en el fondo, marcas de rodillas. «Sin agua desde que olvidamos dónde estaba el manantial. Hay que cavar más abajo.»
- **El Camino de Ronda · puesto de guardia (Segunda Torre de Riego)** — placa de la Orden: «Puesto de guardia. Se ruega al viajero declarar lo que recuerda. Se ruega no declarar de más.»
- **La Era · en el centro, una tablilla clavada junto a un trompo pequeño** — «Eloy Ferrán, siete años. Esperó a su padre en la era hasta que se hizo de noche.» **[Nombre: Eloy Ferrán]**
- **La Era · hoz clavada en el suelo, tras vencer a Jacinto** — «Jacinto Ferrán segaba para los que venían a comer. No vino nadie. Segó igual.» **[Nombre: Jacinto Ferrán]**
- **El cercado de ovejas vacío** — sin texto: la puerta abierta, muchas huellas que se alejan y ninguna que vuelve.

> Los cinco Nombres del Cinturón: Oda Bellver, Tomasa, Jacinto Ferrán, Eulalia Ferrán, Eloy Ferrán.

### 3.3 El Archivo

*Historia ambiental:* la ciudad-biblioteca, mitad intacta y mitad en blanco. Los escribas siguen copiando lo que ya no existe. Hilo: **el amor al registro convertido en pánico a perder**.

- **La Puerta del Archivo** — placa: «Se admite a quien traiga algo que conservar. No se admite a quien traiga algo que olvidar.»
- **El Scriptorium Callado · mesa de copia con la pluma aún húmeda** — folio a medias, la letra cada vez más temblorosa, al final una raya. Último renglón: «…y entonces el nombre del capitán era…»
- **La Nave Raspada · escritorio del escriba sentado y quieto** (nave larga cuyas paredes han perdido el relieve) — «Dejé de leer cuando dejé de entender lo que leía. Lo copio igual.»
- **Estantería Nueve · estantería-torre con los lomos intactos y las hojas en blanco** — placa: «Sección de Linajes. Contenido: dado por perdido.»
- **La Sala de los Lacres · balanza con un pesapapeles en un plato y nada en el otro** — cartel: «Todo lo sellado debe constar. Lo que no consta no ha sido sellado. Lo que no ha sido sellado no existe.»
- **El Pasaje de las Llaves · esqueleto de ropajes de la Orden apoyado en una puerta cerrada por dentro** — nota en la mano: «Cerré yo. No me preguntéis por quién.»
- **Una escalera de caracol taponada por libros** — «Por orden del Archivo: no leer en voz alta bajo este arco.»
- **El Aula Pequeña · pupitre infantil con un cuaderno de letras** — última plana: «Lucía copia: A, B, C. Y ya no hay más.» **[Nombre: Lucía]**
- **El Retrato Ausente · marco vacío, un clavo y una sombra más oscura en la pared** — placa bajo el marco: «Fundadora de la Orden.» Sin nombre debajo.
- **El Retrato Ausente · reverso del marco, escrito a lápiz** — «Ardena y la niña Nía. Que no se pierdan.» **[Nombre: Ardena]**
- **Un rincón del Archivo · el escriba que copia con la izquierda porque la derecha ya no le obedece** — «Me quedan nueve folios. Los he repartido entre diez cajas. Si pierdo la cuenta, que no se pierdan las cajas. Aurelio.» **[Nombre: Aurelio]**
- **Un pasillo en blanco · cartel pegado a una pared sin relieve** — «Pasillo tres. En blanco. No se cierra: a veces vuelve.»
- **Una sala del ala de los Negadores** — cartel: «Esta ala está al completo. Cualquier vacío es un error de recuento.»
- **La Sala de los Relatores · fichas sobre las mesas, la letra del propio jugador** — «Ficha de retención. Relator: A. Varga. Retiene el nombre que se raspa. Cuídese de no repetirlo.»
- **La Sala de los Relatores · mesa del fondo con raspadores, un tintero seco y un molde** — «Molde de máscara de Relevo. Seis moldes. Cinco rotos.»
- **La Sala de los Relatores · pared de la mesa de los raspadores** — «Un cuchillo por nombre. Un nombre por Relator. Que ninguno sepa los de los demás.»
- **La Sala de Extracción · una silla con la huella de cientos de manos en los brazos** — placa: «Silla de extracción. Se ruega no atarse: el sellado es voluntario.»
- **El Salón de Sellado · frente al sello de cera gigante** — grabado: «Un sello más. Nadie más se perderá.»

> Los cinco Nombres del Archivo: Ilara (jefa vencida), Corvel (primera Página), Aurelio, Lucía, Ardena.

### 3.4 Las Minas del Origen

*Historia ambiental:* los túneles de la Orden hasta Aún. Primero orgullo, luego hambre de seguir, al final algo respondió. Hilo: **el trabajo que se vuelve ritual y el ritual que se vuelve plegaria**. Color: *exceso*, no vacío.

- **El Andén de los Picos · primer andén con picos apilados** (cada uno con un nombre; el último de la fila, ninguno) — cartel: «Un pico, un nombre. Quien rompa su pico, que lo declare.»
- **El Andén de los Picos · el pico más cercano** — grabado: «Berenguer.» **[Nombre: Berenguer]**
- **La Vagoneta Quieta · vagonetas descarriladas y una cadena con escarcha que no debería haber** — nota: «Cargamos más de lo que podía mover. Seguimos cargando.»
- **Un nicho de ofrendas en la roca** (pan, monedas, un mechón atado con hilo rojo) — «Para el que escucha desde abajo. No sabemos si nos oye. Preferimos que oiga.»
- **Pared de rayas de cuenta** (en grupos de cinco; al final, de seis, de siete, de ninguno) — «Perdí la cuenta de los días. No perdí la de las rayas. Es raro.»
- **La Fila de Espera · esqueletos sentados mirando un túnel tapiado, una chapa de turno en cada mano** — placa: «Turno de descanso. Aguardan relevo. No ha llegado.»
- **La Cuerda de Mil Nudos · pozo vertical, un papel doblado dentro de cada nudo** — uno de tantos: «Estoy bien. Que lo sepan arriba. Dimas.» **[Nombre: Dimas]**
- **Un grafiti en la roca, hecho con la punta de un pico** — «Ahí abajo hay una voz. No es la nuestra. Es la primera.»
- **La Cámara de las Voces · círculo de piedras con marcas de rodillas y velas fundidas** — «Quien baje, que baje callado. Aquí se escucha lo que aún no se ha dicho.»
- **Una sala de estratos** (el exceso: capas de recuerdos como roca) — «Aquí los estratos hablan a la vez. No intentes entender. Intenta no soltar el hilo.»
- **El Cuarto del Capataz · diario con una sola página escrita** — «Han dejado de bajar herramientas. Han empezado a bajar comida. Ya no preguntan qué hacemos.»
- **El Taller de Dola · sobre el banco** — «Todo pico vuelve a su dueño. Quien se lleve uno, que lo traiga.»
- **La Cámara de Apuntalamiento · viga maestra** — «Apuntalad lo que cavasteis. Lo que no se sostiene cae sobre quien lo sostuvo.»
- **La Veta Tapiada · túnel que sube hacia el Cinturón, cerrado desde dentro con un pilar de roca** — placa: «Para que no suba lo que no debe. Para que no baje quien aún espera.»
- **El Trono Hundido · trono con una página sellada abrazada en el regazo** — grabado: «Que no se olvide a la reina. Que no se olvide a quien lo mandó.»
- **El Trono Hundido · la página sellada de la reina** — «Áurea. Se ríe con la boca tapada. Le gusta el pan con sal.» **[Nombre: Áurea]**

> Los cinco Nombres de las Minas: Berenguer, Dimas, Rosendo (lo dice Brunel), Magda Soler (jefa vencida), Áurea (opcional).

### 3.5 La Costa Retenida

*Historia ambiental:* los Descreídos viven en la costa porque el mar se lleva las cosas y nadie las llora. Pero entre sus rezos hay dudas. Hilo: **la serenidad como forma de duelo reprimido**. Color: **nítido**, el más vivo del mapa.

- **El Muro Blanco · casas en el acantilado, sin cristales, con cortinas lavadas hasta el hueso** — placa en la puerta: «Aquí no se guarda nada. Pase y no recoja.»
- **El Altar de Sal · piedra plana con huellas de objetos retirados** — «Lo ofrecido se va. Es el don.»
- **Un mástil con una cuerda de nudos deshechos** — cartel: «Un nudo por pena. Desátalo.»
- **La Casa Atada · estantes repletos, una cuerda atada a un clavo** — nota de Casilda: «Les dije que no podía. Me dijeron que lo entendían. Me dejaron esto: la puerta sin cerrar.»
- **El Faro de las Velas · escalera con una vela en cada peldaño, la más alta aún encendida** — «Aquí vela el último que dudó. Que no se lo digan a los demás.»
- **El Faro de las Velas · la lámpara** — «Cada ofrenda es una luz. Cada luz, un nombre que no vuelve.»
- **La Playa de Nombres · letras hechas con piedras en la arena** — «Marta. Julián. La Niña. La marea ya ha tocado el último.» **[Nombre: Marta] [Nombre: Julián]**
- **Un predicador muerto junto a un cuenco de agua salada, con los dedos entrelazados con fuerza** — nota en el cinto: «Prediqué soltar. Nunca solté esto.»
- **El Muro Blanco · una piedra blanca entre las oscuras** — grabado: «Hijo.»
- **La Barca Varada · remos dentro, una red tejida a medias** — placa: «No volvió de pescar. Desde entonces, pescamos poco.»
- **Acantilado de Cortinas · una voz que canta sin que se vea quién** — verso: «Dicen que cantan los que no recuerdan. Yo canto lo que me sale. Hoy salió tu nombre.»
- **El Banco Doble · banco de piedra con dos hoyos en el asiento y dos copas vacías** — «Quien no olvida, que se siente aquí. Quien olvida, que se siente también.»
- **El Rellano de Cal · círculo blanco en el suelo, antes de entrar** — «Aquí se dijo el Primer Olvido. No se dijo en voz alta.»
- **Un cuarto con una cama hecha, en el Muro Blanco** — «Duerme. Aquí nadie te pedirá el nombre.»

> Los cinco Nombres de la Costa: Marta, Julián, Elvira (el peine de Casilda), Mateo (Eudora vencida), Rufo (opcional).

### 3.6 La Herida

*Historia ambiental:* todo lo reconocible se disuelve. Los textos son más fragmentarios. Hilo: **lo que encontraron al cavar no era un tesoro: era alguien**. Aquí se evita el adverbio *aún*.

- **La Puerta Sin Muro · dintel** (un marco de piedra de pie en mitad de un páramo gris; al cruzarlo, nada cambia) — «Entrada. (No hay salida registrada.)»
- **La Puerta Sin Muro · los tres huecos** — «Cera. Piedra. Cal. Todo lo que hicimos para que no hablase.»
- **El Círculo Colgado · cinco sillas suspendidas sobre un suelo que no está, cada una con una máscara azul y una placa**:
  - «Íñigo. Primero. No soportó el silencio.» **[Nombre: Íñigo]**
  - «Leocadia. Segunda. Dejó de dormir antes de dejar de respirar.» **[Nombre: Leocadia]**
  - «Tadeo. Tercero. Pidió que alguien le cogiera la mano. Nadie pudo.» **[Nombre: Tadeo]**
  - «Brígida. Cuarta. Contó todos los nombres. Se le acabaron.» **[Nombre: Brígida]**
  - «Álvar. Quinto. Se levantó antes de tiempo.» **[Nombre: Álvar]**
  - Una sexta silla, sin placa: «La sexta no tiene nombre. Tiene tu medida.»
- **La Escalera de Hojas · peldaños que son libros sin cubierta; el último, en blanco** — «Lo último que se escribió fue lo primero que se perdió.»
- **El Eco Quieto · figura traslúcida que abre una puerta que no existe** — «Lleva repitiéndolo desde antes de que hubiera puerta.»
- **La Pared Raspada · cientos de nombres, todos con la misma raya diagonal** — «Fueron dados por perdidos. Nadie los pierde de verdad.»
- **Un cuaderno del último Custodio, en el suelo** — «Hemos llegado. No es un lugar. Es una persona. Nos reconoció.»
- **El Hueco del Cuerpo · un hueco en la roca con la forma y el tamaño del jugador** — «Aquí cabías. Aquí cabes.»
- **Una lámpara encendida sin llama** — «Se enciende cuando nadie la mira.»
- **La Mesa de Dos · una taza llena, otra volcada, la silla de la volcada caída hacia atrás** — nota bajo el plato: «Nos dijimos que volveríamos mañana. Lo seguimos diciendo.»
- **Último Ancla antes de la Sala del Asiento (sin nombre en el Hito)** — «Se descansa sin nombre. Hasta que alguien lo ponga.»
- **Antes de entrar en la Sala de Aún** — «Aquí empezó. Aquí puede cerrarse. Pregunta a quien nunca olvida.»
- **La Sala del Asiento · en el asiento** — «Medida del Relevo: la de quien llegue. Se ruega no levantarse.»

> Los cinco Nombres de la Herida: Íñigo, Leocadia, Tadeo, Brígida, Álvar.

---

## 4. Las Páginas de Corvel (6)

Hojas sueltas de un cuaderno, una por región. Se leen en orden y las lee Sabela.

1. **Umbral (cabaña, bajo el tablón):** «Primera página. Guardé a mi madre en una hoja. Ella ya no sabe cómo me llamo. La hoja sí.» **[Nombre: Corvel, en la primera]**
2. **Cinturón (Cruce del Pan):** «Segunda. Los que se dejan copiar enferman. El Prior dice que es el peso del recuerdo. Yo digo que es el hueco.»
3. **Archivo (Estantería Nueve):** «Tercera. Todo lo sellado cuesta algo a alguien. Aquí nadie lleva la cuenta de lo que cuesta.»
4. **Minas (Cámara de las Voces):** «Cuarta. Hay quien oye algo abajo. Si lo ponemos en una página, ¿a quién se lo quitamos?»
5. **Costa (Altar de Sal):** «Quinta. Aprendí que se puede soltar sin perder. Se llama olvidar. Lo prohibieron por eso.»
6. **Herida (La Escalera de Hojas), tachada:** «Sexta. Lo que guardo se lo he quitado a alguien.»

---

## 5. Hitos y Anclas

Cuando se descansa en un Ancla, el Hito muestra los nombres grabados (los sostenidos en esa región). Algunas Anclas añaden una línea propia (una por Ancla "bonita"):

| Ancla | Línea |
|---|---|
| El Último Umbral, primera | "Una pila de piedras. Cada una lleva un nombre. Pronuncias los nombres." |
| Terrazas Secas | "Alguien dejó una cuenta de rosario en la piedra más alta." |
| La Cisterna | "El Hito está seco. Pero las piedras están limpias." |
| Las Galerías Bajas | "Un Hito en un pasillo. Quien lo hizo sabía que habría quien llegase hasta aquí." |
| La Chimenea | "En la piedra de arriba hay una huella: la de un pie con prisa." |
| El Mirador | "Un Hito sin nombres todavía. Se dejó una linterna encendida." |
| El Archivo | "Aquí los nombres están escritos con tinta. Se borran si los tocas." |
| Las Minas | "Cada piedra está tallada con un pico. Ninguna dice quién." |
| La Costa | "Los nombres de este Hito se han lavado con sal. Los lees igual." |
| La Herida | "Se descansa sin nombre. Hasta que alguien lo ponga." |

---

## 6. Objetos con lore (36)

Descripciones de objeto (1-3 frases, voz del mundo). Entre paréntesis: dónde y qué revela.

**Umbral**

1. **Muñeca sin cara** — "Trapo cosido con cariño. Alguien le borró los ojos a propósito, para que no mirase al irse." *(Carro volcado. Los refugiados temían ser reconocidos.)*
2. **Cinta roja** — "Una cinta de pelo, nueva. La compró alguien que pensaba quedarse." *(Ofrenda del Ancla.)*
3. **Diente de leche** — "Pequeño y limpio. Alguien lo guardó para recordar cuándo se cayó." *(Ofrenda. Había un niño entre quienes se fueron.)*
4. **Llave sin cerradura** — "Hierro basto, gastado por el uso. Ninguna puerta del asentamiento la reclama." *(Cabaña.)*

**Cinturón Yermo**

5. **Semilla gris** — "Se reconoce como semilla por la forma, no por el peso. No pesa nada." *(Terraza arada.)*
6. **Azada de madera** — "Mango pulido por muchas manos. La cuchilla se ha cambiado dos veces." *(Esqueleto de la acequia.)*
7. **Cuerda cortada** — "Un cabo limpio, a ras. Quien lo cortó sabía bien lo que hacía." *(Brocal. Se cortó por voluntad, no por azar.)*
8. **Rosario sin cuentas** — "Solo queda el hilo. Las cuentas cayeron al foso una a una." *(Foso de las Terrazas.)*
9. **Medida de trigo** — "Un cuenco de madera con una raya. Mide cuánto grano. Ya no hay grano." *(Torre de Riego.)*
10. **Trompo pequeño** — "De madera de olivo, con la punta gastada. Alguien lo dejó girando." *(El Cruce del Pan. Es de Telmo, el hermano de Iria.)*
11. **Hoz clavada** — "Hierro viejo, mango nuevo. Siegan siempre con la misma." *(La Era, tras Jacinto.)*

**El Archivo**

12. **Pluma de escriba** — "Cañón gastado. Todavía escribe, pero la tinta que traza se va secando." *(Mesa de copia.)*
13. **Lacre roto** — "Cera roja con una huella. Nadie abrió la carta que sellaba." *(Sala de los Lacres.)*
14. **Folio en blanco** — "Papel de calidad. Nada escrito. Ni siquiera la marca de agua." *(Estantería Nueve.)*
15. **Llavero del Custodio** — "Doce llaves. Ninguna abre la puerta donde murió." *(Pasaje de las Llaves. Es de Oriol Maraver.)*
16. **Cuaderno de letras** — "Las letras de una niña aprendiendo. Termina en la C." *(El Aula Pequeña.)*
17. **Cuño de la Orden** — "Hierro frío. Imprime un círculo con una raya que lo cruza." *(El emblema ya contiene su borrado.)*
18. **Molde de máscara** — "Yeso azul, partido. Algunas cosas se hacen para no tener cara." *(Sala de los Relatores.)*

**Las Minas**

19. **Pico con nombre** — "Grabado: «Berenguer». Ya no existe nadie con ese nombre." *(Andén de los Picos.)*
20. **Mechón atado** — "Pelo oscuro atado con hilo rojo. Un regalo para quien escucha." *(Nicho de ofrendas.)*
21. **Vela fundida** — "Cera acumulada en forma de arrodillamiento. Se nota dónde apoyaron las rodillas." *(Cámara de las Voces.)*
22. **Papel de nudo** — "Doblado muchas veces. Dice: «Estoy bien»." *(Pozo vertical. Mintieron para no preocupar a los de arriba.)*
23. **Ficha de turno** — "Una chapa con un número. Quien la dejó esperaba el relevo." *(Fila de Espera.)*

**La Costa**

24. **Concha con hilo** — "Una concha perforada. Se la regalaron a alguien que todavía no ha muerto." *(Playa de Nombres.)*
25. **Peine de hueso** — "Dientes rotos. Alguien lo guardó aun roto. En el mango, un nombre: Elvira." *(Casa Atada.)*
26. **Nudo imposible** — "No se deshace. Cuanto más tiras, más aprieta." *(Mástil.)*
27. **Zapato pequeño** — "Una sandalia de niño, con arena dentro. Alguien la dejó al pie de las letras." *(Playa de Nombres. Es de Telmo.)*
28. **Piedra blanca** — "Lisa. Con una sola letra, casi borrada: «H»." *(El Muro Blanco. Un hijo, muerto o perdido.)*

**La Herida**

29. **Eco de una puerta** — "Pesa menos que el aire. Abre algo, pero no recuerdas qué." *(Eco Quieto.)*
30. **Taza volcada** — "Aún húmeda por dentro. Nadie ha bebido de ella." *(Mesa de Dos.)*
31. **Hoja arrancada** — "El borde pertenece a un libro que ya no existe." *(Escalera de Hojas.)*
32. **Cuaderno del último Custodio** — "Escritura apresurada, pulso firme: la de alguien que sabe lo que ve." *(La Herida.)*

**Transversales**

33. **Moneda sin cara** — "Valía algo. Ahora vale lo que cuesta mirarla." *(Cualquier región.)*
34. **Botón de uniforme** — "Metal oscuro, cuatro agujeros. Pertenecía a un guardia del Archivo." *(Archivo y Umbral.)*
35. **Retal de estandarte** — "Rojo desvaído, un hilo dorado. Todos tuvieron bandera una vez." *(Cualquier región.)*
36. **Carta sin destinatario** — "El sobre dice solo: «A quien siga en pie»." *(Cualquier región.)*

---

## 7. Reliquias y amuletos (15)

Los efectos son **sugerencias** para el diseño de sistemas; las cifras las fija quien diseñe la economía. Formato: **Nombre** — texto del objeto. *Efecto sugerido · dónde.*

1. **Aguja del Escriba** — "Cose lo que se rasga. El cuerpo recuerda cómo era antes." *Cura un poco más rápido · Archivo.*
2. **Dedal de la Torre** — "Protege el dedo, no la mano." *Amortigua un golpe leve · Torre de Riego (o Cano).*
3. **Medalla del Umbral** — "Tosca. Se concede a quien cruza sin mirar atrás." *Al morir conservas una fracción de los Ecos · Umbral oculto (o Cano).*
4. **Trapo de Iria** — "Una vez hubo alguien que lo llevaba." *+1 de vida máxima · misión de Iria.*
5. **Lacre de silencio** — "Sella el ruido." *Los enemigos te oyen desde menos lejos · Gaspar.*
6. **Diente de la Mina** — "Duro y blanco." *Más daño al golpear piedra y hueso · Minas.*
7. **Cuenta del Rosario** — "La última. Evita una caída mortal, una sola vez." *Hasta el próximo Ancla · foso de las Terrazas, escondida.*
8. **Campanilla de la Costa** — "Suena sola cuando algo amenaza." *Aviso de enemigos cercanos en el borde de pantalla · Costa.*
9. **Pesa del Archivo** — "Un contrapeso de balanza." *Los golpes lentos pegan más y los rápidos menos · Archivo.*
10. **Pluma sin tinta** — "Escribió todo lo que pudo." *Los Ecos se recogen desde más lejos · Sabela, las seis Páginas.*
11. **Llave sin puerta** — "Hierro que abre lo que ya no existe." *Revela muros falsos al acercarse · Umbral (o Cano).*
12. **Corona sin Reina** — "Pesa más que el oro." *El enemigo desviado queda aturdido más tiempo · Casimar.*
13. **Piedra blanca de la Costa** — "Lisa y silenciosa." *Tras un parry exitoso recuperas un poco de vida · Muro Blanco.*
14. **Vela del Faro** — "Todavía caliente, aunque nadie la ha encendido." *Las Anclas lejanas se marcan en el minimapa · Rufo.*
15. **Insignia de Mensajera** — "Un pie alado de hierro. Corrió hasta donde nadie esperaba." *Menos espera entre dashes · Oda (secreto).*

---

## 8. Habilidades: "Has recordado: …"

Cada aviso va seguido de dos frases de descripción (pantalla del recuerdo o diario). El nombre que muestra hoy el juego va entre paréntesis.

1. **Has recordado: la Carrera** *(Dash)* — "Es la prisa de Oda, que llevaba cartas por los Pasos Rotos. Corre: alguien espera."
2. **Has recordado: el Segundo Aliento** *(Doble salto)* — "Es el aire que Tomasa guardaba entre un peldaño y el siguiente. Basta para saltar una vez más."
3. **Has recordado: el Agarre** *(Salto de pared)* — "Es la mano de Jacinto, que subía los bancales con el cesto a cuestas. El muro, ahora, te sostiene."
4. **Has recordado: el Golpe Hondo** *(Excavar)* — "Es el gesto de Magda, que picó hasta oír lo que había debajo. El suelo guarda memoria del pico que lo rompió."
5. **Has recordado: Nombrar** *(Nombrar)* — "Es el juego de Linde: decir en voz alta lo perdido para que vuelva. Un nombre dicho con ternura sostiene un instante."

---

## 9. Nombres de sala (59)

Los marcados con * ya existen. El nombre en pantalla es el de este listado.

**El Último Umbral (8):** El Último Umbral* · El Patio de los Nombres · La Fragua del Umbral · La Escalera del Remiendo · El Rellano de la Vela · Detrás del Estandarte · La Puerta Tapiada · El Sótano de los Cantores

**El Cinturón Yermo (14):** Las Terrazas Secas* · La Cisterna* · Las Galerías Bajas* · El Aljibe* · La Chimenea* · La Pasarela de los Mensajeros* · El Mirador* · La Torre de Riego* · La Casa Varga · El Surco Ciego · El Cruce del Pan · El Campo de los Ferrán · La Era · El Camino de Ronda

**El Archivo (10):** La Puerta del Archivo · El Scriptorium Callado · La Nave Raspada · La Sala de los Lacres · Estantería Nueve · El Aula Pequeña · El Pasaje de las Llaves · El Retrato Ausente · La Sala de los Relatores · El Salón de Sellado

**Las Minas del Origen (9):** El Andén de los Picos · La Cuerda de Mil Nudos · La Cámara de las Voces · La Fila de Espera · La Veta Tapiada · El Taller de Dola · La Cámara de Apuntalamiento · El Trono Hundido · La Vagoneta Quieta

**La Costa Retenida (9):** El Muro Blanco · La Playa de Nombres · El Altar de Sal · El Faro de las Velas · La Casa Atada · La Barca Varada · El Banco Doble · Acantilado de Cortinas · El Rellano de Cal

**La Herida (9):** La Puerta Sin Muro · El Círculo Colgado · La Escalera de Hojas · El Eco Quieto · El Hueco del Cuerpo · La Mesa de Dos · La Pared Raspada · La Sala del Asiento · La Sala de Aún

(*El Mirador* es parte de la sala de la Pasarela; el título que muestra el juego sigue siendo "La Pasarela de los Mensajeros" y el nombre de El Mirador se usa en el mapa y los textos.)

---

## 10. Diálogos de ejemplo de los PNJ

Máximo 4 líneas por intercambio. Los PNJ solo hablan en zonas de calma. Tuteo.

### Iria
- *Fase 1:* "Mi hermano estaba aquí. Ahora dicen que no tuve hermano." / "¿Tú no olvidas nada? Entonces sabes cómo era. Cuéntamelo."
- *Fase 2 (tras el primer objeto):* "¿Y si me lo inventé? Tú eres el único que puede decirme que no."
- *Fase 3 (si has entregado los dos):* "Telmo. Se llamaba Telmo. Ya lo puedo decir sin mirarte."
- *Fase 3 (si no):* "Me voy con el señor de la cal. Dice que allí no duele."

### Aldara
- *Fase 1:* "Cada nudo es un nombre. Si alguien lo trae de vuelta, lo deshago."
- *Fase 2 (tras el Archivo):* "Se me aflojan los nudos. Ya no sé de quién es cada uno."
- *Fase 3 (acto IV, ante el Hito):* "Te nombro: el que no olvida. No es honor. Es oficio." / "Hay un nudo sin nombre. Yo lo apreté, pero no sé por quién."
- *Tras Compartir:* "Linde. Ya está. Ya está deshecho."
- *Si callaste un nombre:* "Hay un nudo menos. No me lo has dicho. No hace falta."

### Garrán
- *Fase 1:* "El Filo no recuerda cómo cortó. Eso es lo bueno del hierro." / "Es un raspador de escriba. Alguien lo afiló para otra cosa."
- *Fase 2 (tras el Centinela):* "Las rejas del Aljibe las forjé yo. Me pagaron bien. No pregunté para qué."
- *Fase 3 (con el hierro):* "Suena. Por fin un hierro que suena. Vuelve mañana."

### Cano
- *Fase 1:* "Todo se vende, hasta lo que no recuerdas haber tenido." / "¿Una vela? No. Tengo un clavo que fue una vela. Sale más barato."
- *Fase 2:* "El carro pesa menos. Lo que no vendo, se me olvida que lo tengo."
- *Fase 3 (ante la Puerta Sin Muro):* "Me quedan cosas de gente que ya no existe. Las vendo a su nombre." / "Si buscas algo más que sentarte o soltar, el Fogón sigue encendido."

### Vael
- *Fase 1:* "No obligamos a nadie. Solo esperamos al lado." / "Ven a la cal cuando pese demasiado. Allí nadie pregunta."
- *Fase 2 (la máscara):* "Esa máscara la llevaban los que venían de noche."
- *Fase 3 (si hablas con él por Casilda):* "Lo hago por su bien. Tú también lo harías, si pesaras lo que ella."

### Hermano Gaspar
- *Fase 1:* "Yo guardé la puerta del Aljibe. Lo sé porque me lo han dicho."
- *Fase 2:* "No me pidas perdón por ellos. Pídeme que te enseñe a dejar de llevar una espada."
- *Fase 3:* "Si me ves otra vez con sello, mátame. Será que me han vuelto a convencer."

### Sabela
- *Fase 1:* "El pasillo tres está en blanco. No lo cierro: a veces vuelve." / "¿Tu nombre? No hace falta. Ya está escrito... en alguna parte."
- *Fase 2 (tras Ilara):* "Éramos tres, bajo el mismo maestro. Una se perdió copiando. El otro sella. Yo me escondo."
- *Fase 3 (con las seis Páginas):* "Lo que guardo se lo he quitado a alguien. Qué frase. Qué valiente. Y la tachó."

### Dola
- *Fase 1:* "A lo hondo no se baja: se cae. Y de ahí se sube a pulso."
- *Fase 2 (tras Magda):* "Se equivocó por ambición. Eso decía mi abuelo. Yo creo que se equivocó por oír."
- *Fase 3:* "El pico no pregunta. El pico encuentra."

### Brunel
- *Siempre:* "Dimas. Presente. Rosendo. Presente. Todos presentes. Todos." / "No me interrumpas, que pierdo la cuenta."
- *Tras Magda:* "Magda. ¿Magda? Presente. Sí. Presente."
- *Tras Compartir:* "Todos presentes. Ya he terminado. Qué silencio."

### Quiteria la Blanca
- *Fase 1:* "No te voy a pedir que dejes de sufrir. Solo que dejes de llevarlo todo tú solo." / "Yo fui como tú. Duermo mejor desde entonces."
- *Ofreciendo el sueño:* "No te lo quito. Te lo dejo en la orilla, por si lo quieres."
- *Tras el sueño:* "¿Has descansado? No hace falta que respondas. Lo veo."
- *Tras Eudora:* "Se ha ido tranquila. Eso es lo que importa. ¿Quieres un último olvido, a tu medida?"
- *Fase 3:* "Pasa, pasa. ¿Tienes hambre? A los extraños siempre se les da de comer."

### Mirena
- *Fase 1:* "Te llevo a la otra cala. No pregunto qué buscas; las aguas ya preguntan por mí."
- *Fase 2 (faro):* "Cuando el faro se apaga, la costa se queda sin nombre. Cuida el faro."
- *Fase 3:* "Los de cal me dan pena. Los de ocre, miedo. Tú, trabajo."

### Casilda
- *Fase 1:* "Aquí no se guarda nada. Pase y no recoja. (Baja la voz.) Mentira."
- *Fase 2:* "Viene todos los días. Tan amable. Me dice que sufro. Yo ya lo sabía."
- *Fase 3 (si intervienes):* "Gracias. No me lo quites. Tampoco me lo agradezcas."

### Los jefes que hablan (líneas de combate y de muerte)

- **Jacinto (inicio):** "Ya vienen. Hay que terminar la era antes de que lleguen."
- **Jacinto (muerte):** "Qué tarde se ha hecho. ¿Habéis comido?"
- **Sor Ilara (inicio):** "Esto no está en la lista. Esto no está en la lista. Esto no está en la lista."
- **Sor Ilara (muerte):** "Ya no queda nadie por copiar. ¿Y yo?"
- **Hesper (acto del ofrecimiento):** "Pasa. Aquí se te recuerda. Te daremos un lugar y un nombre."
- **Hesper (chantaje amable):** "Tu memoria no se pierde nunca. Qué desperdicio que sea solo tuya."
- **Hesper (inicio del combate):** "Un sello más. Nadie más se perderá."
- **Hesper (muerte):** "Lo intenté. ¿Lo intenté?"
- **Casimar (inicio):** "¿Se acuerda alguien de ella? ¿Alguien?"
- **Eudora (inicio):** "Todo lo que cargas, déjalo en la cal."
- **Eudora (muerte):** "Qué hermosa tarde. ¿Quién eres?" (sonríe)
- **Oda (inicio de La Última Carrera):** "Corre."
- **Magda, Maelis, el Centinela:** no hablan.

### Lo que dicen de él

1. "Dicen que no duerme. Yo digo que no sabe cómo."
2. "Llegó de noche. Se sentó junto a mis muertos y se supo todos los nombres."
3. "Ese de la máscara... lo vi en un sueño que ya no recuerdo."
4. "Si llega a la Herida, que no vuelva con lo que le dieron."
5. (Quiteria) "No te lo quito. Te lo dejo en la orilla, por si lo quieres."

---

## 11. La voz del Caminante

No habla casi nunca. Una frase por escena, nunca más de dos palabras repetidas.

| Cuándo | Línea |
|---|---|
| Lee la carta del Mirador | "Oda." |
| Vence a Jacinto | "Jacinto." |
| Vence a Magda | "Magda." |
| Al callar un nombre | "Lo callo. No lo olvido." |
| Despierta del sueño de la Costa | "Sigo aquí." |
| Sala de los Relatores | "Lo recuerdo todo. Eso no es lo mismo que saberlo." |
| Ante el Hito del Umbral (acto IV) | "Se llamaba Linde. Lo digo para que alguien más lo haya oído." |
| Ante la Sala de Aún | "No vine a salvar a nadie. Vine a que no me dejen solo con ella." |
| Final Compartir | "Me llamo Ansel." |

---

## 12. Textos de los finales

### Sellar

> Te sientas. La piedra conoce tu medida.
> Aún duerme. El mundo se queda como estaba:
> quieto, entero, sin nadie que lo cambie.

*Imagen final:* el Hito del Umbral, un nombre nuevo grabado. El Fogón, apagado.

### Soltar

> Entras en el blanco. Nada pesa.
> Aún descansa, y el mundo con ella.
> Solo tú sabes lo que se perdió.

*Imagen final:* la pizarra de Brunel, en blanco.

### Compartir

> Dices los nombres. Salen de ti como hilos.
> Aún descansa. El mundo olvidará una parte.
> Tú también. Te llamas Ansel.

*Imagen final:* el Hito del Umbral. Una niña graba un nombre. *(Si Iria no está, el nombre aparece grabado sin que nadie lo haya grabado.)*

### Relevo (epílogo)

> Alguien viene a relevar la guardia.
> La mensajera corre hasta la casa que le faltaba.
> La carta, al fin, está sobre la mesa.

*Imagen final:* la Casa Varga, con la carta de Oda sobre la mesa.

### Epílogos pequeños (una línea cada uno, solo si se cumplieron)

- **Iria:** "Telmo vuelve a tener nombre."
- **Aldara:** "El último nudo ya no está atado."
- **Brunel:** "La lista terminó. Todos presentes."
- **Casilda:** "Hay una puerta que sigue sin cerrar."
- **Sabela:** "La última página no dice nada. Y se entiende."
- **Dola:** "El pozo quedó cerrado. El pico, colgado."

---

## 13. Verificación de nombres (es / en / ca / gl)

Se revisó cada nombre propio por acepciones vulgares o escatológicas. Un cambio se hizo por riesgo en gallego y portugués.

| Nombre | Resultado |
|---|---|
| Ansel Varga, Linde, Oda Bellver, Oriol Maraver | Sin problemas. ("Pellín" se descartó por coloquial/cómico.) |
| Iria, Aldara, Telmo, Vael | Sin problemas. |
| Garrán, Cano, Gaspar, Sabela, Dola, Brunel | Sin problemas. |
| Quiteria, Mirena, Casilda, Eudora, Mateo | Sin problemas. |
| Jacinto, Eulalia, **Eloy** Ferrán | "Pau" se cambió por **Eloy**: en gallego/portugués "pau" tiene un uso vulgar. |
| Ilara, Hesper, Corvel, Maelis, Ardena, Nía | Sin problemas. Hesper recuerda a "hespérides" (poético). |
| Casimar, Áurea, Magda Soler, Rufo | Sin problemas. ("Rufo" es un adjetivo arcaico, "rojizo".) |
| Ielda, Tamar, Tomasa | Sin problemas. |
| Aurelio, Lucía, Berenguer, Dimas, Rosendo | Sin problemas. |
| Marta, Julián, Elvira, Tomás, Inés, Rubén, Ossenna, Fara | Sin problemas. |
| Íñigo, Leocadia, Tadeo, Brígida, Álvar | Sin problemas. |
| Aún, Margen, Rastro, Cascarón, Paño, Raspador, Relevo, Hondos | Sin problemas. ("Rasurar" se evitó: significa afeitar.) |
| Lugares: Último Umbral, Cinturón Yermo, Archivo, Minas del Origen, Costa Retenida, Herida, Aljibe, Cisterna, Chimenea | Sin problemas. |
