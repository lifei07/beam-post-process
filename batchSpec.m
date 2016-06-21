%% BATCH PROCESSING RAW DATA

% ========== BEGIN OF INPUT SECTION ==========

% the section of higher energy should be placed at right side of the image,
% if it's on the left side, turn on the switch.
ifFlip = true;

% size of original image
imgOrgSize = [1600 1200]; %[pixel] [x y]

% pixel index of infinity energy point on the orginal image
infPointIndex = 328;

% crop region of the image and background. the values are in pixel
cropRect = [550 650 750 1500]; % [y1 x1 y2 x2]
bgCropRect = [600 60 650 110]; % [y1 x1 y2 x2]

% calibration values
calibValue = [0.0786885 0.1162791/sqrt(2)]; % [mm]

% set filter span for smooth and median value filter 
filterSpan = [3 3];

% set baseline level for background substraction, it should be between [0 1]
baseline = 0.05;

% energy ticks for x-axis
eManualTick = [30 40 50 60 70 80 90 100 110 120]; % [MeV]

% switch for pseudocolor plot
IF_GEN_PSEUDOCOLOR_PLOT = true;
IF_SAVE_PSEUDOCOLOR_PLOT = true;

% figure size of the 2D pseudocolor plot
figSize = [1000 200]; % [pixel]

% switch for 1D plot
IF_GEN_1DPLOT = false;
IF_SAVE_1DPLOT = false;

% set colormap
colormap( myColormap( 'chaojie', 256 ));

% ========== END OF INPUT SECTION ==========

[ fileName, pathName ] = uigetfile( {'*.tif'; '*.bmp'; '*.*'}, 'select files', ...
        'multiselect', 'on' );
if iscell( fileName )
    nFiles = length( fileName );
else
    nFiles = 1;
end

% read spectrum calibration
fid = fopen( 'pos.txt', 'r' ); specPos = fscanf( fid, '%f', Inf ); fclose( fid );
fid = fopen( 'ene.txt', 'r' ); specEne = fscanf( fid, '%f', Inf ); fclose( fid );

if ifFlip
    infPointIndex = imgOrgSize(1) - infPointIndex + 1;
    cropRect2_tmp = imgOrgSize(1) - cropRect(4) + 1;
    cropRect4_tmp = imgOrgSize(1) - cropRect(2) + 1;
    bgCropRect2_tmp = imgOrgSize(1) - bgCropRect(4) + 1;
    bgCropRect4_tmp = imgOrgSize(1) - bgCropRect(2) + 1;
    cropRect(2) = cropRect2_tmp;
    cropRect(4) = cropRect4_tmp;
    bgCropRect(2) = bgCropRect2_tmp;
    bgCropRect(4) = bgCropRect4_tmp;
end


infPoint = ( infPointIndex - cropRect(2) ) * calibValue(1);
xrange = [0 cropRect(4)-cropRect(2)]*calibValue(1);
yrange = [0 cropRect(3)-cropRect(1)]*calibValue(2);
xgrid = (0:cropRect(4)-cropRect(2)) * calibValue(1);
ygrid = (0:cropRect(3)-cropRect(1)) * calibValue(2);
toInfPoint = abs( xgrid - infPoint );
egrid = interp1( specPos, specEne, toInfPoint, 'linear', 'extrap' );
xManualTick = interp1( egrid, xgrid, eManualTick, 'linear', 'extrap' );

peakE = zeros( nFiles, 1 );
sigmaE = zeros( nFiles, 1 );
fwhmE = zeros( nFiles, 1 );
meanE = zeros( nFiles, 1 );
counts = zeros( nFiles, 1 );

