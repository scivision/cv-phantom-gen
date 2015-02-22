% generate test patterns for optical flow
% Michael Hirsch
% August 2012
% writes 16-bit or 8-bit unsigned integer files of phantoms. Suggest using
% .pgm output if using with Black Robust Flow estimator
%
% 
function varargout = RunGenOFtestPattern(playVideo,movieType,OFtestMethod,textureSel,nFrame,...
                        nRow,nCol,dx,dy,fStep,BitDepth,pWidth,nPhantom,phantomSpacing,swirlParam)
% [data] = RunGenOFtestPattern(playVideo,movieType,OFtestMethod,textureSel,nFrame,nRow,nCol,dx,dy,fStep,BitDepth,pWidth,swirlParam)
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
% OFtestMethod: 'swirl'
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

if nargin<3 || isempty(OFtestMethod), OFtestMethod = 'horizslide'; end

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

fillValue = 0;

if ismatlab
    if verLessThan('matlab','8.1'), %R2013a
        warning('Some image toolbox functions REQUIRE R2013a or newer')
        oldWay = true; %uses slower transformation algorithms
    else
        oldWay = false;
    end
else % octave
   page_output_immediately(1)
   page_screen_output(0)
   oldWay = true; % octave 3.8.1 didn't have imwarp 
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
[bgMaxVal,bgMinVal,data,myClass] = OFgenParamInit(BitDepth,nRow,nCol,nFrame);
 
if playVideo
%h.f = figure('pos',[250 250 560 600]); 
h.f = figure(1); clf
h.ax = axes('parent',h.f);
%h.img = imshow(nan(nRow,nCol),'parent',h.ax,'DisplayRange',[bgMinVal bgMaxVal]);
h.img = imagesc(nan(nRow,nCol));
colormap('gray')
axis('image')
set(h.ax,'ydir','normal')
axis(h.ax,'on')
h.t = title('');
else h.img = [];
end


%% create surface texture
   myInt = str2func(myClass);
switch lower(textureSel)
    case 'wall',           bg = bgMaxVal .* ones(nRow,nCol,myClass);
    case 'uniformrandom',  bg = bgMinVal + (bgMaxVal-bgMinVal).*rand(nRow,nCol);
    case {'gaussian'}
        bg = fspecial('gaussian',[nRow,nCol],GaussSigma); %create wide 2D gaussian shape
        bg = double(bgMaxVal).*bg./max(max(bg)); %normalize to full bit range
        bg = myInt(bg); %cast to desired class
    case {'vertsine'}
        centerCol = pWidth; %<update>
        bg = zeros(1,nCol,'double'); %yes, double to avoid quantization
        bg(pWidth-pWidth/2:pWidth+pWidth/2-1) = sind(linspace(0,180,pWidth)); %don't do int8 yet or you'll quantize it to zero!
        bg = double(bgMaxVal) .* repmat(bg,nRow,1); 
        bg = myInt(bg);    % cast to desired class
    case 'laplacian'
        bg = abs(fspecial('log',[nRow,nCol],50));
        bg = bgMaxVal.*bg./max(max(bg)); %normalize to full bit range
    case 'checkerboard'
    bg = myInt(checkerboard(nRow/8).*bgMaxVal);
    case 'xtriangle'
    bg(1,1:nCol/2) = myInt(bgMinVal:round((bgMaxVal-bgMinVal)/(nRow/2)):bgMaxVal);
    bg(1,nCol/2+1:nCol) = fliplr(bg);   bg = repmat(bg,[nRow,1]);
    case 'ytriangle'
    bg(1:nRow/2,1) = myInt(bgMinVal:round((bgMaxVal-bgMinVal)/(nRow/2)):bgMaxVal);
    bg(nRow/2+1:nRow,1) = flipud(bg);   bg = repmat(bg,[1,nCol]);
    case {'pyramid','pyramid45'}
        bg = zeros(nRow,nCol,myClass);
        temp = myInt(bgMinVal:round((bgMaxVal-bgMinVal)/(nRow/2)):bgMaxVal);
        for i = 1:nRow/2
           bg(i,i:end-i+1) = temp(i); %north face
           bg(i:end-i+1,i) = temp(i); %west face
           bg(end-i+1,i:end-i+1) = temp(i); %south face
           bg(i:end-i+1,end-i+1) = temp(i); %east face
        end
        if strcmpi(textureSel,'pyramid45'), bg = imrotate(bg,45,'bilinear','crop'); end
    case 'spokes' %3 pixels wide
        bg = zeros(nRow,nCol,myClass);
        bg(nRow/2-floor(pWidth/2) : nRow/2+ floor(pWidth/2) ,1:nCol) = bgMaxVal; %horizontal line
        bg(1:nRow,...
            nCol/2-floor(pWidth/2): nCol/2+ floor(pWidth/2)  ) = bgMaxVal; %vertical line
        bg = bg + imrotate(bg,45,'bilinear','crop'); %diagonal line
    case 'vertbar' %vertical bar, starts center of image
        centerCol = nRow/2;
        bg = zeros(nRow,nCol,myClass);
        
        %bg(1:nRow,end-4:end) = bgMaxVal; %vertical line, top to bottom
        
        % vertical bar starts 1/4 from bottom and 1/4 from top of image
        bg(nRow*1/4:nRow*3/4, nCol/2 - floor(pWidth/2) : nCol/2 + floor(pWidth/2)) = bgMaxVal; 
    otherwise, error('unspecified texture selected')
