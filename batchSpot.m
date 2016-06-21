%% BATCH PROCESSING RAW DATA

% ========== BEGIN OF INPUT SECTION ==========

% crop region of the image and background. the values are in pixel
cropRect = [300 100 850 550]; % [y1 x1 y2 x2] 
bgCropRect = [570 1 620 51]; % [y1 x1 y2 x2], set it [] if background substraction is not applied

% calibration values
% calibValue = [0.0786885 0.1162791/sqrt(2)]; % [mm]
calibValue = [1 1];

% the drifting length of beam
driftLength = 0.6; % [m]

% set filter span for smooth and median value filter 
filterSpan = [3 3];

% set baseline level for background substraction, it should be between [0 1]
baseline = 0;

% switch for pseudocolor plot
IF_GEN_PSEUDOCOLOR_PLOT = true;
IF_SAVE_PSEUDOCOLOR_PLOT = false;

% set colormap
colormap( myColormap( 'chaojie', 256 ));

% set figure size of the generated pseudocolor images
figSize = [800 600]; % [W H]

% ========== END OF INPUT SECTION ==========

xrange = [0 cropRect(4)-cropRect(2)]*calibValue(1);
yrange = [0 cropRect(3)-cropRect(1)]*calibValue(2);
xgrid = (0:cropRect(4)-cropRect(2)) * calibValue(1);
ygrid = (0:cropRect(3)-cropRect(1)) * calibValue(2);

[ fileName, pathName ] = uigetfile( {'*.tif'; '*.bmp'; '*.*'}, 'select files', ...
        'multiselect', 'on' );
if iscell( fileName )
    nFiles = length( fileName );
else
    nFiles = 1;
end

counts = zeros( nFiles, 1 );
pos = zeros( nFiles, 2 );
sigma = zeros( nFiles, 2 );
fwhm = zeros( nFiles, 2 );

for ii = 1:nFiles
    
    if iscell( fileName )
        openFullName = strcat( pathName, fileName{ii} );
    else
        openFullName = strcat( pathName, fileName );
    end
    imgOrg = double(imread( openFullName ));
    img = imgOrg( cropRect(1):cropRect(3), cropRect(2):cropRect(4) );
    if ~isempty( bgCropRect )
        bg = imgOrg( bgCropRect(1):bgCropRect(3), bgCropRect(2):bgCropRect(4) );
        bg = mean( bg(:) );
        img = filterImg( img, 'base substract', 'baseline', bg );
    end
    
    img = filterImg( img, 'median value', 'hsize', filterSpan );
    img = filterImg( img, 'smooth', 'hsize', filterSpan );
    img = filterImg( img, 'base substract', 'baselinetype', 'relative', 'baseline', baseline );

    counts(ii) = getCounts( img );
    [pos_tmp, sigma_tmp, ~, ~] = getSpotPosSize( img, xrange, yrange, 'rms gaussian fitting' );
    [~, fwhm_tmp, ~, ~] = getSpotPosSize( img, xrange, yrange, 'fwhm' );
    pos(ii,:) = pos_tmp;
    sigma(ii,:) = sigma_tmp;
    fwhm(ii,:) = fwhm_tmp;
    
    if IF_GEN_PSEUDOCOLOR_PLOT
        magx = 0.2 * diff(yrange);
        magy = 0.2 * diff(xrange);
    	imagesc( xrange, yrange, img ); hold on
    	xint = sum( img, 1 ); xint = xint/max(xint) * magx;
    	yint = sum( img, 2 ); yint = yint/max(yint) * magy;
    	plot( xgrid, xint + xrange(1), 'linewidth', 1, 'color', 'k' );
    	plot( yint + yrange(1), ygrid, 'linewidth', 1, 'color', 'k' );
        xfit = magx * exp( -0.5*(xgrid-pos(ii,1)).^2/sigma(ii,1)^2 );
        yfit = magy * exp( -0.5*(ygrid-pos(ii,2)).^2/sigma(ii,2)^2 );
        plot( xgrid, xfit + xrange(1), 'linestyle', '--', 'color', 'red' );
        plot( yfit + yrange(1), ygrid, 'linestyle', '--', 'color', 'red' );
    	hold off
    	% caxis( colorRange );
    	cb = colorbar; 
        cb.Label.String = 'cnts.';
        cb.FontSize = 16;
    	xlabel( 'x (mm)' ); ylabel( 'y (mm)' );
    	xlim( xrange ); ylim( yrange )
        axis image
        set( gcf, 'color', 'w', 'position', [0 0 figSize] )
        set( gca, 'fontsize', 16, 'linewidth', 1 )
    	if IF_SAVE_PSEUDOCOLOR_PLOT
            suffixIndex = strfind( openFullName, '.' );
            suffixIndex = suffixIndex(end);
            saveFullName = strcat( openFullName(1:suffixIndex-1), '.png' );
            saveImg = frame2im( getframe(gcf) );
            [saveImg, cmap] = rgb2ind( saveImg, 256 );
            imwrite( saveImg, cmap, saveFullName, 'png' );
    	end
    end
