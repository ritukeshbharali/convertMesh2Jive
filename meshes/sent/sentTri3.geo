SetFactory("OpenCASCADE");

a   = 0.5;
l0  = 0.015;
h   = l0/8;    // 4,6,8
lc  = 0.05;

Point(1) = {-a, -a, 0, lc};
Point(2) = {a, -a, 0, lc};
Point(3) = {a, a, 0, lc};
Point(4) = {-a, a, 0, lc};
Point(5) = {-a, h/2, 0, lc};
Point(6) = {0, h/2, 0, lc};
Point(7) = {0, -h/2, 0, lc};
Point(8) = {-a, -h/2, 0, lc};
Point(9) = {0, 2*l0, 0, lc};
Point(10) = {a, 2*l0, 0, lc};
Point(11) = {a, -2*l0, 0, lc};
Point(12) = {0, -2*l0, 0, lc};

Line(1) = {1,2};
Line(2) = {2,11};
Line(3) = {11,10};
Line(4) = {10,3};
Line(5) = {3,4};
Line(6) = {4,5};
Line(7) = {5,6};
Line(8) = {6,7};
Line(9) = {7,8};
Line(10) = {8,1};
Line(11) = {6,9};
Line(12) = {9,10};
Line(13) = {11,12};
Line(14) = {12,7};

Line Loop(101) = {1,2,13,14,9,10};       Plane Surface(101) = {101};
Line Loop(102) = {4,5,6,7,11,12};        Plane Surface(102) = {102};
Line Loop(103) = {-14,-13,3,-12,-11,8};  Plane Surface(103) = {103};


Physical Line("bottom") = {1};
Physical Line("right")  = {2,3,4};
Physical Line("top")    = {5};
Physical Line("left")   = {6,10};

Physical Surface("domain") = {101,102,103};

Field[1] = Box;
Field[1].VIn = h;
Field[1].VOut = lc;
Field[1].XMin = 0;
Field[1].XMax = 0.5;
Field[1].YMin = -1*lc;
Field[1].YMax = 1*lc;
Background Field = 1;
Mesh.Algorithm = 5;

Mesh 2;
Save "sent.msh";
