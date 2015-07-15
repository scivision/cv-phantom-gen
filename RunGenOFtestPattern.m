% generate test patterns for optical flow
% Michael Hirsch
% August 2012
% writes 16-bit or 8-bit unsigned integer files of phantoms. Suggest using
% .pgm output if using with Black Robust Flow estimator
%
%
function varargout = RunGenOFtestPattern(playVideo,movieType,translate,textureSel,nFrame,...
                        nRow,nCol,dx,dy,fStep,BitDepth,pWidth,nPhantom,phantomSpacing,swirlParam)
% [data] = RunGenOFtestPattern(playVideo,movieType,translate,textureSel,nFrame,nRow,nCol,dx,dy,fStep,BitDepth,pWidth,swirlParam)
% EXAMPLE
%
% 3 parallel vertical bars
% RunGenOFtestPattern(1,[],'horizSlide','vertBar',128,256,256,.5,.5,1,8,5,3,15)
%
% horizontal vertical bar slide (simple):
% RunGenOFtestPattern(1,[],'horizSlide','vertBar',128,256,256,.5,.5,1,8,5)
%
% SINE WAVE:
% data = RunGenOFtestPattern(1,[],'horizSlide','vertsine',128,256,256,.5,.5,1,64,128);
% vortices:
% swirlParam.x0=[256,256,256]; swirlParam.y0=[384,256,128]; swirlParam.radius=40; swirlParam.strength=0.035;
% RunGenOFtestPattern(1,'pgm','swirlStill','vertBar',256,512,512,.5,.5,1,8,5,1,0,swirlParam)
%
% sheared pyramid45:
% RunGenOFtestPattern(1,[],'ShearRight','pyramid45',256,512,512,.5,.5,1,16,5,1)
%
% inputs:
% playVideo: show preview while writing (slower)
% movieType: [], don't write movie
%            'pgm', series of PGM images (no compression) <-- needed for Black C code
%            'png', series of PNG images
%            'Lossless', Motion JPEG 2000
%            'MJPEG', lossy .avi % can cause false artifacts due to compression, use with great care
% translate: 'swirl'
%               'rotate360ccw'
%               'rotate180ccw'
%               'rotate90ccw'
%               'vertslide'
%               'horizslide'
%               'still'
%               'diagslide'
%               'shearright'
%
% textureSel:   'vertBar'
%               'uniformRandom'
%               'wall'
%               'checkerboard'
%               'xTriangle'
%               'yTriangle'
%
% nFrame:     default 256 frames of video
% nRow:         default 256 y-pixels
% nCol:         default 256 x-pixels
% dx:   horizontal pixel step size b/w frames
% dy:	vertical pixel step size b/w frames
% fStep:    skips frames (for testing) (default=1 no skipping)
% BitDepth: 8 or 16 (only tested for PNG)
% pWidth: Width of bar
% nPhantom: number of phantoms
% phantomSpacing: scalar or nFramex1 vector
% swirlParam: parameters for swirl method only (blank otherwise)
%               swirlParam.strength: vector of swirl strength
%               swirlParam.x0: vector of swirl x-center
%               swirlParam.y0: vector of swirl y-center
%               swirlParam.radius: vector of swirl radii
% outputs:
% data: entire video sequence as 16-bit numbers

% example of how imwarp is so much faster
% oldway horizslide vertbar, playVideo: 20.2 sec. R2013b
% newway horizslide vertbar, playVideo: 8.5 sec. R2013b
% oldway horizslide vertbar, playVideo: 26.8 sec. octave 3.8.1
%
% oldway horizslide vertbar, no play: 14.2 sec. R2013b using 4 CPU cores
% newway horizslide vertbar, no play: 04.2 sec. R2013b using 1 CPU core
% oldway horizslide vertbar, no play: 14.3 sec. octave 3.8.1


if nargin<1 || isempty(playVideo), playVideo = true; end

if nargin<2, movieType = []; end

if nargin<3 || isempty(translate), translate = 'horizslide'; end

if nargin<4 || isempty(textureSel), textureSel = 'vertbar'; end

if nargin<5 || isempty(nFrame), nFrame = 256; end

if nargin<6 || isempty(nRow), nRow = 512; nCol = 512; end

if nargin<8 || isempty(dx), dx = 1; dy = 1; end

if nargin<10 || isempty(fStep), fStep = 1; end

if nargin<11 || isempty(BitDepth), BitDepth = 64; end

