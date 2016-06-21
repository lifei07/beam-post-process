function [ pos, width, posLower, posUpper ] = getSpotPosSize( img, xrange, yrange, type )

pos = zeros( 2, 1 );
width = zeros( 2, 1 );
posLower = zeros( 2, 1 );
posUpper = zeros( 2, 1 );

intx = sum( img, 1 );
intx = intx / max(intx);
inty = sum( img, 2 );
inty = inty / max(inty);

xx = linspace( xrange(1), xrange(2), size(img,2) );
yy = linspace( yrange(1), yrange(2), size(img,1) );

if strcmp( type, 'rms gaussian fitting' )
	[ pos(1), width(1), posLower(1), posUpper(1) ] = ...
	    getProfilePosWidth( xx, intx, 'type', 'rms gaussian fitting' );
	[ pos(2), width(2), posLower(2), posUpper(2) ] = ...
	    getProfilePosWidth( yy, inty, 'type', 'rms gaussian fitting' );
elseif strcmp( type, 'fwhm' )
	[ pos(1), width(1), posLower(1), posUpper(1) ] = ...
	    getProfilePosWidth( xx, intx, 'type', 'fwhm' );
	[ pos(2), width(2), posLower(2), posUpper(2) ] = ...
	    getProfilePosWidth( yy, inty, 'type', 'fwhm' );
end


end