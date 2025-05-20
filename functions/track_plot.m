function track_plot(dir_track_plot, data_source, numberCyclone, tt, lat, lon, time, psl_min, lat_min, lon_min, PSL)

% track_plot - Genera un mapa con la trayectoria de un ciclón y el campo de presión
%
% Esta función crea una figura con la distribución espacial de la presión a nivel del mar 
% (PSL) en un instante de tiempo específico, junto con la ubicación del mínimo de presión 
% y la trayectoria del ciclón. También incluye un shapefile de las masas continentales.
%
% Parámetros de entrada:
%
%   dir_track_plot : Directorio donde se guardará la figura generada (string)
%   data_source    : Fuente de datos utilizada (por ejemplo: 'CFSR', 'ERAI') (string)
%   numberCyclone  : Número identificador del ciclón (entero)
%   tt             : Índice de tiempo del paso actual (entero)
%   lat            : Vector de latitudes [degrees North or South]
%   lon            : Vector de longitudes [degrees East]
%   time           : Tiempo correspondiente al campo de presión (datetime o string con formato 'yyyy-MMM-dd HH:mm:ss', ej. '1985-Jun-16 12:00:00')
%   psl_min        : Valor mínimo de presión a nivel del mar (hPa)
%   lat_min        : Latitud del mínimo de presión (degrees North or South)
%   lon_min        : Longitud del mínimo de presión (degrees East)
%   PSL            : Matriz 2D del campo de presión a nivel del mar (hPa), dimensiones [lat x lon]
%
% La figura se guarda automáticamente como archivo PNG con nombre:
%   'track_plot_<data_source>_<numberCyclone>_<tt>.png' en el directorio especificado.
%
% Ejemplo de uso:
%   track_plot('figs', 'CFSR', 3, 12, lat, lon, '1985-Jun-16 12:00:00', 978.2, -45.0, 289.5, PSL)
%
% -------------------------------------------------------------------------
% Revisión de código:
%
% 2025-05-20 - Limpieza general del código y agregados comentarios descriptivos.
% 2019-01-01 - Primera versión funcional.
%
% -------------------------------------------------------------------------

% Preprocesamiento de datos
lon = double(lon);
lat = double(lat);

PSL = double(PSL);
% Revisa orientación del campo si necesario:
if size(PSL,1) ~= length(lat)
    PSL = PSL';  % Asegura que PSL tiene [lat, lon]
end
PSL = permute(PSL, [2 1]); % Transponer para que coincida con lon/lat

% Eliminar duplicados en longitudes (por cambio de -180/180 a 0/360)
[lon, uniqueIdx] = unique(lon, 'stable');
PSL = PSL(uniqueIdx, :);

% Define color map
% auxcmap = [
%     100, 52, 233
%     44, 124, 229
%     73, 204, 92
%     248, 196, 33
%     251, 102, 64
%     248, 37, 83
%     ] / 255;

auxcmap = [
    0.3922    0.2039    0.9137
    0.2923    0.3323    0.9066
    0.1925    0.4606    0.8995
    0.2139    0.6004    0.7027
    0.2656    0.7430    0.4585
    0.4734    0.7914    0.2977
    0.7854    0.7772    0.1925
    0.9747    0.7016    0.1515
    0.9800    0.5340    0.2068
    0.9832    0.3768    0.2578
    0.9779    0.2610    0.2916
    0.9725    0.1451    0.3255
    ];


% Crear figura
h = figure('Units', 'centimeters', 'Position', [2, 2, 30, 20]);  
ax = subplot(1, 1, 1);

% Mostrar campo de presión
contourf(lon, lat, PSL', 920:5:1080, 'LineWidth', 0.5, 'EdgeColor', [0.8 0.8 0.8]);
set(gca, 'YDir', 'normal');
xlabel('Longitude [degrees]');
ylabel('Latitude [degrees]');

% Título con fecha y presión mínima
t = title({[datestr(datetime(time), 'mmm.dd, yyyy HH'), ' UTC']; ...
           ['Min. pressure = ', num2str(round(psl_min), '%04d'), ' hPa']; ''}, ...
           'FontWeight', 'bold', 'FontSize', 12, 'HorizontalAlignment', 'left');
set(t, 'Units', 'Normalized');
pos = get(t, 'Position');
set(t, 'Position', [0, pos(2), pos(3)]);

hold on;
  
% Configuración de ejes
set(ax, 'TickDir', 'out', 'XMinorTick', 'off', 'YMinorTick', 'off');
axis equal;
xlim([min(lon), max(lon)]);
ylim([min(lat), max(lat)]);

% Dibujar shapefile del mundo
S = shaperead('landareas.shp', 'UseGeoCoords', true);

for k = 1:length(S)
    lon_shape = S(k).Lon;
    lat_shape = S(k).Lat;

    % Convertir longitudes negativas a 0-360
    lon_shape(lon_shape < 0) = lon_shape(lon_shape < 0) + 360;

    % Evitar líneas locas: insertar NaN donde el salto en longitud es muy grande
    dlon = abs(diff(lon_shape));
    jumps = [false, dlon > 180];
    lon_shape(jumps) = NaN;
    lat_shape(jumps) = NaN;

    % Dibujar
    plot(lon_shape, lat_shape, 'k')
end

% Marcar mínimo de presión
plot(lon_min, lat_min, 'X', 'Color', [1 1 1], 'MarkerSize', 18, 'LineWidth', 3);

% Configurar colorbar
colormap(auxcmap);
caxis([960 1020]);

cb = colorbar('southoutside', 'LineWidth', 0.5, 'FontSize', 10);
ylabel(cb, 'Mean Sea Level Pressure [hPa]');
cb.TickDirection = 'out';

% Guardar figura
% pause(1)    

saveas(h, [dir_track_plot, '/track_plot_', data_source, '_', num2str(numberCyclone, '%04d'), '_', num2str(tt, '%03d'), '.png'])
close(h)

end
