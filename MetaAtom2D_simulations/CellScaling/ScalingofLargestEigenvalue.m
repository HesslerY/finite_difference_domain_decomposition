%% Multicell Single Partition Analysis with real dielectric + PML
close all
clear all

%% ================ ESSENTIAL SIMULATION PARAMETERS=================
L0 = 1e-6;  % length unit: microns
maxCellNumber = 1;
SingleCellSize = 40;
epsilon = 0.5;
Sx = SingleCellSize; Sy = SingleCellSize;

%% ==================== Create Data Directory
condData = []; iterData = [];
wvlen = 1;
for epsilon = [1]
systemSize = []; conditions = [];
for numCells = 1:10
    N = [numCells*SingleCellSize+numCells+1 numCells*SingleCellSize+numCells+1];  % [Nx Ny]
    systemSize = [systemSize; N];
    N0 = N; %record the original N for comparison
    Npml = 0*[5 5];  % [Nx_pml Ny_pml] need to deal with the special case where both are 0
    xrange = numCells*[-0.5 0.5];  % x boundaries in L0
    yrange = numCells*[-0.5, 0.5];  % y boundaries in L0

    %% Note on grid resolution of the system
    % dx/(wvlen) ~1/20 or smaller

    [xrange, yrange, N, dL, Lpml] = domain_with_pml(xrange, yrange, N, Npml);  % domain is expanded to include PML
    %FINAL GRID PARAMETERS ARE DETERMINED AT THIS POINT
    %xrange and yrange are slightly larger
    %% Cell Division Setup
    M= N(1)*N(2);

    %% NOTE dL is not in SI units when it comes out of domain_with_pml; for our purposes, that is okay
    %for now
    resolutionFactor = max([dL(1)/N(1) dL(2)/N(2)]); %dx/N ~meters
    %spatially, what is the smallestlength scale that we have to resolve
    Nx = N(1); Ny = N(2);

    %% Set up the permittivity.
    FeatureDims = [SingleCellSize/4, SingleCellSize/4, SingleCellSize/6];
    [eps_air, cellIndices] =... 
        multiRandomCellDielectricSingleLayerSep(numCells, numCells, SingleCellSize, SingleCellSize, Npml,epsilon,FeatureDims); %% ADD coe to account for PML


    %% Set up the magnetic current source density.
    Mz = zeros(N);
    ind_src = [ceil(N/5) ceil(N/5)];%ceil(N/2);  % (i,j) indices of the center cell; Nx, Ny should be odd
    Mz(ind_src(1), ind_src(2)) = 1;
    %Mz(75, 75) = 1;
    %scale = 1e-13; %% make matrix scaling look nicer
    [A, omega,b, Sxf, Dxf,Dyf] = solveTE_Matrices(L0,wvlen, xrange, yrange, eps_air, Mz, Npml);
    %A = scale*A; b = scale*b;
    
    %% Set up the MultiCell Regime
    divx = numCells; divy = numCells;
    xCells = numCells; yCells = numCells; %% these specify the number of cells we will be dividing into
    CellDimx = N(1)/divx;
    CellDimy = N(2)/divy;
    conditions = [conditions; eigs(A,1,'largestabs')]
    

    
end
condData = [condData, conditions];


    
end
figure; 
semilogy(systemSize,abs(condData));
title('Largest Eigenvalues')
xlabel('system size')
ylabel('eigenvalues')