if nargin<12 || isempty(pWidth), pWidth = 10; end

if nargin<13 || isempty(nPhantom), nPhantom=1; end

if nargin<14 || isempty(phantomSpacing) || all(phantomSpacing==0), phantomSpacing = 0; end

if nargin<15 || isempty(swirlParam)
    swirlParam.strength = []; swirlParam.radius =[]; swirlParam.x0 = []; swirlParam.y0=[];
end

if ~isoctave
    if verLessThan('matlab','8.1'), %R2013a
        oldWay = true; %uses slower transformation algorithms
    else
        oldWay = false;
    end
else % octave
   page_output_immediately(1)
   page_screen_output(0)
   pkg load image
   oldWay = true; % octave 4.0.0 didn't have imwarp
  % display(nRow); display(nCol)
end

writeVid = ~isempty(movieType);

%angleSel = 45; %degrees

GaussSigma = 35;
%% indices
%indices for frame looping
I = 1:fStep:nFrame;
%indices for number of phantoms
Iphantom = 1:nPhantom;
if length(phantomSpacing)==1
    for i = Iphantom
    phantomSpacing(i) = phantomSpacing(1) * i;
    %TODO add time-dependant spacing
    end
end
%% initialize
[bgminmax,data,myClass] = OFgenParamInit(BitDepth,nRow,nCol,nFrame);

if playVideo
%h.f = figure('pos',[250 250 560 600]);
h.f = figure(1); clf
h.ax = axes('parent',h.f);
%h.img = imshow(nan(nRow,nCol),'parent',h.ax,'DisplayRange',bgminmax);
h.img = imagesc(nan(nRow,nCol));
colormap('gray')
axis('image')
set(h.ax,'ydir','normal')
axis(h.ax,'on')
h.t = title('');
else h.img = [];
end


%% create surface texture
bg = phantomTexture(textureSel,myClass,nRow,nCol,bgminmax,pWidth,GaussSigma);

%% write AVI video
fPrefix = [translate,'-',textureSel,'-'];
try
    if any(strcmpi({'lossless','mjpeg','avi'},movieType))

        switch lower(movieType)
            case 'lossless'
                writeObj = VideoWriter([fPrefix,'.mj2'], 'Archival');
                writeObj.MJ2BitDepth = BitDepth; %Mono16
            case {'mjpeg','avi'}
                writeObj = VideoWriter([fPrefix,'.avi'],'Motion JPEG AVI');
                writeObj.Quality = 100; %trying to avoid compression artifacts--these images are highly compressible anyway
        end

        writeObj.FrameRate = 10;
        open(writeObj)
    else 
        writeObj = [];
    end
catch 
    error('Writing movie files directly must be done in Matlab R2012a or newer')
end

%% do translation
data = translateTexture(bg,data,h,I,Iphantom,dx,nRow,nCol,myClass,oldWay,swirlParam,phantomSpacing,writeObj,writeVid,playVideo,movieType,fPrefix,nFrame,translate);


close(writeObj)

try display([num2str(compTime,'%0.1f'),' seconds required to compute phantom']), end

if nargout>0, varargout{1} = data; end %don't send out huge data if not requested

end %function

%%

function [bgminmax,data,myClass] = OFgenParamInit(BitDepth,nRow,nCol,nFrame)

if BitDepth == 8 || BitDepth == 16
    myClass = ['uint',int2str(BitDepth)];
    myInt = str2func(myClass);
    bgMax = myInt(2^BitDepth - 1);
elseif BitDepth == 32
    myClass = 'single';
    bgMax = 1; %normalize
    myInt = str2func(myClass);
elseif BitDepth == 64
    myClass = 'double';
    bgMax = 1; %normalize
    myInt = str2func(myClass);
else
    error(['unknown bit depth ',int2str(BitDepth)])
end



bgMin = myInt(0);


data = zeros(nRow,nCol,nFrame,myClass); %initialize all frame
  display(['max,min pixel intensities for ',myClass,' are taken to be: ',num2str(bgMin),',',num2str(bgMax)])

bgminmax = [bgMin,bgMax];

end %function

function dataFrame = doShearRight(bg,i,nFrame,dx,nRow,nCol,oldWay,fillValue)
%display(i)
           T = [1,0,0;...
               (nFrame-i*dx)/nFrame,1,0;...
                 0,0,1];

 dataFrame = doTform(T,bg,oldWay,nRow,nCol,fillValue);
end
