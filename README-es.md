# Docker Self Discover

---

# 1. Introducción

## ¿Qué es Docker Self Discover?

Docker Self Discover es un proyecto diseñado para facilitar la configuración de un clúster de Docker Swarm en entornos donde hay múltiples nodos workers. Este sistema automatiza el proceso de descubrimiento de nodos en la red local, eliminando la necesidad de conocer las direcciones IP de cada nodo de antemano. El objetivo es simplificar la implementación de Docker Swarm en proyectos distribuidos, mejorando la escalabilidad y la eficiencia.

## ¿Para qué sirve?

Docker Self Discover permite a los nodos workers descubrirse y unirse automáticamente a un clúster Docker Swarm. Una vez configurado, cualquier nodo worker que se agregue al sistema será capaz de encontrar y unirse al clúster sin intervención manual, lo que reduce el tiempo y el esfuerzo necesarios para configurar un entorno de Swarm en una red de múltiples dispositivos.

## Beneficios y Casos de Uso

### Beneficios:
- **Automatización del descubrimiento de nodos**: Los nodos pueden descubrirse automáticamente en la misma red sin necesidad de configuración manual.
- **Facilidad de instalación**: El proceso de instalación es sencillo y está automatizado mediante scripts.
- **Escalabilidad**: Ideal para entornos donde se añaden nuevos nodos frecuentemente.
- **Compatibilidad con arquitecturas ARM**: Compatible con dispositivos como Raspberry Pi, lo que lo hace ideal para proyectos en hardware ligero.
- **Seguridad**: Se utiliza un sistema de autenticación mediante contraseña para proteger la comunicación entre nodos.

### Casos de Uso:
- **Redes de microservicios**: Docker Self Discover facilita la creación y gestión de redes de microservicios que requieren un clúster de Docker Swarm para la distribución de cargas de trabajo.
- **IoT y dispositivos distribuidos**: Ideal para entornos con múltiples dispositivos, como Raspberry Pi, que necesitan conectarse a un clúster Docker sin intervención manual.
- **Infraestructura escalable**: En proyectos donde se requiere agregar nodos workers de manera frecuente, Docker Self Discover simplifica la configuración.

---

# 2. Requisitos

Antes de comenzar con la configuración de Docker Self Discover, asegúrate de tener los siguientes requisitos tanto para el sistema como para las herramientas necesarias.

## Requisitos del Sistema

- **Sistema operativo**: Linux (Ubuntu, Debian, Raspbian, o cualquier distribución basada en Debian).
- **Arquitectura**: x86_64 o ARM (compatible con Raspberry Pi y otros dispositivos similares).
- **Docker**: Debes tener Docker instalado en cada nodo que se unirá al clúster. Docker Self Discover funciona específicamente con Docker Swarm.
- **Red Local**: Todos los nodos workers deben estar en la misma red local para que puedan descubrirse entre sí.
- **Conexión a Internet**: Para la descarga de dependencias y la configuración inicial.

## Herramientas Requeridas

1. **Miniconda**: Para gestionar los entornos virtuales de Python, especialmente en plataformas como Raspberry Pi donde instalar Anaconda podría no ser viable debido al consumo de recursos.
   - Se instalará automáticamente si no está presente.

2. **Nmap**: Herramienta de escaneo de redes utilizada para descubrir los dispositivos en la misma red local.
   - Debe estar instalado en el sistema.

3. **Curl**: Herramienta de línea de comandos utilizada para realizar solicitudes HTTP desde el nodo worker a otros nodos en la red.
   - También se instalará automáticamente si no está presente.

4. **Python 3.9**: Se recomienda tener Python 3.9 o superior. El proyecto utiliza Conda para gestionar el entorno virtual.
   - Conda configurará el entorno automáticamente si no está presente.

## Requisitos de Hardware

- **Nodo principal** (máster): Al menos 1 nodo debe ser configurado como nodo principal para iniciar el clúster Docker Swarm.
- **Nodos workers**: Pueden ser tanto servidores físicos como dispositivos como Raspberry Pi u otros sistemas ligeros. Cada uno de estos nodos debe ser capaz de ejecutar Docker y tener acceso a la red.

## Configuración de Red

- Asegúrate de que los nodos puedan comunicarse entre sí sin restricciones de firewall u otras configuraciones que impidan el tráfico en el puerto de Docker Swarm (predeterminado es el puerto TCP 2377).

---

# 3. Instalación

Este apartado te guiará a través de los pasos necesarios para instalar Docker Self Discover en tus nodos de forma automática. El proceso se realiza a través de dos scripts: `install.sh` y `setup.sh`. El script `install.sh` detecta el tipo de nodo y redirige a `setup.sh`, que se encargará de realizar la instalación y configuración automáticamente, solicitando información solo cuando sea necesario.

## 3.1. Instalación Automática en el Nodo Worker

1. **Ejecutar el script de instalación**

   En el nodo worker, simplemente ejecuta el script `install.sh`. Este script preguntará el tipo de nodo y redirigirá automáticamente a `setup.sh` para la instalación.

   ```bash
   sudo bash install.sh
   ```

