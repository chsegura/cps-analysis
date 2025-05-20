function cps_plot(dir_phase_plot, data_source, numberCyclone, sdate, edate, B_symmetry, VT_L, VT_U, psl, wnd_sfc, horizontalLayout)

% cps_plot - Genera un gráfico de cyclone phase space 
%
% Esta función crea una figura compuesta por dos paneles que representan la evolución
% de un ciclon en el cyclone phase space. Se trazan dos relaciones:
% (1) la 900-600 hPa Storm-Relative Thickness Symmetry (B) frente al 900-600 hPa Thermal Wind (-Vlt), y
% (2) el 600-300 hPa Thermal Wind (-Vut) frente al 900-600 hPa Thermal Wind (-Vlt).
% 
% El color de los puntos representa la presión a nivel del mar (psl), y el tamaño
% indica la magnitud del viento superficial (wnd_sfc). Las letras 'S' y 'E' indican
% el inicio y el final de la trayectoria.
%
% Parámetros de entrada:
%
%   dir_phase_plot   : Directorio donde se guardará la figura generada (string)
%   data_source      : Fuente de datos utilizada (por ejemplo: 'CFSR', 'ERAI') (string)
%   numberCyclone    : Número identificador del ciclon (entero)
%   sdate            : Fecha de inicio del sistema (string, formato 'yyyy-mm-dd HH:MM:SS')
%   edate            : Fecha de término del sistema (string, formato 'yyyy-mm-dd HH:MM:SS')
%   B_symmetry       : Vector con la 900-600 hPa Storm-Relative Thickness Symmetry
%   VT_L             : Vector con el 900-600 hPa Thermal Wind
%   VT_U             : Vector con el 600-300 hPa Thermal Wind
%   psl              : Vector con la presión a nivel del mar (hPa)
%   wnd_sfc          : Vector con la magnitud del viento superficial
%   horizontalLayout : Si es 1, el layout es horizontal (1x2); si es 0, es vertical (2x1)
%
% La figura se guarda automáticamente como archivo PNG con nombre:
%   'phase_plot_<data_source>_<numberCyclone>.png' en el directorio especificado.
%
% Ejemplo de uso:
%   cps_plot('figs', 'CFSR', 3, '2025-01-01 00:00:00', '2025-01-05 18:00:00', B_symmetry, VT_L, VT_U, psl, wnd_sfc, 0)
%
% -------------------------------------------------------------------------
% Revisión de código:
%
% 2025-05-20 - Limpieza general del código y agregados comentarios descriptivos.
% 2019-01-01 - Primera versión funcional.
%
% -------------------------------------------------------------------------

%% Parámetros de visualización

% auxcmap = [
%     224, 60, 49
%     255, 127, 65
%     247, 234, 72
%     45, 200, 77
%     20, 123, 209
%     117, 59, 189
%     ] / 255;

% Define color map
auxcmap = [
    100, 52, 233
    44, 124, 229
    73, 204, 92
    248, 196, 33
    251, 102, 64
    248, 37, 83
    ] / 255;

% Scatter size configuration
wnd_bins = 5:25;
numLevels = 5; % <-- Número de niveles representativos para la leyenda
idx = round(linspace(1, length(wnd_bins), numLevels));
wnd_vals = wnd_bins(idx);
disp("Niveles seleccionados para la leyenda:");
disp(wnd_vals);

sizesc = linspace(15, 150, length(wnd_bins));
colorsc = linspace(960, 1020, size(auxcmap, 1));
wcolor = [0 0 0]; % Color for S and E labels

%% Configuración de la figura

if horizontalLayout
    warning('Modo horizontal aún no configurado. Usando modo vertical por defecto.');
    horizontalLayout = false;  % Revertimos al modo vertical
end

if horizontalLayout
%     h = figure('Position', [100, 100, 1150, 450]);
    h = figure('Units', 'centimeters', 'Position', [2, 2, 40, 15]);
    ax1 = subplot(1, 2, 1);
    ax2 = subplot(1, 2, 2);
