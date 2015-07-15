function data = translateTexture(bg,data,oldWay,swirlParam,U)
isoct = isoctave;
%% need this for when this function is called by itself using Oct2Py/Octave
if isoct
 pkg load image
end

[nRow,nCol,nFrame] = size(data);
fillValue = 0;
%display(I)
try
    swx0 = swirlParam.x0; swy0 = swirlParam.y0;
    swstr = swirlParam.strength; swrad = swirlParam.radius;
end
%% init figure
if U.playvideo
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
else 
    h.img = [];
end

%% multiple phantoms
%indices for frame looping
I = 1:U.fstep:U.nframe;
%%
[fPrefix,writeObj]= setupvid(U.translate, U.texture, U.movietype);
%%
if ~oldWay
    RA = imref2d([nCol,nRow],[1 nCol],[1 nRow]);
end

%if isempty(mtranslate), data=[]; return, end
switch lower(U.translate)
    case 'swirlstill' %currently, swirl starts off weak, and increases in strength
        swirlParam.x0(1:length(swirlParam.x0)) = U.fwidth; %FIXME
        display('The Swirl algorithm is alpha-testing--needs manual positioning help')
        for i = I

           data(:,:,i) = makeSwirl(bg,...
                                 swx0,swy0,...
                                 swstr * (i-1), swrad,...
                                 false,fillValue,U.bitdepth);
           doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end
    case 'shearrightswirl'
        swx0(1:length(swy0)) = centerCol; %FIXME
        %method: swirl, then shear

        %parfor i = 1:fStep:nFrame
        for i = I

            %Step 1: swirl
            dataFrame = makeSwirl(bg,...
                                 swx0,swy0,...
                                 swstr * i, swrad,...
                                 false,0,BitDepth);
            %step 2: shear
            data(:,:,i) = doShearRight(dataFrame,i,nFrame,dxy(1),nRow,nCol,oldWay);

            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end

    case 'still'
        for i = I
            data(:,:,i) = bg;
            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end
    case 'rotate360ccw'
        for i = I
            q = (nFrame-i)/nFrame*360; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end
    case 'rotate180ccw'
        for i = I
            q = (nFrame-i)/nFrame*180; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end
    case 'rotate90ccw'
        for i = I
            q = (nFrame-i)/nFrame*90; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end
    case 'shearright'
        for i = I
            data(:,:,i) = doShearRight(bg,i,nFrame,dxy(1),nRow,nCol,oldWay,fillValue);

            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end

    case 'diagslide'
        for i = I
            T =   [1,0,0
                   0,1,0
                -nFrame+i*dxy(1),  -nFrame+i*dxy(2),  1];

            data(:,:,i) = doTform(T,RA,bg,oldWay,nRow,nCol,fillValue);

            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end

    case 'horizslide'
        display(['Horizontally moving feature, dim: ',num2str(size(data))])
        %parfor i=I
        for i=I
          % imtranslate ~50% faster than doTform way
          if isoct
            data(:,:,i) = imtranslate(bg,[-nFrame+i*U.dxy(1), 0]); 
          else %octave 4.0 with image 2.4.0 revised in 2013 still has messed-up imtranslate that wraps
            %data(:,:,i) = imtranslate(bg,-nFrame+i*U.dxy(1), 0,'wrap');  %NO
            T =   [1,0,0
                   0,1,0
                  -nFrame+i*U.dxy(1), 0, 1];
            data(:,:,i)= doTform(T,RA,bg,oldWay,nRow,nCol,fillValue);
          end
          doVid(writeObj,data(:,:,i),U,h,i,fPrefix) 
        end %for i

        doWriteVid(writeObj,data,U)

    case 'vertslide'
        for i = I
            T =   [1,0,0
                   0,1,0
                   0,-nFrame+i*U.dxy(2), 1];

            data(:,:,i) = doTform(T,RA,bg,oldWay,U.nrow,U.ncol,fillValue);

            doVid(writeObj,data(:,:,i),U,h,i,fPrefix)
        end

    otherwise 
        try close(writeObj), end
        error(['Unknown motion method ',U.translate,' specified'])
end %switch
try close(writeObj),end
end %function

function doVid(writeObj,dataFrame,U,hImg,i,fPrefix)
% this only works for NON-parfor methods!
%
if ~isempty(U.movietype)
    switch lower(U.movietype)
        case {'lossless','mjpeg','avi'}
            writeVideo(writeObj,dataFrame)
        case 'png'
            imwrite(dataFrame,[fPrefix,int2str(i),'.png'],'png')
        case 'pgm'
            imwrite(dataFrame,[fPrefix,int2str(i),'.pgm'],'pgm')
    end
end

if U.playvideo
    set(hImg.img,'cdata',dataFrame)
    set(hImg.t,'string',['Frame ',int2str(i)])
    pause(0.001)
end
end %function

function data = doTform(T,RA,bg,oldWay,nRow,nCol,fillValue)
    if ~oldWay  %new way
        tform = affine2d(T);
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

function [fPrefix,writeObj] = setupvid(translate,textureSel,movieType)
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

end %function

function dataFrame = doShearRight(bg,i,nFrame,dx,nRow,nCol,oldWay,fillValue)
%display(i)
           T = [1,0,0;...
               (nFrame-i*dx)/nFrame,1,0;...
                 0,0,1];

 dataFrame = doTform(T,bg,oldWay,nRow,nCol,fillValue);
end %function

function doWriteVid(writeObj,data,U)
% this function is for those methods using parfor
if ~isempty(U.movietype)
    [nRow,nCol,nFrame] = size(data);

    writeVideo(writeObj,reshape(data,nRow,nCol,1,nFrame))
end 

end %function

