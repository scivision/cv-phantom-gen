function bg = phantomTexture(textureSel,dtype,nRow,nCol,bgminmax,pWidth,GaussSigma)

%% need this for when this function is called by itself using Oct2Py/Octave
try
 fspecial('average',1,1)
catch
 pkg load image
end
%% main program
   myInt = str2func(dtype);
switch lower(textureSel)
    case 'wall'           
        bg = bgminmax(2) .* ones(nRow,nCol,dtype);
    case 'uniformrandom'
        bg = bgminmax(1) + (bgminmax(2)-bgminmax(1)).*rand(nRow,nCol);
    case {'gaussian'}
        bg = fspecial('gaussian',[nRow,nCol],GaussSigma); %create wide 2D gaussian shape
        bg = double(bgminmax(2)).*bg./max(max(bg)); %normalize to full bit range
        bg = myInt(bg); %cast to desired class
    case {'vertsine'}
        centerCol = pWidth; %<update>
        bgr = zeros(1,nCol,'double'); %yes, double to avoid quantization
        bg = zeros(nRow,nCol,dtype);
        bgr(pWidth-pWidth/2:pWidth+pWidth/2-1) = sind(linspace(0,180,pWidth)); %don't do int8 yet or you'll quantize it to zero!
        rowind = nRow*1/4:nRow*3/4;
        %bg = double(bgMaxVal) .* repmat(bg,nRow,1);
	      bg(rowind,:) = double(bgminmax(2)) .* repmat(bgr,length(rowind),1);
        bg = myInt(bg);    % cast to desired class
    case 'laplacian'
        bg = abs(fspecial('log',[nRow,nCol],50));
        bg = bgminmax(2).*bg./max(max(bg)); %normalize to full bit range
    case 'checkerboard'
    bg = myInt(checkerboard(nRow/8).*bgminmax(2));
    case 'xtriangle'
    bg(1,1:nCol/2) = myInt(bgminmax(1):round((bgminmax(2)-bgminmax(1))/(nRow/2)):bgminmax(2));
    bg(1,nCol/2+1:nCol) = fliplr(bg);   bg = repmat(bg,[nRow,1]);
    case 'ytriangle'
    bg(1:nRow/2,1) = myInt(bgminmax(1):round((bgminmax(2)-bgminmax(1))/(nRow/2)):bgminmax(2));
    bg(nRow/2+1:nRow,1) = flipud(bg);   bg = repmat(bg,[1,nCol]);
    case {'pyramid','pyramid45'}
        bg = zeros(nRow,nCol,dtype);
        temp = myInt(bgminmax(1):round((bgminmax(2)-bgminmax(1))/(nRow/2)):bgminmax(2));
        for i = 1:nRow/2
           bg(i,i:end-i+1) = temp(i); %north face
           bg(i:end-i+1,i) = temp(i); %west face
           bg(end-i+1,i:end-i+1) = temp(i); %south face
           bg(i:end-i+1,end-i+1) = temp(i); %east face
        end
        if strcmpi(textureSel,'pyramid45'), bg = imrotate(bg,45,'bilinear','crop'); end
    case 'spokes' %3 pixels wide
        bg = zeros(nRow,nCol,dtype);
        bg(nRow/2-floor(pWidth/2) : nRow/2+ floor(pWidth/2) ,1:nCol) = bgminmax(2); %horizontal line
        bg(1:nRow,...
            nCol/2-floor(pWidth/2): nCol/2+ floor(pWidth/2)  ) = bgminmax(2); %vertical line
        bg = bg + imrotate(bg,45,'bilinear','crop'); %diagonal line
    case 'vertbar' %vertical bar, starts center of image
        centerCol = nRow/2;
        bg = zeros(nRow,nCol,dtype);

        %bg(1:nRow,end-4:end) = bgMaxVal; %vertical line, top to bottom

        % vertical bar starts 1/4 from bottom and 1/4 from top of image
        bg(nRow*1/4:nRow*3/4, nCol/2 - floor(pWidth/2) : nCol/2 + floor(pWidth/2)) = bgminmax(2);
    otherwise, error(['unspecified texture ',textureSel,' selected'])
end %switch
end %function
