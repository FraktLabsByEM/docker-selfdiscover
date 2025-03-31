# Docker Self-discover

### Descripción General

Este proyecto tiene como objetivo facilitar la integración automática de dispositivos a una red, validando su acceso a través de un servidor y realizando tareas de configuración en segundo plano. Está compuesto por dos partes: **Master** y **Worker**. El **Master** gestiona el servidor y la configuración, mientras que el **Worker** busca dispositivos en la red y los integra al sistema de manera automática.

### Componentes Principales

1. **Listener** (Master)
   - **listener.py**: Un servidor Flask que gestiona las solicitudes de dispositivos que intentan unirse a la red. Valida las solicitudes con un token y MAC address, y permite la actualización de los tokens y la lista blanca.
   - **init.sh**: Script de configuración del entorno y ejecución del servidor `listener.py` en un entorno Conda.
   - **setup-master.sh**: Script para configurar y ejecutar el servicio del servidor `listener.py` al inicio del sistema.

2. **Search Parent** (Worker)
   - **search-parent.sh**: Script que escanea la red en busca de dispositivos y realiza solicitudes a un servidor para integrar esos dispositivos a la red.
   - **setup-worker.sh**: Script para configurar y ejecutar el servicio que ejecuta `search-parent.sh` al inicio del sistema.

---

## Instalación y Configuración

### 1. Instalación de `Listener` (Master)

#### Paso 1: Preparar el Entorno
- Asegúrate de tener Anaconda y Python instalados. El servidor `listener.py` utiliza un entorno Conda específico.

#### Paso 2: Activar el Entorno
Ejecuta el script `init.sh` para activar el entorno Conda y ejecutar el servidor:

```bash
bash init.sh
```

#### Paso 3: Configuración del Servicio
Para asegurarte de que el servidor se ejecute al iniciar el sistema, puedes ejecutar el script `setup-master.sh`:

```bash
bash setup-master.sh
```

Este script realizará lo siguiente:
- Configurará permisos de ejecución para `init.sh`.
- Creará un servicio `systemd` que ejecutará el servidor al inicio del sistema.
- Iniciará el servicio y garantizará que se ejecute automáticamente en cada arranque.

---

### 2. Instalación de `Search Parent` (Worker)

#### Paso 1: Verificación de Dependencias
El script `search-parent.sh` depende de herramientas de red como `nmap` y `curl`. Asegúrate de tener estas herramientas instaladas en el sistema.

#### Paso 2: Configuración del Servicio
Para convertir `search-parent.sh` en un servicio que se ejecute al inicio del sistema, ejecuta el script `setup-worker.sh`:

```bash
bash setup-worker.sh
```

Este script realiza las siguientes acciones:
- Da permisos de ejecución a `search-parent.sh`.
- Crea un servicio `systemd` para ejecutar `search-parent.sh` automáticamente al inicio del sistema.
- Recarga el `daemon` de `systemd` y habilita el servicio.

---

## Detalles Técnicos

### `listener.py` (Servidor Flask)
El servidor `listener.py` expone varias rutas para gestionar las solicitudes de dispositivos en la red:

1. **POST `/network/<mac>/join`**: Permite a un dispositivo unirse a la red si se proporciona un token válido y un MAC address correcto. El servidor devuelve un token de unión de Docker.
2. **POST `/network/whitelist/<mac>/add`**: Añade una dirección MAC a la lista blanca.
3. **POST `/network/whitelist/<mac>/remove`**: Elimina una dirección MAC de la lista blanca.
4. **POST `/network/whitelist/set`**: Establece una nueva lista blanca de direcciones MAC.
5. **PUT `/network/update/<join_token>`**: Actualiza el token de unión de Docker.
6. **PUT `/network/update/token`**: Actualiza el token de autenticación principal.

### `search-parent.sh` (Worker)
El script `search-parent.sh` realiza un escaneo de dispositivos en la red local utilizando `nmap`, y envía solicitudes POST a los dispositivos encontrados para intentar integrarlos en la red utilizando el servidor `listener.py`.

1. **Escaneo de red**: Utiliza `nmap` para obtener una lista de dispositivos en la misma subred.
2. **Solicitud POST**: Por cada dispositivo encontrado, realiza una solicitud POST al servidor con el token de autenticación y la dirección IP del dispositivo.

---

## Uso Comercial

Este proyecto está diseñado para ser utilizado en entornos de redes automatizadas donde se necesite integrar dispositivos a la red de manera transparente y sin intervención manual. Algunas aplicaciones comerciales pueden incluir:

- **Redes IoT**: Automatización de la integración de dispositivos en redes locales para soluciones de Internet de las Cosas (IoT).
- **Administración de Redes Empresariales**: Facilitando la gestión de redes corporativas al automatizar el proceso de integración de dispositivos.
- **Sistemas de Seguridad**: Verificación automática de dispositivos que se conectan a la red, lo que aumenta la seguridad de la red.

---

## Contribuciones

Las contribuciones son bienvenidas. Si deseas mejorar este proyecto, por favor sigue estos pasos:

1. Forkea este repositorio.
2. Crea una rama para tu nueva característica.
3. Realiza tus cambios y asegúrate de que las pruebas pasen.
4. Haz un pull request detallando los cambios que has realizado.

---

## Licencia

Este proyecto está licenciado bajo la Licencia MIT.

---