else
%     h = figure('Position', [100, 100, 570, 1150]);
    h = figure('Units', 'centimeters', 'Position', [2, 2, 15, 25]);
    ax1 = subplot(2, 1, 1);
    ax2 = subplot(2, 1, 2);
end

%% Primer gráfico: -Vlt vs B

axes(ax1);

plot_background(ax1, '-V_{T}^{L} [900–600 hPa Thermal Wind]', ...
                      'B [900–600 hPa Storm-Relative Thickness Symmetry]', ...
                      [-450 450], [-50 100], sdate, edate, 0, 10, auxcmap);

hold on
plot(VT_L, B_symmetry, 'k', 'LineWidth', 0.5)


plot_scatter(VT_L, B_symmetry, wnd_sfc, psl, auxcmap, sizesc, wnd_bins, colorsc);

text(VT_L(1), B_symmetry(1), 'S', 'Color', wcolor, 'FontSize', 21, 'FontWeight', 'bold');
text(VT_L(end), B_symmetry(end), 'E', 'Color', wcolor, 'FontSize', 21, 'FontWeight', 'bold');

pause(0.1)
add_size_legend(wnd_bins, sizesc, numLevels, horizontalLayout);

%% Segundo gráfico: -Vlt vs -Vut

axes(ax2);

plot_background(ax2, '-V_{T}^{L} [900–600 hPa Thermal Wind]', ...
                      '-V_{T}^{U} [600–300 hPa Thermal Wind]', ...
                      [-450 450], [-450 450], sdate, edate, 0, 0, auxcmap);

hold on
plot(VT_L, VT_U, 'k', 'LineWidth', 0.5)

plot_scatter(VT_L, VT_U, wnd_sfc, psl, auxcmap, sizesc, wnd_bins, colorsc);

text(VT_L(1), VT_U(1), 'S', 'Color', wcolor, 'FontSize', 21, 'FontWeight', 'bold');
text(VT_L(end), VT_U(end), 'E', 'Color', wcolor, 'FontSize', 21, 'FontWeight', 'bold');

%% Ajustes finales

linkaxes([ax1 ax2], 'x')

set(ax2, 'YTick', get(ax2, 'XTick'));
box(ax1, 'on')
box(ax2, 'on')

saveas(h, [dir_phase_plot, '/phase_plot_', data_source, '_', num2str(numberCyclone, '%04d'), '.png'])
close(h)

end

%% Funciones auxiliares

function plot_background(ax, xlabel_text, ylabel_text, xlims, ylims, ...
                         sdate, edate, xline_value, yline_value, auxcmap)
    axes(ax)
    
    % Líneas de referencia
    yline(yline_value, 'k', 'LineWidth', 0.5); % Línea horizontal configurable
    xline(xline_value, 'k', 'LineWidth', 0.5); % Línea vertical configurable
    
    hold on
    xlabel(xlabel_text, 'FontSize', 12)
    ylabel(ylabel_text, 'FontSize', 12)
    xlim(xlims)
    ylim(ylims)
    
    % Ejes y ticks
    set(ax, 'TickDir', 'out', 'XMinorTick', 'on', 'YMinorTick', 'on')
    ax.TickLength(1) = ax.TickLength(1) * 2;
    axis square
        
    % Colormap y colorbar
    colormap(ax, auxcmap);
    caxis([960 1020])
    cb = colorbar('eastoutside', 'LineWidth', 0.5, 'FontSize', 10);
    ylabel(cb, 'Mean Sea Level Pressure [hPa]');
    cb.TickDirection = 'out';
    cb.Position(2) = ax.Position(2);
    cb.Position(4) = ax.Position(4);
    cb.Position(1) = ax.Position(1) + 0.7;

    % Título con fechas
    t = title({['sdate: ', sdate]; ['edate: ', edate]; ''}, 'FontSize', 9, ...
              'HorizontalAlignment', 'left');
    set(t, 'Units', 'Normalized')
    pos = get(t, 'Position');
    set(t, 'Position', [0 pos(2) pos(3)]);
