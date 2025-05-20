#!/bin/bash
# Ejecuta el script computeCPS.m de MATLAB sin abrir la GUI

echo "Iniciando análisis CPS con computeCPS.m..."

matlab -nodisplay -nosplash -nodesktop -r "run('computeCPS.m'); exit;" | tail -n +11

echo "Análisis CPS finalizado."

