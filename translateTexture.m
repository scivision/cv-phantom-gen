function data = translateTexture(bg,data,swirlParam,U)
if ~isfield(U,'motion')
    U.motion=[];
end

%% need this for when this function is called by itself using Oct2Py
% if missing package, try from Octave prompt:  pkg install -verbose -forge image

try
  fspecial('average',1);
catch
  pkg load image
end

nRow = U.rowcol(1); nCol = U.rowcol(2); nFrame = size(data,3);
fillValue = 0;
%display(I)
try
    swx0 = swirlParam.x0; swy0 = swirlParam.y0;
    swstr = swirlParam.strength; swrad = swirlParam.radius;
end

%% multiple phantoms
%indices for frame looping
I = 1:U.fstep:U.nframe;
%%
if ~isoctave
    RA = imref2d([nCol,nRow],[1 nCol],[1 nRow]);
else
    RA =[];
end

%if isempty(mtranslate), data=[]; return, end
switch lower(U.motion)
    case {'none',[]} % no motion
        for i = I
            data(:,:,i) = bg;
        end
    case 'swirlstill' %currently, swirl starts off weak, and increases in strength
        swirlParam.x0(1:length(swirlParam.x0)) = U.fwidth; %FIXME
        display('The Swirl algorithm is alpha-testing--needs manual positioning help--try vertbar texture')
        for i = I

           data(:,:,i) = makeSwirl(bg,...
                                 swx0,swy0,...
                                 swstr * (i-1), swrad,...
                                 false,fillValue,U.bitdepth);
        end
    case 'shearrightswirl'
        display('swirl location not matching shear right now? shear going wrong way?')
        swx0(1:length(swy0)) = U.fwidth; %FIXME
        %method: swirl, then shear

        %parfor i = 1:fStep:nFrame
        for i = I

            %Step 1: swirl
            dataFrame = makeSwirl(bg,...
                                 swx0,swy0,...
                                 swstr * (i-1), swrad,...
                                 false,fillValue,U.bitdepth);
            %step 2: shear
            data(:,:,i) = doShearRight(dataFrame,RA,i,nFrame,U.dxy(1),U.rowcol,fillValue);
        end
    case 'rotate360ccw'
        for i = I
            q = (nFrame-i)/nFrame*360; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
        end
    case 'rotate180ccw'
        for i = I
            q = (nFrame-i)/nFrame*180; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
        end
    case 'rotate90ccw'
        for i = I
            q = (nFrame-i)/nFrame*90; %degrees
            data(:,:,i) = imrotate(bg,q,'bilinear','crop');
        end
    case 'shearright'
        for i = I
            data(:,:,i) = doShearRight(bg,RA,i,nFrame,U.dxy(1),U.rowcol,fillValue);
        end

    case 'diagslide'
        for i = I
            T =   [1,0,0
                   0,1,0
                -nFrame+i*U.dxy(1),  -nFrame+i*U.dxy(2),  1];

            data(:,:,i) = doTform(T,RA,bg,U.rowcol,fillValue);
        end

    case 'horizslide'
        display(['Horizontally moving feature, dim: ',num2str(size(data))])
        %parfor i=I
        for i=I
          % imtranslate ~50% faster than doTform way
          if ~isempty(RA)
            data(:,:,i) = imtranslate(bg,[-nFrame+i*U.dxy(1), 0]);
          else %octave 4.0 with image 2.4.0 revised in 2013 still has messed-up imtranslate that wraps
            %data(:,:,i) = imtranslate(bg,-nFrame+i*U.dxy(1), 0,'wrap');  %NO
            T =   [1,0,0
                   0,1,0
                  -nFrame+i*U.dxy(1), 0, 1];
            data(:,:,i)= doTform(T,RA,bg,U.rowcol,fillValue);
          end
        end %for i



    case 'vertslide'
        for i = I
            T =   [1,0,0
                   0,1,0
                   0,-nFrame+i*U.dxy(2), 1];

            data(:,:,i) = doTform(T,RA,bg,U.rowcol,fillValue);
        end

    otherwise
        error(['Unknown motion method ',U.translate,' specified'])
end %switch

end %function


function data = doTform(T,RA,bg,rowcol,fillValue)
    nrow = rowcol(1); ncol=rowcol(2);
    if ~isempty(RA)  %new way
        tform = affine2d(T);
        data = imwarp(bg,tform,'outputView',RA);
    else % old way

        tform = maketform('affine',T);   %#ok<MTFA1>

        data = imtransform(bg,tform,'bilinear',...
             'Udata',[1 ncol],...
             'Vdata',[1 nrow],...
             'Xdata',[1 ncol],...
             'Ydata',[1 nrow],...
             'fillvalues',fillValue,...
             'size',rowcol); %#ok<DIMTRNS>

    end
%display(['bg ',int2str(size(bg))])
%display(nCol); display(nRow)
%display(['data size ',int2str(size(data))])

end %function

function dataFrame = doShearRight(bg,RA,i,nFrame,dx,rowcol,fillValue)
%display(i)
           T = [1,0,0;...
               (nFrame-i*dx)/nFrame,1,0;...
                 0,0,1];

             dataFrame = doTform(T,RA,bg,rowcol,fillValue);
end %function

function doWriteVid(writeObj,data,U)
% this function is for those methods using parfor
if ~isempty(writeObj) && ~isempty(U.movietype)
    [nRow,nCol,nFrame] = size(data);

    writeVideo(writeObj,reshape(data,nRow,nCol,1,nFrame))
end

end %function

