
%% splits into an nx by ny by nz cell structure

function [Q, permutedIndices, hpart, vpart, partitions] = ...
    IndexPermutationCubicLattice_SLS(N,borderCoords, interiorCoords)
    
    M = prod(N);
    
    %% analyze the border first
    borders = vertcat(borderCoords{:});
    figure;
    scatter3(borders(:,1), borders(:,2), borders(:,3), 'filled')

    interiors = vertcat(interiorCoords{:});
    linearIndexBound = sub2ind(N, borders(:,1), borders(:,2), borders(:,3));
    linearIndexInterior = sub2ind(N, interiors(:,1), interiors(:,2), interiors(:,3));
    linearIndexBound = [linearIndexBound; linearIndexBound+M; linearIndexBound+2*M];
    hpart = length(linearIndexBound); 
    vpart = hpart;
    partitions = [hpart];
    %% we have to be careful with the interior...we have Ex, Ey, Ez, and they 
    %% MUST BE GROUPED TOGETHER.
    %create the linear index not as a vector, but a matrix
    numCells = prod(size(interiorCoords));
    interiorCellSize = length(interiorCoords{1,1,1});
    linearIndexInterior = [linearIndexInterior, linearIndexInterior+M, linearIndexInterior+2*M];
    interiorGroup = mat2cell(linearIndexInterior, repmat(interiorCellSize,[numCells,1]), 3);
    %% flaten indices
    for i = 1:length(interiorGroup)
       allcomponentCellIndices = interiorGroup{i};
       flattened = reshape(allcomponentCellIndices, [],1);
       interiorGroup{i} = flattened;
       partitions = [partitions, length(flattened)];

    end
    linearIndexInterior = cell2mat(interiorGroup);
    %% now we need to reconstruct the indices corresponding to the y and z components

    permutedIndices = [linearIndexBound; linearIndexInterior];

    %% Execute a Symmetry Preserving Column Row Permutation Combination
    xind = zeros(3*M,1);
    yind = zeros(3*M,1);
    vals = ones(3*M,1);

    %% ALWAYS CREATE THE PERMUTATION SPARSE MATRIX LIKE THIS!! 
    for i = 1:length(permutedIndices)
       indexshift = permutedIndices(i);
       xind(i) = i;
       yind(i) = indexshift;
    end
    Q = sparse(xind,yind,vals);


 end