2. **Proceso de instalación automatizado**

   El script `install.sh` realizará lo siguiente automáticamente:

   - Preguntará el tipo de nodo (worker o master) y redirigirá al script correspondiente.
   - Ejecutará `setup.sh`, que configurará el sistema, instalará las dependencias necesarias y pedirá la información requerida.
   
3. **Configuración de la contraseña**

   Durante la ejecución del script `setup.sh`, se te pedirá que ingreses una contraseña personalizada para el nodo. Esta contraseña será guardada internamente en el directorio de trabajo, y será utilizada más adelante por el script `search-parent.sh` para la comunicación segura entre nodos.

   ```bash
   Please enter a custom password for this node:
   ```

4. **Finalización de la instalación**

   El script completará la instalación de todas las dependencias necesarias (como Conda, Docker, y Docker Compose) y configurará un servicio systemd para ejecutar el servicio cada vez que el nodo se encienda y se conecte a la red. Cuando el proceso termine, podrás continuar configurando otros nodos worker si es necesario.

   ```bash
   Configuration finished on this worker node. You can continue setting up other worker nodes.
   ```

Ahora, el proceso está completamente automatizado y solo requiere que ingreses la contraseña durante la ejecución del script.

> **⚠️ Nota Importante:**
>
> Solo los nodos que hayan sido agregados a la **whitelist** de la API pueden unirse automáticamente al clúster. Asegúrate de que el nodo esté en la lista antes de intentar unirse.

---

# 4. API - Nodo Manager

Esta aplicación Flask expone varios endpoints que interactúan con Docker Swarm y gestionan dispositivos que se unen a la red y la interacción con una lista blanca de direcciones MAC. Los endpoints proporcionan funcionalidades para validar tokens, agregar/eliminar direcciones MAC de la lista blanca y actualizar los tokens de unión de Docker.

---

#### 1. **POST /network/<string:mac>/join**

- **Descripción**: Este endpoint maneja una solicitud de un dispositivo para unirse a la red. Valida el token proporcionado y la dirección MAC, y luego devuelve un token de unión de Docker y la dirección IP si la solicitud es exitosa.
  
- **Parámetros**:
  - `mac` (str): La dirección MAC del dispositivo que intenta unirse a la red.

- **Cuerpo del JSON en la Solicitud**:
  ```json
  {
    "token": "tu_token",
    "req_ip": "ip_del_dispositivo"
  }
  ```

- **Respuesta**:
  - **Éxito**: Devuelve el token de unión de Docker y la dirección IP del dispositivo.
  ```json
  {
    "token": "docker_token",
    "ip": "ip_del_dispositivo:puerto"
  }
  ```
  - **Error**: Devuelve mensajes de error si la validación falla.
  ```json
  {
    "error": "Mensaje de error"
  }
  ```

---

#### 2. **POST /network/whitelist/<string:mac>/add**

- **Descripción**: Este endpoint agrega una dirección MAC a la lista blanca de la red. Valida el token y el formato de la dirección MAC.

- **Parámetros**:
  - `mac` (str): La dirección MAC que se va a agregar a la lista blanca.

- **Cuerpo del JSON en la Solicitud**:
  ```json
  {
    "token": "tu_token"
  }
  ```

- **Respuesta**:
  - **Éxito**: Un mensaje confirmando que la dirección MAC se agregó a la lista blanca.
  ```json
  {
    "message": "Dirección MAC agregada a la lista blanca exitosamente"
  }
  ```
  - **Error**: Devuelve mensajes de error si la validación falla.
  ```json
  {
    "error": "Mensaje de error"
  }
  ```

---

#### 3. **POST /network/whitelist/<string:mac>/remove**

- **Descripción**: Este endpoint elimina una dirección MAC de la lista blanca de la red. También valida el token y el formato de la dirección MAC.

- **Parámetros**:
  - `mac` (str): La dirección MAC que se va a eliminar de la lista blanca.

- **Cuerpo del JSON en la Solicitud**:
  ```json
  {
    "token": "tu_token"
  }
  ```

- **Respuesta**:
  - **Éxito**: Un mensaje confirmando que la dirección MAC se eliminó de la lista blanca.
  ```json
  {
    "message": "Dirección MAC eliminada de la lista blanca exitosamente"
  }
  ```
  - **Error**: Devuelve mensajes de error si la validación falla.
  ```json
  {
    "error": "Mensaje de error"
  }
  ```

---

#### 4. **POST /network/whitelist/set**

- **Descripción**: Este endpoint establece la lista blanca con una nueva lista de direcciones MAC. Valida el token proporcionado y el formato de las direcciones MAC.

- **Cuerpo del JSON en la Solicitud**:
  ```json
  {
    "token": "tu_token",
    "whitelist": [
      "mac_direccion_1",
      "mac_direccion_2",
      "mac_direccion_3"
    ]
  }
  ```

