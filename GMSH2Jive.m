function GMSH2Jive(filename,varargin)

if size(varargin) == 0
    getPeriodicEdges    = false;
    getInitPorePressure = false;
elseif size(varargin) == 1
    getPeriodicEdges    = varargin{1};
    getInitPorePressure = false;
elseif size(varargin) == 2
    getPeriodicEdges    = varargin{1};
    getInitPorePressure = varargin{2};
    density             = 1000;
else
    getPeriodicEdges    = varargin{1};
    getInitPorePressure = varargin{2};
    density             = varargin{3};
end

filename = strcat(filename,'.msh');
mesh     = parseGMSH2(filename);
           saveJiveMesh(mesh,getPeriodicEdges);

if getInitPorePressure
    saveInitPressure(mesh,density);
end


end



function mesh = parseGMSH2(filename)

% % --------------------------------------------------------------------- %
% parseGMSH2 is a function that reads a GMSH mesh file (version 2.2), and
% stores nodes, elements and physical names into a struct 'mesh'
%
% input : filename with extension
%
% output: 'mesh' struct containing :
%              name        = filename                    (string)
%              format      = gmsh format                 (double)
%              nodes       = [nodeID x y z]              (array)
%              phy_names   = physical names              (struct)
%              elems       = elements with addl. info    (struct)
%              elemGroup   = element group with phy name (struct)
%              nodeGroup   = node group with phy name    (struct)
%              
%              phy_names.names has [dimension tag]
%              elems has connect, physical tag, geometric tag,
%                        element type
%
% AUTHOR: R. Bharali, ritukesh.bharali.at.chalmers.se
% DATE  : 01 March 2022
%
%  Updates (when, what and who)
%   - [13 February 2023] added option to extract periodic edges
%                        added option for initial pore pressure 
%
% % --------------------------------------------------------------------- %

% Open mesh file
fid = fopen(filename,'r');

[~,mesh.name,~] = fileparts(filename);

% Read gmsh file
disp(' --- Reading mesh!')
while true
    
    % Read a line, exit loop is no char detected
    tline = fgetl(fid);
    if ~ischar(tline); fclose(fid); break; end

    % switch to read cases (self-explanatory)
    switch tline

        case '$MeshFormat'
            mesh.format = parse_format( fid);

        case '$PhysicalNames'
            mesh.phy_names = parse_phy_names(fid);

        case '$Nodes'
            mesh.nodes = parse_nodes(fid);

        case '$Elements'
            mesh.elems = parse_elems(fid);
    end   

end

% Get tags 
phy_names = fieldnames(mesh.phy_names);

% Store element and node groups
for i = 1:length(phy_names)
    phy_name = strrep(phy_names{i},'"','');
    elemGroup = [];
    nodeGroup = [];
    for j = 1:length(mesh.elems)
        if mesh.elems(j).phys_tag == mesh.phy_names.(phy_name)(1,2)
            elemGroup = [elemGroup, j];
            nodeGroup = [nodeGroup, mesh.elems(j).connect];
        end
    end
    nodeGroup = unique(nodeGroup);
    varname = matlab.lang.makeValidName(phy_name);
    mesh.elemGroup.(varname) = elemGroup;
    mesh.nodeGroup.(varname) = nodeGroup;
end

disp(' --- Done reading mesh!')
fclose('all');

end

% ------------ Helper functions --------------- % 

% Parse mesh format
function gmshformat = parse_format( fid)
   tline = fgetl(fid);
   sline = sscanf(tline,'%f');
   tline = fgetl(fid); % $EndMeshFormat
   gmshformat = sline(1);
end



% Parse physical names
function names = parse_phy_names( fid)
   tline  = fgetl(fid);
   nNames = sscanf(tline,'%f');

   for i = 1:nNames
       tline  = fgetl(fid);
       sline  = split(tline);
       varname = matlab.lang.makeValidName(strrep(sline{3},'"',''));
       names.(varname) = [str2double(sline{1}), str2double(sline{2})];
   end

end



% Parse nodes (node number, x, y, z)
function nodes = parse_nodes( fid)
   tline  = fgetl(fid);
   n_rows = sscanf(tline,'%d');
   nodes  = fscanf(fid,'%f',[4,n_rows])';
end



% Parse elements (connectivity, phy_tags, geom_tags, type)
function elems = parse_elems( fid)
   tline       = fgetl(fid);
   n_rows      = sscanf(tline,'%d');

   elems(n_rows,1).connect  = [];
   elems(n_rows,1).phys_tag = [];
   elems(n_rows,1).geom_tag = [];
   elems(n_rows,1).type     = [];

   for i = 1:n_rows
       tline            = fgetl(fid);
       n                = sscanf(tline, '%d')';
       tags             = n(4:3+n(3));
       
       elems(i,1).connect = n(n(3) + 4:end);
       elems(i,1).type    = n(2);
       
       if length(tags) >= 1
           elems(i,1).phys_tag = tags(1);
           if length(tags) >= 2
               elems(i,1).geom_tag = tags(2);
           end
       end
   end   
end


function saveJiveMesh(mesh,periodic)

