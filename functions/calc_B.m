function B_symmetry = calc_B(Z_thick, search_radius_deg, critical_radius_km, ang, minPlat, minPlon, lat, lon)

% calc_B - Calcula el parámetro de simetría térmica (B) en el Cyclone Phase Space
%
% Esta función estima el parámetro B, que representa la simetría térmica relativa
% del ciclón, según la definición de Hart (2003). Se calcula como la diferencia
% entre el promedio ponderado del grosor geopotencial (Z_thick) al lado derecho
% y al lado izquierdo del ciclón, dentro de un radio crítico.
%
% Parámetros de entrada:
%   Z_thick            : Matriz de espesores geopotenciales (900-600 hPa) [lat x lon]
%   search_radius_deg  : Rango en grados para seleccionar la subregión centrada en el mínimo
%   critical_radius_km : Radio crítico (en km) para considerar valores de Z_thick
%   ang                : Dirección de desplazamiento del ciclón (en grados, 0=N)
%   minPlat            : Latitud del centro del ciclón (mínima presión)
%   minPlon            : Longitud del centro del ciclón (mínima presión)
%   lat                : Vector de latitudes
%   lon                : Vector de longitudes
%
% Salida:
%   B                  : Parámetro de simetría térmica
%
% Referencias:
%   Hart, R.E., 2003: A Cyclone Phase Space Derived from Thermal Wind and 
%   Thermal Asymmetry. Mon. Wea. Rev., 131, 585–616.
%
% -------------------------------------------------------------------------
% Revisión de código:
%
% 2025-05-20 - Limpieza general del código y agregados comentarios descriptivos.
% 2019-01-01 - Primera versión funcional.
%
% -------------------------------------------------------------------------

% Conversión a radianes
deg2rad = pi / 180;

% Índices de subregión centrada en el ciclón
[~, poslon(1)] = min(abs(lon - (minPlon - search_radius_deg)));
[~, poslat(1)] = min(abs(lat - (minPlat - search_radius_deg)));
[~, poslon(2)] = min(abs(lon - (minPlon + search_radius_deg)));
[~, poslat(2)] = min(abs(lat - (minPlat + search_radius_deg)));

% Subregión de grosor geopotencial
Z_left = Z_thick(min(poslat):max(poslat), min(poslon):max(poslon));
Z_right = Z_left;
    
% Subconjuntos de lat/lon
subLat = lat(min(poslat):max(poslat));
subLon = lon(min(poslon):max(poslon));
nSubLat = length(subLat);
nSubLon = length(subLon);

angleFromCenter = NaN(nSubLat, nSubLon); % Ángulos desde el centro
latWeights = cos(subLat * deg2rad);     % Pesos latitudinales
    
% Loop principal para asignar valores a Z_left y Z_right
for jlat = 1:nSubLat
    for jlon = 1:nSubLon
        
        % Calcular ángulo entre el centro y el punto actual
        angleFromCenter(jlat, jlon) = bearing(minPlat, minPlon, subLat(jlat), subLon(jlon));

        % Calcular distancia desde el centro
        [~, ~, auxdist] = greatcircle(minPlat, minPlon, subLat(jlat), subLon(jlon));
        d = auxdist(end);

        if d > critical_radius_km
            Z_left(jlat, jlon) = NaN;
            Z_right(jlat, jlon) = NaN;
            continue;
        end

        % Valores sobre la línea de trayectoria: no se usan
        if angleFromCenter(jlat, jlon) == ang
            Z_left(jlat, jlon) = NaN;
            Z_right(jlat, jlon) = NaN;
        elseif ang >= 0 && ang < 180
            if angleFromCenter(jlat, jlon) > ang && angleFromCenter(jlat, jlon) < ang + 180
                Z_left(jlat, jlon) = NaN;
            else
                Z_right(jlat, jlon) = NaN;
            end
        elseif ang >= 180 && ang < 360
            if angleFromCenter(jlat, jlon) > ang - 180 && angleFromCenter(jlat, jlon) < ang
                Z_right(jlat, jlon) = NaN;
            else
                Z_left(jlat, jlon) = NaN;
            end
        end
    end
end
  
%% Cálculo del parámetro B 

weightsR = repmat(latWeights, [1, size(Z_right, 2)]);
weightsR(isnan(Z_right)) = NaN;

weightsL = repmat(latWeights, [1, size(Z_left, 2)]);
weightsL(isnan(Z_left)) = NaN;

% B: diferencia de los promedios ponderados derecha - izquierda
B_symmetry = nansum(Z_right(:) .* weightsR(:)) / nansum(weightsR(:)) - ...
    nansum(Z_left(:) .* weightsL(:)) / nansum(weightsL(:));

% En el hemisferio sur, se invierte el signo
if minPlat < 0
    B_symmetry = -B_symmetry;
end