- **Respuesta**:
  - **Éxito**: Un mensaje confirmando que la lista blanca se actualizó exitosamente.
  ```json
  {
    "message": "Lista blanca actualizada exitosamente"
  }
  ```
  - **Error**: Devuelve mensajes de error si la validación falla.
  ```json
  {
    "error": "Mensaje de error"
  }
  ```

---

#### 5. **PUT /network/update/<string:join_token>**

- **Descripción**: Este endpoint actualiza el token de unión de Docker almacenado en el archivo `join.txt`. Requiere que se proporcione el nuevo token de unión.

- **Parámetros**:
  - `join_token` (str): El nuevo token de unión de Docker.

- **Cuerpo del JSON en la Solicitud**:
  - Ninguno requerido. El token se pasa en la URL.

- **Respuesta**:
  - **Éxito**: Un mensaje confirmando que el token de unión de Docker se actualizó exitosamente.
  ```json
  {
    "message": "Token de unión de Docker actualizado exitosamente"
  }
  ```
  - **Error**: Devuelve mensajes de error si hay un problema con el archivo o la solicitud.
  ```json
  {
    "error": "Mensaje de error"
  }
  ```

---

#### 6. **PUT /network/update/token**

- **Descripción**: Este endpoint actualiza el token principal almacenado en el archivo `token.txt`. Requiere tanto el token antiguo como el nuevo token.

- **Cuerpo del JSON en la Solicitud**:
  ```json
  {
    "old_token": "token_antiguo",
    "new_token": "nuevo_token"
  }
  ```

- **Respuesta**:
  - **Éxito**: Un mensaje confirmando que el token principal se actualizó exitosamente.
  ```json
  {
    "message": "Token principal actualizado exitosamente"
  }
  ```
  - **Error**: Devuelve mensajes de error si la validación falla o el archivo no se encuentra.
  ```json
  {
    "error": "Mensaje de error"
  }
  ```

---

### **Respuestas de Error Comunes**

- **Formato de dirección MAC inválido**: Si la dirección MAC no está en el formato correcto (por ejemplo, `XX:XX:XX:XX:XX:XX`), se devolverá un mensaje de error.

  Ejemplo:
  ```json
  {
    "error": "Formato de dirección MAC inválido"
  }
  ```

- **Token inválido**: Si el token proporcionado no coincide con el token configurado en `token.txt`, se devolverá un mensaje de error.

  Ejemplo:
  ```json
  {
    "error": "Token inválido"
  }
  ```

- **Archivo no encontrado**: Si el archivo esperado (por ejemplo, `token.txt`, `join.txt`, `whitelist.txt`) no se encuentra en el servidor, se devolverá un error de "Archivo no encontrado".

  Ejemplo:
  ```json
  {
    "error": "Archivo no encontrado"
  }
  ```

---

# 5. Resolución de problemas

A continuación se describen algunos problemas comunes y cómo solucionarlos.

## 4.1. El servicio `search-parent.service` no está activo

Si el servicio no está activo, revisa los logs del servicio para ver qué ocurrió:

```bash
sudo journalctl -u search-parent.service
```

Esto te proporcionará información detallada sobre posibles errores en el script o problemas de configuración. Asegúrate de que el archivo `password.txt` esté presente y que la contraseña esté correctamente configurada.

## 4.2. Error al unirse al clúster Docker

Si un nodo no puede unirse al clúster Docker, asegúrate de que:

- El token de acceso esté correctamente configurado.
- La red local esté correctamente configurada y los nodos puedan comunicarse entre sí.
- El puerto 2377 (utilizado por Docker Swarm para la comunicación entre nodos) esté abierto en el firewall de todos los nodos.

---

# 6. Mantenimiento

Para mantener Docker Self Discover actualizado y funcional, realiza los siguientes pasos regularmente:

1. **Actualizar el sistema y dependencias**: Asegúrate de que el sistema operativo y las dependencias de Docker, Docker Compose, y Miniconda estén actualizados.

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Revisar los logs del servicio**: Revisa regularmente los logs del servicio `search-parent.service` para asegurarte de que no haya errores o problemas que requieran intervención.

   ```bash
   sudo journalctl -u search-parent.service
   ```

3. **Reiniciar el servicio después de cambios**: Si realizas modificaciones en la configuración de los nodos o en los scripts, reinicia el servicio para aplicar los cambios:

   ```bash
   sudo systemctl restart search-parent.service
   ```

---

# 7. Contribuir

Si deseas contribuir al proyecto Docker Self Discover, sigue estos pasos:

1. Realiza un **fork** del repositorio en GitHub.
2. Haz tus cambios y asegúrate de que el código funcione correctamente.
3. Envía un **pull request** describiendo las modificaciones realizadas.

Asegúrate de seguir las buenas prácticas de codificación y realizar pruebas antes de realizar un pull request.

### **También puedes hacer issues si encuentras algun nuevo funcionamiento que deberia ser implementado.**

---

# 8. ToDo:

- Agregar soporte para otras arquitecturas
- Validar recorte de log
- API - Master node (node management features)
- API - Worker Node 
- Web interface
- Dashboard Manager  
- Dashboard Worker  