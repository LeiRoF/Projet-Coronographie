function [Zr, R] = process(N, D, div, Op, Ol, yc, xc, m, res, l, i, mask, nb_Mirrors, Radius, Gap, nb_arms, arms_width, arms_width_lyot, Progress)
  
  name = sprintf('D=%.2f, Div=%d, l=%.2f, Op=%.2f, Ol=%.2f', D, div, l, Op, Ol);
  
  % __________________________________________________  
  % G�n�ration ou r�cup�ration du mirroir segment�
  
  fname = sprintf('0-Mirror Div = %.2f px.um-1, Segments = %d, Radius= %.2f um, Gap = %.2f um.fits', div, nb_Mirrors, Radius, Gap);
  if isfile(fname)
    waitbar(0.0, Progress, 'Recuperation of existing mirror');
    [pup,hdr] = readfits(fname);
  else
    waitbar(0.0, Progress, 'Generating mirror');
    Grid = BuildGrid(Radius, sqrt(3.)*Radius/2., Gap, nb_Mirrors, Progress);
    BasisSegmentsCube = BuildApodizedSegment(Grid, Radius, sqrt(3.)*Radius/2., nb_Mirrors,Progress); % segments
    pup = BuildApodizedPupil(Radius, sqrt(3.)*Radius/2., nb_Mirrors, Grid, BasisSegmentsCube, Gap,Progress); % pupil wo aberrations
    writefits(fname,pup);
  end
  
  % __________________________________________________ 
  % Rendre la matrice du miroir carr�e
  
  N
  [sx, sy] = size(pup)
  if sx < N && sy < N
    pup_tmp = zeros(N);
    
    %pup_tmp(N/2+1-floor(sx/2) : N/2+floor(sx/2)+1 , N/2+1-floor(sy/2) : N/2+floor(sy/2)+1) = pup;
    ox = ceil(N/2-sx/2)
    oy = ceil(N/2-sy/2)
    
    w = zeros(sx+2,sy+2);
    w(:,:) = 1;
    %writefits('Test0.fits',w);
    %pup_tmp(ox-1 : ox+sx , oy-1 : oy+sy) = w;
    %writefits('Test1.fits',pup_tmp);
    pup_tmp(ox+2 : ox+sx+1 , oy+2 : oy+sy+1) = pup;
    %writefits('Test2.fits',pup_tmp);
    
  end
  clear pup;
  pup = pup_tmp;
  
  % __________________________________________________ 
  % Cr�ation de la pupille
  
  waitbar(0.1, Progress, 'G�n�ration de la pupille');
  p = mkpup(N ,D ,Op) .* mkspider(N, nb_arms, arms_width);
  
  % __________________________________________________ 
  % Application de la pupille au miroir
  
  p = pup .* p;
  waitbar(0.2, Progress, 'Application de la pupille');
  writefits(sprintf('1-Pupille %s.fits', name),p);
  
  % __________________________________________________ 
  % Cr�ation du masque
  
  waitbar(0.3, Progress, 'G�n�ration du masque');
  M = FQPM(N, N/2, N/2);
  writefits("2-Masque.fits", M);
  
  % __________________________________________________ 
  % Pupille: TF -> PSF
  
  waitbar(0.4, Progress, 'TF 1');
  A = Shift_im2(p, N);
  writefits(sprintf('3a-TFPupille %s.fits', name),A);
  writefits(sprintf('3b-TFPupille %s.fits', name),abs(A).^2);
  a = A;
  % A: avec masque      a: sans masque
  
  % __________________________________________________ 
  % Application du masque
  
  waitbar(0.5, Progress, 'Application du masque');
  if mask == 1;
  A = A .* M;
  writefits(sprintf('4a-TFMasque %s.fits', name), A);
  writefits(sprintf('4b-TFMasque %s.fits', name), abs(A).^2);
  end;

  % __________________________________________________ 
  % TF-1
  
  waitbar(0.6, Progress, 'TF 2');
  A = fftshift(ifft2(fftshift(A)));
  writefits(sprintf('5a-TFMasque2 %s.fits', name), A);
  writefits(sprintf('5b-TFMasque2 %s.fits', name), abs(A).^2);
  
  % __________________________________________________ 
  % Cr�ation du Lyot
  
  waitbar(0.7, Progress, 'G�n�ration du Lyot Stop');
  L = mkpup(N, D*l, Ol);
  L = L .* mkspider(N, nb_arms, arms_width_lyot);
  writefits(sprintf("6-Lyot %s.fits", name),L);
  
  % __________________________________________________ 
  % Application du Lyot
  
  waitbar(0.8, Progress, 'Application du Lyot Stop');
  A = A .* L;
  writefits(sprintf('7a-ApplicationLyot %s.fits', name),A);
  writefits(sprintf('7b-ApplicationLyot %s.fits', name),abs(A).^2);

  % __________________________________________________ 
  % TF -> PSF Coronographique
  
  waitbar(0.9, Progress, 'TF 3');
  A = fftshift(fft2(fftshift(A)));
  writefits(sprintf('8a-TFLyot %s.fits', name),A);
  writefits(sprintf('8b-TFLyot %s.fits', name),abs(A).^2);
  
  % __________________________________________________ 
  % Profil radial PSF
  
  waitbar(1.0, Progress, 'G�n�ration du profile radial');
  Max = max(max(abs(a)^2)); % Max 2D
  B = (abs(A)^2)/Max;
  [Zr, R] = radialavg(B,m,0,0,Progress);
  
  % __________________________________________________ 
  % Plots
  
  if mod(i,3) == 0;
  semilogy((R(1:res*12)*N/2)/res,Zr(1:res*12),'--','DisplayName',name);hold on;
  end;
  if mod(i,3) == 1;
  semilogy((R(1:res*12)*N/2)/res,Zr(1:res*12),':','DisplayName',name);hold on;
  end;
  if mod(i,3) == 2;
  semilogy((R(1:res*12)*N/2)/res,Zr(1:res*12),'-.','DisplayName',name);hold on;
  end;

  % __________________________________________________ 
  % Legend
  
  xlabel({'Position sur le d�tecteur','(en r�solution angulaire)'});
  ylabel ({'Intensit� normalis�e'});
  set(gcf, 'name', 'Profil radial av masque');
  
endfunction