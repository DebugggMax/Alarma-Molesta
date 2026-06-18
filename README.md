#  Despertador Inteligente (Object Detection Alarm)

Una aplicación móvil desarrollada en Flutter que te obliga a levantarte de la cama. Para apagar la alarma, el usuario debe enfocar con la cámara de su dispositivo un objeto específico (como una "Silla" o una "Taza"). 

La aplicación utiliza Inteligencia Artificial (Google ML Kit) ejecutándose de forma 100% local (offline) para analizar el video en tiempo real y verificar si el objeto enfocado es el correcto.

##  Características Principales (MVP)
* **100% Offline:** El reconocimiento de imágenes se procesa en el dispositivo, sin depender de internet.
* **Detección en Tiempo Real:** No requiere tomar una foto estática; escanea los cuadros de video en vivo.
* **Sistema de Alarmas:** Programación de hora nativa con reproducción de audio continua.

##  Tecnologías y Librerías
* **Framework:** Flutter (Dart)
* **Machine Learning:** `google_mlkit_image_labeling`
* **Cámara:** `camera`
* **Audio:** `audioplayers` o `just_audio`
* **Gestor de Alarmas:** `android_alarm_manager_plus` (o equivalente)

##  Estructura del Proyecto
El código base sigue una arquitectura simple basada en la separación de responsabilidades:
* `lib/models/`: Estructuras de datos (Ej. `AlarmModel`).
* `lib/screens/`: Interfaz de usuario visible (UI).
* `lib/services/`: Lógica pesada (Cámara, ML Kit, Audio).
* `lib/utils/`: Constantes y helpers globales.

##  Instrucciones de Instalación
1. Clona este repositorio.
2. Ejecuta `flutter pub get` en la terminal para instalar las dependencias.
3. Conecta un dispositivo físico (recomendado para probar la cámara y alarmas reales).
4. Ejecuta `flutter run`.