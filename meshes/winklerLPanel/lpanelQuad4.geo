SetFactory("OpenCASCADE");

a   = 500;
l0  = 10;
h   = l0/4;
lc  = 25.;

Point(1) = {0, 0, 0, lc};
Point(2) = {a/2,  0, 0, lc};
Point(3) = {a/2, 230, 0, lc};
Point(4) = {a/2, a/2, 0, lc};
Point(5) = {470, a/2, 0, lc};
Point(6) = {a, a/2, 0, lc};
Point(7) = {a, a, 0, lc};
Point(8) = {0, a, 0, lc};
Point(9) = {0, 350., 0, lc};
Point(10) = {0, 230, 0, lc};
Point(11) = {a/2, 350., 0, lc};

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
Line(11) = {9,11};
Line(12) = {11,4};
Line(13) = {10,3};

Line Loop(101) = {1,2,-13,10};        Plane Surface(101) = {101};
Line Loop(102) = {4,5,6,7,8,11,12};   Plane Surface(102) = {102};
Line Loop(103) = {-13,-3,-12,-11,9};  Plane Surface(103) = {103};

Recombine Surface {101};   // for quads
Recombine Surface {102};   // for quads
Recombine Surface {103};   // for quads

Physical Line("bottom") = {1};
Physical Line("right")  = {6};
Physical Line("top")    = {7};
Physical Line("left")   = {8,9,10};
Physical Line("load")   = {5};

Physical Surface("domain") = {101,102,103};

Field[1] = Box;
Field[1].VIn = h;
Field[1].VOut = lc;
Field[1].XMin = 0;
Field[1].XMax = 250;
Field[1].YMin = 230;
Field[1].YMax = 350;
Background Field = 1;
Mesh.Algorithm = 5;

Mesh 2;
Save "lpanel.msh";