end

function plot_scatter(x, y, wnd_sfc, psl, auxcmap, sizesc, wnd_bins, colorsc)
    for i = 1:length(wnd_sfc)

        % Tamaño del scatter
        if wnd_sfc(i) <= wnd_bins(1)
            auxsize = sizesc(1);
        elseif wnd_sfc(i) >= wnd_bins(end)
            auxsize = sizesc(end);
        else
            pos = wnd_bins - wnd_sfc(i);
            pos(pos < 0) = NaN;
            idx = find(pos == min(pos), 1);
            auxsize = sizesc(idx);
        end

        % Color del scatter
        if psl(i) < colorsc(1)
            auxcolor = auxcmap(1,:);
        elseif psl(i) >= colorsc(end)
            auxcolor = auxcmap(end,:);
        else
            pos = colorsc - psl(i);
            pos(pos < 0) = NaN;
            idx = find(pos == min(pos), 1);
            auxcolor = auxcmap(idx,:);
        end

%         scatter(x(i), y(i), 'o', 'SizeData', auxsize, ...
%                 'MarkerFaceColor', auxcolor, 'MarkerEdgeColor', 'k');
            plot(x(i), y(i), 'o', 'markersize', sqrt(auxsize), ...
                'MarkerFaceColor', auxcolor, 'MarkerEdgeColor', 'k');
    end
end

function add_size_legend(wnd_bins, sizesc, numLevels, horizontalLayout)
    % Validar que numLevels no sea mayor que la longitud de wnd_bins
    numLevels = min(numLevels, length(wnd_bins));
    
    % Forzar mínimo de niveles representativos
    if numLevels < 3
    warning('Number of levels too low. Automatically adjusted to 3.');
    numLevels = 3;
    end

    % Elegir índices espaciados uniformemente
    idx = round(linspace(1, length(wnd_bins), numLevels));
    sizes = sizesc(idx);
    wnd_vals = wnd_bins(idx);

    % Mostrar en consola los niveles que se usarán
    disp('Niveles seleccionados para la leyenda:');
    disp(wnd_vals);

    % Construir etiquetas
    leg_labels = strings(1, numLevels);
    leg_labels(1) = "≤ " + wnd_vals(1);
    leg_labels(end) = "≥ " + wnd_vals(end);
    for i = 2:numLevels-1
        leg_labels(i) = string(wnd_vals(i));
    end

    hold on
    sc = gobjects(1, numLevels);
    for i = 1:numLevels
        sc(i) = plot(NaN, NaN, 'ok', 'MarkerFaceColor', 'k', ...
                     'MarkerSize', sqrt(sizes(i)));
    end

    [l, icons] = legend(sc, leg_labels, 'Location', 'southwest');
    l.Position(4) = l.Position(4) + (horizontalLayout * 0.185 + ~horizontalLayout * 0.1);
end

% function add_size_legend(wnd_bins, sizesc, horizontalLayout)
%     leg_labels = {'≤ 5','10','15','20','≥ 25'};
%     idx = round(linspace(1, length(wnd_bins), length(leg_labels)))
%     sizes = sizesc(idx);
%     hold on
%     for i = 1:length(sizes)
%         sc(i) = plot(NaN, NaN, 'ok', 'MarkerFaceColor', 'k', 'MarkerSize', sqrt(sizes(i)));
% %         sc(i) = scatter(NaN, NaN, sizes(i), 'k', 'filled');
%     end
%     [l, icons]= legend(sc, leg_labels, 'Location', 'southwest');
%     l.Position(4) = l.Position(4) + (horizontalLayout * 0.185 + ~horizontalLayout * 0.1);
% end
