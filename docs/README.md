# Monitorización de métricas

En este proyecto podemos ver unas soluciones de monitorización de métricas mediante el uso de Grafana.
En el ejemplo las métricas son solo de sistema (equipos o contenedores). Aunque no se incluyen metricas de aplicaciones u otras fuentes,
las herramientas empleadas (Prometheus e InfluxDB) permiten recopilar métricas de cualquier fuente preparada para ello.

## Flujo de datos

![alt:Esquema_del_Sistema](docs/Esquema_Metrics-Monitor.png)

Como vemos en el esquema de este ejemplo, el sistema se puede considerar en tres capas:

1) Captura de mediciones

2) Recopilación de datos. En estos casos las herramientas permiten realizar análisis e incluso generar alarmas o graficas

3) Representación gráfica. La solución presentada es Grafana por su facilidad de configuración y el amplio catálogo de Dashboards existentes

### Captura de métricas

**Node Exporter** Aunque es posible instalarlo en el sistema se empleará contenedores con privilegios para simplificar el despliegue.

**cAdvisor** En este caso, la aplicación desarrollada por Google prioriza la monitorización de contenedores. Esta aplicación además
permite la consulta de forma directa de los datos con una sencilla interfaz gráfica, en el mismo puerto donde se exponen las métricas.

**Telegraf** Desarrollado por InfluxData, es el complemento perfecto para su base de datos de series temporales (InfluxDB). Dispone de
plugins y facilidades de configuración para recoger datos de diversas fuentes, incluso de Prometheus.

### Recopilación de datos

Para recoger los datos de las diversas fuentes, empleamos dos opciones:

1) **Prometheus**: nos permite leer los datos que han sido recopilados por las aplicaciones. Es prometheus quien realiza la solicitud de datos mediante HTTP a las fuentes. Los datos recogidos por Prometheus están en el formato estándar de facto del mismo nombre (Prometheus). 
Prometheus expone dichos datos para que sean recogidos a su vez por otras herramientas, como en nuestro caso Grafana. Actua por tanto de concentrador.

2) **InfluxDB** Esta base de datos de series temporales permite la entrada de datos de muy diversos y variados formatos. Los almacena y permite su acceso por otras herramientas. Esta aplición también es capaz de analizar los datos, realizar búsquedas y presentar gráficas, todo ello a través de su interfaz gráfico web.

### Representación gráfica

La aplicación escogida en Grafana. Es una herramienta muy potente que permite leer datos de varias fuentes (En nuestro ejemplo Prometheus y InfluxDB), exporar los datos y realizar impresionantes representaciones gráficas de los datos. Contamos con una gran colección de paneles preconfigurados en función de la fuente de datos. En el proyecto se incluyen dichos dashboards en ficheros .json que pueden ser importados desde la interfaz gráfica.

## Parametrización

En la puesta en marcha usaremos los ficheros gen-certs.sh si no disponemos de certificados y set-env.sh para preparar adecuadamente los directorios.

### Captura de datos

La captura de datos se realiza en este ejemplo por tres aplicaciones diferentes:

1) **Node-Exporter** mediante el siguiente fichero **docker-compose.yml** podemos ejecutar un servicio que captura datos del nodo y los expone para ser recopilados por otra aplicación. En el ejemplo no se ha incluido para simplificar el contenido del proyecto.

```yaml
---
version: '3.8'

services:
  node_exporter:
    image: quay.io/prometheus/node-exporter:latest
    container_name: node_exporter
    command:
      - '--path.rootfs=/host'
    network_mode: host
    pid: host
    restart: unless-stopped
    volumes:
      - '/:/host:ro,rslave'
```
Este contenedor no requiere vincular puertos, ya que tiene privilegios para dejar expuesto en el puerto **9100** las métricas recogidas.

2) **cAdvisor** es un contenedor más del stack generado por el docker-compose que expone en el puerto 8080 y en el path /metrics los datos recogidos del sistema y los contenedores. Se exponen en formato Prometheus.

Además, en el ejemplo se ha configurado para usar el servicio **redis** que nos permite almacenar en memoria las métricas sin usar disco y  durante el tiempo configurado.

También se ha incluido la configuración de las alertas, quedando pendiente la configuración de Alertmanager.

3) **Telegraf** de forma similar a Node Exporter, mediante un fichero `docker-compose.yml` y otro fichero de configuración `telegraf.conf` podemos ejecutar un servicio que captura datos del nodo. A diferencia de Node Exporter los datos son remitidos a la salida configurada en el fichero de configuración. En el fichero de configuración (`./datos/telegraf/config/telegraf.conf`) debemos revisar los siguientes apartados:

* `[[outputs.influxdb_v2]]`: Revisaremos y adecuaremos los valores: **urls**, **token**, **organization** y **bucket** que deben coincider con los configurados en la base de datos InfluxDB.

* Revisaremos y los apartados `[[inputs.cpu]]`, `[[inputs.disk]]` y `[[inputs.diskio]]`

* Podríamos incluso usar el apartado `[[inputs.prometheus]]` configurando el campo `urls` para recopilar los datos de Node Exporter y cAdvisor.

### Recopilación de datos

