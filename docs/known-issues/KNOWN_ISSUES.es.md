# Problemas conocidos del código original

*English version: [KNOWN_ISSUES.md](KNOWN_ISSUES.md).*

Las rutinas originales de MATLAB (la carpeta `legacy/`, traducidas del programa
en Fortran) fueron la implementación de referencia de los tests de regresión.
Se quitaron del árbol de trabajo cuando el código refactorizado las reprodujo;
siguen en el historial de git bajo la etiqueta `legacy-reference`
(`git checkout legacy-reference`). Los resultados de referencia que produjeron
están en `tests/fixtures/`.

Los problemas encontrados en el código original se listan aquí con la decisión
tomada. Cuando un problema era un error evidente de programación se **corrigió
también en el código original**, y los fixtures se regeneraron con la versión
corregida (la etiqueta guarda esa versión).

Estado de cada ítem: **Corregido** (en el código original y en el nuevo),
**Resuelto** (en el código nuevo; el original conservaba el comportamiento
anterior), **Revisado** (comprobado, sin cambios) o **Aceptado** (se mantiene el
comportamiento original). No queda ningún ítem abierto.

## Corregido en el código original

| Archivo | Problema | Corrección |
|---------|----------|------------|
| `main1.m` | Líneas de prueba `a=1, b=2, c=3` al comienzo | Eliminadas |
| `main1.m` | La sección final usaba identificadores sin definir (`fid12/fid15/fid19/fid20`) y fallaba al terminar cada corrida | Cierra los identificadores de archivo que realmente se abrieron |
| `main1.m` | `ARMANS(I3)` (paréntesis) y `[...] = ini==ANSYS(...)` fallaban al activar la salida ANSYS | `ARMANS{I3}` y llamada simple |
| `BOUND.m` | `ini` solo se asignaba con `TEST == 102`, por lo que `TEST 101` fallaba | Se asigna siempre |
| `IGN012.m` | **Crítico.** La integración por diferencias centrales estaba en una función anidada `ign012` que nunca se llamaba, así que ningún nodo se movía salvo los de desplazamiento impuesto (velocidades y aceleraciones exactamente 0) | Se agregó la llamada `ign012;` |
| `IGN012.m` | La aceleración en y usaba `V(2,I)` (un escalar sobrante del bucle de nodos) en lugar de `V(2,:)` (ítem 11) | `V(2,:)` |
| `BOUND.m` | `TEST 101`: paréntesis mal puesto en el apoyo del extremo derecho (ítems 3 y 19) | `(M1 - 0.51)*LCO` |
| `CALOAD.m` | `TEST 102`: condición incorrecta, el segundo punto de carga nunca se cargaba (ítem 15) | `LOGIC2 && LOGIC3` |

## Ítems

1. **`ENERG2.m`, líneas 172-174: la energía cinética no se suma.** `ENCN` era un
   vector por nodo en lugar de un escalar. **Resuelto.** El código nuevo da las
   dos cosas: la energía cinética de cada nodo (`results.final.kineticEnergy`,
   y `results.snapshots.kineticEnergy` en los pasos de snapshot) y el total del
   modelo (`results.energy.kinetic`).
2. **`WRIENE.m`, línea 35: formato inválido `%25.12` (falta la `e`).** `LET.ENE`
   quedaba truncado y desordenado. **Resuelto.** El historial de energías forma
   parte del archivo de resultados (`results.energy`); ya no hay archivo de
   texto.
3. **`BOUND.m`, `TEST == 101`: precedencia de operadores.** `mask2` usaba
   `U0 > (M1 - 0.51*LCO)` en lugar de `(M1 - 0.51)*LCO` y no seleccionaba
   ningún nodo. **Corregido.** La columna de nodos centrales del extremo
   derecho es la cargada, y ahora está fija en x (es el mismo error que el
   ítem 19).
4. **`CABAR.m` / `ENERG2.m`: barra rastreada fija en 7014.** **Resuelto**:
   `params.trackedBar`.
5. **`TEST == 102`: geometría escrita en unidades de módulo** (`33.49`, `4.51`,
   `50.5`...), por lo que el ensayo solo funcionaba con `M >= ~70`.
   **Resuelto**: `FourPointBending(supportPosition=, loadPosition=)`, con los
   valores originales por defecto, y un error cuando una posición no coincide
   con ningún nodo.
6. **`IMPERF.m`: `LABELN` se pone en 1 y enseguida en 0,** de modo que la
   perturbación de la malla nunca se aplica y la semilla no tiene efecto.
   **Resuelto** en el código nuevo: el usuario la define con un solo número,
   `meshPerturbation`: 0 (el valor por defecto) deja el reticulado regular y
   cualquier valor positivo activa la perturbación con ese coeficiente de
   variación (por ejemplo `0.02` para el 2 % de la longitud del módulo). Ya no
   es un indicador que se edita en el código. La comprobación de estabilidad
   del paso de tiempo usa las longitudes reales (perturbadas) de las barras.
