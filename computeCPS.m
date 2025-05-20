%% Script principal: Seguimiento de ciclones y cálculo del CPS
%
% Este script realiza el seguimiento de trayectorias ciclónicas utilizando
% datos atmosféricos de reanálisis. Se calculan parámetros del Cyclone Phase Space
% de Hart (CPS), se generan figuras de trayectorias y diagramas de fase,
% y se escriben archivos de salida con la información procesada.
%
% Organización de carpetas:
% ├── input/filelists       : listas con rutas de archivos NetCDF (HGT/MSLP)
% ├── input/tracks          : trayectorias de ciclones
% ├── functions             : funciones utilizadas para el análisis
% ├── output/track_gifs     : gifs de trayectorias
% ├── output/phase_plots    : diagramas CPS
% └── output/text_files     : resultados de los parametros en archivos .txt
%
% Antes de ejecutar: hacer respaldo de 'text_files', 'phase_plots' y 
% 'track_gifs' ya que serán reemplazados por los nuevos resultados.
% 
% Referencias:
%   Hart, R.E., 2003: A Cyclone Phase Space Derived from Thermal Wind and 
%   Thermal Asymmetry. Mon. Wea. Rev., 131, 585–616.
%
% -------------------------------------------------------------------------
% Revisión de código:
%
% 2025-05-20 - Limpieza general del código y agregados comentarios descriptivos.
% 2022-12-16 - Revisión y agregados comentarios descriptivos.
% 2019-01-01 - Primera versión funcional.
%
% -------------------------------------------------------------------------

%% Limpieza del entorno y configuración gráfica

clearvars; close all; clc;

% Establecer color de fondo blanco en figuras
set(0, 'DefaultFigureColor', [1 1 1]);

% set(0, 'DefaultFigureRenderer', 'opengl');
set(0, 'DefaultFigureRenderer', 'painters');

%% Añadir carpeta de funciones al path

addpath('functions');

%% Configuración general

plot_cyclone_track = true;     % Mostrar la trayectoria del ciclón
plot_phase_diagram = true;     % Mostrar el diagrama de fase (CPS)

% Directorios de salida
dir_phase_plots = 'output/phase_plots';     % Figuras del diagrama de fase
dir_track_gifs  = 'output/track_gifs';      % Animaciones de trayectorias
dir_output_text = 'output/text_files';      % Archivos de texto

% Crear los directorios si no existen
if ~exist(dir_phase_plots, 'dir'); mkdir(dir_phase_plots); end
if ~exist(dir_track_gifs, 'dir'); mkdir(dir_track_gifs); end
if ~exist(dir_output_text, 'dir'); mkdir(dir_output_text); end

%% Archivos de entrada

infile_filelist_hgt  = 'filelist_hgt.txt';   % Lista de archivos HGT
infile_filelist_mslp = 'filelist_mslp.txt';  % Lista de archivos MSLP
infile_track_orig    = 'Track';              % Trayectorias ciclones originales

%% Archivos de salida

outfile_track_selected = 'Track_selected';       % Trayectorias seleccionadas
outfile_cps_raw        = 'cps_parameters_raw';   % Parámetros CPS raw
outfile_cps_avg        = 'cps_parameters_avg';   % Parámetros CPS suavizados

%% Configuración de datos de entrada

data_source     = 'CFSR';           % Fuente de datos (solo para rotulado en figuras)
var_name_mslp   = 'PRMSL_L101';     % Nombre de variable de presión a nivel del mar
var_name_hgt    = 'HGT_L100';       % Nombre de variable de altura geopotencial
var_name_levels = 'level0';         % Niveles verticales
var_name_lat    = 'lat';            % Nombre de variable latitud
var_name_lon    = 'lon';            % Nombre de variable longitud

% Configuraciones por defecto (no cambiar!)
critical_radius_km  = 500;                % Radio crítico (km) para cálculos
cps_pressure_levels = {300, 600, 900};    % Niveles para el cálculo del CPS
search_radius_deg   = 10;                 % Radio de búsqueda (grados)

%% Selección temporal

% year_min = 1950;  % Año inicial
year_min = 2010;  % Año inicial
year_max = 2030;  % Año final

% month_min=1;
% month_max=12;

% Configuración de meses (no funcional por ahora)
month_sel = 1:12; % Meses incluidos en el análisis (aún no implementado)

