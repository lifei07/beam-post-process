function map = myColormap( scheme, ncolor, varargin )

colormapLib = 'myColormap.mat';

opts = struct( 'inverse', false, 'beta', 0 );
validProperties = fieldnames( opts );

nArgs = length( varargin );
if mod( nArgs, 2 )
    error('myColormap needs propertyName/propertyValue pairs')
end

for pair = reshape( varargin, 2, [] )
   property = lower( pair{1} );
   if any( strcmp( property, validProperties ) )
       opts.(property) = pair{2};
   else
       error( '%s is not a recognized property name', property )
   end
end


if nargin == 0
    
    colormapInfo = whos( matfile( colormapLib ) );
    nColormap = length( colormapInfo );
    scale = linspace( 0, 1, 256 )';
    
    figure
    for iColormap = 1:nColormap
       
        %subplot( nColormap, 1, iColormap )
        subplot( ceil( nColormap/8 ), 8, iColormap )
        
        imagesc( flipud(scale) ); axis off;
        cmapName = colormapInfo(iColormap).name;
        load( colormapLib, cmapName );
        %cmap = eval( cmapName );
        cmap = myColormap( cmapName, 64 );
        colormap( cmap ); freezeColors;
        title( cmapName )
        
    end

else
    
    load( colormapLib, lower( scheme ) );
    baseMap = eval( scheme );

    idx1 = linspace( 1, ncolor, size( baseMap, 1 ) );
    idx2 = 1:ncolor;
    map = interp1( idx1, baseMap, idx2, 'pchip' );
    % eliminate occasional, small negative numbers and numbers greater than one
    % occurring at one end of the Edge colormap because of cubic interpolation
    map = min( map, 1 );
    map = max( map, 0 );
    map = brighten( map, opts.beta );
    if opts.inverse
        map = flipud( map );
    end
    
end