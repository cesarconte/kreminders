# Recordatorios (kreminders)

Réplica nativa y fiel de **Apple Reminders** de macOS Golden Gate / Sequoia para **KDE Plasma 6** en **Wayland**.

## Características

* **Diseño 1:1 con macOS Reminders**:
  * Barra lateral con efecto translúcido.
  * Tarjetas de **Listas Inteligentes (Smart Lists)** en cuadrícula 2x2:
    * 🔵 **Hoy (Today)**: Recordatorios programados para la fecha actual con badge azul.
    * 🔴 **Programados (Scheduled)**: Recordatorios con fecha/hora límite.
    * 🟣 **Todos (All)**: Totalidad de tareas pendientes en todas las listas.
    * 🟠 **Con marca (Flagged)**: Tareas destacadas con bandera.
    * 🟢 **Completadas (Completed)**: Historial de tareas finalizadas.
  * **Listas Personalizadas**: Creación de listas temáticas con selector de color Apple e icono.
  * **Panel de Tareas**:
    * Checkbox circular interactivo con animación de completado y tachado suave.
    * Gestión de títulos, notas explicativas, fechas de vencimiento y prioridad.
    * Búsqueda en tiempo real.
* **Integración con KDE Plasma 6**:
  * Notificaciones de escritorio nativas cuando vence un recordatorio.
  * Persistencia local automática en formato JSON en `~/.local/share/kreminders/reminders.json`.
  * Integración con Wayland y atajos de teclado.

## Compilación e Instalación

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
cmake --install build
```
