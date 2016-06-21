function [ imgFilt ] = filterImg( imgOrg, type, varargin )

options = struct( 'hsize', [3 3], ...
	'sigma', 0.5, ...
    'baseline', 0.0, ...
    'baselinetype', 'absolute' );
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

switch lower(type)
    case 'median value'
        imgFilt = medfilt2( imgOrg, options.hsize );
    case 'smooth'
        win = fspecial( 'gaussian', options.hsize, options.sigma );
        imgFilt = filter2( win, imgOrg );
    case 'base substract'
        switch options.baselinetype
            case 'absolute'
                imgFilt = imgOrg - options.baseline;
            case 'relative'
                imgFilt = imgOrg - options.baseline * max(imgOrg(:));
            otherwise
                error( 'invalid baseline type' );
        end
        imgFilt( imgFilt < 0 ) = 0;
    otherwise
        error( 'Invalid image filter type.' )
end


end