end

posMean = mean( pos );
posStd = std( pos );
sigmaMean = mean( sigma );
sigmaStd = std( sigma );
fwhmMean = mean( fwhm );
fwhmStd = std( fwhm );
cntStd = std(counts);
cntMean = mean(counts);
pos(:,1) = pos(:,1) - posMean(1);
pos(:,2) = pos(:,2) - posMean(2);

fprintf( 'position (avg)\t%0.4f %0.4f\n', posMean )
fprintf( 'position (std)\t%0.4f %0.4f\n', posStd )
fprintf( 'beam size rms (avg)\t%0.4f %0.4f\n', sigmaMean )
fprintf( 'beam size rms (std)\t%0.4f %0.4f\n', sigmaStd )
fprintf( 'beam size fwhm (avg)\t%0.4f %0.4f\n', fwhmMean )
fprintf( 'beam size fwhm (std)\t%0.4f %0.4f\n', fwhmStd )
fprintf( 'CCD counts (avg)\t%0.4f %0.4f\n', cntMean )
fprintf( 'CCD counts (std)\t%0.4f %0.4f\n', cntStd )

%% PLOT BEAM POSITION DISTRIBUTION

figure;
scatter( pos(:,1), pos(:,2), 30, counts, 'filled' );
xlabel( 'x (mm)' ); ylabel( 'y (mm)' )
cb = colorbar;
cb.Label.String = 'charge (arb. unit)';
cb.FontSize = 16;
colormap(jet)
box on
axis image
% xlim( [posMean(1)-posStd(1)*10 posMean(1)+posStd(1)*10] );
% ylim( [posMean(2)-posStd(2)*4 posMean(2)+posStd(2)*4] );

%% PLOT BEAM POINTING JITTER VS SHOT NO.

shotNo = 1:nFiles;
figure;
plot( shotNo, pos(:,1)/driftLength, '-', 'linewidth', 1.5 ); hold on
plot( shotNo, pos(:,2)/driftLength, '-', 'linewidth', 1.5 );
title( 'Pointing jitter' );
xlabel( 'shot no.' )
ylabel( '\theta (mrad)' )
legend( '\theta_x', '\theta_y' )
ylim([-10 10])

%% PLOT BEAM DIVERGENCE VS SHOT NO.

shotNo = 1:nFiles;
figure;
plot( shotNo, sigma(:,1)/driftLength, '-', 'linewidth', 1.5, 'color', [     0    0.4470    0.7410] ); hold on
plot( shotNo, fwhm(:,1)/driftLength, '--', 'linewidth', 1.5, 'color', [     0    0.4470    0.7410] );
plot( shotNo, sigma(:,2)/driftLength, '-', 'linewidth', 1.5, 'color', [    0.8500    0.3250    0.0980] );
plot( shotNo, fwhm(:,2)/driftLength, '--', 'linewidth', 1.5, 'color', [    0.8500    0.3250    0.0980] );
title( 'Beam divergence' );
xlabel( 'shot no.' )
ylabel( 'beam divergence (mrad)' )
legend( '\theta_x (rms)', '\theta_x (FWHM)', '\theta_y (rms)', '\theta_y (FWHM)' )
% ylim([-10 10])

%% PLOT CCD COUNTS VS SHOT NO.

shotNo = 1:nFiles;
figure;
plot( shotNo, counts, '-', 'linewidth', 1.5 ); 
title( 'Counts fluctuation' );
xlabel( 'shot no.' )
ylabel( 'CCD cnts.' )