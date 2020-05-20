function main
  
  % __________________________________________________  
  % Installation des prérequis
  
  close("all");
  addpath('./utils');
  
  if !any(strcmp({ver.Name}, 'image'))
    pkg install -forge image
  end
  
  pkg load image
  
  figure;
 
  % __________________________________________________  
  % Récupération de la configuration
  
  [n, airy, div, D, nb_arms, arms_width, arms_width_lyot, nb_Mirrors, Diametre, Gap, Op, Ol, l, mask, pupil, lyot, based_on_pupil, spider_origin, hide_center_mirors] = config(0);
  
  % __________________________________________________  
  % Barres de progression
  
  ParentProgress = waitbar(0.0, 'Simulation');
  pos_w1=get(ParentProgress,'position');
  pos_w2=[0 100 pos_w1(3) pos_w1(4)];
  set(ParentProgress,'position',pos_w2,'doublebuffer','on')
  
  Progress = waitbar(0.0, 'BuildGrid X');
  pos_w1=get(ParentProgress,'position');
  pos_w2=[pos_w1(1) pos_w1(2)+pos_w1(4) pos_w1(3) pos_w1(4)];
  set(Progress,'position',pos_w2,'doublebuffer','on')
  
  
for simu=0:n
  
  % __________________________________________________  
  % Configuration de la simulation
  
  [n, airy, div, D, nb_arms, arms_width, arms_width_lyot, nb_Mirrors, Diametre, Gap, Op, Ol, l, mask, pupil, lyot, based_on_pupil, spider_origin, hide_center_mirors] = config(simu);
  
  % __________________________________________________  
  % Modification des paramètres
  
  arms_width = ceil(arms_width/div);
  arms_width_lyot = ceil(arms_width*arms_width_lyot);
  D = D/div;
  N = floor(D)*airy
  N2 = ceil(log2(N))
  N = 2^(N2)
  
  Radius = Diametre/(2*div);
  Gap = Gap/div;
  
  yc = 0; % Position x centre
  xc = 0; % Position y centre
  m = N/2; % Bins number
    
  % __________________________________________________ 
  % Run simulations 
  
  name = sprintf('Simulation %d / %d', simu+1, n+1);
  waitbar((simu+1)/(n+1), ParentProgress, name);
    
  fprintf('Simulation for: %s ...\n', name);
  process(N, D, div, Op, Ol, yc, xc, m, airy, l, simu, mask, pupil, lyot, based_on_pupil, nb_Mirrors, Radius, Gap, nb_arms, arms_width, arms_width_lyot, spider_origin, hide_center_mirors, Progress);
  
end
  
  % __________________________________________________ 
  % End
  close(Progress);
  close(ParentProgress);
  legend
  
endfunction