end

%% write AVI video
 fPrefix = [OFtestMethod,'-',textureSel,'-'];
 try
if any(strcmpi({'lossless','mjpeg','avi'},movieType))
   
switch lower(movieType)
    case 'lossless'
writeObj = VideoWriter([fPrefix,'.mj2'],...
                        'Archival');
writeObj.MJ2BitDepth = BitDepth; %Mono16
    case {'mjpeg','avi'}
writeObj = VideoWriter([fPrefix,'.avi'],...
                        'Motion JPEG AVI');
writeObj.Quality = 100; %trying to avoid compression artifacts--these images are highly compressible anyway
end

writeObj.FrameRate = 10;
open(writeObj)
else writeObj = [];
end
 catch, error('Writing movie files directly must be done in Matlab R2012a or newer')
 end


  %display(I)
swx0 = swirlParam.x0; swy0 = swirlParam.y0;
swstr = swirlParam.strength; swrad = swirlParam.radius;
%
switch lower(OFtestMethod)
    case 'swirlstill' %currently, swirl starts off weak, and increases in strength
        swirlParam.x0(1:length(swirlParam.x0)) = centerCol %FIXME
        display('The Swirl algorithm is alpha-testing--needs manual positioning help')
        for i = I
           
           data(:,:,i) = makeSwirl(bg,...
                                 swx0,swy0,...
                                 swstr * (i-1), swrad,...
                                 false,fillValue,BitDepth);
           doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end
    case 'shearrightswirl' 
        swx0(1:length(swy0)) = centerCol %FIXME
        %method: swirl, then shear
        tic
        
        %parfor i = 1:fStep:nFrame
        for i = I
            
            %Step 1: swirl
            dataFrame = makeSwirl(bg,...
                                 swx0,swy0,...
                                 swstr * i, swrad,...
                                 false,0,BitDepth);
            %step 2: shear
            data(:,:,i) = doShearRight(dataFrame,i,nFrame,dx,nRow,nCol,oldWay); 
            
            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end
        compTime = toc;
        
    case 'still'
        for i = I
            data(:,:,i) = bg; 
            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end 
    case 'rotate360ccw'
        for i = I
            q = (nFrame-i)/nFrame*360; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end 
    case 'rotate180ccw'
        for i = I
            q = (nFrame-i)/nFrame*180; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end 
    case 'rotate90ccw'
        for i = I
            q = (nFrame-i)/nFrame*90; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end   
    case 'shearright'
        for i = I
            data(:,:,i) = doShearRight(bg,i,nFrame,dx,nRow,nCol,oldWay,fillValue);
           
            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end
        
    case 'diagslide'
        for i = I
            T =   [1,0,0
                   0,1,0
                -nFrame+i*dx,  -nFrame+i*dy,  1];
                 
            data(:,:,i) = doTform(T,bg,oldWay,nRow,nCol,fillValue);
           
            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end
        
    case 'horizslide' 
        display('Horizontally moving wall')
        display(size(data))
        close(h.f) % won't use it
        parfor i=I 
          tmpData = zeros(nRow,nCol,myClass);
          for iPhantom = Iphantom
            T =   [1,0,0
                   0,1,0
                  -nFrame+i*dx+phantomSpacing(iPhantom), 0, 1];
                      
            tmpData = tmpData + doTform(T,bg,oldWay,nRow,nCol,fillValue);
          end %for iPhantom
          data(:,:,i) = tmpData;
             %data(:,:,i) = imtranslate(bg,-nFrame+i*dx, 0); %broken in Octave 3.8.1
        end %for i
        try close(h.f), end

        doWriteVid(writeObj,data,writeVid,playVideo,movieType,fPrefix)
        
    case 'vertslide'
        for i = I
            T =   [1,0,0
                   0,1,0
                   0,-nFrame+i*dy, 1];
               
            data(:,:,i) = doTform(T,bg,oldWay,nRow,nCol,fillValue);

            doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix)
        end
   
    otherwise, close(writeObj),error('Unknown method specified') 
