function testFFT()
close('all')

npix = 512;
nrep = 3;
nsin = npix/nrep;
%% sine wave
s(1,:) = sind(linspace(0,360,nsin));
s = s + 1; %keeps always positive -- probably not needed but...
s = repmat(s,npix,nrep);

Smagdb = doplot(s);
disp('zoom into figure 3 to see the peaks near the center "DC" value')
%% skelton like

q = false(512);
q(:,[20,40]) = true;
% "bend" the vertical lines
maxshift = 10;
cshft = round(maxshift * sind(linspace(0,180,npix)));
% could probably do this with bsxfun, but clarity > efficiency here
for iq = 1:npix
    qrow(1,:) = q(iq,:);
    shift = [0,cshft(iq)]; %this is a row vector, so we use 2nd argument
   q(iq,:) = circshift(qrow,shift);
end

Qmagdb = doplot(q);

end

function Dmagdb = doplot(d)

npix = size(d,1);

figure
imagesc(d),colormap('gray')
title('d')
xlabel('x-pix')
ylabel('y-pix')
%%
d = padarray(d,[npix,npix]);
D = fftshift(fft2(d));
Dmagdb = 20*log10(abs(D));
%%
figure
imagesc(Dmagdb)
title('|D| [dB]')
xlabel('x-frequency bin #')
ylabel('y-frequency bin #')
title('|D| [dB]')
colorbar
set(gca,'clim',[0,55])
%%
%get middle row index
mid = size(d,1)/2+1;

figure
plot(abs(D(mid,:))) %1-D cut of center 
title('1-D center cut of |D|')
axis('tight')
xlabel('frequency bin #')
ylabel('|D|')

end