% % --------------------------------------------------------------------- %
% saveJiveMesh is a function that takes 'mesh' as the argument and creates
% a mesh file in the Jem Jive format. Physical names are stored as
% ElementGroup and NodeGroup, except domain elements.
%
% input : 'mesh' struct
%
% output: none
%
% AUTHOR: R. Bharali, ritukesh.bharali.at.chalmers.se
% DATE  : 01 March 2022
% % --------------------------------------------------------------------- %

% GMSH 1D elements
gmsh1Delems = [1,8];

% GMSH 2D elements
gmsh2Delems = [2,3,9,10,16];

% GMSH 3D elements
gmsh3Delems = [4,5,6,7,11,12,13,14,17,18,19];

% Get filename
filename = mesh.name;

% Get element type of domain and set mesh rank
elem_type = mesh.elems(end).type;

if ismember(elem_type,gmsh1Delems)
    mesh_rank = 1;
elseif ismember(elem_type,gmsh2Delems)
    mesh_rank = 2;
elseif ismember(elem_type,gmsh3Delems)
    mesh_rank = 3;
else
    error('Parsing error!!!')
end

% Open mesh file
fid = fopen(strcat(filename,'.mesh'),'wt');

% Write nodes and coordinates
fprintf(fid, '<Nodes>\n');
if mesh_rank == 1
    fprintf(fid,'%d %12.8f;\n',[mesh.nodes(:,1),mesh.nodes(:,2)]');
elseif mesh_rank == 2
    fprintf(fid,'%d %12.8f %12.8f;\n',[mesh.nodes(:,1),mesh.nodes(:,2),...
            mesh.nodes(:,3)]');
elseif mesh_rank == 3
    fprintf(fid,'%d %12.8f %12.8f %12.8f;\n',[mesh.nodes(:,1),mesh.nodes(:,2),...
            mesh.nodes(:,3),mesh.nodes(:,4)]');
end
fprintf(fid, '</Nodes>\n\n');

% Get domain elements
dom_idx = mesh.phy_names.domain(1,2);
fprintf(fid, '<Elements>\n');

% Print domain elements to file
for i = 1:length(mesh.elems)
    % if mesh.elems(i).phys_tag == dom_idx

    elem_type = mesh.elems(i).type;
        
        switch elem_type

            % --- FIRST ORDER ELEMENTS --- %

            % 2 noded line (1D)
            case 1
                fprintf(fid,'%d %d %d;\n',[i, mesh.elems(i).connect]');

            % 3 noded tri (2D)
            case 2
                fprintf(fid,'%d %d %d %d;\n',[i, mesh.elems(i).connect]');

            % 4 noded quad (2D)
            case 3
                fprintf(fid,'%d %d %d %d %d;\n',[i, mesh.elems(i).connect]');

            % 4 noded tetra (3D)
            case 4
                fprintf(fid,'%d %d %d %d %d;\n',[i, mesh.elems(i).connect]');

            % 8 noded hex (3D)
            case 5
                fprintf(fid,'%d %d %d %d %d %d %d %d %d;\n',[i, mesh.elems(i).connect]');    

            % --- SECOND ORDER ELEMENTS --- %    

            % 3 noded line (1D)
            case 8
                fprintf(fid,'%d %d %d %d;\n',[i,mesh.elems(i).connect([1,3,2])]');                
                %fprintf(fid,'%d %d %d %d;\n',[i,mesh.elems(i).connect]');                

            % 6 noded tri (2D)
            case 9
                fprintf(fid,'%d %d %d %d %d %d %d;\n',[i, mesh.elems(i).connect([1,4,2,5,3,6])]');
                % fprintf(fid,'%d %d %d %d %d %d %d;\n',[i, mesh.elems(i).connect]');

            % 9 noded quad (2D)    
            case 10 
                fprintf(fid,'%d %d %d %d %d %d %d %d %d %d;\n',[i, mesh.elems(i).connect([1,5,2,6,3,7,4,8,9])]');

            % 8 noded quad (2D)    
            case 16 
                fprintf(fid,'%d %d %d %d %d %d %d %d %d;\n',[i, mesh.elems(i).connect([1,5,2,6,3,7,4,8])]');   

            % 10 noded tetra (3D)
            case 11
                fprintf(fid,'%d %d %d %d %d %d %d %d %d %d %d;\n',[i, mesh.elems(i).connect]');    

            otherwise
                error('Not yet implemented! DIY!!!')
        end
    % end
end
fprintf(fid, '</Elements>\n\n');

% Write element groups
 
phy_names = fieldnames(mesh.phy_names);

for i = 1:length(phy_names)
    field = strrep(phy_names{i},'"','');
    fprintf(fid, strcat('<ElementGroup name="',field,'Elems">\n'));
    fprintf(fid, '{');
    for j = 1:length(mesh.elemGroup.(field))
        fprintf(fid, '%d,',mesh.elemGroup.(field)(j));
    end
    fprintf(fid, '}\n');
    fprintf(fid, strcat('</ElementGroup>\n\n'));
end

% Sort edges if they are periodic

if periodic
    disp(' --- Looking for periodic edges!')

    if isfield(mesh.nodeGroup,'bottom')
        if isfield(mesh.nodeGroup,'top')
            if length(mesh.nodeGroup.bottom) == length(mesh.nodeGroup.top)
                
                % Sort according to x-coordinate
                nodes0   = mesh.nodes(mesh.nodeGroup.bottom,:);
                nodes1   = mesh.nodes(mesh.nodeGroup.top,:);

                nodes0   = sortrows(nodes0,2);
                nodes1   = sortrows(nodes1,2);

                mesh.nodeGroup.bottom = nodes0(:,1);
                mesh.nodeGroup.top    = nodes1(:,1);

                % Check periodicity
                err = sum(mesh.nodes(mesh.nodeGroup.bottom,2)-...
                                 mesh.nodes(mesh.nodeGroup.top,2));
                if err > 1e-10
                    disp('     *** bottom and top are not fully periodic!')
                    disp(['         err = ',num2str(err)])
                end

                disp('     *** bottom and top are periodic!')

            else
                disp('     *** bottom and top have different # of nodes!')

            end
        end
    end

    if isfield(mesh.nodeGroup,'left')
        if isfield(mesh.nodeGroup,'right')
            if length(mesh.nodeGroup.left) == length(mesh.nodeGroup.right)
                
                % Sort according to x-coordinate
                nodes0   = mesh.nodes(mesh.nodeGroup.left,:);
                nodes1   = mesh.nodes(mesh.nodeGroup.right,:);

                nodes0    = sortrows(nodes0,3);
                nodes1    = sortrows(nodes1,3);

                mesh.nodeGroup.left  = nodes0(:,1);
                mesh.nodeGroup.right = nodes1(:,1);

                % Check periodicity
                err = sum(mesh.nodes(mesh.nodeGroup.left,3)-...
                                 mesh.nodes(mesh.nodeGroup.right,3));
                if err > 1e-10
                    disp('     *** left and right are not fully periodic!')
                    disp(['         err = ',num2str(err)])
                end

                disp('     *** left and right are periodic!')

            else
                disp('     *** left and right have different # of nodes!')

            end
        end
    end

    if isfield(mesh.nodeGroup,'back')
        if isfield(mesh.nodeGroup,'front')
            if length(mesh.nodeGroup.back) == length(mesh.nodeGroup.front)
                
                % Sort according to x-coordinate
                nodes0   = mesh.nodes(mesh.nodeGroup.back,:);
                nodes1   = mesh.nodes(mesh.nodeGroup.front,:);

                nodes0    = sortrows(nodes0,4);
                nodes1    = sortrows(nodes1,4);

                mesh.nodeGroup.left  = nodes0(:,1);
                mesh.nodeGroup.right = nodes1(:,1);

                % Check periodicity
                err = sum(mesh.nodes(mesh.nodeGroup.back,4)-...
                                 mesh.nodes(mesh.nodeGroup.front,4));
                if err > 1e-10
                    disp('     *** back and front are not fully periodic!')
                    disp(['         err = ',num2str(err)])
                end

                disp('     *** back and front are periodic!')

            else
                disp('     *** back and front have different # of nodes!')

            end
        end
    end
end

% Write node groups

for i = 1:length(phy_names)
    field = strrep(phy_names{i},'"','');
    fprintf(fid, strcat('<NodeGroup name="',field,'Nodes">\n'));
    fprintf(fid, '{');
    for j = 1:length(mesh.nodeGroup.(field))
        fprintf(fid, '%d,',mesh.nodeGroup.(field)(j));
    end
    fprintf(fid, '}\n');
    fprintf(fid, strcat('</NodeGroup>\n\n'));
end

fclose(fid);

disp(' --- Mesh saved in Jive format!')

end

function saveInitPressure(mesh,density)

% GMSH 1D elements
gmsh1Delems = [1,8];

% GMSH 2D elements
gmsh2Delems = [2,3,9,10,16];

% GMSH 3D elements
gmsh3Delems = [4,5,6,7,11,12,13,14,17,18,19];

% Get filename
filename = mesh.name;

% Get element type of domain and set mesh rank
elem_type = mesh.elems(end).type;

if ismember(elem_type,gmsh1Delems)
    mesh_rank = 1;
elseif ismember(elem_type,gmsh2Delems)
    mesh_rank = 2;
elseif ismember(elem_type,gmsh3Delems)
    mesh_rank = 3;
else
    error('Parsing error!!!')
end

hmax = max(mesh.nodes(:,mesh_rank+1));
fid  = fopen(strcat(filename,'.pdata'),'wt');

fprintf(fid, strcat('<NodeTable name="','initPres">\n'));

fprintf(fid, strcat('<Section columns="','dp">\n'));

for inode = 1:length(mesh.nodes(:,1))
    hcoord = mesh.nodes(inode,mesh_rank+1);
    dp     = density*9.81*(hmax-hcoord);
    fprintf(fid,'%d %12.8f;\n',[mesh.nodes(inode,1), dp]');
end

fprintf(fid, strcat('</Section>\n'));
fprintf(fid, strcat('</NodeTable>\n\n'));

disp(' --- Initial pressure stored in .pdata file!')

end




