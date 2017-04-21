function [w,v,ci,energy_nodes] = cascade_secs(varargin) %this is get_eigs

flavor = varargin{1};
% defaults:
g = 2;
logemin = 3;
logemax = 10;
NumNodes = 200;

if nargin >= 2
    g = varargin{2};
end
if nargin >= 3 %you have changed the cross sections
    logemin = varargin{3};
    logemax = varargin{4};
    NumNodes = varargin{5};
end
if flavor==-1
    sigma_fname = '/total_cross_sections/nuebarxs';
elseif flavor == -2
    sigma_fname = '/total_cross_sections/numubarxs';
    
elseif flavor == 1
    sigma_fname = '/total_cross_sections/nuexs';
elseif flavor == 2
    sigma_fname = '/total_cross_sections/numuxs';
else
    error('flavor for secs must be +/- 1 or 2 ')
end
if flavor > 0
    dxs_fname = 'differential_cross_sections/dxsnu';
    sig3fname = '/total_cross_sections/nutauxs';
    secname = '/tau_decay_spectrum/secfull';
    regenname = '/tau_decay_spectrum/tfull';
else
    dxs_fname = 'differential_cross_sections/dxsnubar';
    sig3fname = '/total_cross_sections/nutaubarxs';
    secname = '/tau_decay_spectrum/secbarfull';
    regenname = '/tau_decay_spectrum/tbarfull';
end

energy_nodes = logspace(logemin,logemax,NumNodes);
[RHSMatrix] = get_RHS_matrices(energy_nodes,sigma_fname,sig3fname,dxs_fname,secname,regenname);


phi_0 = energy_nodes.^(2-g)';
[v,w] = eig(RHSMatrix);
ci = (v^-1)*[phi_0; phi_0];
w = diag(w);

end

function  [RHSMatrix, sigma_array] = get_RHS_matrices(energy_nodes,sigma_fname,sig3fname,dxs_fname,secname,regenname)
NumNodes = length(energy_nodes);
h5flag = 1
if h5flag
    sigma_array1 = h5read('../data/NuFATECrossSections.h5',sigma_fname)';
    sigma_array2 = h5read('../data/NuFATECrossSections.h5',sig3fname)';
    dsigmady = h5read('../data/NuFATECrossSections.h5',dxs_fname)';
    emuregen = h5read('../data/NuFATECrossSections.h5',secname)';
    tauregen = h5read('../data/NuFATECrossSections.h5',regenname)';
else
    sigma_array1 = load(['../data/' sigma_fname);
    sigma_array2 = load(['../data/' sig3fname);
    dsigmady = load(['../data/' dxs_fname);
    emuregen = load(['../data/' secname);
    tauregen = load(['../data/' regenname);
end
DeltaE = diff(log(energy_nodes));
RHSMatrix1 = zeros(NumNodes);
RHSMatrix2 = zeros(NumNodes);
RHSMatrix3 = zeros(NumNodes);
RHSMatrix4 = zeros(NumNodes);


%     1: Regular NC bit
for i = 1:NumNodes
    for j = i+1:NumNodes
        RHSMatrix1(i,j) = DeltaE(j-1)*dsigmady(j,i)*energy_nodes(j).^-1*energy_nodes(i).^2;
    end
end

RHSMatrix1 = -diag(sigma_array1) + RHSMatrix1;
%    2: nue/numu secondary production
for i = 1:NumNodes
    for j = i+1:NumNodes
        RHSMatrix2(i,j) = DeltaE(j-1)*emuregen(j,i)*energy_nodes(j).^-1*energy_nodes(i).^2;
    end
end
%     3 is zero; 4 is tau regen
for i = 1:NumNodes
    for j = i+1:NumNodes
        RHSMatrix4(i,j) = DeltaE(j-1)*(dsigmady(j,i)+tauregen(j,i))*energy_nodes(j).^-1*energy_nodes(i).^2;
    end
end
RHSMatrix4 = -diag(sigma_array2) + RHSMatrix4;
RHSMatrix = [RHSMatrix1 RHSMatrix2; RHSMatrix3 RHSMatrix4];
end
