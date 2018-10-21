%% Single layer Schur complement with PML setup
close all
clear

%% ================ ESSENTIAL SIMULATION PARAMETERS=================
L0 = 1e-6;  % length unit: microns
wvlen = 1.55*L0;  % wavelength in L0
iterSchur = []; iterUnRed = [];
maxCellNumber = 1;
SingleCellSize = 20;
epsilon = 10;
Sx = SingleCellSize; Sy = SingleCellSize;

k = 1; xCells =k; 
g = 2; yCells = g;

%% ================ Domain Size Parameters ==========================
N = [k*SingleCellSize+k+1 g*SingleCellSize+g+1];  % [Nx Ny]
N0 = N;
Npml = [10 10];  
xrange = k*L0*[-1 1];  % x boundaries in L0
yrange = g*L0*[-1 1];  % y boundaries in L0

%% Generate Parameters for Domain with PML
[xrange, yrange, N, dL, Lpml] = domain_with_pml(xrange, yrange, N, Npml);  

%% ==============Setup Dielectric ===================================
[eps_air, cellIndices] = ... 
    multiRandomCellDielectricSingleLayerSep(k, g, SingleCellSize,...
    SingleCellSize, Npml,epsilon); %% ADD coe to account for PML

%% setup point source 
Mz = zeros(N);
ind_src = [ceil(N/2) ceil(N/2)];%ceil(N/2);  % (i,j) indices of the center cell; Nx, Ny should be odd
Mz(ind_src(1), ind_src(2)) = 1;

Mz1 = zeros(N0);
Mz1(ceil(N0/2)) = 1;
%% ============ ==== FDFD Matrix Setup ==== ===========================%
%with pml
[A, omega,b, Sxf, Dxf,Dyf] = solveTE_Matrices_unscaled(wvlen, xrange, ...
    yrange, eps_air, Mz, Npml);


%% ===========TEST OF THE REORDERING ================================%

%% first, let's get back the dimensions of the small domain
Noriginal = N-2*Npml; %factor of 2 accounts for the fact that you need a pml on each side
pmloffset = 2*Npml(1);
pmlwidth = Npml(1);
M = N(1)*N(2);
indexorder = transpose(1:N(1)*N(2));
NaturalOrdering = CoordinateIndexing(N(1), N(2));

Nx = N(1); Ny = N(2);
boundaryIndices = [1];
for i = 1:xCells
    boundaryIndices = [boundaryIndices, boundaryIndices(i)+...
        SingleCellSize+1];
end
boundaryIndices = pmloffset/2 + boundaryIndices;

Cx = length(boundaryIndices)-1;
totCells = Cx^2;

%% these cells store the actual x and y coordinates
boundaryCells = [];
interiorCellIndexDict = cell(totCells,1); 
interiorCellDict = cell(totCells, 1);
pmlCellIndexDict = cell(4+4*Cx,1); %explicitly assumes a square arrangement
pmlCellDict = cell(4+4*Cx, 1);
pmlBoundaryCellCoords = [];

pmlBoundaryCell =[]; pmlCell = [];
boundaryCellIndex = []; interiorCellIndex = [];
pmlCellIndex = [];

%% we need a map of all the boundaryindices in x and y to cell index
boundaryMap = []; counter = 1;
for i = boundaryIndices(1:end-1)
    for j = boundaryIndices(1:end-1)
        boundaryMap = [boundaryMap; i,j, counter];
        counter = counter+1
    end
end
nodeMap = zeros(N);
d = size(boundaryMap);
for i = 1:d(1)
    nodeMap(boundaryMap(i,1)+1:boundaryMap(i,1)+SingleCellSize,...
        boundaryMap(i,2)+1:boundaryMap(i,2)+SingleCellSize) = ...
    boundaryMap(i,3);

end

%% We need a map for all the nodes to some index for the pml cells
index = 1;
side1 = Npml(1);
side2 = N(1) - Npml(1); %% ASSUMING that side1 = side

