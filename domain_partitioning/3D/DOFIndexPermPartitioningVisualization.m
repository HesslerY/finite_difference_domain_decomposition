%% ODF Visualization partitioning

clear;
close all;

%% Parameter Set-up
c0 = 3*10^8;
L0 = 1e-6;  % length unit: microns
wvlen = 4.0*L0;  % wavelength in L0
xrange = [-5 5]*L0;  % x boundaries in L0
yrange = [-5 5]*L0;  % y boundaries in L0
zrange = [-5 5]*L0;
xCells = 3;
N = [10*xCells 10 10];  % [Nx Ny]
Nx = N(1); Ny = N(2); Nz = N(3);
M = N(1)*N(2)*N(3);
Npml = [0 0 0];  % [Nx_pml Ny_pml]
mu0 = 4*pi*10^-7; mu_0 = mu0; mu = mu0;
eps0 = 8.85*10^-12; eps_0 = eps0;
%[xrange, yrange, N, dL, Lpml] = domain_with_pml(xrange, yrange, N, Npml);  % domain is expanded to include PML

%% Set up the permittivity.
eps_r = ones(N);

%% Set up the current source density.
Mz = zeros(N); My = Mz; Mx = Mz;
ind_src = [2 2 2];%ceil(N/2);  % (i,j) indices of the center cell; Nx, Ny should be odd
Mz(ind_src(1), ind_src(2), ind_src(3)) = 1;
JCurrentVector = [Mx; My; Mz];
[Ex, Ey, Ez, A,b] = solve3D(L0, wvlen, xrange, yrange, zrange, eps_r, JCurrentVector, Npml);

% filename = ['D:\Nathan\Documents\StanfordYearOne\Fan Group\FDFDSchurComplement' ...
%     '\MetaAtom3D\StencilVisualization\AMatrix.csv'];
% csvwrite(filename,A)
 [permutedIndices, boundaryCells, interiorCells, interiorCellArr, hpart, vpart] = ...
     IndexPermutation3DOneDChain(N,xCells);
  
xind = zeros(3*Nx*Ny*Nz,1);
yind = zeros(3*Nx*Ny*Nz,1);
vals = ones(3*Nx*Ny*Nz,1);
for j = 1:3*N(1)*N(2)*N(3)

   indexshift = permutedIndices(j);
   xind(j) = j;
   yind(j) = indexshift;
   %Q(i,indexshift) = 1;
end
Q = sparse(xind,yind,vals);

%%test permutation matrix should permute index order to permuted indices

%% Transform Equations
SymA = Q*A*transpose(Q);
%issymmetric(SymA)
SymB = Q*b;
figure
spy(SymA);

%%Schur complement
[ASchur, bmod, App, Apv, Avp, Avv, bp, bv] = ...
    FourblockSchur(SymA,SymB, hpart, vpart)
 
%% Plot of Cellson the Boundary
X = boundaryCells(:,1); Y = boundaryCells(:,2); Z = boundaryCells(:,3);
figure;
Xint = interiorCells(:,1); Yint = interiorCells(:,2); Zint = interiorCells(:,3); 
scatter3(X, Y, Z);
% cube_plot([1.5 1.5 1.5], 3.5, 3.5, 3.5, 'y');
% material metal
% alpha('color');
% alphamap('rampup');
% hold on;
% cube_plot([0.5 0.5 0.5], 5, 5, 5, 'g');
% % The following lines make the cube transparent
% material metal
% alpha('color');
% alphamap('rampup');

xlabel('x direction')
ylabel('y direction')
zlabel('z direction')
axis([1 Nx+0.5 1 Ny+0.5 1 Nz+0.5])
% set(gca,'Ydir','reverse')
% set(gca,'Zdir','reverse')

% plot of interoir cells and boundary cells
figure;
scatter3(X,Y,Z,'filled') %here are the boundary cells
title('boundary cells')
hold on;
scatter3(Xint, Yint, Zint, 'filled', 'g');
xlabel('x direction')
ylabel('y direction')
zlabel('z direction')
title('all cells')
axis([1 Nx+0.5 1 Ny+0.5 1 Nz+0.5])

%plot of interio cells only
figure;
scatter3(Xint, Yint, Zint);
title('interior cells')

figure;%
SingleCellSize = Nx/xCells;
nodesCell = 3*(SingleCellSize-2)*8*8; nodesCell = length(interiorCells)/xCells;
for i = 0:xCells-1
    scatter3(Xint(i*nodesCell+1:(i+1)*nodesCell), Yint(i*nodesCell+1:(i+1)*nodesCell),...
        Zint(i*nodesCell+1:(i+1)*nodesCell), 'MarkerEdgeColor',rand(1,3),...
              'MarkerFaceColor',rand(1,3),...
              'LineWidth',1.5)
    title('interior cells of 1st cell')
    hold on;
end