7. **`CALCOEV.m`: el coeficiente de variación nunca se guarda** (`COEF` en lugar
   de `COEV`). **Resuelto**: `results.barProps.criticalStrainCv` y
   `results.material`, que además guarda E, Gf, los coeficientes del reticulado
   y la deformación crítica media, mínima y máxima (lo que imprimía `WRICON`).
8. **`DEFEP.m`: verificación de seguridad sin uso** (`KR < 1.01`). **Resuelto**:
   `buildBarProperties` lanza `ldem:material:criticalLengthTooShort`.
9. **El campo aleatorio es obligatorio.** **Resuelto**: `params.randomFieldFile`
   es opcional (vacío = todos los multiplicadores valen 1).
10. **La prealocación `INT = 168000`, `INB = 2300000`** limitaba el tamaño de la
    malla. **Resuelto**: todos los tamaños se deducen del número de módulos.
11. **`ign012`: la aceleración en y usa un índice incorrecto.** **Corregido**
    en el código original y en el nuevo (`ldem.solver.integrateStep`); el test de
    regresión ahora compara las tres componentes.
12. **`ign012`: la energía de amortiguamiento mezcla vectores y escalares.**
    **Resuelto**: `state.dampingEnergy` es un escalar. (Los casos de referencia
    tienen `CON = 0`, donde las dos definiciones coinciden.)
13. **`ENERG2.m` / `IGN012.m`: `KL` siempre vale 2.** La condición `B > NBA` que
    daría `KL = 4` a las diagonales nunca se cumple porque
    `NBA = NBS = NBT`. **Revisado.** El tipo de barra se conoce por cómo se
    construye el modelo (arista de la malla, barra entre centros o diagonal,
    `mesh.barType`), pero `KL = 2` es correcto para todos los tipos: da la
    energía de la barra `E*deformación^2*L/2`, coherente con la ley de fuerza.
    Con `KL = 4` en las diagonales el balance de energía se desviaría 13.5 %
    (viga elástica; las diagonales guardan el 36 % de la energía elástica) y
    4.6 % (viga con daño), contra 0.05-0.1 % con `KL = 2`.
14. **`ENEX` (trabajo externo) nunca se calcula.** **Resuelto**:
    `energy.external` es el trabajo realizado sobre los grados de libertad que
    el escenario mantiene fijos y `energy.balance = external - internal`. El
    balance es menor al 1 % del trabajo externo (0.01-0.5 % en los tests de
    referencia), también con ablandamiento y rotura (tests en `TestSimulate` y
    `TestSolver`).
15. **`CALOAD.m`, `TEST == 102`: el segundo punto de carga nunca se carga.** La
    condición `LOGIC1 && LOGIC2` no puede cumplirse. **Corregido**: los dos
    puntos de carga se mueven (`LOGIC2 && LOGIC3`).
16. **Un `TDAF` menor que medio paso de tiempo nunca cambia el amortiguamiento.**
    **Aceptado** (`ldem.solver.dampingCoefficient` lo reproduce).
17. **Convención de signo de `TEST == 101`.** Los nodos cargados se mueven a
    `x0 - VF2*TIME`, lo que comprime el prisma para `VF2 > 0` aunque el
    comentario dice "tracción". **Aceptado**: misma convención, documentada en
    `UniaxialTension`; usar un `loadingVelocity` negativo para traccionar.
18. **`ANSYS.m`: tres problemas en los archivos de macro.** (a) La línea
    `ET,IFILE,4` es un comando de ANSYS inválido (un descuido por `ET,3,4`);
    (b) las restricciones (`D,nodo,UX`...) solo se escriben para
    `TEST == 102`; (c) la sección de "cargas aplicadas" escribe
    `F,nodo,Fx,-10` para nodos elegidos con coordenadas fijas en el código
    (`50.5*LCO`...) que no coinciden con ningún nodo de la viga. **Resuelto.**
    `ldem.io.exportAnsys` escribe `ET,3,4` (a) y las restricciones de valor
    cero de todos los escenarios (b). Para (c) la sección de cargas lista el
    desplazamiento impuesto a los nodos cargados como `D,nodo,UY,valor`,
    medido desde su posición inicial (nada en el tiempo cero). ANSYS conserva
    la última restricción de cada grado de libertad, así que estas líneas
    reemplazan a las de valor cero. Las coordenadas de los nodos del archivo
    siguen siendo las posiciones actuales, por lo que el archivo muestra el
    estado de la simulación; no es un reinicio desde el reticulado sin
    deformar.
19. **`CALOAD.m`, `TEST == 101`: los nodos cargados no estaban fijos** (el mismo
    error que el ítem 3): su posición se sobrescribía en cada paso y luego se
    movían libremente, así que ninguna fuerza hacía trabajo sobre ellos y el
    balance de energía no podía cerrar. **Corregido** junto con el ítem 3.
