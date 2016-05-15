function [bg,data] = phantomTexture(U)
bitdepth=U.bitdepth;
nrow = U.rowcol(1); ncol= U.rowcol(2); nframe=U.nframe;
fwidth = U.fwidth; 

[bgmm,data,dtype] = OFgenParamInit(bitdepth,U.rowcol,nframe);

%% need this for when this function is called by itself using Oct2Py/Octave
try
 fspecial('average',1); 
catch
 pkg load image
end

%% main program
switch lower(U.texture)
    case 'wall'           
        bg = bgmm(2) .* ones(U.rowcol,dtype);
    case 'uniformrandom'
        bg = bgmm(1) + (bgmm(2)-bgmm(1)) .* cast(rand(U.rowcol),dtype);
    case {'gaussian'}
        bg = fspecial('gaussian',U.rowcol, U.gaussiansigma); %create wide 2D gaussian shape
        bg = double(bgmm(2)).*bg./max(max(bg)); %normalize to full bit range
        bg = cast(bg,dtype); %cast to desired class
    case {'vertsine'}
        bgr = zeros(1,ncol,'double'); %yes, double to avoid quantization
        bg = zeros(U.rowcol,dtype);
        bgr(fwidth-fwidth/2:fwidth+fwidth/2-1) = sind(linspace(0,180,fwidth)); %don't do int8 yet or you'll quantize it to zero!
        rowind = nrow*1/4:nrow*3/4;
        %bg = double(bgMaxVal) .* repmat(bg,nRow,1);
	      bg(rowind,:) = double(bgmm(2)) .* repmat(bgr,length(rowind),1);
        bg = cast(bg,dtype);    % cast to desired class
    case 'laplacian'
        bg = abs(fspecial('log',U.rowcol,50)); %double
        bg = cast(double(bgmm(2)).* bg./max(bg(:)),dtype); %normalize to full bit range
    case 'checkerboard'
        bg = cast(checkerboard(nrow/8).*double(bgmm(2)),dtype);
    case 'xtriangle'
        bg(1,1:ncol/2) = cast(bgmm(1):round((bgmm(2)-bgmm(1))/(nrow/2)):bgmm(2),dtype);
        bg(1,ncol/2+1:ncol) = fliplr(bg);   
        bg = repmat(bg,[nrow,1]);
    case 'ytriangle'
        bg(1:nrow/2,1) = cast(bgmm(1):round((bgmm(2)-bgmm(1))/(nrow/2)):bgmm(2),dtype);
        bg(nrow/2+1:nrow,1) = flipud(bg);   
        bg = repmat(bg,[1,ncol]);
    case {'pyramid','pyramid45'}
        bg = zeros(nrow,ncol,dtype);
        temp = cast(bgmm(1):round((bgmm(2)-bgmm(1))/(nrow/2)):bgmm(2),dtype);
        for i = 1:nrow/2
           bg(i,i:end-i+1) = temp(i); %north face
           bg(i:end-i+1,i) = temp(i); %west face
           bg(end-i+1,i:end-i+1) = temp(i); %south face
           bg(i:end-i+1,end-i+1) = temp(i); %east face
        end
        if strcmpi(U.texture,'pyramid45')
            bg = imrotate(bg,45,'bilinear','crop'); 
        end
    case 'spokes' %3 pixels wide
        bg = zeros(U.rowcol,dtype);
        bg(nrow/2-floor(fwidth/2) : nrow/2+ floor(fwidth/2) ,1:ncol) = bgmm(2); %horizontal line
        bg(1:nrow,...
            ncol/2-floor(fwidth/2): ncol/2+ floor(fwidth/2)  ) = bgmm(2); %vertical line
        bg = bg + imrotate(bg,45,'bilinear','crop'); %diagonal line
    case 'vertbar' %vertical bar, starts center of image
        bg = zeros(U.rowcol,dtype);

        %bg(1:nRow,end-4:end) = bgMaxVal; %vertical line, top to bottom

        % vertical bar starts 1/4 from bottom and 1/4 from top of image
        bg(nrow*1/4:nrow*3/4, ncol/2 - floor(fwidth/2) : ncol/2 + floor(fwidth/2)) = bgmm(2);
    otherwise, error(['unspecified texture ',U.texture,' selected'])
end %switch
end %function

function [bgmm,data,dtype] = OFgenParamInit(BitDepth,rowcol,nFrame)

if BitDepth == 8 || BitDepth == 16
    dtype = ['uint',int2str(BitDepth)];
    bgMax = intmax(dtype);
elseif BitDepth == 32
    dtype = 'single';
    bgMax = 1; %normalize
elseif BitDepth == 64
    dtype = 'double';
    bgMax = 1; %normalize
else
    error(['unknown bit depth ',int2str(BitDepth)])
end

bgMin = cast(0,dtype);

% rowcol explicit indicies for oct2py compatibility
data = zeros([rowcol(1),rowcol(2),nFrame],dtype); %initialize all frame

  disp(['max,min pixel intensities for ',dtype,' are taken to be: ',num2str(bgMin),',',num2str(bgMax)])

bgmm = [bgMin,bgMax];

end %function
