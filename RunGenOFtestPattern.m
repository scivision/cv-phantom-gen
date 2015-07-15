% generate test patterns for optical flow
% Michael Hirsch
% August 2012
% writes 16-bit or 8-bit unsigned integer files of phantoms. Suggest using
% .pgm output if using with Black Robust Flow estimator
%
%
function varargout = RunGenOFtestPattern(playVideo,movieType,mtranslate,textureSel,nFrame,...
                        nRow,nCol,dxy,fStep,BitDepth,pWidth,nPhantom,phantomSpacing,swirlParam)
% [data] = RunGenOFtestPattern(playVideo,movieType,mtranslate,textureSel,nFrame,nRow,nCol,dxy,fStep,BitDepth,pWidth,swirlParam)
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
% mtranslate: 'swirl'
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
% dxy:   horizontal / vertical pixel step size b/w frames
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

if nargin<3 || isempty(mtranslate), mtranslate = 'horizslide'; end

if nargin<4 || isempty(textureSel), textureSel = 'vertbar'; end

if nargin<5 || isempty(nFrame), nFrame = 10; end

if nargin<6 || isempty(nRow), nRow = 512; nCol = 512; end

if nargin<8 || isempty(dxy), dxy = [1, 1]; end

if nargin<10 || isempty(fStep), fStep = 1; end

if nargin<11 || isempty(BitDepth), BitDepth = 16; end

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

%% create surface texture
[bg,bgminmax,data,myClass] = phantomTexture(textureSel,nRow,nCol,nFrame,pWidth,GaussSigma,BitDepth);

%% do translation
data = translateTexture(bg,data,fStep,dxy,myClass,oldWay,swirlParam,nPhantom,phantomSpacing,textureSel,writeVid,playVideo,movieType,mtranslate);

if nargout>0, varargout{1} = data; end %don't send out huge data if not requested

end %function
