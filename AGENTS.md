# Reglas Globales de Desarrollo - Ecosistema CachyOS / Kity / CachyOS.UI

## 1. Política Estricta de Instalación: ÚNICAMENTE `/usr`

> [!IMPORTANT]
> **ESTÁ ESTRICTAMENTE PROHIBIDO duplicar instalaciones en `~/.local`**.
> Todos los proyectos del ecosistema (`cachyos-ui`, `kity`, `kcm-kity`, `audiotube-extended`, etc.) se instalan **ÚNICAMENTE en `/usr`**.

- **Comando de instalación estándar**:
  ```bash
  sudo -n cmake --install build --prefix /usr
  ```
- **Prohibido**:
  - `cmake --install build --prefix ~/.local`
  - Copiar binarios, plasmoides, librerías `.so`, archivos `.desktop` o iconos a `~/.local`.
- **Razón**: Evitar conflictos de versiones, duplicidades innecesarias y sombreado (*shadowing*) de librerías en KDE Plasma 6 y CachyOS.

---

## 2. Protocolo Universal de Pre-Verificación QML (Tolerancia Cero a Fallos de Carga)

> [!CAUTION]
> **ESTÁ TERMINANTEMENTE PROHIBIDO dar por finalizada una tarea sin verificar previamente en tiempo de ejecución que el motor QML carga sin errores**.

Cada vez que se añadan o modifiquen archivos QML o componentes de `CachyOS.UI`:

1. **Verificación de Tipos y Propiedades**:
   - Nunca inventar nombres de componentes o propiedades asumidas. Verificar siempre su existencia y firma en los archivos fuente (`cachyos-ui/src/controls/`, `CachyPalette.qml`, `CachyTheme.qml`).
2. **Ciclo Obligatorio de Verificación en Ejecución**:
   - Tras compilar e instalar en `/usr`, ejecutar siempre un ciclo de prueba con el binario correspondiente:
     - Si se modificó una aplicación concreta (ej. `audiotube`):
       ```bash
       timeout 2s audiotube
       ```
     - Si se modificó la librería `cachyos-ui` de forma general:
       ```bash
       timeout 2s cachyos-ui-gallery
       ```
3. **Criterio de Aceptación Estricto**:
   - La tarea solo se considera lista si la salida de la terminal está **100% limpia** de los siguientes errores críticos de QML:
     - `QQmlApplicationEngine failed to load component`
     - `Type ... unavailable`
     - `... is not a type`
     - `Cannot assign to non-existent property`
   - Si aparece cualquiera de estos errores, debe corregirse y verificarse de nuevo antes de responder al usuario.
