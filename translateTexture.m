function data = translateTexture(bg,data,h,I,Iphantom,dx,nRow,nCol,myClass,oldWay,swirlParam,phantomSpacing,writeObj,writeVid,playVideo,movieType,fPrefix,nFrame,mtranslate)

fillValue = 0;

%display(I)
swx0 = swirlParam.x0; swy0 = swirlParam.y0;
swstr = swirlParam.strength; swrad = swirlParam.radius;
%%
switch lower(mtranslate)
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
        %parfor i=I
        for i=I
          tmpData = zeros(nRow,nCol,myClass);
          for iPhantom = Iphantom
            T =   [1,0,0
                   0,1,0
                  -nFrame+i*dx+phantomSpacing(iPhantom), 0, 1];

            tmpData = tmpData + doTform(T,bg,oldWay,nRow,nCol,fillValue);
          end %for iPhantom
          data(:,:,i) = tmpData;
          %data(:,:,i) = imtranslate(bg,-nFrame+i*dx, 0); %broken in Octave 3.8.1
          doVid(writeObj,data(:,:,i),writeVid,playVideo,movieType,h,i,fPrefix) 
        end %for i

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
end %switch
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
end %function

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
