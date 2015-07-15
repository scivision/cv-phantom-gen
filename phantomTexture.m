function [bg,data] = phantomTexture(U)
bitdepth=U.bitdepth;
nrow = U.nrow; ncol=U.ncol; nframe=U.nframe;
fwidth = U.fwidth; 

[bgmm,data,dtype] = OFgenParamInit(bitdepth,nrow,ncol,nframe);

%% need this for when this function is called by itself using Oct2Py/Octave
try
 fspecial('average',1); 
catch
 pkg load image
end

%% main program
   myInt = str2func(dtype);
switch lower(U.texture)
    case 'wall'           
        bg = bgmm(2) .* ones(nrow,ncol,dtype);
    case 'uniformrandom'
        bg = bgmmx(1) + (bgmm(2)-bgmm(1)).*rand(nrow,ncol);
    case {'gaussian'}
        bg = fspecial('gaussian',[nrow,ncol],GaussSigma); %create wide 2D gaussian shape
        bg = double(bgmm(2)).*bg./max(max(bg)); %normalize to full bit range
        bg = myInt(bg); %cast to desired class
    case {'vertsine'}
        bgr = zeros(1,ncol,'double'); %yes, double to avoid quantization
        bg = zeros(nrow,ncol,dtype);
        bgr(fwidth-fwidth/2:fwidth+fwidth/2-1) = sind(linspace(0,180,fwidth)); %don't do int8 yet or you'll quantize it to zero!
        rowind = nrow*1/4:nrow*3/4;
        %bg = double(bgMaxVal) .* repmat(bg,nRow,1);
	      bg(rowind,:) = double(bgmm(2)) .* repmat(bgr,length(rowind),1);
        bg = myInt(bg);    % cast to desired class
    case 'laplacian'
        bg = abs(fspecial('log',[nRow,nCol],50));
        bg = bgmm(2).*bg./max(max(bg)); %normalize to full bit range
    case 'checkerboard'
    bg = myInt(checkerboard(nRow/8).*bgmm(2));
    case 'xtriangle'
    bg(1,1:nCol/2) = myInt(bgmm(1):round((bgmm(2)-bgmm(1))/(nRow/2)):bgmm(2));
    bg(1,nCol/2+1:nCol) = fliplr(bg);   bg = repmat(bg,[nRow,1]);
    case 'ytriangle'
    bg(1:nRow/2,1) = myInt(bgmm(1):round((bgmm(2)-bgmm(1))/(nRow/2)):bgmm(2));
    bg(nRow/2+1:nRow,1) = flipud(bg);   bg = repmat(bg,[1,nCol]);
    case {'pyramid','pyramid45'}
        bg = zeros(nrow,ncol,dtype);
        temp = myInt(bgmm(1):round((bgmm(2)-bgmm(1))/(nRow/2)):bgmm(2));
        for i = 1:nRow/2
           bg(i,i:end-i+1) = temp(i); %north face
           bg(i:end-i+1,i) = temp(i); %west face
           bg(end-i+1,i:end-i+1) = temp(i); %south face
           bg(i:end-i+1,end-i+1) = temp(i); %east face
        end
        if strcmpi(textureSel,'pyramid45'), bg = imrotate(bg,45,'bilinear','crop'); end
    case 'spokes' %3 pixels wide
        bg = zeros(nRow,nCol,dtype);
        bg(nrow/2-floor(fwidth/2) : nrow/2+ floor(fwidth/2) ,1:ncol) = bgmm(2); %horizontal line
        bg(1:nrow,...
            ncol/2-floor(fwidth/2): ncol/2+ floor(fwidth/2)  ) = bgmm(2); %vertical line
        bg = bg + imrotate(bg,45,'bilinear','crop'); %diagonal line
    case 'vertbar' %vertical bar, starts center of image
        bg = zeros(nrow,ncol,dtype);

        %bg(1:nRow,end-4:end) = bgMaxVal; %vertical line, top to bottom

        % vertical bar starts 1/4 from bottom and 1/4 from top of image
        bg(nrow*1/4:nrow*3/4, ncol/2 - floor(fwidth/2) : ncol/2 + floor(fwidth/2)) = bgmm(2);
    otherwise, error(['unspecified texture ',textureSel,' selected'])
end %switch
end %function

function [bgmm,data,myClass] = OFgenParamInit(BitDepth,nRow,nCol,nFrame)

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

bgmm = [bgMin,bgMax];
end %function
