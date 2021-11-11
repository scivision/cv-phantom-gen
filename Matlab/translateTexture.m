function data = translateTexture(bg,data,swirlParam,U)
% function data = translateTexture(bg,data,swirlParam,U)
%
% to make multiple simulataneous phantoms, call this function repeatedly and sum the result
%

if ~isfield(U,'motion')
    U.motion=[];
end
if ~isfield(U,'nframe') || isempty(U.nframe)
    U.nframe=1;
end
if ~isfield(U,'fstep') || isempty(U.fstep)
    U.fstep=1;
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
%disp(I)
swx0 = swirlParam.x0; swy0 = swirlParam.y0;
swstr = swirlParam.strength; swrad = swirlParam.radius;

%% multiple phantoms
%indices for frame looping
I = 1:U.fstep:U.nframe;
%%
RA = imref2d([nCol,nRow],[1 nCol],[1 nRow]);

%if isempty(mtranslate), data=[]; return, end
switch lower(U.motion)
    case {'none',[]} % no motion
        for i = I
            data(:,:,i) = bg;
        end
    case 'swirlstill' %currently, swirl starts off weak, and increases in strength
        swirlParam.x0(1:length(swirlParam.x0)) = U.fwidth; %FIXME
        disp('The Swirl algorithm is alpha-testing--needs manual positioning help--try vertbar texture')
        for i = I

           data(:,:,i) = makeSwirl(bg,...
             swx0,swy0,...
             swstr * (i-1), swrad,...
             false,fillValue,U.bitdepth);
        end
    case 'shearrightswirl'
        disp('swirl location not matching shear right now? shear going wrong way?')
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
        disp(['Horizontally moving feature, dim: ',num2str(size(data))])
        %parfor i=I
        for i=I
          % imtranslate ~50% faster than doTform way
          data(:,:,i) = imtranslate(bg,[-nFrame+i*U.dxy(1), 0]);
        end %for i



    case 'vertslide'
        for i = I
            T =   [1,0,0
                   0,1,0
                   0,-nFrame+i*U.dxy(2), 1];

            data(:,:,i) = doTform(T,RA,bg);
        end

    otherwise
        error(['Unknown motion method ',U.translate,' specified'])
end %switch

end %function


function data = doTform(T,RA,bg)
    tform = affine2d(T);
    data = imwarp(bg,tform,'outputView',RA);
%disp(['bg ',int2str(size(bg))])
%disp(nCol); disp(nRow)
%disp(['data size ',int2str(size(data))])

end %function

function dataFrame = doShearRight(bg,RA,i,nFrame,dx,rowcol,fillValue)
%disp(i)
           T = [1,0,0;...
               (nFrame-i*dx)/nFrame,1,0;...
                 0,0,1];

             dataFrame = doTform(T,RA,bg,rowcol,fillValue);
end %function