1) **Prometheus** nos permitirá recoger datos de diversas fuentes, a través de la configuración de scrapers en el fichero `./datos/config/prometheus.yml`. En este fichero vemos dos **scrappers** configurados para recoger los datos de las dos fuentes.

Estos datos serán expuestos en el puerto **9090** para ser recopilados por otra aplicación para su tratamiento, almacenamiento y análisis.

Además dispone de una interfaz gráfica que permite explorar los datos y representarlos gráficamente disponible en el puerto 9090

Se han incluidos algunas alertas a modo de ejemplo, a través del fichero alerts.yml, cuya ubicación de icnluye en el fichero de configuración de prometheus.


2) **Incluxdb** nos permiten almacenar los datos de las métricas. En este ejemplo se ha empleado la última versión (2.x) de la base de datos Influxdb. 

Para la parametrización debemos de considerar, además del archivo `docker-compose.yml` los siguientes archivos:

* `./datos/influx/config/config.yml`: permite parametrizar el comportamiento de la base de datos. De especial relevancia son los parámetros **http-bind-address**, **tls-cert** y **tls-key**, siempre teniendo en cuenta que son parámetros internos al contenedor.

* `./datos/influx/env.influxdb`: son las variables de entorno de arranque del contenedor. Podrían estar listadas dentro del fichero docker-compose.yml, pero se han extraído por facilidad de lectura.

## Puesta en marcha

El acceso a Grafana por primera vez empleará el usuario `admin` y password por defecto `admin`. Por algún motivo que desconozco no está considerando los valores introducidos.

### Fuentes de datos

1) Prometheus

Una vez cambiado el password por defecto, en el panel lateral accedemos a la configuración (rueda dentada) para seleccionar el submenu **Datasources**.

En éste pulsando **Add data source** podemos seleccionar la primera de ellas, por ejemplo **Prometheus**

En la configuración de la fuente de datos de Prometheus debemos configurar los parámetros:
* URL, con el formato `http://<NOMBREDELHOST>:9090`
* Access: Browser
El resto se dejarán por defecto. Pulsaremos `Save & Test`

2) InfluxDB

De nuevo añadiremos otro origen de datos, esta vez seleccionamos **InfluxDB**.

Modificaremos los siguientes datos:
* Query Language: Flux (empleado por InfluxDB 2.x)
* URL: con el formato `https://<NOMBREDELHOST>:8086`
* Organization: con el valor de la variable  DOCKER_INFLUXDB_INIT_ORG del fichero `env.influxdb`
* Token: con el valor de la variable DOCKER_INFLUXDB_INIT_ADMIN_TOKEN
* Default Bucket: con el valor de la variable DOCKER_INFLUXDB_INIT_BUCKET
El resto se dejarán por defecto. Pulsaremos `Save & Test`

### Paneles

Ahora importaremos los paneles para cada una de las fuentes de datos.

Accedemos al menú de **Dashboards** en el panel lateral y dentro de este al submenú **Manage**. Pulsaremos en **Import** para acceder a la carga de los ficheros .json con los Dashboards. Será neceario repetir la operación con los siguientes  identificadores:
* 14282 para el origen cAdvisor. En la siguiente pantalla seleccionamos el origen de los datos en el último de los campos. (Prometheus o el nombre que le asignaramos)
* 1860 para el origen Node Exporter. Como en el caso anterior seleccionamos en el último campo el origen de Prometheus.
* No he encontrado dashboards que funcionen con las consultas Flux, necesarias para la fuente de datos InfluxDB v2. Por este motivo he creado a modo de ejemplo un dashboard. Este se puede leer e importar desde el fichero: `./Dashboards/dashboard-telegrad-system.json`. Disculpad lo burdo del panel, pero es solo un ejemplo para tomar de referencia.

## TODO

**Alertas Prometheus**
docker run --name alertmanager -d -p 9093:9093 quay.io/prometheus/alertmanager
https://github.com/prometheus/alertmanager
https://awesome-prometheus-alerts.grep.to/rules.html

## Referencias

**Importantes**
https://prometheus.io/docs/guides/node-exporter/
https://github.com/google/cadvisor/blob/master/docs/runtime_options.md
https://prometheus.io/docs/prometheus/latest/configuration/configuration/
https://grafana.com/docs/grafana/latest/installation/docker/?src=grafana_footer
https://hub.docker.com/_/influxdb

**Alarmas prometheus**
https://awesome-prometheus-alerts.grep.to/rules.html

**Otras referencias:**
https://logz.io/blog/prometheus-tutorial-docker-monitoring/#whatisprometheus
https://grafana.com/docs/grafana/latest/installation/docker/?src=grafana_footer
https://community.grafana.com/t/grafana-docker-and-data-persistence/33702/2
https://github.com/nicolargo/docker-influxdb-grafana/blob/master/docker-compose.yml
https://medium.com/@mertcan.simsek276/docker-monitoring-with-cadvisor-prometheus-and-grafana-adefe1202bf8
https://hub.docker.com/r/philhawthorne/docker-influxdb-grafana/
https://github.com/blasebast/monitoring-grafana-influxdb-telegraf-prometheus
https://www.jorgedelacruz.es/2020/11/23/en-busca-del-dashboard-perfecto-influxdb-telegraf-y-grafana-parte-i-instalando-influxdb-telegraf-y-grafana-sobre-ubuntu-20-04-lts/
