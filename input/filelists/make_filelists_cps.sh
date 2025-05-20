#!/bin/bash

# Generador de listas de archivos para CPS
# -----------------------------------------
# Este script busca archivos en carpetas específicas y 
# genera listas de archivos para ser usados por el script principal en MATLAB.

# Asegúrese de que estas rutas existan y contengan los archivos esperados.

# Lista de archivos de presión a nivel del mar (MSLP)
DIR_MSLP=/media/chris/data_cps/mslp
find $DIR_MSLP -name "CFSR*" | sort -n > filelist_mslp.txt
echo "Archivo filelist_mslp.txt generado con archivos de $DIR_MSLP"

# Lista de archivos de altura geopotencial (HGT)
DIR_HGT=/media/chris/data_cps/hgt
find $DIR_HGT -name "CFSR*" | sort -n > filelist_hgt.txt
echo "Archivo filelist_hgt.txt generado con archivos de $DIR_HGT"

