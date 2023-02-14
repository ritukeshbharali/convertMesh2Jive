SetFactory("OpenCASCADE");

lc  = 0.5;
lc2 = 0.05;

Point(1) = {0, -0.375, 0, lc2};
Point(2) = {0.5, -0.4625, 0, lc2};
Point(3) = {5.0, -1.25, 0, lc};
Point(4) = {5.0, 1.25, 0, lc};
Point(5) = {0.5, 0.4625, 0, lc2};
Point(6) = {0, 0.375, 0, lc2};

Line(1) = {1,2};
Line(2) = {2,3};
Line(3) = {3,4};
Line(4) = {4,5};
Line(5) = {5,6};
Line(6) = {6,1};
Line(7) = {2,5};

Line Loop(101) = {1,7,5,6};     Plane Surface(101) = {101};
Line Loop(102) = {2,3,4,-7};    Plane Surface(102) = {102};

Recombine Surface {101};   // for quads
Recombine Surface {102};   // for quads

Physical Line("bottom") = {1,2};
Physical Line("right")  = {3};
Physical Line("top")    = {4,5};
Physical Line("left")   = {6};

Physical Surface("domain") = {101,102};

Mesh 2;
Save "taper.msh";
