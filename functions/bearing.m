function bearingDeg = bearing(lat1, lon1, lat2, lon2)
% BEARING Calculates the azimuth (bearing) from one geographic point to another.
% 
% Input:
%   lat1, lon1 - Latitude and longitude of the starting point (degrees)
%   lat2, lon2 - Latitude and longitude of the destination point (degrees)
%
% Output:
%   bearingDeg - Azimuth/bearing from point 1 to point 2 (degrees, 0–360)
%
% Notes:
%   Uses the great-circle bearing formula on a spherical Earth.
%   Angle is measured clockwise from true north.
%
% -------------------------------------------------------------------------
% Revisión de código:
%
% 2019-01-01 - Primera versión funcional.
%
% -------------------------------------------------------------------------

% Constants
deg2rad = pi / 180;
rad2deg = 180 / pi;

% Convert input coordinates from degrees to radians
lat1Rad = lat1 * deg2rad;
lon1Rad = lon1 * deg2rad;
lat2Rad = lat2 * deg2rad;
lon2Rad = lon2 * deg2rad;

% Compute bearing using spherical trigonometry
deltaLon = lon2Rad - lon1Rad;
x = sin(deltaLon) * cos(lat2Rad);
y = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLon);
bearingRad = atan2(x, y);

% Convert bearing from radians to degrees and wrap to 0–360
bearingDeg = mod(rad2deg * bearingRad + 360, 360);

end