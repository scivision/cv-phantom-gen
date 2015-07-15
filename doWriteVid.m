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

end %if
if playVideo && ~isoctave
   implay(data)
end
end %function
