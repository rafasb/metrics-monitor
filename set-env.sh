#!/bin/bash

echo Creamos los directorios de almacenamiento de los cetificados y
echo de los datos de las aplicaciones
echo 
mkdir ./certs
mkdir ./datos/influxdb/data
mkdir ./datos/prometheus/data
sudo mkdir -p ./datos/grafana/data/dashboards
sudo mkdir -p ./datos/grafana/data/provisioning/datasources
sudo cp  ./datos/grafana/config/dashboards/all.yml ./datos/grafana/data/dashboards/all.yml
sudo cp ./datos/grafana/config/provisioning/datasources/all.yml ./datos/grafana/data/provisioning/datasources/all.yml
sudo chown -R 472:472 ./datos/grafana/data
