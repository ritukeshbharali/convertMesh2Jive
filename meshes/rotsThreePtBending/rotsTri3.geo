SetFactory("OpenCASCADE");

a   = 0.5;
l0  = 5;
h   = l0/5;
lc  = 25;

Point(1) = {0, 0, 0, lc};
Point(2) = {222.5, 0, 0, lc};
Point(3) = {222.5, 50, 0, lc};
Point(4) = {227.5, 50, 0, lc};
Point(5) = {227.5, 0, 0, lc};
Point(6) = {450, 0, 0, lc};
Point(7) = {450, 100, 0, lc};
Point(8) = {227.5, 100, 0, lc};
Point(9) = {222.5, 100, 0, lc};
Point(10) = {0, 100, 0, lc};

Line(1) = {1,2};
Line(2) = {2,3};
Line(3) = {3,4};
Line(4) = {4,5};
Line(5) = {5,6};
Line(6) = {6,7};
Line(7) = {7,8};
Line(8) = {8,9};
Line(9) = {9,10};
Line(10) = {10,1};

Line Loop(101) = {1,2,3,4,5,6,7,8,9,10};       Plane Surface(101) = {101};

Physical Line("bottom") = {1,5};
Physical Line("right")  = {6};
Physical Line("load")   = {8};
Physical Line("left")   = {10};

Physical Surface("domain") = {101};

Field[1] = Box;
Field[1].VIn = h;
Field[1].VOut = l0;
Field[1].XMin = 220;
Field[1].XMax = 230;
Field[1].YMin = 50;
Field[1].YMax = 100;
Background Field = 1;
Mesh.Algorithm = 5;

Mesh 2;
Save "rots.msh";
