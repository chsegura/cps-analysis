function [Vlt, Vut] = calc_VltVut(Z, lat, lon, search_radius_deg, critical_radius_km, minPlat, minPlon, indices, logp)

% calc_VltVut - Calcula los parámetros de viento térmico inferior y superior
%
% Esta función estima los parámetros Vlt (viento térmico inferior) y Vut (viento térmico superior)
% dentro del Cyclone Phase Space propuesto por Hart (2003). Se basa en el cálculo de la pendiente
% de una regresión lineal entre el espesor geopotencial y el logaritmo de la presión, en diferentes
% capas de la troposfera.
%
% Parámetros de entrada:
%   Z                  : Matriz tridimensional de geopotencial [niveles x lat x lon]
%   lat                : Vector de latitudes (grados)
%   lon                : Vector de longitudes (grados)
%   search_radius_deg  : Radio de búsqueda en grados para recorte espacial
%   critical_radius_km : Radio crítico (en km) para incluir puntos en los cálculos
%   minPlat            : Latitud del centro del ciclón (mínima presión)
%   minPlon            : Longitud del centro del ciclón (mínima presión)
%   indices            : Índices de niveles [top, mid, bot] para el cálculo de Vut y Vlt
%   logp               : Vector del logaritmo de los niveles de presión
%
% Salida:
%   Vlt                : Pendiente de la regresión (viento térmico inferior)
%   Vut                : Pendiente de la regresión (viento térmico superior)
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

% Índices de subregión centrada en el ciclón
[~, poslon(1)] = min(abs(lon - (minPlon - search_radius_deg)));
[~, poslat(1)] = min(abs(lat - (minPlat - search_radius_deg)));
[~, poslon(2)] = min(abs(lon - (minPlon + search_radius_deg)));
[~, poslat(2)] = min(abs(lat - (minPlat + search_radius_deg)));

% Subconjunto de geopotencial (Z) para la región seleccionada
subZ = Z(:, min(poslat):max(poslat), min(poslon):max(poslon));

% Subconjuntos de lat/lon
subLat = lat(min(poslat):max(poslat));
subLon = lon(min(poslon):max(poslon));
nSubLat = length(subLat);
nSubLon = length(subLon);

% Eliminar puntos fuera del radio crítico
for jlat = 1:nSubLat
    for jlon = 1:nSubLon
        [~, ~, auxdist] = greatcircle(minPlat, minPlon, subLat(jlat), subLon(jlon));
        d = auxdist(end);
        if d > critical_radius_km
            subZ(:, jlat, jlon) = NaN;
        end
    end
end

% Cálculo de delta Z por nivel
dZ = NaN(length(logp), 1);
for jlev = 1:length(logp)
    sliceZ = squeeze(subZ(jlev, :, :));
    dZ(jlev) = max(sliceZ(:)) - min(sliceZ(:));
end

% Regresión lineal para thermal winds 
indtop = indices(1);   % top
indmid = indices(2);   % mid
indbot = indices(3);   % bot

% Inferior: entre niveles medio e inferior
if indmid < indbot
    p = polyfit(logp(indmid:indbot), dZ(indmid:indbot), 1);
else
    p = polyfit(logp(indbot:indmid), dZ(indbot:indmid), 1);
end
Vlt = p(1);

% Superior: entre niveles superior e intermedio
if indtop < indmid
    p = polyfit(logp(indtop:indmid), dZ(indtop:indmid), 1);
else
    p = polyfit(logp(indmid:indtop), dZ(indmid:indtop), 1);
end
Vut = p(1);