% Advertencia
warning('La selección por mes aún no está implementada. Solo se utiliza el rango de años.')

% Mostrar configuración seleccionada
fprintf('Buscando trayectorias con:\n');
fprintf('  Años: desde %d hasta %d\n', year_min, year_max);
fprintf('  Meses: [%s] (no funcional aún)\n', num2str(month_sel));

%% NO MODIFICAR DE AQUÍ HACIA ABAJO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

%% Conversión de grados a radianes (constantes internas)

deg2rad = pi / 180;
rad2deg = 180 / pi;

%% Leer trayectorias desde archivo

disp(['The trajectories in the file "', infile_track_orig, '" are being read...'])
disp(' ')

fid = fopen(['input/tracks/', infile_track_orig],'r');
S = textscan(fid, '%s', 'delimiter', '\n');
S = S{1};
fclose(fid);

% Encontrar líneas que contienen "start" (inicio de cada trayectoria)
idx = find(contains(S, 'start'));

% Extraer datos de cada trayectoria
iwant = cell(length(idx), 1);
for i = 1:length(idx)-1
    iwant{i} = S(idx(i)+1 : idx(i+1)-1);
end
iwant{end} = S(idx(end)+1:end);

% Convertir a datos numéricos
clear cyclone_tracks
for k = 1:length(iwant)
    cyclone_tracks{k} = str2num(char(iwant{k}));
end

% Asegurar formato columna
if size(cyclone_tracks,1) < size(cyclone_tracks,2)
    cyclone_tracks = cyclone_tracks';
end

% Mostrar formato esperado
disp('The trajectories must contain these columns:')
varNames = {'Lon', 'Lat', 'WindSpeed', 'Pressure', 'Year', 'Month', 'Day', 'Hour'};
cell2table(cell(1, numel(varNames)), 'VariableNames', varNames)

disp(['There are ', num2str(length(cyclone_tracks)), ' trajectories in the "', infile_track_orig, '" file'])
disp(' ')

%% Información de cada ciclón 

clear dur s_year s_month s_day s_hour s_id e_year e_month e_day e_hour

for i = 1:length(cyclone_tracks)
    dur(i,1)      = size(cyclone_tracks{i}, 1);
    s_year(i,1)   = cyclone_tracks{i}(1,5);
    s_month(i,1)  = cyclone_tracks{i}(1,6);
    s_day(i,1)    = cyclone_tracks{i}(1,7);
    s_hour(i,1)   = cyclone_tracks{i}(1,8);
    s_id(i,1)     = i;
    
    e_year(i,1)   = cyclone_tracks{i}(end,5);
    e_month(i,1)  = cyclone_tracks{i}(end,6);
    e_day(i,1)    = cyclone_tracks{i}(end,7);
    e_hour(i,1)   = cyclone_tracks{i}(end,8);
end

s_date = datenum(s_year, s_month, s_day, s_hour, 0, 0);
e_date = datenum(e_year, e_month, e_day, e_hour, 0, 0);

%% Seleccionar ciclones en periodo deseado

ind_Cyclone = find(s_year >= year_min & e_year <= year_max);
cyclone_tracks_backup = cyclone_tracks;

% Asegurar formato columna
if size(ind_Cyclone,1) > size(ind_Cyclone,2)
    ind_Cyclone = ind_Cyclone';
end

cyclone_tracks = cyclone_tracks(ind_Cyclone);
if size(cyclone_tracks,1) < size(cyclone_tracks,2)
    cyclone_tracks = cyclone_tracks';
end

disp(['Selected trajectories are writing to the file "', outfile_track_selected, '"...'])
disp(' ')

fid = fopen([dir_output_text, '/', outfile_track_selected], 'wt');

