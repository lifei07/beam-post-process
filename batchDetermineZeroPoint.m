files = struct( 'name', 'raw/zeropoint ((*)).tif', ...
    'from', 1, 'to', 50, 'step', 1, 'padwidth', 0 );

nFiles = length(files.from:files.step:files.to);

imSize = [1200 1600]; %[H W]

bg = 32768;

imSum = zeros(imSize);

for ii = 1:nFiles
    fileName = genFileName( files, ii );
    img = double( imread( fileName ) );
    img = filterImg( img, 'base substract', 'baselinetype', 'absolute', 'baseline', bg );
    imSum = imSum + img;
end

imSum_inty = mean( imSum, 1 );
imSum_intx = mean( imSum, 2 );

figure;
plot( imSum_inty ); hold on
plot( imSum_intx );

figure
imagesc( imSum )