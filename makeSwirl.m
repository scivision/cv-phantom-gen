function [Iswirl,u,v] = makeSwirl(I,x0,y0,strength,radius,showPlot,fillValue,BitDepth,Detachment)
% function makeSwirl(I,x0,y0,strength,radius,showPlot,fillValue,BitDepth)
%
% inputs:
% I: image data (default is checkerboard 512x512 pixels)
% x0: x-pixel of swirl center
% y0: y-pixel of swirl center
% strength: factor indicating how strong twisting is
% radius: radius from center over which swirl has effect
% showPlot: true to show plots (default false)
% fillValue: value to fill unused pixels with (default 0)
%
% inspired by Python SciKit-Image processing toolkit "swirls" function
%
% tested with 16-bit images
% compiled by Michael Hirsch 2012
%
% Note: Octave 3.8 does not yet have makeresampler or tformarray.  

if isoctave
    warning('Octave 4.0 still does not have makeresampler')
end

if nargin<8 || isempty(BitDepth), BitDepth = 8; end
myClass = ['uint',int2str(BitDepth)];
whiteVal = 2^BitDepth-1;

if nargin<1 || isempty(I), I = whiteVal*checkerboard(64); end
[nRow, nCol] = size(I);
if nargin<2 || isempty(x0),       x0 = round(nCol/2); end
if nargin<3 || isempty(y0),       y0 = round(nRow/2); end
if nargin<4 || isempty(strength), strength = 10; end
if nargin<5 || isempty(radius),   radius = 120; end
if nargin<6 || isempty(showPlot), showPlot=false; end
if nargin<7 || isempty(fillValue),fillValue = 0; end
%
if nargin<9 || isempty(Detachment), Detachment = false; end


Nswirl = length(x0);


%all radii the same?
if Nswirl>length(radius) %set all radii to first radius value
    radius(1:Nswirl) = radius(1);
end

%all strengths the same?
if Nswirl>length(strength)
    strength(1:Nswirl) = strength(1);
end

%initialize mesh
[xi,yi] = meshgrid(1:nCol,1:nRow);


%% setup dilation
if Detachment
% assumes vertical auroral phantom image
LHW = 10; %line half-width (For snipping)

subI = zeros(nRow,nCol,myClass); %initialize subtraction image

%put 'snip' north and south of each swirl
for ii = 1:Nswirl
    subI(y0(ii)+radius(ii)-1:y0(ii)+radius(ii),...
         x0(ii)-LHW:x0(ii)+LHW) = whiteVal;
    subI(y0(ii)-radius(ii):y0(ii)-radius(ii)+1,...
         x0(ii)-LHW:x0(ii)+LHW) = whiteVal;
end

% morphological dilation structuring element
%se = strel('ball',1,0.5,0);

end
%% do work

resamp = makeresampler('linear','fill'); %'cubic' is much slower

radius= log(2).*radius./5;

Iswirl = I;

for ii = 1:Nswirl

%distances of each pixel to swirl center
%rho = sqrt((xi-x0(ii)).^2 + (yi-y0(ii)).^2);
rho = hypot(xi-x0(ii), yi-y0(ii));

%make the swirl: |theta| depends on rho
theta = strength(ii).*...
            exp( -rho./radius(ii) )...
            + atan2(yi-y0(ii),xi-x0(ii));

% polar to cartesian conversion %pol2cart() would take two steps
u = x0(ii) + rho.*cos(theta); 
v = y0(ii) + rho.*sin(theta);

% implement the transform
T = cat(3,u,v);
Iswirl = tformarray(Iswirl,[],resamp,[2 1],[1 2],[],...
                  T,fillValue);

  if Detachment
        % morphological: increment phantom 'detachment'
        %subI = imdilate(subI,se); 

        subI2 = strength(ii).*(subI./25); % this "fades in" detachment (very crude)

        % 'snip' by subtracting from main image
        Iswirl = Iswirl - subI2;
  end %if 
end %for
%% plotting
%display(strength(ii)*65535/25)
if showPlot
subplot(2,1,1)
if Detachment
    imshow(subI2), axis on
    title('subtraction image')
else
    title('no subtraction used')
end
subplot(2,1,2)
imshow(Iswirl), axis on
title('swirl')
pause(0.05)
end
%%
if nargout==0, clear, end
end