for i = 1:Cx
    nodeMap(1:side1,boundaryIndices(i)+1:boundaryIndices(i)+...
        SingleCellSize) = index;
    index = index+1;
    nodeMap(boundaryIndices(i)+1:boundaryIndices(i)+...
    SingleCellSize, 1:side1) = index;
    index = index+1;
    
    nodeMap(boundaryIndices(i)+1:boundaryIndices(i)+...
    SingleCellSize, side2+1:end) = index;
    index = index+1;
    
    nodeMap(side2+1:end,boundaryIndices(i)+1:boundaryIndices(i)+...
    SingleCellSize) = index;
    index = index+1;
   
end

% top left and bottom right corners
nodeMap(1:side1, 1:side1) = index;
index = index+1;
nodeMap(side2+1:end, side2+1:end) = index;
index = index+1;

%top right and bottom left corners
nodeMap(boundaryIndices(end)+1:boundaryIndices(end)+Npml(1),1:side1) = index;
index = index+1;
nodeMap(1:side1, boundaryIndices(end)+1:boundaryIndices(end)+Npml(2)) = index;
index = index+1;


%% cycle through all points on the grid in integer indexing
cellIndex = 1;
cx = 1; cy = 1;

regionMap = zeros(Cx+2, Cx+2)

for i = 1:(Nx*Ny) %O(N^2) where N is Nx = Ny
    
   startIndex = NaturalOrdering(i,:); 
   x = startIndex(1); y = startIndex(2);
   key=strcat(num2str(x),',', num2str(y));

   %% condition for being inside the pml buffer
   if(x > pmlwidth+Noriginal(1) || y > pmlwidth+Noriginal(2) ...
       || x <= Npml(1) || y <= Npml(2))
       pmlCell = [pmlCell; startIndex];
       pmlCellIndex = [pmlCellIndex; i];
       pmlIndex = nodeMap(x,y);
       if(pmlIndex == 0) %this is the case
           pmlBoundaryCell = [pmlBoundaryCell, i];
           pmlBoundaryCellCoords = [pmlBoundaryCellCoords; startIndex];
       else
           pmlCellDict{pmlIndex} = [pmlCellDict{pmlIndex}; startIndex];
           pmlCellIndexDict{pmlIndex} = [pmlCellIndexDict{pmlIndex}; i];
       end
   %% condition for being inside the structure
   else
       if(any(x == boundaryIndices)||any(y==boundaryIndices))
           boundaryCells = [boundaryCells; startIndex];
           boundaryCellIndex = [boundaryCellIndex; i];
       else
           cellIndex = nodeMap(x,y);
           interiorCellDict{cellIndex} = [interiorCellDict{cellIndex}; startIndex];
           interiorCellIndexDict{cellIndex}=...
               [interiorCellIndexDict{cellIndex}; i];
       end
       
   end

end %% end of natural ordering indexing for loop

interiorCells = cell2mat(interiorCellDict);
interiorCellIndex = cell2mat(interiorCellIndexDict);
pmlCells = cell2mat(pmlCellDict);
pmlCellIndex = cell2mat(pmlCellIndexDict);
vpart = length(boundaryCellIndex) + length(pmlBoundaryCell);
hpart = vpart;
pmlxpart = M - length(pmlCellIndex);
pmlypart = pmlxpart;

%% figure out the order in which the pml cells are added
% figure()
% scatter(pmlCells(:,1), pmlCells(:,2))
% hold on
% s2 = size(pmlCellDict{1})
% for i = 1:4*Cx
%     figure()
%     scatter(pmlCells(:,1), pmlCells(:,2))
%     hold on
%     scatter(pmlCells(1+(i-1)*s2(1):1+(i)*s2(1),1),...
%         pmlCells(1+(i-1)*s2(1):1+(i)*s2(1),2))
% 
% end
start1 = [];
a = 1;
for i = 1:Cx
    start1 = [start1; a,a+3];
    a = a+4;