for k = 1:length(cyclone_tracks)
    % Escribir encabezado
    nPoints    = size(cyclone_tracks{k}, 1);
    trackYear  = cyclone_tracks{k}(1,5); % año
    trackMonth = cyclone_tracks{k}(1,6); % mes
    trackDay   = cyclone_tracks{k}(1,7); % día
    trackHour  = cyclone_tracks{k}(1,8); % hora
    trackNum   = k;
    
    fprintf(fid, 'start %d %d %d %d %d %d\n', ...
        nPoints, trackYear, trackMonth, trackDay, trackHour, trackNum);

    % Escribir datos: (lon, lat, wind, pres, year, month, day, hour)
    fprintf(fid, '%f %f %f %f %f %f %f %f\n', [cyclone_tracks{k}]');
end

fclose(fid);
disp('Selected trajectories were successfully written')
disp(' ')

%% Recalcular información de los ciclones

clear dur s_year s_month s_day s_hour s_id e_year e_month e_day e_hour

for i = 1:length(cyclone_tracks)
    dur(i,1)      = size(cyclone_tracks{i}, 1);
    s_year(i,1)   = cyclone_tracks{i}(1,5);
    s_month(i,1)  = cyclone_tracks{i}(1,6);
    s_day(i,1)    = cyclone_tracks{i}(1,7);
    s_hour(i,1)   = cyclone_tracks{i}(1,8);
    s_id(i,1)     = i;
    
    e_year(i,1)   = cyclone_tracks{i}(end,5);
    e_month(i,1)  = cyclone_tracks{i}(end,6);
    e_day(i,1)    = cyclone_tracks{i}(end,7);
    e_hour(i,1)   = cyclone_tracks{i}(end,8);
end

s_date = datenum(s_year, s_month, s_day, s_hour, 0, 0);
e_date = datenum(e_year, e_month, e_day, e_hour, 0, 0);

%% Leer archivos de geopotencial y presión

fileList_HGT  = textread(['input/filelists/', infile_filelist_hgt], '%s');
fileList_MSLP = textread(['input/filelists/', infile_filelist_mslp], '%s');

% Extraer fechas desde nombres de archivo
clear fileDates_HGT
for i=1:length(fileList_HGT)
    timeStr = fileList_HGT{i}(end-10:end);
    fileDates_HGT(i, 1) = datenum(str2num(timeStr(1:4)), str2num(timeStr(5:6)), str2num(timeStr(7:8)), str2num(timeStr(10:11)), 0, 0);
end
clear fileDates_MSLP
for i=1:length(fileList_MSLP)
    timeStr = fileList_MSLP{i}(end-10:end);
    fileDates_MSLP(i,1) = datenum(str2num(timeStr(1:4)), str2num(timeStr(5:6)), str2num(timeStr(7:8)), str2num(timeStr(10:11)), 0, 0);
end

%% Leer datos asociados a cada ciclón

clear cyclone_cps_params
for k = 1:length(cyclone_tracks)
    disp(['Cyclone number:', num2str(k)])
    disp(datestr(s_date(k), 'yyyy-mm-dd_HH:MM:SS'))
    
    tsub = cyclone_tracks{k};
    time = datenum(tsub(:,5), tsub(:,6), tsub(:,7), tsub(:,8), 0, 0);
    
    % Convertir longitudes > 180
    tsub(tsub(:,1)>180,1) = tsub(tsub(:,1)>180,1) - 360;
    
    % Leer campos de altura geopotencial (Z)
    
    % Verificar
    [~, idx_HGT] = intersect(fileDates_HGT, time);
    if length(idx_HGT) < length(time)
        disp(['Skipping cyclone ', num2str(k), ': missing geopotential height data.'])
        continue
    end
    
    files1 = fileList_HGT(idx_HGT);
    clear Z3
    for i = 1:length(files1)
        Z3(:,:,:,i) = ncread(files1{i}, var_name_hgt);
    end
    
    Z = permute(Z3, [4 3 2 1]); % tiempo, niveles, lat, lon
    lat = ncread(files1{1}, var_name_lat);
    lon = ncread(files1{1}, var_name_lon);
    
    if max(lon)>180
        lonpos = true;
    elseif min(lon)<0
        lonpos = false;
    else
        lonpos = false;
    end
    
    % Leer presión a nivel del mar (MSLP)
    
    % Verificar
    [~, idx_MSLP] = intersect(fileDates_MSLP, time);
    if length(idx_MSLP) < length(time)
        disp(['Skipping cyclone ', num2str(k), ': missing MSLP data.'])        
        continue
    end
    
    files1 = fileList_MSLP(idx_MSLP);
    clear PSL_in
    for i = 1:length(files1)
        PSL_in(:,:,i) = ncread(files1{i}, var_name_mslp);
    end
    
    PSL = permute(PSL_in, [3 2 1]);
    if min(PSL(:)) > 1500
        PSL = PSL / 100; % convertir Pa a hPa
    end
    
    % Leer niveles de presión
    files1 = fileList_HGT(idx_HGT);
    pnew = ncread(files1{1}, var_name_levels);
    logp = log(pnew * 100);
    
    % Asignar índices
    indices(1) = find(pnew == cps_pressure_levels{1}); % top
    indices(2) = find(pnew == cps_pressure_levels{2}); % mid
    indices(3) = find(pnew == cps_pressure_levels{3}); % bottom
    
    indtop = indices(1);
    indmid = indices(2);
    indbot = indices(3);
    
    % Calcular el espesor de Z entre 600 and 900 para el cálculo de B
    Z_thick = Z(:,indmid,:,:) - Z(:,indbot,:,:);
    Z_thick = squeeze(Z_thick);
    
    % Extraer valores de trayectoria
    minP = tsub(:,4);
    minPlat = tsub(:,2);
    minPlon = tsub(:,1);
    V = tsub(:,3);
    
    if lonpos
        idx = minPlon < 0;
        minPlon(idx) = minPlon(idx) + 360;
    end
    
    clear dist ang d_ang B Vlt Vut
    a = length(minPlat);
    dist = NaN(a,1);
    ang = NaN(a,1);
    d_ang = NaN(a,1);
    B = NaN(a,1);
    Vlt = NaN(a,1);
    Vut = NaN(a,1);
    
    for i = 2:length(minPlat)
        % Distancia y ángulo de movimiento
        dist(i) = greatcircle(minPlat(i), minPlon(i), minPlat(i-1), minPlon(i-1));
        ang(i) = bearing(minPlat(i-1), minPlon(i-1), minPlat(i), minPlon(i));
        d_ang(i) = rad2deg * atan2(sin((ang(i-1) - ang(i)) * deg2rad), cos((ang(i-1) - ang(i)) * deg2rad));
        
        % Calcular índice B
        B(i) = calc_B(squeeze(Z_thick(i,:,:)), search_radius_deg, critical_radius_km, ang(i), minPlat(i), minPlon(i), lat, lon);
        
        % Calcular Vlt y Vut
        [Vlt(i), Vut(i)] = calc_VltVut(squeeze(Z(i,:,:,:)), lat, lon, search_radius_deg, critical_radius_km, minPlat(i), minPlon(i), indices, logp);
    end
    
    % Guardar en tabla y en matriz final
    varNames = {'Pressure', 'Lat', 'Lon', 'dist', 'V', 'ang', 'd_ang', 'B', 'Vlt', 'Vut'};
    % dataTable = table(minP, minPlat, minPlon, dist, V, ang, d_ang, B, Vlt, Vut, 'VariableNames', varNames);
    table(minP, minPlat, minPlon, dist, V, ang, d_ang, B, Vlt, Vut, 'VariableNames', varNames)
    cyclone_cps_params{k} = [minPlon, minPlat, minP, V, dist, ang, B, Vlt, Vut, year(time), month(time), day(time), hour(time)];
    
    % Generar gráfico de trayectoria (opcional)
    if plot_cyclone_track
        numberCyclone = k;
        for i = 1:length(time)
            psl_min = minP(i);
            lat_min = minPlat(i);
            lon_min = minPlon(i);
            PSLm = squeeze(PSL(i,:,:));
            tt = i;
            timem = datestr(time(i), 'yyyy-mmm-dd HH:MM:SS');
            track_plot(dir_track_gifs, data_source, numberCyclone, tt, lat, lon, timem, psl_min, lat_min, lon_min, PSLm)
        end
        system(['rm -f ', dir_track_gifs, '/track_plot_', data_source, '_', num2str(numberCyclone, '%04d'), '.gif']);
        system(['convert -delay 50 -loop 0 -density 300 ', dir_track_gifs, '/track_plot_', data_source, '_', num2str(numberCyclone, '%04d'), '_*.png -resize 50% ', dir_track_gifs, '/track_plot_', data_source, '_', num2str(numberCyclone, '%04d'), '.gif']);
        system(['rm -f ', dir_track_gifs, '/track_plot_', data_source, '_', num2str(numberCyclone, '%04d'), '_*.png']);
    end
end

%% Escritura de resultados CPS (Cyclone Phase Space) a archivo de texto

disp(['CPS trajectories are writing to the file "', outfile_cps_raw, '"...'])
disp(' ')

fid = fopen([dir_output_text, '/', outfile_cps_raw], 'wt');

for k = 1:length(cyclone_cps_params)
    % Escribir encabezado de trayectoria
    nPoints     = size(cyclone_cps_params{k}, 1);
    trackYear   = cyclone_cps_params{k}(1,10);
    trackMonth  = cyclone_cps_params{k}(1,11);
    trackDay    = cyclone_cps_params{k}(1,12);
    trackHour   = cyclone_cps_params{k}(1,13);
    
    fprintf(fid, 'start %d %d %d %d %d %d\n', ...
        nPoints, trackYear, trackMonth, trackDay, trackHour, k);
    
    % Escribir los datos de la trayectoria
    % (lon, lat, pres, wind, dist, ang, B, Vlt, Vut, trackYear, trackMonth, trackDay, trackHour)
    fprintf(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f\n', ...
        cyclone_cps_params{k}');
end

fclose(fid);

disp('CPS trajectories were successfully written')
disp(' ')

%% Suavizado de salidas CPS (promedio móvil de 24 horas)

cyclone_cps_params_avg = cyclone_cps_params;

for k = 1:length(cyclone_cps_params)
    % Aplicar suavizado móvil a columnas 7 (B), 8 (Vlt), 9 (Vut)
    cyclone_cps_params_avg{k}(:,9) = movmean(cyclone_cps_params{k}(:,9), [2 1], 'omitnan');
    cyclone_cps_params_avg{k}(:,8) = movmean(cyclone_cps_params{k}(:,8), [2 1], 'omitnan');
    cyclone_cps_params_avg{k}(:,7) = movmean(cyclone_cps_params{k}(:,7), [2 1], 'omitnan');
    
    % Calcular vector de tiempo para el track
    time = datenum(cyclone_cps_params_avg{k}(:,10), ...
                   cyclone_cps_params_avg{k}(:,11), ...
                   cyclone_cps_params_avg{k}(:,12), ...
                   cyclone_cps_params_avg{k}(:,13), 0, 0);
    
    % Variables necesarias para el diagrama de fase
    numberCyclone = k;
    sdate = datestr(time(1), 'yyyy-mm-dd HH:MM:SS');
    edate = datestr(time(end), 'yyyy-mm-dd HH:MM:SS');
    
    wnd_sfc = cyclone_cps_params_avg{k}(:,4);  % viento superficial
    psl     = cyclone_cps_params_avg{k}(:,3);  % presión
    Bavg    = cyclone_cps_params_avg{k}(:,7);  % parámetro B
    Vltavg  = cyclone_cps_params_avg{k}(:,8);  % Vt inferior
    Vutavg  = cyclone_cps_params_avg{k}(:,9);  % Vt superior
    
    % Generar gráfico de fase (opcional)
    if plot_phase_diagram
        cps_plot(dir_phase_plots, data_source, numberCyclone, ...
                 sdate, edate, Bavg, Vltavg, Vutavg, ...
                 psl, wnd_sfc, 0)  % horizontalLayout = 0
    end
end

%% Escritura de resultados suavizados a archivo de texto

disp(['CPS avg trajectories are writing to the file "', outfile_cps_avg, '"...'])
disp(' ')

fid = fopen([dir_output_text, '/', outfile_cps_avg], 'wt');

for k = 1:length(cyclone_cps_params_avg)
    nPoints     = size(cyclone_cps_params_avg{k}, 1);
    trackYear   = cyclone_cps_params_avg{k}(1,10);
    trackMonth  = cyclone_cps_params_avg{k}(1,11);
    trackDay    = cyclone_cps_params_avg{k}(1,12);
    trackHour   = cyclone_cps_params_avg{k}(1,13);
    
    fprintf(fid, 'start %d %d %d %d %d %d\n', ...
        nPoints, trackYear, trackMonth, trackDay, trackHour, k);
    
    % (lon, lat, pres, wind, dist, ang, B, Vlt, Vut, trackYear, trackMonth, trackDay, trackHour)
    fprintf(fid, '%f %f %f %f %f %f %f %f %f %f %f %f %f\n', ...
        cyclone_cps_params_avg{k}');
end

fclose(fid);

disp('CPS avg trajectories were successfully written')
disp(' ')

disp('------> computeCPS.m finished successfully :) <------')
disp(' ')