end

close(writeObj)

try display([num2str(compTime,'%0.1f'),' seconds required to compute phantom']), end

if nargout>0, varargout{1} = data; end %don't send out huge data if not requested

end

function [bgMaxVal,bgMinVal,data,myClass] = OFgenParamInit(BitDepth,nRow,nCol,nFrame)

if BitDepth == 8 || BitDepth == 16
    myClass = ['uint',int2str(BitDepth)];
    myInt = str2func(myClass);
    bgMaxVal = myInt(2^BitDepth - 1);
elseif BitDepth == 32 
    myClass = 'single';
    bgMaxVal = 1; %normalize
    myInt = str2func(myClass);
elseif BitDepth == 64
    myClass = 'double';
    bgMaxVal = 1; %normalize
    myInt = str2func(myClass);
else 
    error(['unknown bit depth ',int2str(BitDepth)])
end



bgMinVal = myInt(0);


data = zeros(nRow,nCol,nFrame,myClass); %initialize all frame
  display(['max,min pixel intensities for ',myClass,' are taken to be: ',num2str(bgMinVal),',',num2str(bgMaxVal)])

end

function data = doTform(T,bg,oldWay,nRow,nCol,fillValue)
            if ~oldWay  %new way    
                tform = affine2d(T); 
                RA = imref2d([nCol,nRow],[1 nCol],[1 nRow]);
                data = imwarp(bg,tform,'outputView',RA);
            else % old way     
                
                tform = maketform('affine',T);   %#ok<MTFA1>
                
                data = imtransform(bg,tform,'bilinear',...
                     'Udata',[1 nCol],...
                     'Vdata',[1 nRow],...
                     'Xdata',[1 nCol],...
                     'Ydata',[1 nRow],...
                     'fillvalues',fillValue,...
                     'size',[nRow,nCol]); %#ok<DIMTRNS>
                 
            end
%display(['bg ',int2str(size(bg))])
%display(nCol); display(nRow)
%display(['data size ',int2str(size(data))])
            
end %function

function doVid(writeObj,dataFrame,writeVid,playVideo,movieType,hImg,i,fPrefix)
% this only works for NON-parfor methods!
% 
if writeVid
    switch lower(movieType)
        case {'lossless','mjpeg','avi'}, writeVideo(writeObj,dataFrame)
        case 'png', imwrite(dataFrame,[fPrefix,int2str(i),'.png'],'png')
        case 'pgm', imwrite(dataFrame,[fPrefix,int2str(i),'.pgm'],'pgm')
    end
end
if playVideo
    set(hImg.img,'cdata',dataFrame)
    set(hImg.t,'string',['Frame ',int2str(i)])
    pause(0.01)
end
end

function doWriteVid(writeObj,data,writeVid,playVideo,movieType,fPrefix)
% this function is for those methods using parfor
if writeVid
    [nRow,nCol,nFrame] = size(data);
    switch lower(movieType)
       
        case {'lossless','mjpeg','avi'}, 
            writeVideo(writeObj,reshape(data,nRow,nCol,1,nFrame))
        
        otherwise
            tmpVidFN = [fPrefix,'.avi'];
            display(['trying to make video ',tmpVidFN,' then convert to ',movieType])
            try
               writeObj = VideoWriter(tmpVidFN, 'Motion JPEG AVI');
               writeObj.Quality = 100; 
               open(writeObj)
               writeVideo(writeObj,reshape(data,nRow,nCol,1,nFrame))
               display(['attempting to convert ',tmpVidFN,' to ',movieType,' via ImageMagick via command'])
               ffmpegcmd = ['convert -verbose ',tmpVidFN,' -type Grayscale ',fPrefix,'%03d.pgm'];
               display(ffmpegcmd)
               unix(ffmpegcmd)
            catch
                display(['Im sorry, I was unable to complete conversion of ',tmpVidFN,' to ',movieType])
                lasterr
            end %try
            
    end %switch

end
if playVideo
   implay(data) 
end
end

function dataFrame = doShearRight(bg,i,nFrame,dx,nRow,nCol,oldWay,fillValue)
%display(i)
           T = [1,0,0;...
               (nFrame-i*dx)/nFrame,1,0;...
                 0,0,1];
           
 dataFrame = doTform(T,bg,oldWay,nRow,nCol,fillValue);
end