end
start2 = [];
c = 2;
for i = 1:Cx
    start2 = [start2; c, c+1];
    c = c +4;
end

cornerGroup = pmlCellDict(end-3:end);
cornerGroupIndex = pmlCellIndexDict(end-3:end);
edgeGroup = pmlCellDict(1:end-4);
pmlReorderedCellDict = cell(Cx*4, 1);
pmlReorderedCellIndexDict = cell(Cx*4,1);
for i = 1:2:2*Cx
    first = start1((i+1)/2,1); second = start1((i+1)/2,2);
    pmlReorderedCellDict{i+1} = pmlCellDict{first};
    pmlReorderedCellDict{i} = pmlCellDict{second};
    pmlReorderedCellIndexDict{i} = pmlCellIndexDict{first};
    pmlReorderedCellIndexDict{i+1} = pmlCellIndexDict{second};
    
    f1 = start2((i+1)/2,1); s1 = start2((i+1)/2,2);
    pmlReorderedCellDict{2*Cx+i+1} = pmlCellDict{f1};
    pmlReorderedCellDict{2*Cx+i} = pmlCellDict{s1};
    pmlReorderedCellIndexDict{2*Cx+i} = pmlCellIndexDict{f1};
    pmlReorderedCellIndexDict{2*Cx+i+1} = pmlCellIndexDict{s1};
    
end
pmlReorderedCellDict = vertcat(pmlReorderedCellDict, cornerGroup);
pmlCellDict = vertcat(pmlReorderedCellDict, cornerGroup);
pmlCellIndexDict = vertcat(pmlReorderedCellIndexDict, cornerGroupIndex);
pmlCellIndex = cell2mat(pmlCellIndexDict);
%% This is the final answer we want...the index permutation for the system matrix
permutedIndices = [pmlBoundaryCell.';boundaryCellIndex; ...
    interiorCellIndex; pmlCellIndex];
%% ======================================================================%

%%Permute Indices one more time so that all the interior cells are grouped
%%correctly

%% Execute a Symmetry Preserving Column Row Permutation Combination
xind = zeros(Nx*Ny,1);
yind = zeros(Nx*Ny,1);
vals = ones(Nx*Ny,1);

%% ALWAYS CREATE THE PERMUTATION SPARSE MATRIX LIKE THIS!! 
for i = 1:N(1)*N(2)
   indexshift = permutedIndices(i);
   xind(i) = i;
   yind(i) = indexshift;
   %Q(i,indexshift) = 1;
end
Q = sparse(xind,yind,vals);

%% Transform Equations
SymA = Q*A*transpose(Q);
%issymmetric(SymA)
symB = Q*b;

%% ============= Test Solve ==============================
x2 = SymA\symB;

hold on
scatter(pmlCell(:,1), pmlCell(:,2))
scatter(boundaryCells(:,1), boundaryCells(:,2))
%scatter(interiorCells(1:1600,1), interiorCells(1:1600,2), '.')
scatter(pmlBoundaryCellCoords(:,1), pmlBoundaryCellCoords(:,2));

%% =========== Visualize the ordering of the pml====================
figure()
scatter(boundaryCells(:,1), boundaryCells(:,2))
hold on
scatter(pmlCells(1:400,1), pmlCells(1:400,2), '.')


%% check the reordered pmlReorderedCellDict
figure()
scatter(pmlBoundaryCellCoords(:,1), pmlBoundaryCellCoords(:,2),'.');
hold on
scatter(boundaryCells(:,1), boundaryCells(:,2), '.');
for i = 1:4*Cx+4
    figure()
    scatter(pmlBoundaryCellCoords(:,1), pmlBoundaryCellCoords(:,2),'.');
    hold on
    scatter(boundaryCells(:,1), boundaryCells(:,2), '.');
    a = pmlReorderedCellDict{i};
    scatter(a(:,1), a(:,2),'.')
    hold on
end