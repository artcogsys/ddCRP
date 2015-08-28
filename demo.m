clear
dims = [50 50];
N = prod(dims);
T = 100;
K = 10;

signal = 1; % Amplitude of cluster mean
noise = 2; % Amplitude of the observation noise

[coords{1:length(dims)}] = ind2sub(dims,find(ones(dims)));
coords = [coords{:}];

weights = 1./dist(coords,coords');
weights(1:(N+1):numel(weights)) = 0;
weights = num2cell(weights,2);
A = {1:(N)};A = A(ones(N,1));
for i = 1:N
  weights{i}(i) = 0;
  A{i}(weights{i}<1) = [];
  weights{i}(weights{i}<1) = [];
end

Pi_true = zeros(N,1);
seeds = randperm(N,K);
Pi_true(seeds) = 1:K;
unassigned = Pi_true==0;
screensize = get(0,'ScreenSize');
figdim = (screensize(3:end)-[0 40])./2;
figure(1);set(1,'OuterPosition',[1 screensize(4)-figdim(2) figdim])
subplot(1,2,1)
while any(unassigned)
  for k = randperm(K)
    nbs = setdiff(unique([A{Pi_true==k}]),find(~unassigned));
    if ~isempty(nbs)
      sel = nbs(randi(length(nbs)));
      Pi_true(sel) = k;
      unassigned(sel) = false;
      imagesc(reshape(Pi_true,dims))
      title('Cluster structure')
      axis square
      drawnow
      if ~any(unassigned)
        break
      end
    end
  end
end


X = randn(K,T);
Y = X(Pi_true,:)*signal+randn(N,T)*noise;
Y = zscore(Y,[],2);
[~, inds] = sort(Pi_true);
subplot(1,2,2);imagesc((Y(inds,:)*Y(inds,:)')./T)
title('Node timecourse correlation')
axis square
caxis([-1 1])
colorbar
drawnow

%%

clear opts

opts.steps = 20;
opts.hyp.a0 = 2;
opts.hyp.b0 = 1;
opts.hyp.mu0 = 0;
opts.hyp.kappa0 = 1;
samples = PMC_ddCRP_NG(Y',A,opts);

Z = double(bsxfun(@eq,samples{end,2},1:max(samples{end,2})));
Q = Z*Z';

Ztrue = double(bsxfun(@eq,Pi_true,1:K));
Qtrue = Ztrue*Ztrue';

figure(2);set(2,'OuterPosition',[1 40 figdim])
subplot(1,2,1)
colormap hot
imagesc(Qtrue(inds,inds));
axis square
title('True coassignment-matrix')

subplot(1,2,2)
imagesc(Q(inds,inds));
axis square
title('Empirical coassignment-matrix')
