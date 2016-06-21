function [ xMean, width, x1, x2 ] = getProfilePosWidth( x, y, varargin )

options = struct( 'smoothspan', 1, ...
	'baseline', 0, ...
    'baselinetype', 'absolute', ...
	'type', 'rms', ...
    'peakposition', false );
validProperties = fieldnames( options );

nArgs = length( varargin );
if mod( nArgs, 2 )
    error('getProfileWidth needs propertyName/propertyValue pairs')
end

for pair = reshape( varargin, 2, [] )
   property = lower( pair{1} );
   if any( strcmp( property, validProperties ) )
       options.(property) = pair{2};
   else
       error( '%s is not a recognized property name', property )
   end
end

if isrow(x); x = x'; end
if isrow(y); y = y'; end
y = smooth( y, options.smoothspan );
switch options.baselinetype
    case 'absolute'
        y = y - options.baseline;
    case 'relative'
        y = y - max(y(:)) * options.baseline;
    otherwise
        error( 'invalid baseline type!' )
end
y( y<0 ) = 0.0;

w = y/sum(y);
xMean = sum(x.*w);

switch options.type
	case {'rms', 'rms gaussian fitting'}
		width = sqrt( sum( (x-xMean).^2.*w ) );
		x1 = xMean - width;
		x2 = xMean + width;
        if strcmp( options.type, 'rms gaussian fitting' )
            fo = fitoptions( 'Method', 'NonlinearLeastSquares', ...
                'StartPoint', [xMean width^2 max(y) 0], ...
                'Lower', [min(x) 0 0 0], ...
                'Upper', [max(x) (max(x)-min(x))^2 Inf Inf] );
            ft = fittype( 'a*exp(-0.5*(x-mu)^2/s2)+b', ...
                'coefficients', {'mu', 's2', 'a', 'b'}, 'options', fo );
            yfit = fit( x, y, ft );
            xMean = yfit.mu;
            width = sqrt( yfit.s2 );
        end

	case 'fwhm'
		yMax = max(y);
		idx1 = find( y > 0.5 * yMax, 1, 'first' );
		idx2 = find( y > 0.5 * yMax, 1, 'last' );
		x1 = interp1( y( idx1-1:idx1 ), x( idx1-1:idx1 ), 0.5 * yMax );
		x2 = interp1( y( idx2:idx2+1 ), x( idx2:idx2+1 ), 0.5 * yMax );
		width = abs( x2-x1 );
        
	otherwise
		error( 'invalid type includes rms and fwhm' );
end

if options.peakposition
    xMean = x(y == max(y));
end

end

