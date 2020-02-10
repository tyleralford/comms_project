
clc;

syms('G1','C1','G2','C2','G3','A','Gi','Go','s','Vi');

X1 = s*C1;
X2 = s*C2;
G = [ G1,-G1               ,        0,     0,  0;...
     -G1, G1+X1+G2+G3+X2   ,-G3-X2   ,-G2   ,  0;...
       0,         -G3-X2   , G3+X2+Go,     0,-Go;...
       0,            -G2   ,        0, G2+Gi,  0;...
       0,                 0,      -Go,     0, Go];
assert(all(G.'==G,'all')); %'
I = 0*Vi*zeros(size(G,1),1);%no current sources

%Voltage equations
G(1,:) = [1,0,0,0,0];
I(1) = Vi;

G(5,:) = [0,0,0,-A,-1];


V = G\I;
H = simplify(V(3)/V(1));

syms('R1','R2','R3','Ri','Ro','Ainv');
H=subs(H,G1,1/R1);
H=subs(H,G2,1/R2);
H=subs(H,G3,1/R3);
H=subs(H,Go,1/Ro);
H=subs(H,A ,1/Ainv);

H=simplify(H);
H=subs(H,Ro,0);
H=subs(H,Ainv,0);
H=simplify(H)