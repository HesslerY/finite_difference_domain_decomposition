
function [SymA,SymB, Q, permutedIndices, interiorInd, boundaryInd, hpart, vpart] = ...
MultiCellReorderAcc(A, b,xCells, yCells, N)

    Nx = N(1); 
    Ny = N(2);

    totCells = xCells*yCells;
    
    %% Do the multicell Reindexing
    Nindexing = zeros(Nx*Ny,2);
    
    counter = 1;
    xDiv = Nx/xCells;
    yDiv = Ny/yCells;
    totCells = xCells*yCells;
    boundaryCoords = zeros(totCells*(2*xDiv+2*yDiv-4),2);
    interiorCoords = zeros(Nx*Ny-totCells*(2*xDiv+2*yDiv-4),2);
    boundaryInd = zeros(totCells*(2*xDiv+2*yDiv-4),1);
    interiorInd = zeros(Nx*Ny-totCells*(2*xDiv+2*yDiv-4),1);
    bc = 1; ic = 1;
    for i = 0:xCells-1
        for j =0:yCells-1
            xBeg = i*xDiv+1;
            yBeg = j*yDiv+1;
            xEnd = (i+1)*xDiv;
            yEnd = (j+1)*yDiv;
            for k = xBeg:xEnd
               for l = yBeg:yEnd
                  point = [k, l]; 
                  natIndex = CoordtoNatIndex(k,l,Nx);
                  Nindexing(counter,:) =point ;
                  if(mod(k,xDiv) == 0 || mod(k, xDiv) ==1 || mod(l,yDiv) == 0 || mod(l, yDiv) == 1)
                    boundaryCoords(bc,:) =  [k,l];
                    boundaryInd(bc,:) =  natIndex;
                    bc = bc+1;
                  else
                    interiorInd(ic,:) = natIndex;
                    interiorCoords(ic,:) = [k,l];
                    ic = ic+1;
                  end
                  counter = counter+1;
               end
            end
        end
    end
    permutedIndices = [boundaryInd; interiorInd];
    
    %% Get the new matrix Q
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

    SymA = Q*A*transpose(Q);
    %issymmetric(SymA)
    SymB = Q*b;
    
    hpart = length(boundaryInd);
    vpart = hpart;

    
end