for ii = 1:nFiles

    if iscell( fileName )
        openFullName = strcat( pathName, fileName{ii} );
    else
        openFullName = strcat( pathName, fileName );
    end
    img = double(imread( openFullName ));
    if ifFlip
        img = fliplr( img );
    end
    bg = img( bgCropRect(1):bgCropRect(3), bgCropRect(2):bgCropRect(4) );
    bg = mean( bg(:) );
    img = img( cropRect(1):cropRect(3), cropRect(2):cropRect(4) );
    img = img - bg;
    img( img<0 ) = 0;
    img = filterImg( img, 'median value', 'hsize', filterSpan );
    img = filterImg( img, 'smooth', 'hsize', filterSpan );
    img = filterImg( img, 'base substract', 'baseline', baseline, ...
        'baselinetype', 'relative' );

    xint = sum( img, 2 ); xint = xint/max(xint);
    [xintIndexPeak, xintIndexSigma] = getProfilePosWidth( 1:length(ygrid), xint, 'type', 'rms', ...
        'peakposition', true );
    r = round(xintIndexSigma);
    crop1 = max([xintIndexPeak-r 1]);
    crop2 = min([xintIndexPeak+r size(img,1)]);
    
    yint = sum( img(crop1:crop2, :), 1 ); yint = yint/max(yint);
    [ePeak, eFWHM] = getProfilePosWidth( egrid, yint, 'type', 'fwhm', ...
        'peakposition', true );
    [~, eSigma] = getProfilePosWidth( egrid, yint, 'type', 'rms' );

    fwhmE(ii) = eFWHM;
    sigmaE(ii) = eSigma;
    peakE(ii) = ePeak;
    meanE(ii) = trapz( egrid, egrid.*yint ) / trapz( egrid, yint );
    counts(ii) = sum( img(:) );
    
    if IF_GEN_PSEUDOCOLOR_PLOT
        if ii == 1; figure; h1 = axes; end
        axes(h1);
    	imagesc( xrange, yrange, img );
    	% caxis( colorRange );
    	cb = colorbar; cb.Label.String = 'cnts.'; cb.FontSize = 14;
    	xlabel( 'energy (MeV)' ); ylabel( 'y (mm)' );
    	xlim( xrange ); ylim( yrange )
        set( gcf, 'color', 'w', 'position', [0 0 figSize] )
        set( gca, 'fontsize', 14, 'linewidth', 1, ...
            'xtick', xManualTick, 'xticklabel', eManualTick );
    	if IF_SAVE_PSEUDOCOLOR_PLOT
            suffixIndex = strfind( openFullName, '.' );
            suffixIndex = suffixIndex(end);
            saveFullName = strcat( openFullName(1:suffixIndex-1), '_2d_plot.png' );     
            saveImg = frame2im( getframe(gcf) );
            [saveImg, cmap] = rgb2ind( saveImg, 256 );
            imwrite( saveImg, cmap, saveFullName, 'png' );
    	end
    end
    
    if IF_GEN_1DPLOT
        if ii == 1; figure; h2 = axes; end
        axes(h2);
    	plot( xgrid, yint, 'linewidth', 2 );
    	xlabel( 'energy (MeV)' ); ylabel( 'arb. unit' );
    	xlim( xrange ); ylim( [0 1.2] )
        set( gcf, 'color', 'w', 'position', [0 0 figSize] )
        set( gca, 'fontsize', 14, 'linewidth', 1, ...
            'xtick', xManualTick, 'xticklabel', eManualTick );
    	if IF_SAVE_1DPLOT
            suffixIndex = strfind( openFullName, '.' );
            suffixIndex = suffixIndex(end);
            saveFullName = strcat( openFullName(1:suffixIndex-1), '_1d_plot.png' ); 
            saveImg = frame2im( getframe(gcf) );
            [saveImg, cmap] = rgb2ind( saveImg, 256 );
            imwrite( saveImg, cmap, saveFullName, 'png' );
    	end
    end

end

peakEMean = mean( peakE );
peakEStd = std( peakE );
meanEMean = mean( meanE );
meanEStd = std( meanE );
sigmaEMean = mean( sigmaE );
sigmaEStd = std( sigmaE );
fwhmEMean = mean( fwhmE );
fwhmEStd = std( fwhmE );

fprintf( 'peak E (avg)\t%0.4f\n', peakEMean )
fprintf( 'peak E (std)\t%0.4f\n', peakEStd )
fprintf( 'mean E (avg)\t%0.4f\n', meanEMean )
fprintf( 'mean E (std)\t%0.4f\n', meanEStd )
fprintf( 'dE rms (avg)\t%0.4f\n', sigmaEMean )
fprintf( 'dE rms (std)\t%0.4f\n', sigmaEStd )
fprintf( 'dE fwhm (avg)\t%0.4f\n', fwhmEMean )
fprintf( 'dE fwhm (std)\t%0.4f\n', fwhmEStd )


%% PLOT MEAN ENERGY AND ENERGY SPREAD (FWHM)

shotNo = 1:nFiles;
figure;
plot( shotNo, meanE, '-', 'linewidth', 1.5 ); hold on
plot( shotNo, fwhmE, '-', 'linewidth', 1.5 );
xlabel( 'shot no.' )
ylabel( 'energy (MeV)' )
legend( 'mean ene.', 'ene. spread (FWHM)' )
ylim([0 160])

%% PLOT RELATIVE ENERGY SPREAD (FWHM)
shotNo = 1:nFiles;
figure;
plot( shotNo, fwhmE./meanE * 100, '-', 'linewidth', 1.5 );
xlabel( 'shot no.' )
ylabel( 'energy spread (%)' )
ylim([0 100])

